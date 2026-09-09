import 'dart:io';

import 'package:fieldtally/data/parsing/ingress_tsv_parser.dart';
import 'package:fieldtally/domain/guards/import_guards.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

const allTimePath = 'test/fixtures/sample_export_all_time.tsv';
const weekPath = 'test/fixtures/sample_export_week.tsv';

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
