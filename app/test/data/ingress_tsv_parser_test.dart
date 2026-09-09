import 'dart:io';

import 'package:fieldtally/data/parsing/ingress_tsv_parser.dart';
import 'package:fieldtally/data/parsing/parse_exception.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

const allTimePath = 'test/fixtures/sample_export_all_time.tsv';
const weekPath = 'test/fixtures/sample_export_week.tsv';

String fixture(String path) => File(path).readAsStringSync();

/// Rebuilds an export from headers and values.
String buildExport(List<String> headers, List<String> values) =>
    '${headers.join('\t')}\n${values.join('\t')}\n';

/// Splits a fixture into (headers, values).
(List<String>, List<String>) split(String raw) {
  final lines = raw.trim().split('\n');
  return (lines[0].split('\t'), lines[1].split('\t'));
}

/// Matches an exception of the given kind, optionally on a given column.
Matcher throwsParseError(ParseErrorKind kind, {String? column}) {
  var matcher = isA<ExportParseException>().having((e) => e.kind, 'kind', kind);
  if (column != null) {
    matcher = matcher.having((e) => e.column, 'column', column);
  }
  return throwsA(matcher);
}

void main() {
  const parser = IngressTsvParser();

  group('real ALL TIME export', () {
    test('extracts snapshot metadata', () {
      final snapshot = parser.parseSingle(fixture(allTimePath));

      expect(snapshot.timeSpan, TimeSpan.allTime);
      expect(snapshot.agentName, 'AgentDemo');
      expect(snapshot.faction, 'Enlightened');
      expect(snapshot.level, 9);
      expect(snapshot.recordedAt, DateTime(2026, 1, 15, 13, 7, 39));
    });

    test('extracts all 59 counters', () {
      final snapshot = parser.parseSingle(fixture(allTimePath));

      // 64 columns in total, 5 of which are pure metadata. `Level` counts as a
      // counter: it is tracked over time (Appendix A).
      expect(snapshot.counters, hasLength(59));
      expect(snapshot.counters['Lifetime AP'], 101542335);
      expect(snapshot.counters['Unique Portals Visited'], 9756);
      expect(snapshot.counters['Recursions'], 1);
      expect(snapshot.counters['Level'], 9);
    });

    test('keeps zero valued counters rather than dropping them', () {
      final snapshot = parser.parseSingle(fixture(allTimePath));

      // A zero is information: "never done", not "unknown".
      expect(snapshot.counters['OPR Live Events'], 0);
      expect(snapshot.counters.containsKey('OPR Live Events'), isTrue);
    });
  });

  group('real WEEK export', () {
    test('reports the declared period without correcting it', () {
      // The parser does not judge, it reports faithfully. Blocking is the
      // guards' job (§3.1.3).
      expect(parser.parseSingle(fixture(weekPath)).timeSpan, TimeSpan.week);
    });
  });

  group('mapping by header name, never by position (§3.1.1)', () {
    test('an export with reordered columns yields the same result', () {
      final (headers, values) = split(fixture(allTimePath));

      // Fully reverse the column order: a positional parser would produce
      // nonsense, this one must be indifferent.
      final indices = List.generate(headers.length, (i) => i).reversed.toList();
      final shuffled = buildExport(
        [for (final i in indices) headers[i]],
        [for (final i in indices) values[i]],
      );

      final original = parser.parseSingle(fixture(allTimePath));
      final reordered = parser.parseSingle(shuffled);

      expect(reordered.agentName, original.agentName);
      expect(reordered.level, original.level);
      expect(reordered.recordedAt, original.recordedAt);
      expect(reordered.counters, equals(original.counters));
    });

    test('an unknown column becomes a tracked counter (§3.1.2)', () {
      final (headers, values) = split(fixture(allTimePath));
      final raw = buildExport(
        [...headers, 'Zeta Anomaly Tokens'],
        [...values, '4242'],
      );

      final snapshot = parser.parseSingle(raw);

      // No hard coded list: a brand new counter is tracked from its first
      // appearance, without waiting for an app update.
      expect(snapshot.counters['Zeta Anomaly Tokens'], 4242);
      expect(snapshot.counters, hasLength(60));
    });

    test('a counter disappearing does not break parsing', () {
      final (headers, values) = split(fixture(allTimePath));
      final index = headers.indexOf('Orion Tokens');
      headers.removeAt(index);
      values.removeAt(index);

      final snapshot = parser.parseSingle(buildExport(headers, values));

      expect(snapshot.counters.containsKey('Orion Tokens'), isFalse);
      expect(snapshot.counters, hasLength(58));
      expect(snapshot.counters['Apollo Tokens'], 12802);
    });

    test('tolerates a changing format hint on Date and Time', () {
      final (headers, values) = split(fixture(allTimePath));
      headers[headers.indexOf('Date (yyyy-mm-dd)')] = 'Date';
      headers[headers.indexOf('Time (hh:mm:ss)')] = 'Time';

      final snapshot = parser.parseSingle(buildExport(headers, values));

      expect(snapshot.recordedAt, DateTime(2026, 1, 15, 13, 7, 39));
    });
  });

  group('locale specific number formats (§6)', () {
    for (final entry in {
      'thin space': '101 542 335',
      'anglo-saxon comma': '101,542,335',
      'german period': '101.542.335',
      'swiss apostrophe': "101'542'335",
    }.entries) {
      test('accepts a thousands separator: ${entry.key}', () {
        final (headers, values) = split(fixture(allTimePath));
        values[headers.indexOf('Lifetime AP')] = entry.value;

        final snapshot = parser.parseSingle(buildExport(headers, values));

        expect(snapshot.counters['Lifetime AP'], 101542335);
      });
    }
  });

  group('clean failures (§3.1)', () {
    test('empty text', () {
      expect(() => parser.parse(''), throwsParseError(ParseErrorKind.emptyText));
    });

    test('headers without a value row', () {
      final (headers, _) = split(fixture(allTimePath));
      expect(
        () => parser.parse('${headers.join('\t')}\n'),
        throwsParseError(ParseErrorKind.headerOnly),
      );
    });

    test('text that is not tab separated', () {
      expect(
        () => parser.parse('hello\nthis is not an export'),
        throwsParseError(ParseErrorKind.notTabSeparated),
      );
    });

    test('missing metadata column, reported by name', () {
      final (headers, values) = split(fixture(allTimePath));
      final index = headers.indexOf('Agent Name');
      headers.removeAt(index);
      values.removeAt(index);

      expect(
        () => parser.parseSingle(buildExport(headers, values)),
        throwsParseError(ParseErrorKind.missingColumn, column: 'Agent Name'),
      );
    });

    test('duplicate headers', () {
      final raw = buildExport(
        [
          'Time Span',
          'Agent Name',
          'Agent Faction',
          'Date',
          'Time',
          'Level',
          'Hacks',
          'Hacks',
        ],
        [
          'ALL TIME',
          'AgentDemo',
          'Enlightened',
          '2026-01-15',
          '13:07:39',
          '9',
          '1',
          '2',
        ],
      );

      expect(
        () => parser.parseSingle(raw),
        throwsParseError(ParseErrorKind.duplicateHeader, column: 'Hacks'),
      );
    });

    test('value count inconsistent with headers', () {
      final (headers, values) = split(fixture(allTimePath));
      values.removeLast();

      expect(
        () => parser.parseSingle(buildExport(headers, values)),
        throwsParseError(ParseErrorKind.columnCountMismatch),
      );
    });

    test('non numeric value, reported with its column and raw value', () {
      final (headers, values) = split(fixture(allTimePath));
      values[headers.indexOf('Hacks')] = 'lots';

      expect(
        () => parser.parseSingle(buildExport(headers, values)),
        throwsA(
          isA<ExportParseException>()
              .having((e) => e.kind, 'kind', ParseErrorKind.notAnInteger)
              .having((e) => e.column, 'column', 'Hacks')
              .having((e) => e.rawValue, 'rawValue', 'lots'),
        ),
      );
    });

    test('non existent date', () {
      final (headers, values) = split(fixture(allTimePath));
      values[headers.indexOf('Date (yyyy-mm-dd)')] = '2026-02-30';

      expect(
        () => parser.parseSingle(buildExport(headers, values)),
        throwsParseError(ParseErrorKind.nonExistentDate, column: 'Date'),
      );
    });

    test('nothing is half stored when a value fails', () {
      final (headers, values) = split(fixture(allTimePath));
      values[headers.indexOf('Hacks')] = '';

      // The parser throws rather than returning a partial snapshot: a visible
      // failure beats a silently skewed history.
      expect(
        () => parser.parseSingle(buildExport(headers, values)),
        throwsParseError(ParseErrorKind.emptyValue, column: 'Hacks'),
      );
    });
  });

  group('paste robustness', () {
    test('handles Windows line endings and a BOM', () {
      final raw = '﻿${fixture(allTimePath).replaceAll('\n', '\r\n')}';

      expect(parser.parseSingle(raw).agentName, 'AgentDemo');
    });

    test('ignores trailing blank lines', () {
      expect(parser.parseSingle('${fixture(allTimePath)}\n\n  \n').level, 9);
    });

    test('time is optional and defaults to midnight (Appendix B)', () {
      final (headers, values) = split(fixture(allTimePath));
      values[headers.indexOf('Time (hh:mm:ss)')] = '';

      final snapshot = parser.parseSingle(buildExport(headers, values));

      expect(snapshot.recordedAt, DateTime(2026, 1, 15));
    });
  });
}
