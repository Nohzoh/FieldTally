import 'package:fieldtally/domain/counter_series.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

StatSnapshot at(DateTime date, Map<String, int> counters) => StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: date,
      level: 9,
      counters: counters,
    );

void main() {
  const builder = CounterSeriesBuilder();

  group('series', () {
    test('an unknown counter yields nothing', () {
      final series = builder.series(
        snapshots: [at(DateTime(2026, 1, 1), const {'Hacks': 10})],
        exportHeader: 'Orion Tokens',
      );

      expect(series.isEmpty, isTrue);
      expect(series.isPlottable, isFalse);
      expect(series.gain, isNull);
    });

    test('is chronological whatever order the snapshots come in', () {
      final series = builder.series(
        snapshots: [
          at(DateTime(2026, 1, 20), const {'Hacks': 30}),
          at(DateTime(2026, 1, 1), const {'Hacks': 10}),
          at(DateTime(2026, 1, 10), const {'Hacks': 20}),
        ],
        exportHeader: 'Hacks',
      );

      expect(series.points.map((p) => p.value), [10, 20, 30]);
      expect(series.minValue, 10);
      expect(series.maxValue, 30);
      expect(series.gain, 20);
    });

    test('skips snapshots that did not carry the counter', () {
      // A gap in the imports is not a dip to zero (§3.1.2).
      final series = builder.series(
        snapshots: [
          at(DateTime(2026, 1, 1), const {'Orion Tokens': 100}),
          at(DateTime(2026, 1, 10), const {'Hacks': 5}),
          at(DateTime(2026, 1, 20), const {'Orion Tokens': 160}),
        ],
        exportHeader: 'Orion Tokens',
      );

      expect(series.points.map((p) => p.value), [100, 160]);
    });
  });

  group('ranges', () {
    final history = [
      for (var day = 1; day <= 40; day++)
        at(DateTime(2026, 2, 1).add(Duration(days: day - 1)), {'Hacks': day * 10}),
    ];

    test('the whole history is the default', () {
      final series =
          builder.series(snapshots: history, exportHeader: 'Hacks');

      expect(series.points, hasLength(40));
    });

    test('a week keeps only the last seven days', () {
      final series = builder.series(
        snapshots: history,
        exportHeader: 'Hacks',
        range: ChartRange.week,
      );

      expect(series.points, hasLength(8)); // seven days, inclusive of both ends
      expect(series.points.last.value, 400);
    });

    test('a month keeps more than a week and less than everything', () {
      final series = builder.series(
        snapshots: history,
        exportHeader: 'Hacks',
        range: ChartRange.month,
      );

      expect(series.points.length, greaterThan(8));
      expect(series.points.length, lessThan(40));
    });

    test('the range is measured from the last snapshot, not from today', () {
      // An agent who stopped importing weeks ago should still see their last
      // week of data rather than an empty chart.
      final old = [
        at(DateTime(2020, 1, 1), const {'Hacks': 10}),
        at(DateTime(2020, 1, 5), const {'Hacks': 20}),
      ];

      final series = builder.series(
        snapshots: old,
        exportHeader: 'Hacks',
        range: ChartRange.week,
      );

      expect(series.points, hasLength(2));
    });

    test('a range holding a single point borrows the one before it', () {
      // Otherwise the chart draws nothing and the reader cannot tell progress
      // from a flat line.
      final sparse = [
        at(DateTime(2026, 1, 1), const {'Hacks': 10}),
        at(DateTime(2026, 3, 1), const {'Hacks': 90}),
      ];

      final series = builder.series(
        snapshots: sparse,
        exportHeader: 'Hacks',
        range: ChartRange.week,
      );

      expect(series.points, hasLength(2));
      expect(series.isPlottable, isTrue);
      expect(series.gain, 80);
    });
  });

  group('activity calendar', () {
    test('is empty without at least two snapshots', () {
      expect(
        builder.activityByDay([
          at(DateTime(2026, 1, 1), const {'Lifetime AP': 100}),
        ]),
        isEmpty,
      );
    });

    test('attributes the AP gained to the day it was measured', () {
      final activity = builder.activityByDay([
        at(DateTime(2026, 1, 1, 9), const {'Lifetime AP': 1000}),
        at(DateTime(2026, 1, 5, 20), const {'Lifetime AP': 4000}),
      ]);

      // Deliberately not spread across the four days in between: nothing tells
      // us which days were actually played, and spreading would invent data.
      expect(activity, {DateTime(2026, 1, 5): 3000});
    });

    test('sums several snapshots taken the same day', () {
      final activity = builder.activityByDay([
        at(DateTime(2026, 1, 1, 8), const {'Lifetime AP': 1000}),
        at(DateTime(2026, 1, 2, 9), const {'Lifetime AP': 1500}),
        at(DateTime(2026, 1, 2, 21), const {'Lifetime AP': 1900}),
      ]);

      expect(activity[DateTime(2026, 1, 2)], 900);
    });

    test('ignores days without progress', () {
      final activity = builder.activityByDay([
        at(DateTime(2026, 1, 1), const {'Lifetime AP': 1000}),
        at(DateTime(2026, 1, 2), const {'Lifetime AP': 1000}),
      ]);

      expect(activity, isEmpty);
    });

    test('ignores a drop rather than recording negative activity', () {
      // Should not happen after the guards of §3.1.3, but a forced import can
      // still land one, and a negative square would be nonsense.
      final activity = builder.activityByDay([
        at(DateTime(2026, 1, 1), const {'Lifetime AP': 1000}),
        at(DateTime(2026, 1, 2), const {'Lifetime AP': 400}),
      ]);

      expect(activity, isEmpty);
    });

    test('ignores snapshots without the AP column', () {
      final activity = builder.activityByDay([
        at(DateTime(2026, 1, 1), const {'Lifetime AP': 1000}),
        at(DateTime(2026, 1, 2), const {'Hacks': 5}),
        at(DateTime(2026, 1, 3), const {'Lifetime AP': 1600}),
      ]);

      expect(activity, {DateTime(2026, 1, 3): 600});
    });
  });
}
