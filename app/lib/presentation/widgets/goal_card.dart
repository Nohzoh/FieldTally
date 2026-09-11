import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/goal.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';

/// A personal target on one counter, and how it is going (§3.7).
///
/// Deliberately distinct from the badge card above it: a badge threshold comes
/// from the game, a goal is something the agent decided, and conflating the
/// two would make the app look like it invented the target.
class GoalCard extends ConsumerWidget {
  const GoalCard({
    super.key,
    required this.exportHeader,
    required this.currentValue,
    required this.progress,
  });

  final String exportHeader;
  final int currentValue;

  /// Null when no goal is set on this counter.
  final GoalProgress? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(locale.languageCode);
    final dates = DateFormat(l10n.shortDateFormat, locale.toString());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child:
                      Text(l10n.goalTitle, style: theme.textTheme.titleSmall),
                ),
                if (progress != null)
                  TextButton(
                    onPressed: () => _remove(context, ref),
                    child: Text(l10n.goalRemove),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (progress == null) ...[
              Text(l10n.goalNone, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _edit(context, ref, null),
                icon: const Icon(Icons.flag_outlined),
                label: Text(l10n.goalSet),
              ),
            ] else ...[
              Text(
                progress!.isReached
                    ? l10n.goalReached
                    : l10n.goalRemaining(
                        numbers.format(progress!.remaining),
                        numbers.format(progress!.goal.target),
                      ),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              // §3.9: the bar never carries the information alone.
              LinearProgressIndicator(
                value: progress!.progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Text(
                _status(l10n, dates),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _statusColour(theme),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _edit(context, ref, progress!.goal),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.goalEdit),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _status(AppLocalizations l10n, DateFormat dates) {
    final current = progress!;
    final deadline = current.goal.deadline;

    if (current.missedBy(DateTime.now())) {
      return l10n.goalMissed(dates.format(deadline!));
    }
    if (current.isReached) return l10n.goalReached;

    final onTrack = current.isOnTrack;
    if (onTrack == null) {
      // Either no deadline to judge against, or no pace to judge with — and
      // "no opinion" is not "behind".
      final projected = current.projectedDate;
      if (projected == null) return l10n.goalNoOpinion;
      return l10n.goalOnTrack(dates.format(projected));
    }
    return onTrack
        ? l10n.goalOnTrack(dates.format(deadline!))
        : l10n.goalBehind(dates.format(deadline!));
  }

  Color? _statusColour(ThemeData theme) {
    final current = progress!;
    if (current.missedBy(DateTime.now())) return theme.colorScheme.error;
    if (current.isOnTrack == false) return theme.colorScheme.error;
    return theme.colorScheme.outline;
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await ref.read(goalRepositoryProvider).remove(exportHeader);
    messenger.showSnackBar(SnackBar(content: Text(l10n.goalRemoved)));
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Goal? existing,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final goal = await showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _GoalSheet(
        exportHeader: exportHeader,
        currentValue: currentValue,
        existing: existing,
      ),
    );
    if (goal == null) return;

    await ref.read(goalRepositoryProvider).set(goal);
    messenger.showSnackBar(SnackBar(content: Text(l10n.goalSaved)));
  }
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({
    required this.exportHeader,
    required this.currentValue,
    required this.existing,
  });

  final String exportHeader;
  final int currentValue;
  final Goal? existing;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late final TextEditingController _target = TextEditingController(
    text: widget.existing?.target.toString() ?? '',
  );

  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _deadline = widget.existing?.deadline;
  }

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  /// A target at or below where the counter already stands is not a goal, it
  /// is a statement of the present.
  int? get _validTarget {
    final parsed = int.tryParse(_target.text.trim());
    if (parsed == null || parsed <= widget.currentValue) return null;
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dates = DateFormat(l10n.shortDateFormat, locale);
    final target = _validTarget;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.goalTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _target,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.goalTarget,
              errorText: _target.text.trim().isEmpty || target != null
                  ? null
                  : l10n.goalInvalid,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _deadline == null
                      ? l10n.goalNoDeadline
                      : '${l10n.goalDeadline} · ${dates.format(_deadline!)}',
                ),
              ),
              if (_deadline != null)
                TextButton(
                  onPressed: () => setState(() => _deadline = null),
                  child: Text(l10n.goalClearDeadline),
                ),
              TextButton(
                onPressed: _pickDeadline,
                child: Text(l10n.goalPickDeadline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: target == null ? null : () => _submit(target),
              child: Text(l10n.goalSave),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _submit(int target) {
    Navigator.of(context).pop(
      Goal(
        exportHeader: widget.exportHeader,
        target: target,
        deadline: _deadline,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      ),
    );
  }
}
