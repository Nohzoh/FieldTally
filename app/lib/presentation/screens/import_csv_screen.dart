import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../data/parsing/agent_stats_csv_parser.dart';
import '../../data/parsing/parse_exception.dart';
import '../../domain/csv_import.dart';
import '../../l10n/app_localizations.dart';
import '../messages.dart';
import '../providers/providers.dart';

/// Bulk import of an Agent Stats history (§3.1, Appendix B).
///
/// The on-ramp for the second target user of §2: someone who already has years
/// of history elsewhere and would otherwise have to start from zero.
///
/// Same principle as a single paste — nothing is written before the agent has
/// seen what would land — but the checking is heavier, because a file spanning
/// years can hold a bad row anywhere in the middle.
class ImportCsvScreen extends ConsumerStatefulWidget {
  const ImportCsvScreen({super.key});

  @override
  ConsumerState<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends ConsumerState<ImportCsvScreen> {
  final _controller = TextEditingController();

  CsvImportPlan? _plan;
  ExportParseException? _error;
  bool _saving = false;

  bool get _hasResult => _plan != null || _error != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    setState(() {
      _plan = null;
      _error = null;
    });

    try {
      final registry = await ref.read(counterRegistryProvider.future);
      final snapshots = AgentStatsCsvParser(registry: registry)
          .parse(_controller.text);
      final existing = await ref.read(snapshotRepositoryProvider).latest();

      if (!mounted) return;
      setState(() {
        _plan = const CsvImportPlanner().plan(
          snapshots,
          existingLatest: existing?.snapshot,
          registry: registry,
        );
      });
    } on ExportParseException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<void> _import() async {
    final plan = _plan;
    if (plan == null || _saving) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);

    final repository = ref.read(snapshotRepositoryProvider);
    for (final snapshot in plan.snapshots) {
      await repository.save(snapshot);
    }

    // Deliberately no milestone notifications here: importing a year of
    // history crosses tiers that were earned long ago, and announcing them
    // would be a burst of stale congratulations (§3.7). The reminder is still
    // re-armed, because the newest snapshot has just moved.
    await ref.read(notificationCoordinatorProvider).rescheduleReminder(
          latestSnapshot: (await repository.latest())?.snapshot.recordedAt,
          l10n: l10n,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.importCsvDone(plan.snapshots.length))),
    );
    context.go(Routes.snapshots);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final dates = DateFormat(l10n.shortDateFormat, locale);
    final plan = _plan;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importCsvTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(Routes.snapshots),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!_hasResult) ...[
                  Text(l10n.importCsvInstructions),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _controller,
                  maxLines: _hasResult ? 2 : 8,
                  minLines: _hasResult ? 1 : 4,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.importCsvField,
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
                if (plan != null && plan.isBlocked) ...[
                  const SizedBox(height: 16),
                  _AnomalyCard(plan: plan, dates: dates),
                ],
                if (plan != null && !plan.isEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.importCsvSummary(
                      plan.snapshots.length,
                      plan.counterCount,
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.importCsvRange(
                      dates.format(plan.from!),
                      dates.format(plan.to!),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  // Said out loud rather than left implicit: on this path the
                  // declarative guard simply does not exist.
                  Text(
                    l10n.importCsvNoTimeSpan,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ],
            ),
          ),
          if (plan != null && !plan.isEmpty)
            Material(
              elevation: 8,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: plan.isBlocked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.icon(
                              onPressed: () => context.go(Routes.snapshots),
                              icon: const Icon(Icons.arrow_back),
                              label: Text(l10n.doNotSave),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: _saving ? null : _confirmOverride,
                              child: Text(l10n.saveAnyway),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _import,
                            icon: const Icon(Icons.download),
                            label: Text(
                              l10n.importCsvConfirm(plan.snapshots.length),
                            ),
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Same rule as a single import (§3.1.3): overriding takes a separate action
  /// and a confirmation, never a button beside the message.
  Future<void> _confirmOverride() async {
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

    if ((confirmed ?? false) && mounted) await _import();
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final ExportParseException error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
          ],
        ),
      ),
    );
  }
}

class _AnomalyCard extends ConsumerWidget {
  const _AnomalyCard({required this.plan, required this.dates});

  final CsvImportPlan plan;
  final DateFormat dates;

  static const _maxListed = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final extra = plan.regressions.length - _maxListed;

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
                    l10n.importCsvAnomalyTitle,
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
              l10n.importCsvAnomaly(plan.regressions.length),
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 12),
            for (final found in plan.regressions.take(_maxListed))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${l10n.importCsvAnomalyLine(
                    dates.format(found.at),
                    registry
                            ?.forExportHeader(found.regression.exportHeader)
                            ?.label(language) ??
                        found.regression.exportHeader,
                    found.regression.previous,
                    found.regression.current,
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
        ),
      ),
    );
  }
}
