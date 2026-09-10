import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../data/parsing/parse_exception.dart';
import '../../domain/guards/import_guards.dart';
import '../../domain/models/counter_registry.dart';
import '../../domain/models/stat_snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../messages.dart';
import '../providers/providers.dart';

/// "Add a snapshot" screen (§3.1).
///
/// The principle behind this screen: **nothing is saved before the user has
/// seen what was detected.** The export format is undocumented and can change
/// without notice (§6); the preview is what lets a parsing anomaly be spotted
/// before it pollutes the history.
class AddSnapshotScreen extends ConsumerStatefulWidget {
  const AddSnapshotScreen({super.key, this.initialText});

  /// Pre-filled text, eventually supplied by the Android share sheet.
  final String? initialText;

  @override
  ConsumerState<AddSnapshotScreen> createState() => _AddSnapshotScreenState();
}

class _AddSnapshotScreenState extends ConsumerState<AddSnapshotScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText ?? '');

  StatSnapshot? _parsed;
  ImportCheck? _check;
  ExportParseException? _error;
  bool _saving = false;

  /// The analysis produced something to show — a preview or an error.
  bool get _hasResult => _parsed != null || _error != null;

  @override
  void initState() {
    super.initState();
    if ((widget.initialText ?? '').isNotEmpty) {
      // Arriving from a share: go straight to the preview instead of making
      // the user press a button again.
      WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
    }
  }

  @override
  void didUpdateWidget(AddSnapshotScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A second share while already sitting on this screen reuses the same
    // State: go_router rebuilds the route rather than recreating the widget,
    // so initState does not run again. Without this, sharing a corrected
    // export after spotting a wrong period would keep showing the first one.
    final text = widget.initialText;
    if (text != null && text.isNotEmpty && text != oldWidget.initialText) {
      _controller.text = text;
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
      final registry = await ref.read(counterRegistryProvider.future);

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
      setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    final snapshot = _parsed;
    if (snapshot == null || _saving) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    await ref.read(snapshotRepositoryProvider).save(snapshot);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.snapshotSaved)));
    context.go(Routes.home);
  }

  /// Overriding a guard is possible, but never one click away from the message
  /// (§3.1.3): it takes a separate action, then a confirmation that spells out
  /// the consequence.
  Future<void> _saveAnyway() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveAnywayTitle),
        content: Text(l10n.saveAnywayBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.saveAnywayConfirm),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) await _save();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addSnapshotTitle),
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
                // Once there is a result the instructions have done their job,
                // and the field no longer needs six lines. On a small screen,
                // keeping both would show the decision buttons without the
                // reason behind them, pushed below the fold.
                if (!_hasResult) ...[
                  const _Instructions(),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _controller,
                  maxLines: _hasResult ? 2 : 6,
                  minLines: _hasResult ? 1 : 3,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.pasteFieldLabel,
                    hintText: l10n.pasteFieldHint,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _analyze,
                  icon: const Icon(Icons.search),
                  label: Text(l10n.analyze),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _ErrorCard(error: _error!),
                ],
                // The anomaly comes before the preview: it is the information
                // the decision hinges on, it should not have to be scrolled to.
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
          // Pinned at the bottom: otherwise the 59 counters of the preview
          // would have to be scrolled past to reach the save button, and any
          // anomaly would leave the screen at the very moment of deciding.
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
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.instructionsTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(l10n.instructionsBody),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final ExportParseException error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hint = error.rawValueHint(l10n);

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
                    l10n.parseErrorTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error.message(l10n),
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview of the detected values, shown **before** anything is saved.
class _Preview extends ConsumerWidget {
  const _Preview({required this.snapshot, required this.check});

  final StatSnapshot snapshot;
  final ImportCheck check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final theme = Theme.of(context);
    final format = DateFormat(l10n.previewDetailedDateFormat, locale);

    final headers = registry?.sortHeaders(snapshot.counters.keys) ??
        snapshot.counters.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.previewTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          l10n.previewNotSavedYet,
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
                _Field(label: l10n.fieldAgent, value: snapshot.agentName),
                _Field(label: l10n.fieldFaction, value: snapshot.faction),
                _Field(
                  label: l10n.fieldPeriod,
                  value: check.declaredTimeSpan.label(l10n),
                ),
                _Field(
                  label: l10n.fieldRecordedAt,
                  value: format.format(snapshot.recordedAt),
                ),
                _Field(
                  label: l10n.fieldLevel,
                  value: snapshot.level?.toString() ?? l10n.unknownValue,
                ),
                _Field(
                  label: l10n.fieldCounterCount,
                  value: '${snapshot.counters.length}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.detectedValues, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._grouped(headers, registry, l10n, locale).entries.map(
              (group) => _CategoryBlock(
                title: group.key,
                headers: group.value,
                snapshot: snapshot,
                registry: registry,
              ),
            ),
      ],
    );
  }

  /// Groups headers by category, in the order already computed by the
  /// registry — that is, the order of the in-game stats screen.
  Map<String, List<String>> _grouped(
    List<String> headers,
    CounterRegistry? registry,
    AppLocalizations l10n,
    String language,
  ) {
    final groups = <String, List<String>>{};
    for (final header in headers) {
      final key = registry?.categoryKeyFor(header) ??
          CounterRegistry.fallbackCategoryKey;
      final label =
          registry?.categories[key]?.label(language) ?? l10n.fallbackCategory;
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
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(title),
      subtitle: Text(l10n.counterCount(headers.length)),
      children: [
        for (final header in headers)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  // A counter that is not enriched yet shows under its raw
                  // label rather than being hidden (§3.1.2).
                  child: Text(
                    registry?.forExportHeader(header)?.label(locale) ?? header,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  NumberFormat.decimalPattern(locale)
                      .format(snapshot.counters[header]),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
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

  /// How many regressions are listed before falling back to a count. Enough to
  /// judge, short of a wall of text.
  static const _maxListed = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final extra = check.regressions.length - _maxListed;

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
                    check.title(l10n),
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
              check.message(l10n) ?? '',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            if (check.hasRegressions) ...[
              const SizedBox(height: 12),
              // The precise list of what went down, and by how much: this is
              // what lets the user judge for themselves.
              for (final regression in check.regressions.take(_maxListed))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${l10n.anomalyRegressionLine(
                      registry
                              ?.forExportHeader(regression.exportHeader)
                              ?.label(locale) ??
                          regression.exportHeader,
                      regression.previous,
                      regression.current,
                      regression.drop,
                    )}',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              if (extra > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.anomalyRegressionMore(extra),
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
          child: check.isBlocked ? _blocked(context) : _allowed(context),
        ),
      ),
    );
  }

  Widget _allowed(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: const Icon(Icons.check),
          label: Text(AppLocalizations.of(context).saveSnapshot),
        ),
      );

  /// When a guard fires, the prominent action is the one that protects the
  /// history. The override exists, but discreetly and behind a confirmation —
  /// never a button sitting next to the message (§3.1.3).
  Widget _blocked(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: () => context.go(Routes.home),
          icon: const Icon(Icons.arrow_back),
          label: Text(l10n.doNotSave),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: saving ? null : onSaveAnyway,
          child: Text(l10n.saveAnyway),
        ),
      ],
    );
  }
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
