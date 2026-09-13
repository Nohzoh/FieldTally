import 'badge_projection.dart';
import 'goal.dart';

/// What a counter's chart draws a line at (§3.5, #61).
enum ChartTargetKind {
  /// A target the agent set themselves.
  goal,

  /// The next badge tier, when the registry declares thresholds.
  badge,
}

class ChartTarget {
  const ChartTarget({required this.value, required this.kind, this.tierName});

  final int value;
  final ChartTargetKind kind;

  /// Registry tier key (`bronze`, `onyx`) for a badge target, null for a goal.
  final String? tierName;
}

/// The nearest thing still ahead of [currentValue], or null when there is
/// nothing left to aim at.
///
/// A goal wins over a badge: it is what the agent asked for, and the app's own
/// suggestion should not talk over them. But only while it is still ahead —
/// once it is met there is nothing to aim at, and a line drawn below the curve
/// would say only that the agent has already arrived, which [GoalCard] says
/// in words. The next tier then takes over, if there is one.
///
/// Deliberately pure: the rule is four lines and every branch of it is worth a
/// test, none of which should need a widget.
ChartTarget? chartTargetFor({
  required int? currentValue,
  Goal? goal,
  BadgeProjection? projection,
}) {
  if (currentValue == null) return null;

  if (goal != null && goal.target > currentValue) {
    return ChartTarget(value: goal.target, kind: ChartTargetKind.goal);
  }

  final next = projection?.next;
  if (next != null && next.value > currentValue) {
    return ChartTarget(
      value: next.value.round(),
      kind: ChartTargetKind.badge,
      tierName: next.name,
    );
  }

  return null;
}
