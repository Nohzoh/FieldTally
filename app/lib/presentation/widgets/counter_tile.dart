import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/tracked_counter.dart';
import '../../l10n/app_localizations.dart';

/// One row of the counter list (§3.4).
///
/// Shows the current value, the progress since the previous snapshot, and —
/// for a counter that has stopped appearing in imports — a discreet chip
/// saying since when. The counter stays in its usual category rather than
/// being moved to a separate screen (§3.1.2).
class CounterTile extends StatelessWidget {
  const CounterTile({
    super.key,
    required this.counter,
    required this.label,
    this.onTap,
  });

  final TrackedCounter counter;

  /// Already resolved by the caller: the enriched translation, or the raw
  /// export header when the registry does not know this counter.
  final String label;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(locale);

    return ListTile(
      onTap: onTap,
      title: Text(label),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              _delta(l10n, numbers),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!counter.isActive) ...[
            const SizedBox(width: 8),
            _InactiveChip(lastSeen: counter.lastSeen),
          ],
        ],
      ),
      trailing: Text(
        numbers.format(counter.lastValue),
        style: theme.textTheme.titleMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  String _delta(AppLocalizations l10n, NumberFormat numbers) {
    final delta = counter.delta;
    // Null and zero are different things: "no comparison point yet" versus
    // "no progress since last time".
    if (delta == null) return l10n.noDelta;
    final formatted = numbers.format(delta.abs());
    return l10n.deltaSince(delta >= 0 ? '+$formatted' : '−$formatted');
  }
}

class _InactiveChip extends StatelessWidget {
  const _InactiveChip({required this.lastSeen});

  final DateTime lastSeen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        l10n.inactiveSince(DateFormat(l10n.shortDateFormat, locale)
            .format(lastSeen)),
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.outline),
      ),
    );
  }
}
