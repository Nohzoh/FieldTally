import 'counter_series.dart';
import 'models/counter_registry.dart';

/// Window the recent pace is measured over (§3.6).
enum ProjectionWindow {
  week(Duration(days: 7)),
  month(Duration(days: 30));

  const ProjectionWindow(this.span);

  final Duration span;
}

/// Where a counter stands against its badge thresholds, and when the next one
/// is likely to land (§3.6).
class BadgeProjection {
  const BadgeProjection({
    required this.value,
    required this.current,
    required this.next,
    required this.perDay,
    required this.window,
  });

  final int value;

  /// Highest tier already reached, or null below bronze.
  final CounterTier? current;

  /// Tier being worked towards, or null once onyx is done.
  final CounterTier? next;

  /// Recent pace, in counter units per day. Null when it cannot be measured,
  /// zero or negative when the agent has stalled.
  final double? perDay;

  final ProjectionWindow window;

  /// Every tier reached.
  bool get isComplete => next == null;

  /// How much is left to reach [next].
  int? get remaining =>
      next == null ? null : (next!.value - value).round().clamp(0, 1 << 62);

  /// Share of the way from [current] to [next], between 0 and 1.
  double? get progress {
    if (next == null) return null;
    final from = current?.value ?? 0;
    final span = next!.value - from;
    if (span <= 0) return null;
    return ((value - from) / span).clamp(0.0, 1.0);
  }

  /// Days until [next] at the recent pace, or null when no honest estimate
  /// exists.
  ///
  /// A stalled or shrinking counter yields null rather than infinity or a date
  /// centuries away: "not at this pace" is the truthful answer, and a made-up
  /// date is worse than none.
  double? get daysToNext {
    final rate = perDay;
    final left = remaining;
    if (rate == null || left == null || rate <= 0) return null;
    return left / rate;
  }

  /// Projected date, measured from [from] — normally the latest snapshot,
  /// since that is when the pace was last observed.
  DateTime? projectedDate(DateTime from) {
    final days = daysToNext;
    if (days == null) return null;

    // Anything beyond a few years says more about the pace being slow than
    // about a real date, and printing "12 March 2091" invites false precision.
    if (days > 365 * 5) return null;

    return from.add(Duration(hours: (days * 24).round()));
  }
}

/// Computes badge projections from a counter's history (§3.6).
///
/// Thresholds come from the enrichment registry, which is refreshed from the
/// project site (§3.1.4) — so correcting a wrong threshold is a pull request,
/// not a release.
class BadgeProjector {
  const BadgeProjector();

  /// [points] must be chronological. Returns null when the counter has no
  /// known thresholds, which is the case for most of them.
  BadgeProjection? project({
    required List<SeriesPoint> points,
    required CounterEnrichment? enrichment,
    ProjectionWindow window = ProjectionWindow.month,
  }) {
    if (enrichment == null || enrichment.tiers.isEmpty) return null;
    if (points.isEmpty) return null;

    final tiers = [...enrichment.tiers]
      ..sort((a, b) => a.value.compareTo(b.value));
    final value = points.last.value;

    CounterTier? current;
    CounterTier? next;
    for (final tier in tiers) {
      if (value >= tier.value) {
        current = tier;
      } else {
        next = tier;
        break;
      }
    }

    return BadgeProjection(
      value: value,
      current: current,
      next: next,
      perDay: _paceFor(points, window),
      window: window,
    );
  }

  /// Pace over the window, measured back from the most recent snapshot.
  ///
  /// From the last snapshot rather than from today, for the same reason the
  /// charts do it (§3.5): an agent who stopped importing three weeks ago has
  /// not suddenly slowed down, the app simply stopped hearing about it.
  double? _paceFor(List<SeriesPoint> points, ProjectionWindow window) {
    if (points.length < 2) return null;

    final last = points.last;
    final cutoff = last.at.subtract(window.span);

    // The anchor is the first point at or before the cutoff when there is one,
    // so a window holding a single snapshot still has something to measure
    // against instead of reporting no pace at all.
    SeriesPoint? anchor;
    for (final point in points) {
      if (point.at.isAfter(cutoff)) {
        anchor ??= point;
        break;
      }
      anchor = point;
    }
    anchor ??= points.first;
    if (identical(anchor, last)) return null;

    final days = last.at.difference(anchor.at).inMinutes / (60 * 24);
    if (days <= 0) return null;

    return (last.value - anchor.value) / days;
  }
}
