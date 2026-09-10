import 'package:fieldtally/domain/csv_import.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

StatSnapshot at(DateTime date, Map<String, int> counters) => StatSnapshot(
      timeSpan: TimeSpan.unknown,
      agentName: '',
      faction: '',
      recordedAt: date,
      counters: counters,
    );

void main() {
  const planner = CsvImportPlanner();

  test('an empty file plans nothing', () {
    final plan = planner.plan(const []);

    expect(plan.isEmpty, isTrue);
    expect(plan.isBlocked, isFalse);
    expect(plan.from, isNull);
  });

  test('summarises the span and the counters involved', () {
    final plan = planner.plan([
      at(DateTime(2024, 1, 1), const {'Hacks': 10, 'Links Created': 1}),
      at(DateTime(2026, 6, 1), const {'Hacks': 90}),
    ]);

    expect(plan.snapshots, hasLength(2));
    expect(plan.from, DateTime(2024, 1, 1));
    expect(plan.to, DateTime(2026, 6, 1));
    expect(plan.counterCount, 2);
    expect(plan.isBlocked, isFalse);
  });

  test('finds a bad row in the middle of a long history', () {
    // The whole point of checking every pair: a file carrying years of data
    // can hold a bad row anywhere, and importing it silently would poison the
    // diffs from that date onwards.
    final plan = planner.plan([
      at(DateTime(2024, 1, 1), const {'Hacks': 10}),
      at(DateTime(2024, 6, 1), const {'Hacks': 500}),
      at(DateTime(2025, 1, 1), const {'Hacks': 90}),
      at(DateTime(2025, 6, 1), const {'Hacks': 900}),
    ]);

    expect(plan.hasRegressions, isTrue);
    expect(plan.regressions, hasLength(1));
    expect(plan.regressions.single.at, DateTime(2025, 1, 1));
    expect(plan.regressions.single.regression.drop, 410);
  });

  test('compares the file against what is already stored', () {
    final plan = planner.plan(
      [at(DateTime(2026, 6, 1), const {'Hacks': 40})],
      existingLatest: at(DateTime(2026, 1, 1), const {'Hacks': 100}),
    );

    expect(plan.isBlocked, isTrue);
  });

  test('a file predating the stored history is a backfill, not a regression',
      () {
    // Importing years of older data is exactly what this feature is for; its
    // values are legitimately lower than today's.
    final plan = planner.plan(
      [at(DateTime(2020, 1, 1), const {'Hacks': 5})],
      existingLatest: at(DateTime(2026, 1, 1), const {'Hacks': 100}),
    );

    expect(plan.isBlocked, isFalse);
  });

  test('a counter appearing partway through is not a regression', () {
    final plan = planner.plan([
      at(DateTime(2024, 1, 1), const {'Hacks': 10}),
      at(DateTime(2025, 1, 1), const {'Hacks': 20, 'Drone Hacks': 5}),
    ]);

    expect(plan.hasRegressions, isFalse);
  });

  test('several bad rows are all reported', () {
    final plan = planner.plan([
      at(DateTime(2024, 1, 1), const {'Hacks': 100}),
      at(DateTime(2024, 2, 1), const {'Hacks': 40}),
      at(DateTime(2024, 3, 1), const {'Hacks': 200}),
      at(DateTime(2024, 4, 1), const {'Hacks': 80}),
    ]);

    expect(plan.regressions, hasLength(2));
    expect(
      plan.regressions.map((r) => r.at),
      [DateTime(2024, 2, 1), DateTime(2024, 4, 1)],
    );
  });
}
