import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A GitHub-style calendar of activity (§3.5).
///
/// Written here rather than taken from a package: `flutter_heatmap_calendar`,
/// suggested in §5.1, hard-codes its weekday labels in English with no hook to
/// override them, which shows through immediately in a French interface. The
/// widget itself is a grid of squares, so owning it costs little and buys full
/// control over labels, theming and semantics.
class ActivityCalendar extends StatelessWidget {
  const ActivityCalendar({
    super.key,
    required this.activityByDay,
    required this.from,
    required this.to,
    this.squareSize = 13,
    this.spacing = 3,
  });

  /// The span to draw, normally the whole history.
  ///
  /// Passed in rather than derived from the active days: a calendar showing
  /// only the days with progress would hide the gaps, which are exactly what
  /// this view is for.
  final DateTime from;
  final DateTime to;

  /// Value per day. Days absent from the map are drawn as "nothing recorded",
  /// which is not the same as zero progress — the app simply has no snapshot
  /// measuring that day.
  final Map<DateTime, int> activityByDay;

  final double squareSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    final peak = activityByDay.values.isEmpty
        ? 0
        : activityByDay.values.reduce((a, b) => a > b ? a : b);

    // Whole weeks, so the columns line up under their weekday label.
    final start = _startOfWeek(from);
    final weeks = (to.difference(start).inDays / 7).floor() + 1;

    final weekdayLabels = DateFormat.E(locale).dateSymbols.STANDALONESHORTWEEKDAYS;
    final months = DateFormat.MMM(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // most recent weeks first in view
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeekdayLabels(
                labels: weekdayLabels,
                squareSize: squareSize,
                spacing: spacing,
              ),
              const SizedBox(width: 6),
              for (var week = 0; week < weeks; week++)
                Padding(
                  padding: EdgeInsets.only(right: spacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 14,
                        child: _MonthLabel(
                          week: week,
                          start: start,
                          format: months,
                        ),
                      ),
                      for (var weekday = 0; weekday < 7; weekday++)
                        _Square(
                          day: start.add(Duration(days: week * 7 + weekday)),
                          activityByDay: activityByDay,
                          peak: peak,
                          size: squareSize,
                          spacing: spacing,
                          locale: locale,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _Legend(colour: theme.colorScheme.primary, size: squareSize),
      ],
    );
  }

  static DateTime _startOfWeek(DateTime day) =>
      DateTime(day.year, day.month, day.day)
          .subtract(Duration(days: day.weekday % 7));
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels({
    required this.labels,
    required this.squareSize,
    required this.spacing,
  });

  final List<String> labels;
  final double squareSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 14),
        // Every other row, as GitHub does: seven stacked labels do not fit at
        // this square size in any language.
        for (var weekday = 0; weekday < 7; weekday++)
          SizedBox(
            height: squareSize + spacing,
            child: weekday.isOdd
                ? Text(labels[weekday], style: style)
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel({
    required this.week,
    required this.start,
    required this.format,
  });

  final int week;
  final DateTime start;
  final DateFormat format;

  @override
  Widget build(BuildContext context) {
    final first = start.add(Duration(days: week * 7));
    final previous = start.add(Duration(days: (week - 1) * 7));

    // Label only the column where a new month begins.
    if (week != 0 && first.month == previous.month) {
      return const SizedBox.shrink();
    }
    return Text(
      format.format(first),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({
    required this.day,
    required this.activityByDay,
    required this.peak,
    required this.size,
    required this.spacing,
    required this.locale,
  });

  final DateTime day;
  final Map<DateTime, int> activityByDay;
  final int peak;
  final double size;
  final double spacing;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = activityByDay[day];

    // Intensity relative to the agent's own best day: absolute thresholds
    // would be meaningless between agents whose AP differ by orders of
    // magnitude.
    final intensity = value == null || peak == 0 ? 0.0 : value / peak;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: Tooltip(
        message: value == null
            ? DateFormat.yMMMd(locale).format(day)
            : '${DateFormat.yMMMd(locale).format(day)} · '
                '${NumberFormat.decimalPattern(locale).format(value)} AP',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: value == null
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.primary
                    .withValues(alpha: 0.25 + 0.75 * intensity),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colour, required this.size});

  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text('−', style: theme.textTheme.labelSmall),
        const SizedBox(width: 4),
        for (final alpha in [0.0, 0.25, 0.5, 0.75, 1.0])
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: alpha == 0
                    ? theme.colorScheme.surfaceContainerHighest
                    : colour.withValues(alpha: 0.25 + 0.75 * alpha),
              ),
            ),
          ),
        const SizedBox(width: 2),
        Text('+', style: theme.textTheme.labelSmall),
      ],
    );
  }
}
