import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../data/parsing/parse_exception.dart';
import '../../domain/guards/import_guards.dart';
import '../../domain/models/counter_registry.dart';
import '../../domain/models/stat_snapshot.dart';
import '../providers/providers.dart';

/// Écran « Ajouter un relevé » (§3.1).
///
/// Le principe qui structure cet écran : **rien n'est enregistré avant que
/// l'utilisateur ait vu ce qui a été détecté.** Le format d'export n'est pas
/// documenté et peut changer sans préavis (§6) ; l'aperçu est ce qui permet de
/// repérer une anomalie de parsing avant qu'elle ne pollue l'historique.
class AddSnapshotScreen extends ConsumerStatefulWidget {
  const AddSnapshotScreen({super.key, this.initialText});

  /// Texte pré-rempli, à terme fourni par la feuille de partage Android.
  final String? initialText;

  @override
  ConsumerState<AddSnapshotScreen> createState() => _AddSnapshotScreenState();
}

class _AddSnapshotScreenState extends ConsumerState<AddSnapshotScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText ?? '');

  StatSnapshot? _parsed;
  ImportCheck? _check;
  String? _error;
  bool _saving = false;

  /// L'analyse a produit quelque chose à montrer — un aperçu ou une erreur.
  bool get _hasResult => _parsed != null || _error != null;

  @override
  void initState() {
    super.initState();
    if ((widget.initialText ?? '').isNotEmpty) {
      // Arrivée depuis un partage : on va droit à l'aperçu, sans faire
      // retaper sur un bouton.
      WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    setState(() {
      _parsed = null;
      _check = null;
      _error = null;
    });

    try {
      final snapshot = ref.read(parserProvider).parseSingle(_controller.text);
      final previous = await ref.read(snapshotRepositoryProvider).latest();
      final registry =
          await ref.read(counterRegistryProvider.future);

      if (!mounted) return;
      setState(() {
        _parsed = snapshot;
        _check = ref.read(importGuardsProvider).check(
              snapshot,
              previous: previous?.snapshot,
              registry: registry,
            );
      });
    } on ExportParseException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _save() async {
    final snapshot = _parsed;
    if (snapshot == null || _saving) return;

    setState(() => _saving = true);
    await ref.read(snapshotRepositoryProvider).save(snapshot);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Relevé enregistré.')),
    );
    context.go(Routes.home);
  }

  /// Passer outre un garde-fou est possible, mais jamais d'un simple clic à
  /// côté du message (§3.1.3) : il faut une action distincte, puis une
  /// confirmation qui rappelle la conséquence.
  Future<void> _saveAnyway() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrer malgré l\'anomalie ?'),
        content: const Text(
          'Ce relevé est incohérent avec ton historique. L\'enregistrer '
          'faussera durablement tes diffs, tes graphiques et tes projections '
          'de paliers.\n\n'
          'Ne continue que si tu sais précisément pourquoi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer quand même'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un relevé'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Une fois qu'il y a un résultat, la consigne a fait son office
                // et le champ n'a plus besoin d'occuper six lignes. Sur un
                // petit écran, les garder afficherait les boutons de décision
                // sans la raison qui les justifie, reléguée sous la ligne de
                // flottaison.
                if (!_hasResult) ...[
                  const _Instructions(),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _controller,
                  maxLines: _hasResult ? 2 : 6,
                  minLines: _hasResult ? 1 : 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Texte exporté par Ingress',
                    hintText:
                        'Colle ici le texte partagé depuis l\'écran de stats…',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _analyze,
                  icon: const Icon(Icons.search),
                  label: const Text('Analyser'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _ErrorCard(message: _error!),
                ],
                // L'anomalie passe avant l'aperçu : c'est l'information qui
                // conditionne la décision, elle ne doit pas se mériter au
                // défilement.
                if (_check?.isBlocked ?? false) ...[
                  const SizedBox(height: 16),
                  _AnomalyCard(check: _check!),
                ],
                if (_parsed != null && _check != null) ...[
                  const SizedBox(height: 24),
                  _Preview(snapshot: _parsed!, check: _check!),
                ],
              ],
            ),
          ),
          // Épinglée en bas : sans ça, il faudrait faire défiler les 59
          // compteurs de l'aperçu pour atteindre le bouton d'enregistrement,
          // et l'anomalie éventuelle sortirait du champ de vision au moment
          // précis où il faut décider.
          if (_parsed != null && _check != null)
            _SaveActionBar(
              check: _check!,
              saving: _saving,
              onSave: _save,
              onSaveAnyway: _saveAnyway,
            ),
        ],
      ),
    );
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Depuis Ingress', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            const Text(
              'Écran de stats → sélectionne « All Time » → Partager. '
              'Vérifie bien la période : un export « This Week » fausserait '
              'ton historique.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lecture impossible',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: TextStyle(color: scheme.onErrorContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aperçu des valeurs détectées, montré **avant** tout enregistrement.
class _Preview extends ConsumerWidget {
  const _Preview({required this.snapshot, required this.check});

  final StatSnapshot snapshot;
  final ImportCheck check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final theme = Theme.of(context);
    final format = DateFormat('d MMMM y \'à\' HH:mm:ss', 'fr');

    final headers = registry?.sortHeaders(snapshot.counters.keys) ??
        snapshot.counters.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aperçu', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Rien n\'est enregistré tant que tu n\'as pas confirmé.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Field(label: 'Agent', value: snapshot.agentName),
                _Field(label: 'Faction', value: snapshot.faction),
                _Field(label: 'Période', value: check.declaredTimeSpanLabel),
                _Field(label: 'Relevé du', value: format.format(snapshot.recordedAt)),
                _Field(label: 'Niveau', value: '${snapshot.level}'),
                _Field(
                  label: 'Compteurs détectés',
                  value: '${snapshot.counters.length}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Valeurs détectées', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...(_grouped(headers, registry).entries.map(
              (group) => _CategoryBlock(
                title: group.key,
                headers: group.value,
                snapshot: snapshot,
                registry: registry,
              ),
            )),
      ],
    );
  }

  /// Regroupe les en-têtes par catégorie, dans l'ordre déjà calculé par le
  /// registre — donc celui de l'écran de stats du jeu.
  Map<String, List<String>> _grouped(
    List<String> headers,
    CounterRegistry? registry,
  ) {
    final groups = <String, List<String>>{};
    for (final header in headers) {
      final key = registry?.categoryKeyFor(header) ??
          CounterRegistry.fallbackCategoryKey;
      final label = registry?.categories[key]?.label('fr') ?? 'Autres';
      (groups[label] ??= []).add(header);
    }
    return groups;
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.title,
    required this.headers,
    required this.snapshot,
    required this.registry,
  });

  final String title;
  final List<String> headers;
  final StatSnapshot snapshot;
  final CounterRegistry? registry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(title),
      subtitle: Text('${headers.length} compteurs'),
      children: [
        for (final header in headers)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  // Un compteur pas encore enrichi s'affiche sous son libellé
                  // brut plutôt que d'être masqué (§3.1.2).
                  child: Text(
                    registry?.forExportHeader(header)?.label('fr') ?? header,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  NumberFormat.decimalPattern('fr')
                      .format(snapshot.counters[header]),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AnomalyCard extends ConsumerWidget {
  const _AnomalyCard({required this.check});

  final ImportCheck check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final registry = ref.watch(counterRegistryProvider).asData?.value;

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report_problem, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    check.isPartialPeriod
                        ? 'Période partielle détectée'
                        : 'Incohérence avec ton historique',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              check.message ?? '',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            if (check.hasRegressions) ...[
              const SizedBox(height: 12),
              // La liste précise de ce qui a reculé, et de combien : c'est ce
              // qui permet à l'utilisateur de juger par lui-même.
              for (final regression in check.regressions.take(10))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${registry?.forExportHeader(regression.exportHeader)?.label('fr') ?? regression.exportHeader} : '
                    '${regression.previous} → ${regression.current} '
                    '(−${regression.drop})',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              if (check.regressions.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '… et ${check.regressions.length - 10} autres.',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SaveActionBar extends StatelessWidget {
  const _SaveActionBar({
    required this.check,
    required this.saving,
    required this.onSave,
    required this.onSaveAnyway,
  });

  final ImportCheck check;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onSaveAnyway;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: check.isBlocked ? _blocked(context) : _allowed(),
        ),
      ),
    );
  }

  Widget _allowed() => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: const Icon(Icons.check),
          label: const Text('Enregistrer ce relevé'),
        ),
      );

  /// Quand un garde-fou se déclenche, l'action mise en avant est celle qui
  /// protège l'historique. Le contournement existe, mais discret et derrière
  /// une confirmation — jamais un bouton posé à côté du message (§3.1.3).
  Widget _blocked(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: () => context.go(Routes.home),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Ne pas enregistrer'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: saving ? null : onSaveAnyway,
            child: const Text('Enregistrer quand même…'),
          ),
        ],
      );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
