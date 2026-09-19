import 'badge_projection.dart';
import 'counter_series.dart';
import 'models/counter_registry.dart';
import 'models/stat_snapshot.dart';

/// What one counter did over the year.
typedef YearlyGain = ({String exportHeader, int from, int to});

/// A badge tier crossed during the year, and the first snapshot that showed it.
///
/// The date is "when the app first saw it", never "when it happened": between
/// two imports the app knows nothing, and pretending otherwise would put a
/// precise date on a guess.
typedef MedalCrossed = ({
  String exportHeader,
  CounterTier tier,
  DateTime seenOn,
});

/// A year of an agent's history, read back (#153).
class YearInReview {
  const YearInReview({
    required this.year,
    required this.from,
    required this.to,
    required this.gains,
    required this.medals,
    this.busiestMonth,
    this.longestGap,
  });

  final int year;

  /// The two moments the figures actually span.
  ///
  /// [from] is the last snapshot at or before 1 January when there is one, and
  /// otherwise the first snapshot of the year — in which case the recap covers
  /// part of a year and says so rather than looking thin.
  final DateTime from;
  final DateTime to;

  /// True when the history does not reach back to 1 January.
  bool get isPartial => from.year == year;

  /// Counters that moved, in the registry's order.
  final List<YearlyGain> gains;

  /// Tiers crossed during the year, oldest first.
  final List<MedalCrossed> medals;

  /// The month that gained the most AP, 1 to 12, or null when no two
  /// snapshots inside the year carry `Lifetime AP`.
  final int? busiestMonth;

  /// The longest run between two consecutive snapshots inside the year.
  ///
  /// Shown because it is the honest caveat on everything above: a recap built
  /// from a history with a three-month hole is describing what was recorded,
  /// not what was done.
  final Duration? longestGap;

  bool get isEmpty => gains.isEmpty && medals.isEmpty;
}

/// Builds a year's recap from the history alone (#153).
///
/// Everything here is on the device already, which is the whole point: the
/// roadmap filed this under "would need a server" and was wrong. Nothing is
/// fetched, nothing is sent, and the same code runs whether or not the phone
/// has ever been online.
class YearInReviewBuilder {
  const YearInReviewBuilder({this.registry, this.maxGains = 8});

  /// Orders and names the counters. Without it the gains come out
  /// alphabetically under their raw export headers.
  final CounterRegistry? registry;

  /// How many counters to list. A year moves almost everything, and a recap
  /// that lists sixty rows is a spreadsheet.
  final int maxGains;

  /// Null when the year holds nothing to say — no two snapshots to measure
  /// between.
  YearInReview? build({
    required List<StatSnapshot> snapshots,
    required int year,
  }) {
    final sorted = [...snapshots]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final inYear = [
      for (final s in sorted)
        if (s.recordedAt.year == year) s,
    ];
    if (inYear.isEmpty) return null;

    // The value on 1 January is whatever the last snapshot before the year
    // said. Without one the year starts at its own first snapshot, and the
    // recap covers less than a year.
    final before = [
      for (final s in sorted)
        if (s.recordedAt.year < year) s,
    ];
    final start = before.isNotEmpty ? before.last : inYear.first;
    final end = inYear.last;
    if (identical(start, end)) return null;

    return YearInReview(
      year: year,
      from: start.recordedAt,
      to: end.recordedAt,
      gains: _gains(start, end),
      medals: _medals(inYear, start),
      busiestMonth: _busiestMonth(inYear, start),
      longestGap: _longestGap([start, ...inYear]),
    );
  }

  /// What each counter gained, for the counters present at both ends.
  ///
  /// A counter missing from either snapshot has no gain: it was not reported,
  /// which is not the same as not having moved (§3.1.2). Counters that did not
  /// move are left out, and so are falls — `Current AP` and `Level` drop on a
  /// recursion (§3.1.3), and "you lost 24 million AP this year" is a true
  /// sentence that says the wrong thing.
  List<YearlyGain> _gains(StatSnapshot start, StatSnapshot end) {
    final moved = <String, YearlyGain>{};
    for (final entry in end.counters.entries) {
      final was = start.counters[entry.key];
      if (was == null || entry.value <= was) continue;
      moved[entry.key] = (exportHeader: entry.key, from: was, to: entry.value);
    }

    final ordered =
        registry?.sortHeaders(moved.keys) ?? (moved.keys.toList()..sort());
    return [for (final header in ordered.take(maxGains)) moved[header]!];
  }

  /// Every tier crossed during the year, with the snapshot that first showed
  /// it.
  List<MedalCrossed> _medals(List<StatSnapshot> inYear, StatSnapshot start) {
    final registry = this.registry;
    if (registry == null) return const [];

    final crossed = <MedalCrossed>[];
    for (final entry in inYear.last.counters.entries) {
      final enrichment = registry.forExportHeader(entry.key);
      if (enrichment == null || enrichment.tiers.isEmpty) continue;

      final was = start.counters[entry.key];
      if (was == null) continue;

      final before = tierReached(enrichment, was);
      final after = tierReached(enrichment, entry.value);
      if (after == null || (before != null && before.value >= after.value)) {
        continue;
      }

      for (final tier in enrichment.tiers) {
        if (tier.value <= (before?.value ?? 0) || tier.value > after.value) {
          continue;
        }
        // The first import that carried a value at or above the threshold.
        // Not when it was earned — nobody knows that but the agent.
        final seen = inYear.firstWhere(
          (s) => (s.counters[entry.key] ?? -1) >= tier.value,
          orElse: () => inYear.last,
        );
        crossed.add((
          exportHeader: entry.key,
          tier: tier,
          seenOn: seen.recordedAt,
        ));
      }
    }

    crossed.sort((a, b) => a.seenOn.compareTo(b.seenOn));
    return crossed;
  }

  /// The month that gained the most AP.
  int? _busiestMonth(List<StatSnapshot> inYear, StatSnapshot start) {
    final byDay = const CounterSeriesBuilder().activityByDay([
      start,
      ...inYear,
    ]);

    final byMonth = <int, int>{};
    for (final entry in byDay.entries) {
      if (entry.key.year != inYear.first.recordedAt.year) continue;
      byMonth[entry.key.month] = (byMonth[entry.key.month] ?? 0) + entry.value;
    }
    if (byMonth.isEmpty) return null;

    var best = byMonth.entries.first;
    for (final entry in byMonth.entries) {
      // Strictly greater, so a tie keeps the earlier month rather than
      // depending on the order a map happened to iterate in.
      if (entry.value > best.value) best = entry;
    }
    return best.key;
  }

  Duration? _longestGap(List<StatSnapshot> chronological) {
    if (chronological.length < 2) return null;

    Duration? longest;
    for (var i = 1; i < chronological.length; i++) {
      final gap = chronological[i].recordedAt.difference(
        chronological[i - 1].recordedAt,
      );
      if (longest == null || gap > longest) longest = gap;
    }
    return longest;
  }
}
