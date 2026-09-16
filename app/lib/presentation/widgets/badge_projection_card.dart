import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/badge_projection.dart';
import '../../domain/models/counter_registry.dart';
import '../../l10n/app_localizations.dart';
import '../tier_labels.dart';
import 'medal_icon.dart';

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
    this.counterKey,
  });

  final BadgeProjection projection;

  /// Registry key of the counter, so the card can show its emblem (#63). Null
  /// when the counter has no key, or none this release can draw.
  final String? counterKey;

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
    final multiple = projection.topMultiple;
    final date = projection.projectedDate(measuredFrom);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (counterKey != null && MedalIcon.existsFor(counterKey!)) ...[
                  ExcludeSemantics(
                    child: MedalIcon(
                      counterKey: counterKey!,
                      tierName: projection.current?.name,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.projectionTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                      // The metal in the emblem is a colour; this line is the
                      // same fact in words (§3.9).
                      _medalLine(l10n, theme),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // There is always something ahead on a permanent badge: a tier,
            // or the next whole multiple of the top one (#87). A seasonal one
            // can genuinely be finished, or shut — and then it says so rather
            // than offering a target nobody can act on (#99).
            _remainingLine(l10n, theme, numbers, next, multiple),
            const SizedBox(height: 8),
            // §3.9: the bar is never the only carrier — the figures above
            // and below say the same thing in words.
            LinearProgressIndicator(
              value: projection.progress ?? 0,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            // Nothing below this point is about a medal already settled: an
            // estimate, a pace and a window all answer "when", and a closed or
            // completed ladder has no when left.
            if (!projection.isOver && !projection.isFinished) ...[
              Text(
                _estimate(l10n, dates, date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              if (projection.perDay != null && projection.perDay! > 0)
                Text(
                  l10n.projectionPace(
                    numbers.format(projection.perDay!.round()),
                    _windowLabel(l10n, projection.window),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
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

  /// The tier in words, carrying the multiplier once every tier is behind.
  ///
  /// From two upwards: a bare "x 1" would only repeat what "Onyx medal"
  /// already says, and reads like a countdown that has not started.
  Widget _medalLine(AppLocalizations l10n, ThemeData theme) {
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outline,
    );
    final current = projection.current;
    if (current == null) return Text(l10n.medalNone, style: style);

    final tier = tierLabel(l10n, current.name);
    final multiple = projection.topMultiple;
    if (multiple == null || multiple < 2) {
      return Text(l10n.medalTier(tier), style: style);
    }

    return Semantics(
      container: true,
      label: l10n.medalTierMultipleSemantics(tier, multiple),
      child: ExcludeSemantics(
        child: Text(l10n.medalTierMultiple(tier, multiple), style: style),
      ),
    );
  }

  /// What is left, and what it is left for: the next tier, or the next whole
  /// multiple of the top one.
  Widget _remainingLine(
    AppLocalizations l10n,
    ThemeData theme,
    NumberFormat numbers,
    CounterTier? next,
    int? multiple,
  ) {
    final style = theme.textTheme.bodyLarge;

    // Climbed to the top of a ladder that ends: no further multiple, because
    // the game itself stops counting there.
    if (projection.isFinished) {
      return Text(l10n.projectionAllTiers, style: style);
    }

    // Shut before it was climbed. Said as a closed window rather than as a
    // failure, and without a target the agent could act on: what is left is
    // no longer "to go", it is out of reach.
    if (projection.isOver) {
      return Text(l10n.projectionEnded, style: style);
    }

    final remaining = numbers.format(projection.remaining);

    if (next != null) {
      return Text(
        l10n.projectionRemaining(remaining, tierLabel(l10n, next.name)),
        style: style,
      );
    }

    // The multiplier is only ever null while a tier is ahead, which the branch
    // above has already taken.
    final target = multiple! + 1;
    return Semantics(
      container: true,
      label: l10n.projectionRemainingMultipleSemantics(
        remaining,
        tierLabel(l10n, projection.top.name),
        target,
      ),
      child: ExcludeSemantics(
        child: Text(
          l10n.projectionRemainingMultiple(remaining, target),
          style: style,
        ),
      ),
    );
  }

  String _estimate(AppLocalizations l10n, DateFormat dates, DateTime? date) {
    if (date != null) return l10n.projectionDate(dates.format(date));

    // Three different silences now, worth telling apart: nothing is
    // happening; something is, but the target is out of reach at that rate;
    // or it is reachable and the window shuts first, which is the one an
    // agent can still do something about.
    if (projection.missesDeadline(measuredFrom)) {
      return l10n.projectionAfterDeadline;
    }

    final pace = projection.perDay;
    if (pace == null || pace <= 0) return l10n.projectionNoPace;
    return l10n.projectionTooFar;
  }

  String _windowLabel(AppLocalizations l10n, ProjectionWindow window) =>
      switch (window) {
        ProjectionWindow.week => l10n.projectionWindowWeek,
        ProjectionWindow.month => l10n.projectionWindowMonth,
      };
}
