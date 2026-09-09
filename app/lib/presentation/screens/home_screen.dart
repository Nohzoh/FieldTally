import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../domain/repositories/snapshot_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';

/// List of saved snapshots.
///
/// This is **not** the dashboard of §3.3: that one will replace this screen,
/// with its pinned cards and sparklines. In the meantime there has to be
/// somewhere to add a snapshot from and to check what was saved.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snapshots = ref.watch(snapshotsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: l10n.countersTitle,
            onPressed: () => context.go(Routes.counters),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.addSnapshot),
        icon: const Icon(Icons.add),
        label: Text(l10n.addSnapshotAction),
      ),
      body: snapshots.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _Message(
          icon: Icons.error_outline,
          title: l10n.homeLoadError,
          detail: '$error',
        ),
        data: (list) => list.isEmpty
            ? _Message(
                icon: Icons.query_stats,
                title: l10n.homeEmptyTitle,
                detail: l10n.homeEmptyDetail,
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
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat(l10n.snapshotDateFormat, locale);

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
            l10n.snapshotSubtitle(snapshot.counters.length, snapshot.agentName),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deleteSnapshotTooltip,
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
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSnapshotTitle),
        content: Text(l10n.deleteSnapshotBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
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
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
  });

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
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
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
