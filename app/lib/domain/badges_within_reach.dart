import 'badge_projection.dart';
import 'counter_series.dart';
import 'models/counter_registry.dart';
import 'models/stat_snapshot.dart';

/// A badge the recent pace actually reaches, and when (#148).
typedef ReachableBadge = ({
  String exportHeader,
  BadgeProjection projection,

  /// Days at the recent pace. Always finite and positive — the cases where no
  /// honest estimate exists never make it into this record.
  double days,

  /// The date those days land on, measured from the counter's own last
  /// snapshot rather than from today, like every other projection (§3.6).
  DateTime date,
});

/// Which badges the current pace puts within reach, soonest first (#148).
///
/// The counter list can already sort by proximity to the next tier (#90), but
/// it measures that as **the share of the current stretch already crossed**.
/// That answers a different question. A counter at 95 % of onyx can be four
/// hundred days out and one at 60 % can be three days out, so for "what could
/// I finish this weekend" the two sort in the wrong order every time.
///
/// Everything here is already computed by [BadgeProjector] — this only ranks
/// it across counters, which is the one thing no screen did.
class WithinReachBuilder {
  const WithinReachBuilder({
    this.window = ProjectionWindow.month,
    this.limit = 5,
  });

  /// Window the pace is measured over. The ranking changes entirely with it,
  /// which is why the screen states the one it used rather than leaving the
  /// reader to assume.
  final ProjectionWindow window;

  /// How many to keep. A short list is the point: twenty two tiered counters
  /// ranked by date is a table, not an answer.
  final int limit;

  List<ReachableBadge> build({
    required List<StatSnapshot> snapshots,
    CounterRegistry? registry,
    DateTime? now,
  }) {
    // Without thresholds nothing can be ranked at all. The screen says so
    // rather than showing an empty list that looks like a stalled agent.
    if (registry == null || snapshots.isEmpty) return const [];

    final headers = {for (final s in snapshots) ...s.counters.keys};
    final reachable = <ReachableBadge>[];

    for (final header in headers) {
      final enrichment = registry.forExportHeader(header);
      if (enrichment == null || enrichment.tiers.isEmpty) continue;

      // The whole history, never a chart range: a badge is reached against the
      // total, whatever window is being looked at.
      final series = const CounterSeriesBuilder().series(
        snapshots: snapshots,
        exportHeader: header,
      );
      if (series.points.isEmpty) continue;

      final projection = const BadgeProjector().project(
        points: series.points,
        enrichment: enrichment,
        window: window,
        now: now,
      );
      if (projection == null) continue;

      // Past the top tier the game counts in multiples (#87). Those are left
      // out on purpose: a multiple is the same medal counting higher, not a
      // badge to finish, and this list answers "which one could I finish".
      if (projection.next == null) continue;

      final days = projection.daysToNext;
      // `projectedDate` is what decides, and it already refuses every case
      // this list must not invent: a ladder that has closed, a stalled or
      // shrinking counter, a date so far out it says more about the pace than
      // about a date, and a date past a seasonal ladder's own deadline.
      final date = days == null
          ? null
          : projection.projectedDate(series.points.last.at);
      if (days == null || date == null) continue;

      reachable.add((
        exportHeader: header,
        projection: projection,
        days: days,
        date: date,
      ));
    }

    reachable.sort((a, b) {
      final byDate = a.days.compareTo(b.days);
      // Two counters at the same pace keep a stable order between runs rather
      // than swapping on whatever order the set iterated in.
      return byDate != 0 ? byDate : a.exportHeader.compareTo(b.exportHeader);
    });

    return reachable.take(limit).toList();
  }
}
