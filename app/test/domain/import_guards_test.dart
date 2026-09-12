import 'dart:io';

import 'package:fieldtally/data/parsing/ingress_tsv_parser.dart';
import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/guards/import_guards.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

const allTimePath = 'test/fixtures/sample_export_all_time.tsv';
const weekPath = 'test/fixtures/sample_export_week.tsv';
const seedPath = 'assets/counters_registry_seed.json';

StatSnapshot load(String path) =>
    const IngressTsvParser().parseSingle(File(path).readAsStringSync());

StatSnapshot snapshotWith({
  TimeSpan timeSpan = TimeSpan.allTime,
  required Map<String, int> counters,
  DateTime? recordedAt,
}) =>
    StatSnapshot(
      timeSpan: timeSpan,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: recordedAt ?? DateTime(2026, 1, 15),
      level: 9,
      counters: counters,
    );

void main() {
  const guards = ImportGuards();

  group('guard 1 — declarative, allowlist based', () {
    test('an ALL TIME export passes', () {
      final check = guards.check(load(allTimePath));

      expect(check.isPartialPeriod, isFalse);
      expect(check.isBlocked, isFalse);
    });

    test('a WEEK export is blocked and the period is reported', () {
      final check = guards.check(load(weekPath));

      expect(check.isPartialPeriod, isTrue);
      expect(check.isBlocked, isTrue);
      expect(check.declaredTimeSpan, TimeSpan.week);
    });

    for (final span in [TimeSpan.week, TimeSpan.month, TimeSpan.now]) {
      test('${span.name} is refused', () {
        final check =
            guards.check(snapshotWith(timeSpan: span, counters: const {}));
        expect(check.isBlocked, isTrue);
      });
    }

    test('a future, unknown granularity is refused by default', () {
      // The heart of the allowlist choice: what we do not know is treated as
      // partial, never assumed to be cumulative.
      expect(TimeSpan.parse('THIS QUARTER'), TimeSpan.unknown);
      expect(TimeSpan.parse('THIS QUARTER').isCumulative, isFalse);
    });

    test('recognition ignores case and stray spacing', () {
      for (final raw in ['all time', 'ALL TIME', '  All Time  ', 'all_time']) {
        expect(TimeSpan.parse(raw), TimeSpan.allTime, reason: raw);
      }
    });
  });

  group('guard 2 — behavioural', () {
    test('with no earlier snapshot it has nothing to compare, and says so', () {
      final check = guards.check(load(allTimePath));

      expect(check.comparedAgainstPrevious, isFalse);
      expect(check.regressions, isEmpty);
    });

    test('two consistent snapshots trigger nothing', () {
      final previous = snapshotWith(counters: const {'Hacks': 100});
      final check = guards.check(
        snapshotWith(counters: const {'Hacks': 120}),
        previous: previous,
      );

      expect(check.hasRegressions, isFalse);
      expect(check.isBlocked, isFalse);
    });

    test('a counter going down is reported with its magnitude', () {
      final check = guards.check(
        snapshotWith(counters: const {'Hacks': 80}),
        previous: snapshotWith(counters: const {'Hacks': 100}),
      );

      expect(check.regressions, hasLength(1));
      expect(check.regressions.single.exportHeader, 'Hacks');
      expect(check.regressions.single.previous, 100);
      expect(check.regressions.single.current, 80);
      expect(check.regressions.single.drop, 20);
      expect(check.isBlocked, isTrue);
    });

    test('drops are sorted largest first', () {
      final check = guards.check(
        snapshotWith(counters: const {'Hacks': 90, 'Links Created': 10}),
        previous:
            snapshotWith(counters: const {'Hacks': 100, 'Links Created': 500}),
      );

      expect(
        check.regressions.map((r) => r.exportHeader),
        ['Links Created', 'Hacks'],
      );
    });

    test('a counter appearing is not a regression', () {
      final check = guards.check(
        snapshotWith(counters: const {'Hacks': 100, 'Zeta Tokens': 5}),
        previous: snapshotWith(counters: const {'Hacks': 100}),
      );

      expect(check.hasRegressions, isFalse);
    });

    test('a counter disappearing is never read as a reset to zero', () {
      // Rule of §3.1.2: absence is not a zero. A finished anomaly counter must
      // not pollute the anomaly screen on every subsequent import.
      final check = guards.check(
        snapshotWith(counters: const {'Hacks': 100}),
        previous: snapshotWith(
          counters: const {'Hacks': 100, 'Orion Tokens': 14204},
        ),
      );

      expect(check.hasRegressions, isFalse);
    });

    test('tolerance, when configured, absorbs small drops', () {
      const tolerant = ImportGuards(tolerance: 5);
      final previous = snapshotWith(counters: const {'Hacks': 100});

      expect(
        tolerant
            .check(snapshotWith(counters: const {'Hacks': 96}),
                previous: previous)
            .hasRegressions,
        isFalse,
      );
      expect(
        tolerant
            .check(snapshotWith(counters: const {'Hacks': 94}),
                previous: previous)
            .hasRegressions,
        isTrue,
      );
    });
  });

  group('the case that justifies having both guards (§3.1.3)', () {
    test('a WEEK imported after an ALL TIME trips guard 2', () {
      final check = guards.check(load(weekPath), previous: load(allTimePath));

      expect(check.hasRegressions, isTrue);
      expect(
        check.regressions.map((r) => r.exportHeader),
        contains('Unique Portals Visited'),
      );
    });

    test('but Level, Lifetime AP and Current AP give no signal at all', () {
      // Finding of §3.1.3: Ingress never scopes these three to a period. A
      // guard watching only AP would therefore let a WEEK import through
      // without a murmur. That is exactly what this test locks down.
      final check = guards.check(load(weekPath), previous: load(allTimePath));

      expect(
        check.regressions.map((r) => r.exportHeader),
        isNot(anyElement(isIn(StatSnapshot.nonPeriodizedHeaders))),
      );
    });

    test('watching AP alone would detect nothing — demonstration', () {
      final allTime = load(allTimePath);
      final week = load(weekPath);

      for (final header in StatSnapshot.nonPeriodizedHeaders) {
        expect(week.counters[header], allTime.counters[header], reason: header);
      }
    });

    test('a recursion is not an import mistake', () {
      // Recursion resets an agent's level to 1 and their AP to 0, while every
      // lifetime counter carries on. It is the one moment where a counter
      // legitimately goes backwards, and the agent importing that evening must
      // not be told their export looks wrong.
      //
      // It is tolerated today because Level and Current AP are non-periodized
      // and the guard skips them — a reason that has nothing to do with
      // recursion. This pins the outcome so that reason cannot quietly change.
      final check = guards.check(
        snapshotWith(counters: const {
          'Level': 1,
          'Current AP': 0,
          'Recursions': 1,
          'Hacks': 78735,
        }),
        previous: snapshotWith(counters: const {
          'Level': 16,
          'Current AP': 40000000,
          'Recursions': 0,
          'Hacks': 78735,
        }),
      );

      expect(check.hasRegressions, isFalse);
      expect(check.isBlocked, isFalse);
    });

    test('the bundled registry is what actually grants that tolerance', () {
      // In the app the registry decides, not the fallback set — and the
      // registry is fetched from Pages, so it can change without a release.
      // Marking `ap` periodized there would block every recursing agent's next
      // import, remotely. This fails if that ever happens.
      final registry = const CounterRegistryLoader()
          .parse(File(seedPath).readAsStringSync());

      expect(registry.isPeriodized('Current AP'), isFalse);
      expect(registry.isPeriodized('Level'), isFalse);

      final check = guards.check(
        snapshotWith(counters: const {'Level': 1, 'Current AP': 0}),
        previous: snapshotWith(
          counters: const {'Level': 16, 'Current AP': 40000000},
        ),
        registry: registry,
      );

      expect(check.hasRegressions, isFalse);
    });

    test('but a recursion does not excuse a lifetime counter going backwards',
        () {
      // The tolerance covers the two fields recursion resets, and is not an
      // amnesty for the snapshot carrying them: a WEEK export imported on the
      // evening of a recursion is still the mistake the guard exists to catch.
      final check = guards.check(
        snapshotWith(counters: const {
          'Level': 1,
          'Current AP': 0,
          'Recursions': 1,
          'Hacks': 12,
        }),
        previous: snapshotWith(counters: const {
          'Level': 16,
          'Current AP': 40000000,
          'Recursions': 0,
          'Hacks': 78735,
        }),
      );

      expect(check.regressions.map((r) => r.exportHeader), ['Hacks']);
      expect(check.isBlocked, isTrue);
    });

    test('guard 2 protects the CSV path, which has no Time Span', () {
      // On that path (Appendix B) the declarative guard is blind: the column
      // does not exist. Monotonicity is then the only protection, which is one
      // more reason never to disable it.
      final check = guards.check(
        snapshotWith(timeSpan: TimeSpan.unknown, counters: const {'Hacks': 40}),
        previous: snapshotWith(counters: const {'Hacks': 78735}),
      );

      expect(check.isPartialPeriod, isFalse);
      expect(check.hasRegressions, isTrue);
      expect(check.isBlocked, isTrue);
    });
  });
}
