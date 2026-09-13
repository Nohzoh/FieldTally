import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/chart_target.dart';
import '../../domain/counter_series.dart';
import '../../l10n/app_localizations.dart';
import '../tier_labels.dart';

/// One counter, one chart, its own scale (§3.5).
///
/// The audit found Agent Stats unreadable for putting sixty series on a single
/// axis. Here every counter gets its own chart scaled to its own values, which
/// is the whole reason this screen exists.
class CounterChart extends StatelessWidget {
  const CounterChart({super.key, required this.series, this.target});

  final CounterSeries series;

  /// What the agent is aiming for, drawn as a line across the chart (#61).
  /// Null when there is nothing ahead — most counters, most of the time.
  final ChartTarget? target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final numbers = NumberFormat.compact(locale: locale.languageCode);
    // The axis drops the year: at this width the two edge labels collide with
    // the chart border, and the tooltip carries the full date anyway.
    final axisDates = DateFormat(l10n.chartAxisDateFormat, locale.toString());
    final dates = DateFormat(l10n.shortDateFormat, locale.toString());

    if (!series.isPlottable) {
      return _NotEnough(message: l10n.chartNeedsTwoSnapshots);
    }

    final first = series.points.first.at.millisecondsSinceEpoch.toDouble();
    final last = series.points.last.at.millisecondsSinceEpoch.toDouble();
    final min = series.minValue.toDouble();

    // The axis stretches to hold the target, however far above the curve it
    // sits — and it squashes the curve when the target is distant. That is the
    // point: an agent who has set themselves something out of reach learns it
    // by looking, rather than by reading a projected date underneath (#61).
    final target = this.target;
    final max = target == null
        ? series.maxValue.toDouble()
        : [series.maxValue.toDouble(), target.value.toDouble()].reduce(
            (a, b) => a > b ? a : b,
          );

    // A counter that did not move has no vertical range to scale to; pad it so
    // the line sits mid-height instead of dividing by zero.
    final flat = max == min;
    final padding = flat ? 1.0 : (max - min) * 0.12;

    final targetLabel = target == null
        ? null
        : switch (target.kind) {
            ChartTargetKind.goal =>
              l10n.chartTargetGoal(numbers.format(target.value)),
            ChartTargetKind.badge => l10n.chartTargetBadge(
                tierLabel(l10n, target.tierName ?? ''),
                numbers.format(target.value),
              ),
          };

    return Semantics(
      // The chart is never the only carrier of information (§3.9): the values
      // are listed underneath, and this label states the shape in words. The
      // target line is stated too — it is the one mark a screen reader would
      // otherwise miss entirely.
      label: [
        l10n.chartSemantics(
          numbers.format(series.points.first.value),
          numbers.format(series.points.last.value),
          series.points.length,
        ),
        if (targetLabel != null) l10n.chartTargetSemantics(targetLabel),
      ].join(' '),
      child: ExcludeSemantics(
        // Room for the edge labels, which fl_chart centres on their data point
        // and would otherwise clip against the chart border.
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: LineChart(
            LineChartData(
              minX: first,
              maxX: last,
              minY: min - padding,
              maxY: max + padding,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    // An explicit interval: left to itself fl_chart labels the
                    // padded bounds as well as its own ticks, and the two
                    // collided at both ends of the axis.
                    interval: ((max + padding) - (min - padding)) / 4,
                    getTitlesWidget: (value, meta) {
                      // fl_chart labels the axis bounds on top of its own
                      // ticks, and the two overlapped at both ends. Drop a
                      // label that sits almost on a neighbour.
                      final step = ((max + padding) - (min - padding)) / 4;
                      final tooCloseToBottom =
                          (value - (min - padding)).abs() < step * 0.4;
                      final tooCloseToTop =
                          ((max + padding) - value).abs() < step * 0.4;
                      if (tooCloseToBottom || tooCloseToTop) {
                        return const SizedBox.shrink();
                      }
                      // Compact notation: full numbers would eat the chart on
                      // a phone, and the exact figures are right below anyway.
                      return Text(
                        numbers.format(value.round()),
                        style: theme.textTheme.labelSmall,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: (last - first).abs().clamp(1, double.infinity),
                    // Only the two ends, and checked explicitly rather than
                    // left to the interval: fl_chart adds a tick of its own
                    // near the origin, which collided with the first label.
                    // The tooltip carries the exact date for every point.
                    getTitlesWidget: (value, meta) {
                      final isEdge = (value - first).abs() < 1 ||
                          (value - last).abs() < 1;
                      if (!isEdge) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          axisDates.format(
                            DateTime.fromMillisecondsSinceEpoch(value.round()),
                          ),
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Dashed and in a different role colour: §3.9 asks that colour
              // never be the only thing telling two marks apart, and the data
              // line is solid.
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (target != null && targetLabel != null)
                    HorizontalLine(
                      y: target.value.toDouble(),
                      color: theme.colorScheme.tertiary,
                      strokeWidth: 1.5,
                      dashArray: const [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.only(left: 4, bottom: 2),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.tertiary),
                        labelResolver: (_) => targetLabel,
                      ),
                    ),
                ],
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      LineTooltipItem(
                        '${dates.format(DateTime.fromMillisecondsSinceEpoch(spot.x.round()))}\n'
                        '${NumberFormat.decimalPattern(locale.languageCode).format(spot.y.round())}',
                        theme.textTheme.labelMedium ?? const TextStyle(),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (final point in series.points)
                      FlSpot(
                        point.at.millisecondsSinceEpoch.toDouble(),
                        point.value.toDouble(),
                      ),
                  ],
                  isCurved: false,
                  barWidth: 2,
                  color: theme.colorScheme.primary,
                  dotData: FlDotData(
                    show: series.points.length <= 30,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 2.5,
                          color: theme.colorScheme.primary,
                          strokeWidth: 0,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotEnough extends StatelessWidget {
  const _NotEnough({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}
