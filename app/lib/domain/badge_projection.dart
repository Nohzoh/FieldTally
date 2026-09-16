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
    required this.top,
    required this.perDay,
    required this.window,
  });

  final int value;

  /// Highest tier already reached, or null below bronze.
  final CounterTier? current;

  /// Tier being worked towards, or null once onyx is done.
  final CounterTier? next;

  /// The highest tier the registry knows for this counter — onyx, for every
  /// badge in the game today.
  ///
  /// Kept even once it is behind, because past it the target stops being a
  /// tier and becomes a multiple of this value (#87).
  final CounterTier top;

  /// Recent pace, in counter units per day. Null when it cannot be measured,
  /// zero or negative when the agent has stalled.
  final double? perDay;

  final ProjectionWindow window;

  /// Every named tier reached.
  ///
  /// No longer the same thing as having nothing left to chase: past the top
  /// tier the game counts in multiples of it, and so does [target] (#87).
  bool get isComplete => next == null;

  /// How many whole times [top] has been reached, once every tier is behind —
  /// the multiplier the game prints beside the badge. Null while a tier is
  /// still ahead.
  ///
  /// The true multiple, including 1. Whether a bare 1 is worth showing is a
  /// question for the surface drawing it: the medal already says onyx.
  int? get topMultiple => next == null ? multipleOf(top, value) : null;

  /// What the agent is working towards: the next tier, or the next whole
  /// multiple of [top] once every tier is behind.
  ///
  /// Never null for a counter that has tiers at all, which is what keeps the
  /// pace, the estimate and the progress bar working past onyx instead of the
  /// card collapsing to a single sentence.
  num get target => next?.value ?? (topMultiple! + 1) * top.value;

  /// Where the current stretch starts: the tier below, or the multiple of
  /// [top] already reached.
  num get _from =>
      next != null ? (current?.value ?? 0) : topMultiple! * top.value;

  /// How much is left to reach [target].
  int get remaining => (target - value).round().clamp(0, 1 << 62);

  /// Share of the way across the current stretch, between 0 and 1.
  double? get progress {
    final span = target - _from;
    if (span <= 0) return null;
    return ((value - _from) / span).clamp(0.0, 1.0);
  }

  /// Days until [next] at the recent pace, or null when no honest estimate
  /// exists.
  ///
  /// A stalled or shrinking counter yields null rather than infinity or a date
  /// centuries away: "not at this pace" is the truthful answer, and a made-up
  /// date is worse than none.
  double? get daysToNext {
    final rate = perDay;
    if (rate == null || rate <= 0) return null;
    return remaining / rate;
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
/// The highest tier [value] has reached, or null below the first threshold.
///
/// Split out of [BadgeProjector.project] because the medal shown beside a
/// counter needs only this: the tier, from one number, with no history and no
/// pace to measure (#63). Both callers share the definition so a medal and a
/// projection can never disagree about which tier an agent is on.
CounterTier? tierReached(CounterEnrichment? enrichment, int value) {
  if (enrichment == null || enrichment.tiers.isEmpty) return null;

  final tiers = [...enrichment.tiers]
    ..sort((a, b) => a.value.compareTo(b.value));

  CounterTier? reached;
  for (final tier in tiers) {
    if (value < tier.value) break;
    reached = tier;
  }
  return reached;
}

/// How many whole times [tier] has been reached by [value].
///
/// Rounded **down**, always: 351,056,060 XM against an onyx of 25,000,000 is
/// x 14, not x 15. Claiming a multiple that has not been reached is the same
/// error as a threshold set too low (#76) — the app handing an agent something
/// they have not earned.
int multipleOf(CounterTier tier, int value) =>
    tier.value <= 0 ? 0 : value ~/ tier.value;

/// How many whole times the top tier has been reached, or null while a tier is
/// still ahead (#87).
///
/// The counterpart of [tierReached] for the multiplier: one number, no history
/// and no pace, so a tile can show it without building a projection. Both read
/// the same ladder, so a tile and a card can never disagree.
int? topTierMultiple(CounterEnrichment? enrichment, int value) {
  if (enrichment == null || enrichment.tiers.isEmpty) return null;

  final top = enrichment.tiers.reduce((a, b) => b.value > a.value ? b : a);
  if (value < top.value) return null;
  return multipleOf(top, value);
}

/// The stretch [value] is currently crossing: where it starts, and what it
/// aims at.
///
/// Below the first threshold the stretch starts at zero; past the top one it
/// runs from the multiple reached to the next (#87). Null for a counter the
/// registry knows no thresholds for.
({num from, num target})? tierStretch(
  CounterEnrichment? enrichment,
  int value,
) {
  if (enrichment == null || enrichment.tiers.isEmpty) return null;

  final tiers = [...enrichment.tiers]
    ..sort((a, b) => a.value.compareTo(b.value));

  for (final tier in tiers) {
    if (value < tier.value) {
      final below = tiers.takeWhile((t) => t.value <= value);
      return (from: below.isEmpty ? 0 : below.last.value, target: tier.value);
    }
  }

  final top = tiers.last;
  final multiple = multipleOf(top, value);
  return (from: multiple * top.value, target: (multiple + 1) * top.value);
}

/// How far across its current stretch [value] has come, between 0 and 1 (#90).
///
/// One number from one value, with no history and no pace — the counterpart of
/// [tierReached] and [topTierMultiple] for "how close is the next one". Null
/// for a counter with no thresholds, which is not the same as zero: the list
/// sorts those apart rather than calling them "not started".
double? tierProgress(CounterEnrichment? enrichment, int value) {
  final stretch = tierStretch(enrichment, value);
  if (stretch == null) return null;

  final span = stretch.target - stretch.from;
  if (span <= 0) return null;
  return ((value - stretch.from) / span).clamp(0.0, 1.0);
}

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

    final current = tierReached(enrichment, value);
    CounterTier? next;
    for (final tier in tiers) {
      if (value < tier.value) {
        next = tier;
        break;
      }
    }

    return BadgeProjection(
      value: value,
      current: current,
      next: next,
      top: tiers.last,
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
