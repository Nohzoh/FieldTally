import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../domain/guards/import_guards.dart';
import '../../domain/models/stat_snapshot.dart';
import '../../domain/repositories/snapshot_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';

/// Corrects a snapshot entered by mistake (§3.2).
///
/// Nothing derived is ever stored, so a correction propagates to the diffs,
/// the charts and the projections on its own — which is the whole reason §3.2
/// can offer this at all.
///
/// The consistency check of §3.1.3 runs on the corrected values too, against
/// both neighbours: a correction is another way to put a wrong number into the
/// history, and it would be odd to guard the front door and leave this one
/// open.
class EditSnapshotScreen extends ConsumerStatefulWidget {
  const EditSnapshotScreen({super.key, required this.snapshotId});

  final String snapshotId;

  @override
  ConsumerState<EditSnapshotScreen> createState() => _EditSnapshotScreenState();
}

class _EditSnapshotScreenState extends ConsumerState<EditSnapshotScreen> {
  final _controllers = <String, TextEditingController>{};

  StoredSnapshot? _original;
  DateTime? _recordedAt;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _adopt(StoredSnapshot stored) {
    if (_original != null) return;
    _original = stored;
    _recordedAt = stored.snapshot.recordedAt;
    for (final entry in stored.snapshot.counters.entries) {
      _controllers[entry.key] = TextEditingController(text: '${entry.value}');
    }
  }

  StatSnapshot? _edited() {
    final original = _original;
    if (original == null) return null;

    final counters = <String, int>{};
    for (final entry in _controllers.entries) {
      final parsed = int.tryParse(entry.value.text.trim());
      // A field left unreadable keeps the snapshot unsaveable rather than
      // silently reverting to its old value.
      if (parsed == null) return null;
      counters[entry.key] = parsed;
    }

    return StatSnapshot(
      timeSpan: original.snapshot.timeSpan,
      agentName: original.snapshot.agentName,
      faction: original.snapshot.faction,
      recordedAt: _recordedAt ?? original.snapshot.recordedAt,
      level: original.snapshot.level,
      counters: counters,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final dates = DateFormat(l10n.previewDetailedDateFormat, locale);

    final all = ref.watch(snapshotsProvider).asData?.value ?? const [];
    final stored = all.where((s) => s.id == widget.snapshotId).firstOrNull;
    if (stored == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editSnapshotTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _adopt(stored);

    final edited = _edited();
    final regressions = edited == null ? 0 : _regressionsFor(edited, all);
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final language = Localizations.localeOf(context).languageCode;
    final headers = registry?.sortHeaders(_controllers.keys) ??
        (_controllers.keys.toList()..sort());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editSnapshotTitle),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.editRecordedAt,
                            style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(dates.format(_recordedAt!),
                            style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.event),
                              label: Text(l10n.editPickDate),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickTime,
                              icon: const Icon(Icons.schedule),
                              label: Text(l10n.editPickTime),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (regressions > 0) ...[
                  const SizedBox(height: 16),
                  _AnomalyCard(count: regressions),
                ],
                const SizedBox(height: 20),
                Text(l10n.editCounterSection,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final header in headers)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextField(
                      controller: _controllers[header],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                      ],
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        labelText: registry
                                ?.forExportHeader(header)
                                ?.label(language) ??
                            header,
                        errorText:
                            int.tryParse(_controllers[header]!.text.trim()) ==
                                    null
                                ? l10n.editInvalidValue
                                : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: edited == null || _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.editSave),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Counts what would go backwards, against the snapshot before and the one
  /// after: a correction sits inside an existing sequence, so both sides
  /// matter.
  int _regressionsFor(StatSnapshot edited, List<StoredSnapshot> all) {
    final registry = ref.read(counterRegistryProvider).asData?.value;
    const guards = ImportGuards();

    final others = [
      for (final item in all)
        if (item.id != widget.snapshotId) item,
    ]..sort((a, b) => a.snapshot.recordedAt.compareTo(b.snapshot.recordedAt));

    StatSnapshot? before;
    StatSnapshot? after;
    for (final item in others) {
      if (item.snapshot.recordedAt.isAfter(edited.recordedAt)) {
        after ??= item.snapshot;
        break;
      }
      before = item.snapshot;
    }

    var count =
        guards.check(edited, previous: before, registry: registry).regressions.length;
    if (after != null) {
      count += guards
          .check(after, previous: edited, registry: registry)
          .regressions
          .length;
    }
    return count;
  }

  Future<void> _pickDate() async {
    final current = _recordedAt!;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2012),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _recordedAt = DateTime(picked.year, picked.month, picked.day,
          current.hour, current.minute, current.second);
    });
  }

  Future<void> _pickTime() async {
    final current = _recordedAt!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null) return;
    setState(() {
      _recordedAt = DateTime(current.year, current.month, current.day,
          picked.hour, picked.minute);
    });
  }

  Future<void> _save() async {
    final edited = _edited();
    if (edited == null || _saving) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    await ref
        .read(snapshotRepositoryProvider)
        .update(widget.snapshotId, edited);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.editSaved)));
    context.go(Routes.snapshots);
  }
}

/// Warns without blocking: unlike an import, a correction is a deliberate act
/// on a snapshot the agent is already looking at, and the sequence they are
/// mending may legitimately look odd mid-edit.
class _AnomalyCard extends StatelessWidget {
  const _AnomalyCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.report_problem, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.editAnomalyTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.editAnomaly(count),
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
