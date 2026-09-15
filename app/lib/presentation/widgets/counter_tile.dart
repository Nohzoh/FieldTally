import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/tracked_counter.dart';
import '../../l10n/app_localizations.dart';
import '../tier_labels.dart';
import 'medal_icon.dart';

/// One row of the counter list (§3.4).
///
/// Shows the current value, the progress since the previous snapshot, and —
/// for a counter that has stopped appearing in imports — a discreet chip
/// saying since when. The counter stays in its usual category rather than
/// being moved to a separate screen (§3.1.2).
///
/// Counters that carry a badge get its emblem in the leading slot (#63). The
/// slot is reserved even when there is no emblem, so the labels of a mixed
/// category still line up.
class CounterTile extends StatelessWidget {
  const CounterTile({
    super.key,
    required this.counter,
    required this.label,
    this.medalKey,
    this.tierName,
    this.tierMultiple,
    this.onTap,
  });

  final TrackedCounter counter;

  /// Already resolved by the caller: the enriched translation, or the raw
  /// export header when the registry does not know this counter.
  final String label;

  /// Registry key of the counter, when it has one and an emblem exists for
  /// it. Null leaves the slot empty.
  final String? medalKey;

  /// Highest tier reached, or null when the first threshold is still ahead.
  final String? tierName;

  /// How many whole times the top tier has been reached, once every tier is
  /// behind (#87). Null while a tier is still ahead.
  final int? tierMultiple;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(locale);

    return ListTile(
      onTap: onTap,
      // The emblem says nothing a screen reader cannot already read out of
      // this tile: the counter is the title, the tier is spelled out in the
      // subtitle right beside it (§3.9).
      leading: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 28,
          child: medalKey == null
              ? null
              : MedalIcon(counterKey: medalKey!, tierName: tierName),
        ),
      ),
      title: Text(label),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              _subtitle(l10n, numbers),
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

  /// The tier in words ahead of the delta, because the metal in the emblem is
  /// a colour and a colour is never the only carrier (§3.9). Counters with no
  /// emblem read exactly as they did before.
  String _subtitle(AppLocalizations l10n, NumberFormat numbers) {
    final delta = _delta(l10n, numbers);
    if (medalKey == null) return delta;
    return '${_tier(l10n)} · $delta';
  }

  /// From two upwards, for the reason the projection card gives: a bare "x 1"
  /// says nothing the medal beside it does not.
  String _tier(AppLocalizations l10n) {
    if (tierName == null) return l10n.medalNone;
    final tier = tierLabel(l10n, tierName!);
    final multiple = tierMultiple;
    if (multiple == null || multiple < 2) return l10n.medalTier(tier);
    return l10n.medalTierMultiple(tier, multiple);
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
