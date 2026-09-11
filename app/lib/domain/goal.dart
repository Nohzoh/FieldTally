import 'counter_series.dart';

/// A personal target on a counter (§3.7).
class Goal {
  const Goal({
    required this.exportHeader,
    required this.target,
    this.deadline,
    required this.createdAt,
  });

  final String exportHeader;
  final int target;

  /// Optional: a target with no date is a direction rather than a deadline.
  final DateTime? deadline;

  final DateTime createdAt;
}

/// Where a goal stands, and whether the current pace gets there in time.
class GoalProgress {
  const GoalProgress({
    required this.goal,
    required this.value,
    required this.perDay,
    required this.measuredFrom,
  });

  final Goal goal;

  /// Latest known value of the counter.
  final int value;

  /// Recent pace, in counter units per day. Null when it cannot be measured.
  final double? perDay;

  /// When the pace was last observed — the latest snapshot, not today.
  final DateTime measuredFrom;

  bool get isReached => value >= goal.target;

  int get remaining => isReached ? 0 : goal.target - value;

  /// Share of the way from where the goal was set to the target.
  ///
  /// Measured against the target rather than against progress since the goal
  /// was created: an agent who set a goal already halfway there wants to see
  /// halfway, not zero.
  double get progress =>
      goal.target <= 0 ? 1 : (value / goal.target).clamp(0.0, 1.0);

  /// Days to the target at the recent pace, or null when no honest estimate
  /// exists — a stalled or shrinking counter gets none rather than infinity.
  double? get daysToTarget {
    if (isReached) return 0;
    final rate = perDay;
    if (rate == null || rate <= 0) return null;
    return remaining / rate;
  }

  /// Projected arrival, or null when there is no estimate to give.
  DateTime? get projectedDate {
    final days = daysToTarget;
    if (days == null) return null;
    if (days > 365 * 5) return null;
    return measuredFrom.add(Duration(hours: (days * 24).round()));
  }

  /// How the goal stands against its deadline.
  ///
  /// Null when there is no deadline, or no pace to judge by: "no opinion" is
  /// different from "behind", and the screen says so.
  bool? get isOnTrack {
    final deadline = goal.deadline;
    if (deadline == null) return null;
    if (isReached) return true;

    final projected = projectedDate;
    if (projected == null) return null;
    return !projected.isAfter(deadline);
  }

  /// True once the deadline has passed without the target being met.
  bool missedBy(DateTime now) =>
      !isReached &&
      goal.deadline != null &&
      now.isAfter(goal.deadline!);
}

/// Computes goal progress from a counter's history (§3.7).
class GoalTracker {
  const GoalTracker({this.window = const Duration(days: 30)});

  /// How far back the pace is measured.
  final Duration window;

  /// [points] must be chronological. Null when the counter has no history at
  /// all, since there is then nothing to measure.
  GoalProgress? progressFor(Goal goal, List<SeriesPoint> points) {
    if (points.isEmpty) return null;

    return GoalProgress(
      goal: goal,
      value: points.last.value,
      perDay: _pace(points),
      measuredFrom: points.last.at,
    );
  }

  /// Pace over the window, measured back from the most recent snapshot rather
  /// than from today — same reasoning as everywhere else (§3.5, §3.6): an
  /// agent who stopped importing has not slowed down, the app stopped hearing
  /// about it.
  double? _pace(List<SeriesPoint> points) {
    if (points.length < 2) return null;

    final last = points.last;
    final cutoff = last.at.subtract(window);

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
