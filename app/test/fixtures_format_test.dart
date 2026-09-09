// FORMAT tests for the Ingress export fixtures.
//
// Deliberately narrow in scope (see §3.1.1): these only check that both
// fixtures read back as TSV and carry the expected headers. The business
// parser has its own suite in test/data/.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One export row split as TSV, indexed by header name.
///
/// Intentionally minimal: this is not the business parser, just enough to
/// verify the tabular format is intact.
class TsvExport {
  TsvExport(this.headers, this.rows);

  final List<String> headers;
  final List<List<String>> rows;

  static TsvExport read(String path) {
    final lines = File(path)
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final headers = lines.first.split('\t');
    final rows = lines.skip(1).map((line) => line.split('\t')).toList();
    return TsvExport(headers, rows);
  }

  String value(int row, String header) => rows[row][headers.indexOf(header)];
}

/// Snapshot metadata columns, as opposed to counter columns which are
/// "everything else" (§3.1.1).
const metadataHeaders = <String>[
  'Time Span',
  'Agent Name',
  'Agent Faction',
  'Date (yyyy-mm-dd)',
  'Time (hh:mm:ss)',
];

const fixturesDir = 'test/fixtures';
const allTimePath = '$fixturesDir/sample_export_all_time.tsv';
const weekPath = '$fixturesDir/sample_export_week.tsv';

void main() {
  group('Ingress export fixtures', () {
    for (final entry in {
      'ALL TIME': allTimePath,
      'WEEK': weekPath,
    }.entries) {
      final expectedTimeSpan = entry.key;
      final path = entry.value;

      group('$path ($expectedTimeSpan)', () {
        late TsvExport export;

        setUp(() => export = TsvExport.read(path));

        test('the file exists and holds a header plus one snapshot', () {
          expect(File(path).existsSync(), isTrue, reason: 'missing fixture');
          expect(export.rows, hasLength(1));
        });

        test('headers are non empty and free of duplicates', () {
          expect(export.headers, isNotEmpty);
          expect(export.headers.any((h) => h.trim().isEmpty), isFalse,
              reason: 'an empty header would break name based mapping');
          expect(export.headers.toSet(), hasLength(export.headers.length),
              reason: 'duplicate headers would make mapping ambiguous');
        });

        test('every row has as many fields as there are headers', () {
          for (final row in export.rows) {
            expect(row, hasLength(export.headers.length));
          }
        });

        test('the expected metadata columns are present', () {
          for (final header in metadataHeaders) {
            expect(export.headers, contains(header));
          }
          // `Level` is present too, but tracked as a counter in its own right
          // on the registry side (Appendix A).
          expect(export.headers, contains('Level'));
        });

        test('Time Span reads $expectedTimeSpan', () {
          expect(export.value(0, 'Time Span'), expectedTimeSpan);
        });

        test('date and time use the expected formats', () {
          expect(export.value(0, 'Date (yyyy-mm-dd)'),
              matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
          expect(export.value(0, 'Time (hh:mm:ss)'),
              matches(RegExp(r'^\d{2}:\d{2}:\d{2}$')));
        });

        test('every counter column holds an integer', () {
          final counterHeaders = export.headers
              .where((h) => !metadataHeaders.contains(h))
              .toList();
          expect(counterHeaders, isNotEmpty);

          for (final header in counterHeaders) {
            final raw = export.value(0, header);
            expect(int.tryParse(raw), isNotNull,
                reason: 'column "$header": non integer value ("$raw")');
          }
        });

        test('the fixture is anonymised (§3.1.3)', () {
          expect(export.value(0, 'Agent Name'), 'AgentDemo',
              reason: 'no real Ingress codename may be committed');
        });
      });
    }

    test('both fixtures share exactly the same headers', () {
      expect(TsvExport.read(weekPath).headers,
          equals(TsvExport.read(allTimePath).headers));
    });

    test('Level, Lifetime AP and Current AP match between ALL TIME and WEEK',
        () {
      // Finding of §3.1.3: Ingress never scopes these three fields to a
      // period. The behavioural guard therefore cannot rely on them — hence
      // this test, which pins the observation down.
      final allTime = TsvExport.read(allTimePath);
      final week = TsvExport.read(weekPath);

      for (final header in ['Level', 'Lifetime AP', 'Current AP']) {
        expect(week.value(0, header), allTime.value(0, header),
            reason: '"$header" should not vary with the period');
      }
    });

    test('periodized counters are indeed reduced in the WEEK export', () {
      final allTime = TsvExport.read(allTimePath);
      final week = TsvExport.read(weekPath);

      // Counter-proof to the previous test: at least one periodized counter
      // must be strictly lower, otherwise the WEEK fixture adds nothing.
      final periodized = allTime.headers.where(
        (h) =>
            !metadataHeaders.contains(h) &&
            !['Level', 'Lifetime AP', 'Current AP'].contains(h),
      );

      final reduced = periodized.where((h) =>
          int.parse(week.value(0, h)) < int.parse(allTime.value(0, h)));

      expect(reduced, isNotEmpty,
          reason: 'the WEEK fixture must cover a partial period');
      expect(int.parse(week.value(0, 'Unique Portals Visited')),
          lessThan(int.parse(allTime.value(0, 'Unique Portals Visited'))));
    });
  });
}
