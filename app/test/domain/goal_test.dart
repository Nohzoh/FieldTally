import 'package:fieldtally/domain/counter_series.dart';
import 'package:fieldtally/domain/goal.dart';
import 'package:flutter_test/flutter_test.dart';

List<SeriesPoint> daily(DateTime from, List<int> values) => [
      for (var i = 0; i < values.length; i++)
        (at: from.add(Duration(days: i)), value: values[i]),
    ];

Goal goal(int target, {DateTime? deadline}) => Goal(
      exportHeader: 'Unique Portals Visited',
      target: target,
      deadline: deadline,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  const tracker = GoalTracker();

  test('a counter with no history yields no progress', () {
    expect(tracker.progressFor(goal(2000), const []), isNull);
  });

  group('where the goal stands', () {
    test('reports what is left and how far along', () {
      final progress =
          tracker.progressFor(goal(2000), daily(DateTime(2026, 1, 1), [1500]))!;

      expect(progress.value, 1500);
      expect(progress.remaining, 500);
      expect(progress.progress, closeTo(0.75, 0.001));
      expect(progress.isReached, isFalse);
    });

    test('a goal already met is met', () {
      final progress =
          tracker.progressFor(goal(1000), daily(DateTime(2026, 1, 1), [1500]))!;

      expect(progress.isReached, isTrue);
      expect(progress.remaining, 0);
      expect(progress.progress, 1);
      expect(progress.daysToTarget, 0);
    });

    test('progress is measured against the target, not since it was set', () {
      // Someone who sets a goal already halfway there wants to see halfway,
      // not zero.
      final progress =
          tracker.progressFor(goal(2000), daily(DateTime(2026, 1, 1), [1000]))!;

      expect(progress.progress, closeTo(0.5, 0.001));
    });
  });

  group('the projected arrival', () {
    test('follows the recent pace', () {
      final progress = tracker.progressFor(
        goal(2000),
        daily(DateTime(2026, 1, 1), [1400, 1410, 1420, 1430, 1440, 1450]),
      )!;

      expect(progress.perDay, closeTo(10, 0.001));
      expect(progress.daysToTarget, closeTo(55, 0.001));
      expect(progress.projectedDate!.difference(DateTime(2026, 1, 6)).inDays,
          55);
    });

    test('a stalled counter gets none rather than a wrong one', () {
      final progress = tracker.progressFor(
        goal(2000),
        daily(DateTime(2026, 1, 1), [1400, 1400, 1400]),
      )!;

      expect(progress.perDay, 0);
      expect(progress.projectedDate, isNull);
    });

    test('a target centuries away is withheld', () {
      final progress = tracker.progressFor(
        goal(100000000),
        daily(DateTime(2026, 1, 1), [100, 101]),
      )!;

      expect(progress.projectedDate, isNull);
    });
  });

  group('against a deadline', () {
    final steady = daily(DateTime(2026, 1, 1), [1400, 1410, 1420, 1430, 1440]);

    test('no deadline means no opinion', () {
      final progress = tracker.progressFor(goal(2000), steady)!;

      expect(progress.isOnTrack, isNull);
    });

    test('on track when the projection lands before the date', () {
      // 1440 now, 10 a day, 560 to go: about 56 days, so early June is ample.
      final progress = tracker.progressFor(
        goal(2000, deadline: DateTime(2026, 6, 1)),
        steady,
      )!;

      expect(progress.isOnTrack, isTrue);
    });

    test('behind when it lands after', () {
      final progress = tracker.progressFor(
        goal(2000, deadline: DateTime(2026, 2, 1)),
        steady,
      )!;

      expect(progress.isOnTrack, isFalse);
    });

    test('a stalled counter has no opinion rather than being behind', () {
      // "No opinion" and "behind" are different things and read differently.
      final progress = tracker.progressFor(
        goal(2000, deadline: DateTime(2026, 6, 1)),
        daily(DateTime(2026, 1, 1), [1400, 1400]),
      )!;

      expect(progress.isOnTrack, isNull);
    });

    test('a goal already met is on track whatever the pace', () {
      final progress = tracker.progressFor(
        goal(1000, deadline: DateTime(2026, 2, 1)),
        daily(DateTime(2026, 1, 1), [1400, 1400]),
      )!;

      expect(progress.isOnTrack, isTrue);
    });

    test('a passed deadline with the target unmet counts as missed', () {
      final progress = tracker.progressFor(
        goal(2000, deadline: DateTime(2026, 2, 1)),
        steady,
      )!;

      expect(progress.missedBy(DateTime(2026, 3, 1)), isTrue);
      expect(progress.missedBy(DateTime(2026, 1, 15)), isFalse);
    });
  });
}
