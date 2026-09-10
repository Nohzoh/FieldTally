import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import 'activity_calendar.dart';

/// The activity section: caption, calendar and the same facts in words (§3.5).
///
/// Each square is the AP gained **on the day the snapshot that measured it was
/// taken**, not per-day activity. Between two snapshots a week apart nothing
/// tells us which days were actually played, and spreading the total evenly
/// would invent data the app never measured — hence the caption above the
/// calendar rather than a silent approximation.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.activityByDay,
    required this.from,
    required this.to,
  });

  final Map<DateTime, int> activityByDay;

  /// Span of the whole history, so the calendar shows the quiet stretches too.
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    if (activityByDay.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          l10n.activityEmpty,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      );
    }

    final peak = activityByDay.values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.activityTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            l10n.activitySubtitle,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          ActivityCalendar(activityByDay: activityByDay, from: from, to: to),
          const SizedBox(height: 4),
          // §3.9: the calendar is never the only carrier of information, so
          // the same facts are stated in words underneath it.
          Text(
            l10n.activitySummary(
              activityByDay.length,
              NumberFormat.compact(locale: locale).format(peak),
            ),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

}
