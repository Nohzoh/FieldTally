import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A mini trend line for a dashboard card (§3.3).
///
/// Deliberately stripped of axes, grid, labels and interaction: at this size
/// they would be noise, and the number they annotate is already printed right
/// above. Per §3.9 the sparkline is never the only carrier of information —
/// the value and the diff are always shown as text.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values});

  /// Chronological values. Fewer than two points draws nothing.
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();

    final colour = Theme.of(context).colorScheme.primary;
    final min = values.reduce((a, b) => a < b ? a : b).toDouble();
    final max = values.reduce((a, b) => a > b ? a : b).toDouble();

    // A counter that did not move would collapse to a zero-height range and
    // fl_chart would divide by it; pad it so the line sits mid-height.
    final flat = max == min;

    return ExcludeSemantics(
      child: LineChart(
        LineChartData(
          minY: flat ? min - 1 : min,
          maxY: flat ? max + 1 : max,
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i].toDouble()),
              ],
              isCurved: false,
              barWidth: 2,
              color: colour,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: colour.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
