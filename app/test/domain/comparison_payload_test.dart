import 'package:fieldtally/domain/comparison_payload.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

StatSnapshot snapshot({
  String agent = 'Nohzoh',
  String faction = 'Enlightened',
  int? level = 14,
  TimeSpan span = TimeSpan.allTime,
  DateTime? at,
  Map<String, int> counters = const {
    'Level': 14,
    'Unique Portals Visited': 9756,
    'Hacks': 78735,
  },
}) =>
    StatSnapshot(
      timeSpan: span,
      agentName: agent,
      faction: faction,
      recordedAt: at ?? DateTime(2026, 9, 13, 10, 30, 5),
      level: level,
      counters: counters,
    );

void main() {
  const codec = ComparisonPayload();

  group('telling a comparison apart from an import', () {
    test('recognises what it wrote itself', () {
      expect(codec.looksLikeComparison(codec.encode(snapshot())), isTrue);
    });

    test('leaves an Ingress export alone', () {
      // The one that matters: everything shared into the app goes past this,
      // and a real export must carry on to the import preview untouched.
      const export = 'Time Span\tAgent Name\tLevel\n'
          'ALL TIME\tNohzoh\t14\n';
      expect(codec.looksLikeComparison(export), isFalse);
    });

    test('leaves arbitrary text alone', () {
      expect(codec.looksLikeComparison(''), isFalse);
      expect(codec.looksLikeComparison('https://example.org'), isFalse);
      expect(codec.looksLikeComparison('FieldTally is great'), isFalse);
    });

    test('recognises a version it cannot read, so it can say so', () {
      // Better than handing it to the Ingress parser, which would fail with
      // something baffling about tab separation.
      expect(
        codec.looksLikeComparison('FieldTally/9 comparison\nagent\tX\n'),
        isTrue,
      );
    });
  });

  group('the round trip', () {
    test('keeps everything the comparison shows', () {
      final original = snapshot();
      final back = codec.decode(codec.encode(original));

      expect(back.agentName, original.agentName);
      expect(back.faction, original.faction);
      expect(back.level, original.level);
      expect(back.recordedAt, original.recordedAt);
      expect(back.timeSpan, original.timeSpan);
      expect(back.counters, original.counters);
    });

    test('keeps a level that is simply not known', () {
      // Every snapshot migrated from Agent Stats has none (Appendix B), and
      // sending 0 would claim a level 0 agent.
      final back = codec.decode(codec.encode(snapshot(level: null)));
      expect(back.level, isNull);
    });

    test('keeps a codename that is not plain ASCII', () {
      final back = codec.decode(codec.encode(snapshot(agent: 'Agent Éclair')));
      expect(back.agentName, 'Agent Éclair');
    });

    test('survives the line endings a paste can leave behind', () {
      final windows = codec.encode(snapshot()).replaceAll('\n', '\r\n');
      expect(codec.decode(windows).counters['Hacks'], 78735);
    });

    test('carries a counter this build has never heard of', () {
      // An anomaly adds columns mid-season (§3.1.2); the payload must not be
      // limited to what the registry happens to know today.
      final back = codec.decode(
        codec.encode(snapshot(counters: const {'Vesuvius Tokens': 12})),
      );
      expect(back.counters['Vesuvius Tokens'], 12);
    });

    test('is readable, so an agent can check it before sending it', () {
      final text = codec.encode(snapshot());
      expect(text, startsWith('FieldTally/1 comparison\n'));
      expect(text, contains('agent\tNohzoh'));
      expect(text, contains('Unique Portals Visited\t9756'));
    });
  });

  group('what it refuses', () {
    ComparisonPayloadError errorOf(String raw) {
      try {
        codec.decode(raw);
      } on ComparisonPayloadException catch (e) {
        return e.error;
      }
      fail('expected a ComparisonPayloadException');
    }

    test('a version written by a newer FieldTally', () {
      expect(
        errorOf('FieldTally/9 comparison\nagent\tX\n--\nHacks\t1\n'),
        ComparisonPayloadError.unsupportedVersion,
      );
    });

    test('anything but an all-time total', () {
      // A week against a lifetime is not a comparison, it is a trap — the same
      // allowlist the import guards run on (§3.1.3).
      final week = codec.encode(snapshot(span: TimeSpan.week));
      expect(errorOf(week), ComparisonPayloadError.notCumulative);
    });

    test('a payload with no separator between the two halves', () {
      expect(
        errorOf('FieldTally/1 comparison\nagent\tX\nHacks\t1\n'),
        ComparisonPayloadError.malformed,
      );
    });

    test('a counter whose value is not a number', () {
      expect(
        errorOf('FieldTally/1 comparison\nagent\tX\nspan\tallTime\n'
            'recorded\t2026-09-13T10:00:00\n--\nHacks\tlots\n'),
        ComparisonPayloadError.malformed,
      );
    });

    test('a payload with no codename', () {
      expect(
        errorOf('FieldTally/1 comparison\nspan\tallTime\n'
            'recorded\t2026-09-13T10:00:00\n--\nHacks\t1\n'),
        ComparisonPayloadError.malformed,
      );
    });

    test('a payload with no date', () {
      expect(
        errorOf('FieldTally/1 comparison\nagent\tX\nspan\tallTime\n'
            '--\nHacks\t1\n'),
        ComparisonPayloadError.malformed,
      );
    });

    test('a line with no tab in it', () {
      expect(
        errorOf('FieldTally/1 comparison\nagent\tX\nspan\tallTime\n'
            'recorded\t2026-09-13T10:00:00\n--\nHacks\n'),
        ComparisonPayloadError.malformed,
      );
    });
  });
}
