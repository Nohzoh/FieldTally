import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../data/parsing/fieldtally_csv_parser.dart';
import '../../data/parsing/parse_exception.dart';
import '../../domain/csv_import.dart';
import '../../l10n/app_localizations.dart';
import '../import_commit.dart';
import '../providers/providers.dart';
import '../widgets/import_feedback.dart';

/// Reading a FieldTally export back in (#191).
///
/// The other half of §3.8: the app has always been able to write the file and
/// never able to read it, while the FAQ told agents changing phone that it
/// could. This is that promise made true.
///
/// A file, not a paste, unlike the Agent Stats screen next door — the export
/// arrives as a file and a history spanning years does not fit a text field.
/// Same principle otherwise: nothing is written before the agent has seen
/// what would land.
class ImportFieldTallyScreen extends ConsumerStatefulWidget {
  const ImportFieldTallyScreen({super.key});

  @override
  ConsumerState<ImportFieldTallyScreen> createState() =>
      _ImportFieldTallyScreenState();
}

class _ImportFieldTallyScreenState
    extends ConsumerState<ImportFieldTallyScreen> {
  String? _fileName;
  CsvImportPlan? _plan;
  ExportParseException? _error;
  bool _saving = false;

  Future<void> _choose() async {
    final picked = await ref.read(exportFilePickerProvider).pick();
    // Null is the agent backing out of the system picker, which is not a
    // failure and should leave whatever they were looking at alone.
    if (picked == null || !mounted) return;

    setState(() {
      _fileName = picked.name;
      _plan = null;
      _error = null;
    });

    try {
      final snapshots = const FieldTallyCsvParser().parse(picked.content);
      final registry = await ref.read(counterRegistryProvider.future);
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

    await commitImport(ref, plan.snapshots, l10n: l10n);

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
    final fileName = _fileName;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importFieldTallyTitle),
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
                Text(l10n.importFieldTallyInstructions),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _choose,
                  icon: const Icon(Icons.folder_open),
                  label: Text(l10n.importFieldTallyChoose),
                ),
                if (fileName != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    fileName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  ImportErrorCard(error: _error!),
                ],
                if (plan != null && plan.isBlocked) ...[
                  const SizedBox(height: 16),
                  ImportAnomalyCard(plan: plan, dates: dates),
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
                  // The export carries the snapshots and nothing else, and
                  // someone restoring a phone is exactly the person who would
                  // otherwise assume it carried everything.
                  Text(
                    l10n.importFieldTallySnapshotsOnly,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
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

  /// Same rule as everywhere else (§3.1.3): overriding takes a separate action
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
