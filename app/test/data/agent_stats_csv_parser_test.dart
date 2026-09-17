import 'dart:io';

import 'package:fieldtally/data/parsing/agent_stats_csv_parser.dart';
import 'package:fieldtally/data/parsing/parse_exception.dart';
import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/guards/import_guards.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
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

/// The snapshots alone, for the tests that do not care what was skipped.
extension on AgentStatsCsvParser {
  List<StatSnapshot> rowsOf(String raw, {String agentName = ''}) =>
      parse(raw, agentName: agentName).snapshots;
}

void main() {
  late CounterRegistry registry;

  setUp(() {
    registry = const CounterRegistryLoader().parse(
      File(seedPath).readAsStringSync(),
    );
  });

  AgentStatsCsvParser parser({bool withRegistry = true}) =>
      AgentStatsCsvParser(registry: withRegistry ? registry : null);

  group('a file without a header row', () {
    test('reads the documented column order', () {
      // ap, lifetime_ap, explorer
      final snapshots = parser().rowsOf(
        row('2026-01-15', [3281218, 101542335, 9756]),
      );

      final counters = snapshots.single.counters;
      expect(counters['Current AP'], 3281218);
      expect(counters['Lifetime AP'], 101542335);
      expect(counters['Unique Portals Visited'], 9756);
    });

    test('the time is optional and defaults to midnight', () {
      final withoutTime = parser().rowsOf(row('2026-01-15', [10, 20]));
      final withTime = parser().rowsOf(
        row('2026-01-15', [10, 20], time: '18:30:00'),
      );

      expect(withoutTime.single.recordedAt, DateTime(2026, 1, 15));
      expect(withTime.single.recordedAt, DateTime(2026, 1, 15, 18, 30));
    });

    test('the trailing quoted comment is not mistaken for a counter', () {
      final snapshots = parser().rowsOf(
        row('2026-01-15', [10, 20], comment: 'back from the anomaly'),
      );

      expect(snapshots.single.counters, hasLength(2));
      expect(snapshots.single.counters.values, [10, 20]);
    });

    test('a comment containing spaces stays one field', () {
      final snapshots = parser().rowsOf(
        row('2026-01-15', [10], comment: 'two words here'),
      );

      expect(snapshots.single.counters, {'Current AP': 10});
    });
  });

  group('a file with a header row', () {
    test('maps by name, so a reordered file still reads correctly', () {
      // The header wins over the documented order — the only thing that
      // survives the format gaining or losing a column.
      const raw =
          'Date hacker explorer\n'
          '2026-01-15 78735 9756';

      final counters = parser().rowsOf(raw).single.counters;

      expect(counters['Hacks'], 78735);
      expect(counters['Unique Portals Visited'], 9756);
    });

    test('a header with a time column is handled', () {
      const raw =
          'Date Heure ap lifetime_ap\n'
          '2026-01-15 13:07:39 3281218 101542335';

      final snapshot = parser().rowsOf(raw).single;

      expect(snapshot.recordedAt, DateTime(2026, 1, 15, 13, 7, 39));
      expect(snapshot.counters['Current AP'], 3281218);
    });
  });

  group('Agent Stats keys become export headers', () {
    test('hyphenated keys are translated', () {
      // Agent Stats writes mind-controller where the registry writes
      // mind_controller.
      const raw =
          'Date mind-controller country-master nl-1331-meetups\n'
          '2026-01-15 9527 1362460 1';

      final counters = parser().rowsOf(raw).single.counters;

      expect(counters['Control Fields Created'], 9527);
      expect(counters['Largest Control Field'], 1362460);
      expect(counters['NL-1331 Meetup(s) Attended'], 1);
    });

    test('a counter the registry never heard of keeps its own name', () {
      // Several columns belong to counters Niantic has since retired; §3.1.2
      // says they stay tracked rather than being dropped.
      const raw = 'Date recruiter prime_challenge\n2026-01-15 4 12';

      final counters = parser().rowsOf(raw).single.counters;

      expect(counters['recruiter'], 4);
      expect(counters['prime_challenge'], 12);
    });

    test('without a registry, every key keeps its own name', () {
      const raw = 'Date hacker mind-controller\n2026-01-15 1 2';

      final counters = parser(withRegistry: false).rowsOf(raw).single.counters;

      expect(counters, {'hacker': 1, 'mind_controller': 2});
    });
  });

  group('what the format cannot tell us', () {
    test('there is no level, so the snapshot carries none', () {
      // Storing zero would read as "level 0" rather than "not known".
      expect(parser().rowsOf(row('2026-01-15', [10])).single.level, isNull);
    });

    test('there is no Time Span, so the period is unknown', () {
      // Claiming ALL TIME here would wave a partial-period file straight past
      // the declarative guard (§3.1.3).
      final snapshot = parser().rowsOf(row('2026-01-15', [10])).single;

      expect(snapshot.timeSpan, TimeSpan.unknown);
      expect(snapshot.timeSpan.isCumulative, isFalse);
    });

    test('a blank or dash is an absence, not a zero', () {
      // Agent Stats leaves those for a counter that did not exist yet.
      const raw = 'Date ap lifetime_ap explorer\n2026-01-15 10 - 30';

      final counters = parser().rowsOf(raw).single.counters;

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

      final snapshots = parser().rowsOf(raw);

      expect(snapshots, hasLength(3));
      expect(snapshots.map((s) => s.recordedAt.day), [1, 10, 20]);
    });

    test('the behavioural guard still applies across imported rows', () {
      // This path has no declarative guard at all, so monotonicity is the only
      // protection left — and must never be skipped here (§3.1.3, Appendix B).
      //
      // The third column, explorer, on purpose: ap and lifetime_ap are the two
      // fields Ingress never periodises, so the guard rightly ignores them.
      final snapshots = parser().rowsOf(
        [
          row('2026-01-01', [1, 2, 100]),
          row('2026-01-10', [1, 2, 40]),
        ].join('\n'),
      );

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

  group('a header that does not fit the rows (#132)', () {
    // Both cases are real: they are what the two ways of copying the Agent
    // Stats export page actually produced. Each used to import a whole
    // history one column to the left and report success.

    /// A row in the documented order, with a time and an empty comment, as
    /// the real export writes them.
    String realRow(String date) => row(
      date,
      List<int>.generate(AgentStatsCsvParser.columns.length, (i) => i + 1),
      time: '20:16:15',
      comment: '',
    );

    test('a rotated Date header copied as "ate" is set aside', () {
      // The header is complete but its first entry is not recognised as a
      // date, so it stays and would stand in for a counter. #132 detects it;
      // #133 answers by using the documented order rather than refusing, and
      // by saying which was used.
      final header = [
        'ate',
        ...AgentStatsCsvParser.columns,
        'Comment',
      ].join(' ');

      final read = parser().parse('$header\n${realRow('2026-09-05')}');

      expect(read.headerIgnored, isTrue);
      expect(read.snapshots.single.counters['Current AP'], 1);
      expect(read.snapshots.single.counters['Lifetime AP'], 2);
    });

    test('a row-number column with no cells is set aside too', () {
      // Sharing the page gives the header in full — including the '#' column,
      // whose cells do not come across.
      final header = [
        '#',
        'Date',
        ...AgentStatsCsvParser.columns,
        'Comment',
      ].join(' ');

      final read = parser().parse('$header\n${realRow('2026-09-05')}');

      expect(read.headerIgnored, isTrue);
      expect(read.snapshots.single.counters['Current AP'], 1);
      expect(read.snapshots.single.counters['Lifetime AP'], 2);
    });

    test('a header that does fit is used', () {
      final header = [
        'Date',
        ...AgentStatsCsvParser.columns,
        'Comment',
      ].join(' ');
      final snapshots = parser().rowsOf('$header\n${realRow('2026-09-05')}');

      // Values were generated 1, 2, 3… in column order, so the first counter
      // holds 1 and the second 2. Off by one would show immediately.
      expect(snapshots.single.counters['Current AP'], 1);
      expect(snapshots.single.counters['Lifetime AP'], 2);
    });

    test('and no header at all still falls back to the documented order', () {
      // The workaround agents use today: delete the header line.
      final snapshots = parser().rowsOf(realRow('2026-09-05'));

      expect(snapshots.single.counters['Current AP'], 1);
      expect(snapshots.single.counters['Lifetime AP'], 2);
    });
  });

  group('clean failures', () {
    test('empty file', () {
      expect(
        () => parser().rowsOf('   \n  '),
        throwsA(
          isA<ExportParseException>().having(
            (e) => e.kind,
            'kind',
            ParseErrorKind.emptyText,
          ),
        ),
      );
    });

    test('a header with no rows', () {
      expect(
        () => parser().rowsOf('Date ap lifetime_ap'),
        throwsA(
          isA<ExportParseException>().having(
            (e) => e.kind,
            'kind',
            ParseErrorKind.headerOnly,
          ),
        ),
      );
    });

    test('a malformed date, reported with its line', () {
      expect(
        () => parser().rowsOf('15/01/2026 10 20'),
        throwsA(
          isA<ExportParseException>()
              .having((e) => e.kind, 'kind', ParseErrorKind.invalidDate)
              .having((e) => e.position, 'line', 1),
        ),
      );
    });

    test('a date that does not exist', () {
      expect(
        () => parser().rowsOf(row('2026-02-30', [10])),
        throwsA(
          isA<ExportParseException>().having(
            (e) => e.kind,
            'kind',
            ParseErrorKind.nonExistentDate,
          ),
        ),
      );
    });

    test('a non-numeric value names its column', () {
      expect(
        () => parser().rowsOf('Date ap lifetime_ap\n2026-01-15 10 lots'),
        throwsA(
          isA<ExportParseException>()
              .having((e) => e.kind, 'kind', ParseErrorKind.notAnInteger)
              .having((e) => e.column, 'column', 'lifetime_ap'),
        ),
      );
    });

    test('a row with a date and nothing else', () {
      expect(
        () => parser().rowsOf('2026-01-15'),
        throwsA(isA<ExportParseException>()),
      );
    });
  });

  group('a paste taken off the page (#133)', () {
    String realRow(String date) => row(
      date,
      List<int>.generate(AgentStatsCsvParser.columns.length, (i) => i + 1),
      time: '20:16:15',
      comment: '',
    );

    test(
      'the banner, the count and the pagination are skipped and counted',
      () {
        // What sharing the export page actually produces, in order.
        final pasted = [
          'Agent Stats',
          'Il y a 416 points : — 401–416',
          ['#', 'Date', ...AgentStatsCsvParser.columns, 'Comment'].join(' '),
          realRow('2014-11-16'),
          realRow('2014-11-15'),
          '« prev123',
        ].join('\n');

        final read = parser().parse(pasted);

        expect(read.snapshots.length, 2);
        expect(read.snapshots.first.counters['Current AP'], 1);
        // Banner, count, pagination — and the header that did not fit.
        expect(read.ignoredLines, 4);
        expect(read.headerIgnored, isTrue);
      },
    );

    test('a page with no data row at all is refused', () {
      // Tolerating surroundings must not become tolerating nothing.
      expect(
        () => parser().parse('Agent Stats\n« prev123'),
        throwsA(
          isA<ExportParseException>().having(
            (e) => e.kind,
            'kind',
            ParseErrorKind.emptyText,
          ),
        ),
      );
    });

    test('a header with no rows under it still says so', () {
      final header = ['Date', ...AgentStatsCsvParser.columns].join(' ');

      expect(
        () => parser().parse('Agent Stats\n$header'),
        throwsA(
          isA<ExportParseException>().having(
            (e) => e.kind,
            'kind',
            ParseErrorKind.headerOnly,
          ),
        ),
      );
    });

    test('a clean paste reports nothing skipped', () {
      // The reassurance matters as much as the warning: an agent who pasted
      // carefully should not be told something was dropped.
      final read = parser().parse(realRow('2026-09-05'));

      expect(read.ignoredLines, 0);
      expect(read.headerIgnored, isFalse);
    });
  });
}
