import 'models/stat_snapshot.dart';

/// Period shown on a counter chart (§3.5).
enum ChartRange {
  week,
  month,
  all;

  /// How far back the range reaches, or null for the whole history.
  Duration? get span => switch (this) {
        ChartRange.week => const Duration(days: 7),
        ChartRange.month => const Duration(days: 31),
        ChartRange.all => null,
      };
}

/// One measured value at one moment.
typedef SeriesPoint = ({DateTime at, int value});

/// Values of one counter over time, ready to plot (§3.5).
class CounterSeries {
  const CounterSeries({required this.points, required this.range});

  /// Chronological, oldest first. Only snapshots that carried the counter
  /// appear: a gap in the imports is not a dip to zero (§3.1.2).
  final List<SeriesPoint> points;

  final ChartRange range;

  bool get isEmpty => points.isEmpty;

  /// A line needs two points.
  bool get isPlottable => points.length > 1;

  int get minValue => points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  int get maxValue => points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

  /// Progress across the shown range, or null when there is nothing to span.
  int? get gain => isPlottable ? points.last.value - points.first.value : null;
}

/// Builds per-counter series and the activity calendar (§3.5).
///
/// Each counter gets its own series on its own scale — the whole point of
/// §3.5, since the audit found Agent Stats unreadable for putting every series
/// on one axis.
class CounterSeriesBuilder {
  const CounterSeriesBuilder();

  /// [range] is measured back from the **most recent snapshot**, not from
  /// today: an agent who stopped importing three weeks ago should still see
  /// their last week of data rather than an empty chart.
  CounterSeries series({
    required List<StatSnapshot> snapshots,
    required String exportHeader,
    ChartRange range = ChartRange.all,
  }) {
    final all = <SeriesPoint>[
      for (final snapshot in snapshots)
        if (snapshot.counters.containsKey(exportHeader))
          (at: snapshot.recordedAt, value: snapshot.counters[exportHeader]!),
    ]..sort((a, b) => a.at.compareTo(b.at));

    if (all.isEmpty) return CounterSeries(points: const [], range: range);

    final span = range.span;
    if (span == null) return CounterSeries(points: all, range: range);

    final cutoff = all.last.at.subtract(span);
    final within = all.where((p) => !p.at.isBefore(cutoff)).toList();

    // Keep the point just before the cutoff as an anchor, otherwise a range
    // holding a single snapshot draws nothing and the reader cannot tell
    // progress from a flat line.
    if (within.length < 2 && all.length > 1) {
      final index = all.length - within.length - 1;
      if (index >= 0) within.insert(0, all[index]);
    }

    return CounterSeries(points: within, range: range);
  }

  /// Activity per day, for the calendar heatmap (§3.5).
  ///
  /// The value is the AP gained since the previous snapshot, attributed to the
  /// day the snapshot was taken. It is deliberately **not** presented as
  /// per-day activity: between two snapshots a week apart, nothing tells us
  /// which days the agent actually played, and spreading the total evenly
  /// would invent data the app never measured.
  Map<DateTime, int> activityByDay(List<StatSnapshot> snapshots) {
    const apHeader = 'Lifetime AP';

    final withAp = [
      for (final snapshot in snapshots)
        if (snapshot.counters.containsKey(apHeader)) snapshot,
    ]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final byDay = <DateTime, int>{};
    for (var i = 1; i < withAp.length; i++) {
      final gain = withAp[i].counters[apHeader]! - withAp[i - 1].counters[apHeader]!;
      if (gain <= 0) continue;

      final date = withAp[i].recordedAt;
      final day = DateTime(date.year, date.month, date.day);
      byDay[day] = (byDay[day] ?? 0) + gain;
    }
    return byDay;
  }
}
