import 'models/stat_snapshot.dart';

/// How far back the counter list measures recent progress (#89).
///
/// Before this existed there was one measure and no window: the difference
/// between the last two snapshots that carried a counter. That is a rank, not
/// a duration — two snapshots an hour apart and two snapshots six weeks apart
/// produced numbers the list then compared as equals, and the span differed
/// from one counter to the next inside the same list.
enum ProgressWindow {
  /// Since the previous snapshot that carried the counter.
  ///
  /// Kept, and kept as the default: it is what the sub-label under every
  /// counter has always said, and an agent who never opens the control should
  /// not find their list reordered.
  sinceLastSnapshot(null),

  week(Duration(days: 7)),

  month(Duration(days: 30));

  const ProgressWindow(this.span);

  /// Null for [sinceLastSnapshot], which is bounded by a snapshot rather than
  /// by a duration.
  final Duration? span;
}

/// A counter's recent movement: how much, over how long, and so how fast.
///
/// [days] is the span actually measured, which is not the window: the anchor
/// is a real snapshot at or before the cutoff, and an agent who imports once a
/// month has no snapshot seven days back. Dividing by the real span is what
/// makes two counters comparable — a total over "the last seven days" that
/// silently spans forty is the defect this replaces.
typedef CounterPace = ({int gain, double days, double perDay});

/// Every counter's pace over [window], measured from the whole history.
///
/// Counted back from the **most recent snapshot** rather than from today, for
/// the reason §3.5 and §3.6 give: an agent who stopped importing three weeks
/// ago has not slowed down, the app stopped hearing about it.
///
/// A counter absent from the result has no measurable pace — one snapshot, or
/// none inside the window. That is "not known yet", which the list keeps apart
/// from "no progress".
Map<String, CounterPace> paceByCounter(
  List<StatSnapshot> snapshots,
  ProgressWindow window,
) {
  if (snapshots.length < 2) return const {};

  final sorted = [...snapshots]
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  // Each counter's own points: a counter absent from a snapshot has not moved,
  // it was simply not reported (§3.1.2), so it must not be anchored on a
  // snapshot that never carried it.
  final points = <String, List<({DateTime at, int value})>>{};
  for (final snapshot in sorted) {
    for (final entry in snapshot.counters.entries) {
      (points[entry.key] ??= []).add((at: snapshot.recordedAt, value: entry.value));
    }
  }

  final reference = sorted.last.recordedAt;
  final paces = <String, CounterPace>{};

  for (final entry in points.entries) {
    final series = entry.value;
    if (series.length < 2) continue;

    final last = series.last;
    final anchor = _anchorFor(series, window, reference);
    if (anchor == null || identical(anchor, last)) continue;

    final days = last.at.difference(anchor.at).inMinutes / (60 * 24);
    if (days <= 0) continue;

    paces[entry.key] = (
      gain: last.value - anchor.value,
      days: days,
      perDay: (last.value - anchor.value) / days,
    );
  }

  return paces;
}

/// Where the measurement starts.
///
/// For a window, the last point at or before the cutoff — or, when every point
/// is inside it, the earliest one, so a window holding a single extra snapshot
/// still has something to measure against instead of reporting no pace at all.
/// This mirrors `BadgeProjector` exactly, so the list and the projection card
/// cannot disagree about how fast a counter is moving.
({DateTime at, int value})? _anchorFor(
  List<({DateTime at, int value})> series,
  ProgressWindow window,
  DateTime reference,
) {
  final span = window.span;
  if (span == null) return series[series.length - 2];

  final cutoff = reference.subtract(span);
  ({DateTime at, int value})? anchor;
  for (final point in series) {
    if (point.at.isAfter(cutoff)) {
      anchor ??= point;
      break;
    }
    anchor = point;
  }
  return anchor ?? series.first;
}
