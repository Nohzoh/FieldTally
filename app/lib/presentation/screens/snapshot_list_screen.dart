import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/router.dart';
import '../../domain/repositories/snapshot_repository.dart';
import '../../domain/counter_series.dart';
import '../../domain/history_export.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/activity_heatmap.dart';

/// List of saved snapshots (§3.2).
///
/// Split out of the home screen once the dashboard took its place: reviewing,
/// correcting and deleting snapshots is bookkeeping, not something to put in
/// front of someone opening the app to check their progress.
class SnapshotListScreen extends ConsumerWidget {
  const SnapshotListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snapshots = ref.watch(snapshotsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.snapshotsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
        actions: [
          // Import and export both live here rather than on the dashboard:
          // this is the screen about the history itself.
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: l10n.importCsvAction,
            onPressed: () => context.go(Routes.importCsv),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.exportCsv,
            onPressed: () => _exportHistory(context, ref),
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

/// Hands the whole history to the system share sheet as a CSV (§3.8).
///
/// Shared rather than written somewhere fixed: on Android the agent then picks
/// where it goes — Drive, mail, a file manager — instead of the app deciding
/// for them and hiding the file in its own storage.
Future<void> _exportHistory(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final stored = await ref.read(snapshotRepositoryProvider).all();
  if (stored.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.exportCsvEmpty)));
    return;
  }

  final registry = ref.read(counterRegistryProvider).asData?.value;
  final exporter = HistoryCsvExporter(registry: registry);
  final csv = exporter.build(stored);

  // Written to a real temporary file rather than handed over as bytes:
  // share_plus names a data-backed file after a UUID, so the export landed in
  // the agent's Drive as "de7-11f1-….csv".
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/${exporter.fileNameFor(DateTime.now())}');
  await file.writeAsString(csv);

  await SharePlus.instance.share(
    ShareParams(
      subject: l10n.exportCsvSubject,
      files: [XFile(file.path, mimeType: 'text/csv')],
    ),
  );

  messenger.showSnackBar(
    SnackBar(content: Text(l10n.exportCsvDone(stored.length))),
  );
}

class _SnapshotList extends ConsumerWidget {
  const _SnapshotList({required this.snapshots});

  final List<StoredSnapshot> snapshots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat(l10n.snapshotDateFormat, locale);

    // The calendar sits above the list: §3.5 wants it in a global view, and
    // this is the screen that already answers "when did I record what".
    final dates = [for (final stored in snapshots) stored.snapshot.recordedAt]
      ..sort();
    final activity = const CounterSeriesBuilder()
        .activityByDay([for (final stored in snapshots) stored.snapshot]);

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: snapshots.length + 1,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ActivityHeatmap(
                activityByDay: activity,
                from: dates.first,
                to: dates.last,
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        final stored = snapshots[index - 1];
        final snapshot = stored.snapshot;

        return ListTile(
          // A migrated snapshot has no level: the Agent Stats format carries
          // no such column (Appendix B), so the avatar says so rather than
          // printing the absence.
          leading: CircleAvatar(
            child: Text(
              snapshot.level?.toString() ?? l10n.unknownValue,
            ),
          ),
          title: Text(format.format(snapshot.recordedAt)),
          subtitle: Text(
            l10n.snapshotSubtitle(snapshot.counters.length, snapshot.agentName),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.editSnapshotTooltip,
                onPressed: () => context.go(Routes.editSnapshot(stored.id)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.deleteSnapshotTooltip,
                onPressed: () => _confirmDelete(context, ref, stored),
              ),
            ],
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
