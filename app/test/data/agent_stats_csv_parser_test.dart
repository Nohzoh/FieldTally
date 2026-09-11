import 'dart:io';

import 'package:fieldtally/data/parsing/agent_stats_csv_parser.dart';
import 'package:fieldtally/data/parsing/parse_exception.dart';
import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/guards/import_guards.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';

/// A row in the documented column order, filled from the front. Anything not
/// supplied is left blank, which Agent Stats does for counters that did not
/// exist at that date.
String row(String date, List<Object?> values, {String? time, String? comment}) {
  final fields = <String>[
    date,
    ?time,
    for (final value in values) value?.toString() ?? '-',
  ];
  if (comment != null) fields.add('"$comment"');
  return fields.join(' ');
}

void main() {
  late CounterRegistry registry;

  setUp(() {
    registry =
        const CounterRegistryLoader().parse(File(seedPath).readAsStringSync());
  });

  AgentStatsCsvParser parser({bool withRegistry = true}) =>
      AgentStatsCsvParser(registry: withRegistry ? registry : null);

  group('a file without a header row', () {
    test('reads the documented column order', () {
      // ap, lifetime_ap, explorer
      final snapshots =
          parser().parse(row('2026-01-15', [3281218, 101542335, 9756]));

      final counters = snapshots.single.counters;
      expect(counters['Current AP'], 3281218);
      expect(counters['Lifetime AP'], 101542335);
      expect(counters['Unique Portals Visited'], 9756);
    });

    test('the time is optional and defaults to midnight', () {
      final withoutTime = parser().parse(row('2026-01-15', [10, 20]));
      final withTime =
          parser().parse(row('2026-01-15', [10, 20], time: '18:30:00'));

      expect(withoutTime.single.recordedAt, DateTime(2026, 1, 15));
      expect(withTime.single.recordedAt, DateTime(2026, 1, 15, 18, 30));
    });

    test('the trailing quoted comment is not mistaken for a counter', () {
      final snapshots = parser().parse(
        row('2026-01-15', [10, 20], comment: 'back from the anomaly'),
      );

      expect(snapshots.single.counters, hasLength(2));
      expect(snapshots.single.counters.values, [10, 20]);
    });

    test('a comment containing spaces stays one field', () {
      final snapshots = parser()
          .parse(row('2026-01-15', [10], comment: 'two words here'));

      expect(snapshots.single.counters, {'Current AP': 10});
    });
  });

  group('a file with a header row', () {
    test('maps by name, so a reordered file still reads correctly', () {
      // The header wins over the documented order — the only thing that
      // survives the format gaining or losing a column.
      const raw = 'Date hacker explorer\n'
          '2026-01-15 78735 9756';

      final counters = parser().parse(raw).single.counters;

      expect(counters['Hacks'], 78735);
      expect(counters['Unique Portals Visited'], 9756);
    });

    test('a header with a time column is handled', () {
      const raw = 'Date Heure ap lifetime_ap\n'
          '2026-01-15 13:07:39 3281218 101542335';

      final snapshot = parser().parse(raw).single;

      expect(snapshot.recordedAt, DateTime(2026, 1, 15, 13, 7, 39));
      expect(snapshot.counters['Current AP'], 3281218);
    });
  });

  group('Agent Stats keys become export headers', () {
    test('hyphenated keys are translated', () {
      // Agent Stats writes mind-controller where the registry writes
      // mind_controller.
      const raw = 'Date mind-controller country-master nl-1331-meetups\n'
          '2026-01-15 9527 1362460 1';

      final counters = parser().parse(raw).single.counters;

      expect(counters['Control Fields Created'], 9527);
      expect(counters['Largest Control Field'], 1362460);
      expect(counters['NL-1331 Meetup(s) Attended'], 1);
    });

    test('a counter the registry never heard of keeps its own name', () {
      // Several columns belong to counters Niantic has since retired; §3.1.2
      // says they stay tracked rather than being dropped.
      const raw = 'Date recruiter prime_challenge\n2026-01-15 4 12';

      final counters = parser().parse(raw).single.counters;

      expect(counters['recruiter'], 4);
      expect(counters['prime_challenge'], 12);
    });

    test('without a registry, every key keeps its own name', () {
      const raw = 'Date hacker mind-controller\n2026-01-15 1 2';

      final counters = parser(withRegistry: false).parse(raw).single.counters;

      expect(counters, {'hacker': 1, 'mind_controller': 2});
    });
  });

  group('what the format cannot tell us', () {
    test('there is no level, so the snapshot carries none', () {
      // Storing zero would read as "level 0" rather than "not known".
      expect(parser().parse(row('2026-01-15', [10])).single.level, isNull);
    });

    test('there is no Time Span, so the period is unknown', () {
      // Claiming ALL TIME here would wave a partial-period file straight past
      // the declarative guard (§3.1.3).
      final snapshot = parser().parse(row('2026-01-15', [10])).single;

      expect(snapshot.timeSpan, TimeSpan.unknown);
      expect(snapshot.timeSpan.isCumulative, isFalse);
    });

    test('a blank or dash is an absence, not a zero', () {
      // Agent Stats leaves those for a counter that did not exist yet.
      const raw = 'Date ap lifetime_ap explorer\n2026-01-15 10 - 30';

      final counters = parser().parse(raw).single.counters;

      expect(counters.containsKey('Lifetime AP'), isFalse);
      expect(counters['Current AP'], 10);
      expect(counters['Unique Portals Visited'], 30);
    });
  });

  group('several rows', () {
    test('every row becomes a snapshot, oldest first', () {
      final raw = [
        row('2026-01-20', [30]),
        row('2026-01-01', [10]),
        row('2026-01-10', [20]),
      ].join('\n');

      final snapshots = parser().parse(raw);

      expect(snapshots, hasLength(3));
      expect(
        snapshots.map((s) => s.recordedAt.day),
        [1, 10, 20],
      );
    });

    test('the behavioural guard still applies across imported rows', () {
      // This path has no declarative guard at all, so monotonicity is the only
      // protection left — and must never be skipped here (§3.1.3, Appendix B).
      //
      // The third column, explorer, on purpose: ap and lifetime_ap are the two
      // fields Ingress never periodises, so the guard rightly ignores them.
      final snapshots = parser().parse([
        row('2026-01-01', [1, 2, 100]),
        row('2026-01-10', [1, 2, 40]),
      ].join('\n'));

      final check = const ImportGuards().check(
        snapshots.last,
        previous: snapshots.first,
        registry: registry,
      );

      expect(check.isPartialPeriod, isFalse, reason: 'no Time Span to go on');
      expect(check.hasRegressions, isTrue);
      expect(check.isBlocked, isTrue);
    });
  });

  group('clean failures', () {
    test('empty file', () {
      expect(
        () => parser().parse('   \n  '),
        throwsA(isA<ExportParseException>()
            .having((e) => e.kind, 'kind', ParseErrorKind.emptyText)),
      );
    });

    test('a header with no rows', () {
      expect(
        () => parser().parse('Date ap lifetime_ap'),
        throwsA(isA<ExportParseException>()
            .having((e) => e.kind, 'kind', ParseErrorKind.headerOnly)),
      );
    });

    test('a malformed date, reported with its line', () {
      expect(
        () => parser().parse('15/01/2026 10 20'),
        throwsA(isA<ExportParseException>()
            .having((e) => e.kind, 'kind', ParseErrorKind.invalidDate)
            .having((e) => e.position, 'line', 1)),
      );
    });

    test('a date that does not exist', () {
      expect(
        () => parser().parse(row('2026-02-30', [10])),
        throwsA(isA<ExportParseException>()
            .having((e) => e.kind, 'kind', ParseErrorKind.nonExistentDate)),
      );
    });

    test('a non-numeric value names its column', () {
      expect(
        () => parser().parse('Date ap lifetime_ap\n2026-01-15 10 lots'),
        throwsA(isA<ExportParseException>()
            .having((e) => e.kind, 'kind', ParseErrorKind.notAnInteger)
            .having((e) => e.column, 'column', 'lifetime_ap')),
      );
    });

    test('a row with a date and nothing else', () {
      expect(
        () => parser().parse('2026-01-15'),
        throwsA(isA<ExportParseException>()),
      );
    });
  });
}
