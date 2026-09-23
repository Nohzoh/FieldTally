import 'dart:convert';
import 'dart:io';

import 'package:fieldtally/data/parsing/fieldtally_csv_parser.dart';
import 'package:fieldtally/data/parsing/parse_exception.dart';
import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/history_export.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/repositories/snapshot_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';

const header = 'date,time,agent,faction,time_span,level,Hacks\n';

StoredSnapshot stored(
  DateTime date,
  Map<String, int> counters, {
  int? level = 9,
  TimeSpan timeSpan = TimeSpan.allTime,
  String agent = 'AgentDemo',
  String faction = 'Enlightened',
}) => StoredSnapshot(
  id: date.toIso8601String(),
  importedAt: DateTime(2026, 9, 23),
  snapshot: StatSnapshot(
    timeSpan: timeSpan,
    agentName: agent,
    faction: faction,
    recordedAt: date,
    level: level,
    counters: counters,
  ),
);

void main() {
  const parser = FieldTallyCsvParser();

  // The whole point of #191, and the one test that would have caught it on
  // the day the export shipped: what the app writes, the app reads.
  group('the export round-trips', () {
    late CounterRegistry registry;

    setUp(() {
      registry = const CounterRegistryLoader().parse(
        File(seedPath).readAsStringSync(),
      );
    });

    test('every field survives being written and read back', () {
      final csv = HistoryCsvExporter(registry: registry).build([
        stored(DateTime(2026, 1, 2, 8, 30, 15), const {
          'Hacks': 10,
          'Unique Portals Visited': 5,
        }),
        stored(DateTime(2026, 2, 3, 21, 0, 0), const {
          'Hacks': 20,
          'Unique Portals Visited': 9,
        }, level: 12),
      ]);

      final read = parser.parse(csv);

      expect(read, hasLength(2));
      expect(read.first.recordedAt, DateTime(2026, 1, 2, 8, 30, 15));
      expect(read.first.agentName, 'AgentDemo');
      expect(read.first.faction, 'Enlightened');
      expect(read.first.timeSpan, TimeSpan.allTime);
      expect(read.first.level, 9);
      expect(read.first.counters, const {
        'Hacks': 10,
        'Unique Portals Visited': 5,
      });
      expect(read.last.level, 12);
      expect(read.last.counters['Hacks'], 20);
    });

    test('a counter name carrying a comma comes back in one piece', () {
      // The exporter quotes these, and splitting on commas would tear the
      // header apart — which is why this parser reads quotes at all.
      final csv = HistoryCsvExporter(registry: registry).build([
        stored(DateTime(2026, 1, 1), const {'Mission Day(s) Attended': 3}),
      ]);
      expect(csv, contains('Mission Day(s) Attended'));

      final read = parser.parse('date,"a, b"\n2026-01-01,7\n');
      expect(read.single.counters, const {'a, b': 7});
    });

    test('a blank counter cell stays absent rather than becoming a zero', () {
      // §3.1.2: a gap is not a zero. The exporter writes nothing there, and
      // reading it back as 0 would invent a value the agent never had.
      final csv = HistoryCsvExporter(registry: registry).build([
        stored(DateTime(2026, 1, 1), const {'Hacks': 10}),
        stored(DateTime(2026, 2, 1), const {
          'Hacks': 20,
          'Unique Portals Visited': 4,
        }),
      ]);

      final read = parser.parse(csv);
      expect(
        read.first.counters.containsKey('Unique Portals Visited'),
        isFalse,
      );
      expect(read.last.counters['Unique Portals Visited'], 4);
    });

    test('the Level counter and the level column are not the same thing', () {
      // The registry really does carry a counter whose export header is
      // `Level`, so an export of it holds both `level` (the agent's own
      // level, blank when unknown) and `Level` (the counter). Only the case
      // tells them apart, which is why the metadata columns are matched
      // exactly rather than loosely.
      final csv = HistoryCsvExporter(registry: registry).build([
        stored(DateTime(2026, 1, 1), const {'Level': 16, 'Hacks': 10}),
      ]);
      expect(csv.split('\n').first, contains('level,Level'));

      final read = parser.parse(csv);
      expect(read.single.level, 9);
      expect(read.single.counters['Level'], 16);
      expect(read.single.counters['Hacks'], 10);
    });

    test('every counter the registry knows survives the trip', () {
      // The guard against the next collision, rather than against the one
      // already found: any counter whose export header clashes with a
      // metadata column fails here the day it is added to the registry,
      // instead of the day someone restores a phone.
      final seed =
          jsonDecode(File(seedPath).readAsStringSync()) as Map<String, dynamic>;
      final headers = [
        for (final entry in (seed['counters'] as Map<String, dynamic>).values)
          (entry as Map<String, dynamic>)['export_header'] as String,
      ];
      expect(headers, contains('Level'));
      final values = {
        for (var i = 0; i < headers.length; i++) headers[i]: i + 1,
      };

      final csv = HistoryCsvExporter(
        registry: registry,
      ).build([stored(DateTime(2026, 1, 1), values)]);

      expect(parser.parse(csv).single.counters, values);
    });

    test('a blank level comes back as unknown, not as level zero', () {
      final csv = HistoryCsvExporter(registry: registry).build([
        stored(DateTime(2026, 1, 1), const {'Hacks': 1}, level: null),
      ]);

      expect(parser.parse(csv).single.level, isNull);
    });
  });

  group('reading a file', () {
    test('rows come back oldest first whatever order they were written', () {
      final read = parser.parse(
        '$header'
        '2026-03-01,00:00:00,A,E,allTime,9,30\n'
        '2026-01-01,00:00:00,A,E,allTime,9,10\n',
      );

      expect([for (final s in read) s.counters['Hacks']], [10, 30]);
    });

    test('the header decides which column is a counter, not its position', () {
      // §3.1.1. The metadata columns are recognised by name, so an export
      // written with them in another order reads exactly the same.
      final read = parser.parse(
        'Hacks,level,date\n'
        '42,7,2026-01-01\n',
      );

      expect(read.single.counters, const {'Hacks': 42});
      expect(read.single.level, 7);
      expect(read.single.recordedAt, DateTime(2026, 1, 1));
    });

    test('the time is optional and defaults to midnight', () {
      final read = parser.parse('date,Hacks\n2026-01-01,5\n');
      expect(read.single.recordedAt, DateTime(2026, 1, 1));
    });

    test('a file with CRLF line endings reads the same', () {
      // A spreadsheet on Windows writes these, and a history that came back
      // empty because of them would be a baffling failure.
      final read = parser.parse(
        'date,Hacks\r\n2026-01-01,5\r\n2026-02-01,6\r\n',
      );
      expect(read, hasLength(2));
    });

    test('grouping separators left by a spreadsheet are tolerated', () {
      final read = parser.parse('date,Hacks\n2026-01-01,"1,234"\n');
      expect(read.single.counters['Hacks'], 1234);
    });
  });

  group('what it refuses', () {
    test('an empty file', () {
      expect(
        () => parser.parse(''),
        throwsA(
          isA<ExportParseException>().having(
            (e) => e.kind,
            'kind',
            ParseErrorKind.emptyText,
          ),
        ),
      );
    });

    test('a header with no rows under it', () {
      expect(
        () => parser.parse(header),
        throwsA(
          isA<ExportParseException>().having(
            (e) => e.kind,
            'kind',
            ParseErrorKind.headerOnly,
          ),
        ),
      );
    });

    test('a file that is not an export at all', () {
      // What an Agent Stats paste looks like when it lands here by mistake:
      // no date column, so nothing can be read positionally either.
      expect(
        () => parser.parse('2024-01-01 1000 500000\n'),
        throwsA(
          isA<ExportParseException>().having(
            (e) => e.kind,
            'kind',
            ParseErrorKind.missingColumn,
          ),
        ),
      );
    });

    test('a row with more cells than the header has columns', () {
      expect(
        () => parser.parse('date,Hacks\n2026-01-01,5,6\n'),
        throwsA(
          isA<ExportParseException>()
              .having((e) => e.kind, 'kind', ParseErrorKind.columnCountMismatch)
              .having((e) => e.position, 'row', 2),
        ),
      );
    });

    test('the same column twice, which would silently keep one value', () {
      expect(
        () => parser.parse('date,Hacks,Hacks\n2026-01-01,5,6\n'),
        throwsA(
          isA<ExportParseException>().having(
            (e) => e.kind,
            'kind',
            ParseErrorKind.duplicateHeader,
          ),
        ),
      );
    });

    test('a date that does not exist, rather than rolling it forward', () {
      expect(
        () => parser.parse('date,Hacks\n2026-02-30,5\n'),
        throwsA(
          isA<ExportParseException>().having(
            (e) => e.kind,
            'kind',
            ParseErrorKind.nonExistentDate,
          ),
        ),
      );
    });

    test('a value that is not a number, naming the column and the row', () {
      expect(
        () => parser.parse('date,Hacks\n2026-01-01,many\n'),
        throwsA(
          isA<ExportParseException>()
              .having((e) => e.kind, 'kind', ParseErrorKind.notAnInteger)
              .having((e) => e.column, 'column', 'Hacks')
              .having((e) => e.position, 'row', 2),
        ),
      );
    });

    test('a dated row carrying no value at all', () {
      expect(
        () => parser.parse('date,Hacks\n2026-01-01,\n'),
        throwsA(
          isA<ExportParseException>().having(
            (e) => e.kind,
            'kind',
            ParseErrorKind.emptyValue,
          ),
        ),
      );
    });
  });

  group('the declared period', () {
    test('is read back, so the guard of §3.1.3 can see it', () {
      final read = parser.parse('date,time_span,Hacks\n2026-01-01,week,5\n');
      expect(read.single.timeSpan, TimeSpan.week);
    });

    test(
      'is unknown when the column is blank, never assumed to be all time',
      () {
        final read = parser.parse('date,time_span,Hacks\n2026-01-01,,5\n');
        expect(read.single.timeSpan, TimeSpan.unknown);
      },
    );

    test('is unknown when the column is missing entirely', () {
      final read = parser.parse('date,Hacks\n2026-01-01,5\n');
      expect(read.single.timeSpan, TimeSpan.unknown);
    });
  });
}
