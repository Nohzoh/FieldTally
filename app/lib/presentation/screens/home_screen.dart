import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../domain/repositories/snapshot_repository.dart';
import '../providers/providers.dart';

/// Liste des relevés enregistrés.
///
/// Ce n'est **pas** le tableau de bord du §3.3 : celui-ci viendra remplacer
/// cet écran, avec ses cartes épinglées et ses sparklines. En attendant, il
/// faut bien un endroit d'où ajouter un relevé et vérifier ce qui a été
/// enregistré.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(snapshotsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('FieldTally')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.addSnapshot),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un relevé'),
      ),
      body: snapshots.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _Message(
          icon: Icons.error_outline,
          title: 'Impossible de lire l\'historique',
          detail: '$error',
        ),
        data: (list) => list.isEmpty
            ? const _Message(
                icon: Icons.query_stats,
                title: 'Aucun relevé pour l\'instant',
                detail: 'Partage tes stats depuis Ingress, ou colle le texte '
                    'exporté pour créer ton premier relevé.',
              )
            : _SnapshotList(snapshots: list),
      ),
    );
  }
}

class _SnapshotList extends ConsumerWidget {
  const _SnapshotList({required this.snapshots});

  final List<StoredSnapshot> snapshots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = DateFormat('d MMMM y \'à\' HH:mm', 'fr');

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: snapshots.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final stored = snapshots[index];
        final snapshot = stored.snapshot;

        return ListTile(
          leading: CircleAvatar(child: Text('${snapshot.level}')),
          title: Text(format.format(snapshot.recordedAt)),
          subtitle: Text(
            '${snapshot.counters.length} compteurs • ${snapshot.agentName}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer ce relevé',
            onPressed: () => _confirmDelete(context, ref, stored),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    StoredSnapshot stored,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce relevé ?'),
        content: const Text(
          'Il disparaîtra de l\'historique et des graphiques. '
          'Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(snapshotRepositoryProvider).delete(stored.id);
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              detail,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
