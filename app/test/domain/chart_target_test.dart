import 'package:fieldtally/domain/badge_projection.dart';
import 'package:fieldtally/domain/chart_target.dart';
import 'package:fieldtally/domain/goal.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

Goal goalOf(int target) => Goal(
      exportHeader: 'Hacks',
      target: target,
      createdAt: DateTime(2026, 1, 1),
    );

BadgeProjection projectionOf({required int value, CounterTier? next}) =>
    BadgeProjection(
      value: value,
      current: null,
      next: next,
      perDay: 1,
      window: ProjectionWindow.month,
    );

void main() {
  group('what the chart aims at (§3.5)', () {
    test('a goal still ahead wins over the next badge', () {
      // The agent asked for this one; the app's own suggestion does not talk
      // over them.
      final target = chartTargetFor(
        currentValue: 500,
        goal: goalOf(1000),
        projection: projectionOf(
          value: 500,
          next: const CounterTier(name: 'gold', value: 2000),
        ),
      );

      expect(target!.kind, ChartTargetKind.goal);
      expect(target.value, 1000);
      expect(target.tierName, isNull);
    });

    test('with no goal, the next badge is what is left to reach', () {
      final target = chartTargetFor(
        currentValue: 500,
        projection: projectionOf(
          value: 500,
          next: const CounterTier(name: 'gold', value: 2000),
        ),
      );

      expect(target!.kind, ChartTargetKind.badge);
      expect(target.value, 2000);
      expect(target.tierName, 'gold');
    });

    test('a goal already met hands over to the next badge', () {
      // Nothing left to aim at on the agent's own target, and a line drawn
      // below the curve would only say they have already arrived — which the
      // goal card says in words.
      final target = chartTargetFor(
        currentValue: 1500,
        goal: goalOf(1000),
        projection: projectionOf(
          value: 1500,
          next: const CounterTier(name: 'gold', value: 2000),
        ),
      );

      expect(target!.kind, ChartTargetKind.badge);
      expect(target.value, 2000);
    });

    test('a goal met exactly counts as met', () {
      final target = chartTargetFor(
        currentValue: 1000,
        goal: goalOf(1000),
      );

      expect(target, isNull);
    });

    test('onyx earned and no goal leaves nothing to draw', () {
      final target = chartTargetFor(
        currentValue: 999999,
        projection: projectionOf(value: 999999),
      );

      expect(target, isNull);
    });

    test('a counter with neither goal nor tiers leaves the chart alone', () {
      expect(chartTargetFor(currentValue: 42), isNull);
    });

    test('no value yet means nothing to compare against', () {
      expect(
        chartTargetFor(currentValue: null, goal: goalOf(1000)),
        isNull,
      );
    });

    test('a fractional threshold is rounded to the counter\'s own units', () {
      final target = chartTargetFor(
        currentValue: 10,
        projection: projectionOf(
          value: 10,
          next: const CounterTier(name: 'silver', value: 1500.6),
        ),
      );

      expect(target!.value, 1501);
    });
  });
}
