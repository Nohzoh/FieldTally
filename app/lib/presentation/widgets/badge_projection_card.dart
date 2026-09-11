import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/badge_projection.dart';
import '../../l10n/app_localizations.dart';

/// Where a counter stands against its badge tiers, and when the next one is
/// likely to land (§3.6).
///
/// Deliberately says "no estimate" rather than inventing a date when the pace
/// is flat, negative or so slow the answer would be decades out. A projection
/// nobody can act on is worse than an honest blank, because it looks like
/// information.
class BadgeProjectionCard extends StatelessWidget {
  const BadgeProjectionCard({
    super.key,
    required this.projection,
    required this.measuredFrom,
    required this.onWindowChanged,
  });

  final BadgeProjection projection;

  /// When the pace was last observed — the latest snapshot, not today.
  final DateTime measuredFrom;

  final ValueChanged<ProjectionWindow> onWindowChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(locale.languageCode);
    final dates = DateFormat(l10n.shortDateFormat, locale.toString());

    final next = projection.next;
    final date = projection.projectedDate(measuredFrom);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.projectionTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (next == null)
              Text(l10n.projectionComplete, style: theme.textTheme.bodyMedium)
            else ...[
              Text(
                l10n.projectionRemaining(
                  numbers.format(projection.remaining),
                  _tierLabel(l10n, next.name),
                ),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              // §3.9: the bar is never the only carrier — the figures above
              // and below say the same thing in words.
              LinearProgressIndicator(
                value: projection.progress ?? 0,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Text(
                _estimate(l10n, dates, date),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              if (projection.perDay != null && projection.perDay! > 0)
                Text(
                  l10n.projectionPace(
                    numbers.format(projection.perDay!.round()),
                    _windowLabel(l10n, projection.window),
                  ),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              const SizedBox(height: 12),
              // Labelled differently from the chart's range selector on the
              // same screen: one picks what is plotted, the other how far back
              // the pace is measured, and sharing "Week / Month" between them
              // read as the same control twice.
              SegmentedButton<ProjectionWindow>(
                segments: [
                  ButtonSegment(
                    value: ProjectionWindow.week,
                    label: Text(l10n.projectionPaceWeek),
                  ),
                  ButtonSegment(
                    value: ProjectionWindow.month,
                    label: Text(l10n.projectionPaceMonth),
                  ),
                ],
                selected: {projection.window},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    onWindowChanged(selection.first),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _estimate(
    AppLocalizations l10n,
    DateFormat dates,
    DateTime? date,
  ) {
    if (date != null) return l10n.projectionDate(dates.format(date));
    final pace = projection.perDay;
    // Two different silences, worth telling apart: nothing is happening, or
    // something is but the target is out of reach at that rate.
    if (pace == null || pace <= 0) return l10n.projectionNoPace;
    return l10n.projectionTooFar;
  }

  String _tierLabel(AppLocalizations l10n, String name) => switch (name) {
        'bronze' => l10n.projectionTier_bronze,
        'silver' => l10n.projectionTier_silver,
        'gold' => l10n.projectionTier_gold,
        'platinum' => l10n.projectionTier_platinum,
        'onyx' => l10n.projectionTier_onyx,
        // A tier the app does not know the name of still shows, under whatever
        // the registry called it.
        _ => name,
      };

  String _windowLabel(AppLocalizations l10n, ProjectionWindow window) =>
      switch (window) {
        ProjectionWindow.week => l10n.projectionWindowWeek,
        ProjectionWindow.month => l10n.projectionWindowMonth,
      };
}
