import 'models/stat_snapshot.dart';
import 'models/tracked_counter.dart';

/// One pinned card on the dashboard (§3.3).
class DashboardCard {
  const DashboardCard({required this.counter, required this.series});

  final TrackedCounter counter;

  /// Values in chronological order, for the mini sparkline.
  ///
  /// Only snapshots that actually carried the counter appear: a gap in the
  /// imports is not a dip to zero (§3.1.2), and drawing it as one would be a
  /// lie the eye reads instantly.
  final List<int> series;

  /// A sparkline needs at least two points to show anything.
  bool get hasSparkline => series.length > 1;
}

/// Assembles the dashboard from the history and the user's pinned selection.
///
/// Pure logic, kept out of the widgets so the shape of the data can be tested
/// without pumping a screen.
class DashboardBuilder {
  const DashboardBuilder({this.maxSeriesPoints = 20});

  /// The sparkline is a glance, not a chart: past a couple of dozen points it
  /// stops being readable at that size. The full history lives on the counter
  /// detail screen.
  final int maxSeriesPoints;

  /// [pinned] drives both membership and order.
  ///
  /// A pinned counter that never appeared in any import is skipped rather than
  /// shown empty: it usually means the agent pinned it from a previous phone,
  /// or that the counter left the game.
  List<DashboardCard> build({
    required List<StatSnapshot> snapshots,
    required List<String> pinned,
    CounterTracker tracker = const CounterTracker(),
  }) {
    if (snapshots.isEmpty || pinned.isEmpty) return const [];

    final sorted = [...snapshots]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final tracked = {
      for (final counter in tracker.track(sorted)) counter.exportHeader: counter,
    };

    final cards = <DashboardCard>[];
    for (final header in pinned) {
      final counter = tracked[header];
      if (counter == null) continue;

      final series = [
        for (final snapshot in sorted)
          if (snapshot.counters.containsKey(header)) snapshot.counters[header]!,
      ];

      cards.add(
        DashboardCard(
          counter: counter,
          series: series.length > maxSeriesPoints
              ? series.sublist(series.length - maxSeriesPoints)
              : series,
        ),
      );
    }
    return cards;
  }
}
