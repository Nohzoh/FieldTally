import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/share_card.dart';
import 'package:flutter_test/flutter_test.dart';

StatSnapshot snap(
  DateTime at,
  Map<String, int> counters, {
  int? level = 9,
  String agent = 'AgentDemo',
  String faction = 'Enlightened',
}) => StatSnapshot(
  timeSpan: TimeSpan.allTime,
  agentName: agent,
  faction: faction,
  recordedAt: at,
  level: level,
  counters: counters,
);

void main() {
  const builder = ShareCardBuilder();

  group('shareable card (§3.8)', () {
    test('describes the newest snapshot', () {
      final card = builder.build(
        snapshots: [
          snap(DateTime(2026, 1, 1), const {'Hacks': 100}),
          snap(DateTime(2026, 1, 20), const {'Hacks': 400}, level: 10),
        ],
        pinned: const ['Hacks'],
      );

      expect(card!.agentName, 'AgentDemo');
      expect(card.faction, 'Enlightened');
      expect(card.level, 10);
      // Dated by the data, not by the moment the image is made.
      expect(card.recordedAt, DateTime(2026, 1, 20));
      expect(card.lines.single.value, 400);
    });

    test('shows progress across the chosen period', () {
      final card = builder.build(
        snapshots: [
          snap(DateTime(2026, 1, 1), const {'Hacks': 100}),
          snap(DateTime(2026, 1, 20), const {'Hacks': 400}),
        ],
        pinned: const ['Hacks'],
        period: SharePeriod.month,
      );

      expect(card!.lines.single.gain, 300);
      expect(card.since, DateTime(2026, 1, 1));
      expect(card.hasGains, isTrue);
    });

    test('keeps the order of the dashboard selection', () {
      final card = builder.build(
        snapshots: [
          snap(DateTime(2026, 1, 1), const {'Hacks': 1, 'Lifetime AP': 2}),
          snap(DateTime(2026, 1, 2), const {'Hacks': 3, 'Lifetime AP': 4}),
        ],
        pinned: const ['Lifetime AP', 'Hacks'],
      );

      expect(card!.lines.map((line) => line.exportHeader), [
        'Lifetime AP',
        'Hacks',
      ]);
    });

    test('skips a pinned counter no import ever carried', () {
      // Usually pinned on a previous phone, or the counter left the game.
      final card = builder.build(
        snapshots: [
          snap(DateTime(2026, 1, 1), const {'Hacks': 1}),
        ],
        pinned: const ['Never Seen', 'Hacks'],
      );

      expect(card!.lines.single.exportHeader, 'Hacks');
    });

    test('caps how many counters reach the image', () {
      const small = ShareCardBuilder(maxLines: 2);
      final card = small.build(
        snapshots: [
          snap(DateTime(2026, 1, 1), const {'a': 1, 'b': 2, 'c': 3}),
        ],
        pinned: const ['a', 'b', 'c'],
      );

      expect(card!.lines, hasLength(2));
    });

    test('states the earliest period actually covered', () {
      // Claiming a month while one counter only has a week of data would
      // overstate the number printed next to it.
      final card = builder.build(
        snapshots: [
          snap(DateTime(2026, 1, 1), const {'Hacks': 100}),
          snap(DateTime(2026, 1, 10), const {'Hacks': 200, 'Links': 5}),
          snap(DateTime(2026, 1, 20), const {'Hacks': 400, 'Links': 9}),
        ],
        pinned: const ['Hacks', 'Links'],
      );

      expect(card!.since, DateTime(2026, 1, 1));
    });

    test('a single snapshot still makes a card, without gains', () {
      final card = builder.build(
        snapshots: [
          snap(DateTime(2026, 1, 1), const {'Hacks': 100}),
        ],
        pinned: const ['Hacks'],
      );

      expect(card!.lines.single.value, 100);
      expect(card.lines.single.gain, isNull);
      expect(card.since, isNull);
      expect(card.hasGains, isFalse);
    });

    test('nothing to show gives no card at all', () {
      expect(
        builder.build(snapshots: const [], pinned: const ['Hacks']),
        isNull,
      );
      expect(
        builder.build(
          snapshots: [
            snap(DateTime(2026, 1, 1), const {'Hacks': 1}),
          ],
          pinned: const [],
        ),
        isNull,
      );
    });

    test('a level no import carried stays absent rather than invented', () {
      final card = builder.build(
        snapshots: [
          snap(DateTime(2026, 1, 1), const {'Hacks': 1}, level: null),
        ],
        pinned: const ['Hacks'],
      );

      expect(card!.level, isNull);
    });

    test('measures the period back from the newest snapshot', () {
      // An agent who stopped importing three weeks ago still gets their last
      // week of data, not an empty card.
      final card = builder.build(
        snapshots: [
          snap(DateTime(2026, 1, 1), const {'Hacks': 100}),
          snap(DateTime(2026, 1, 5), const {'Hacks': 150}),
        ],
        pinned: const ['Hacks'],
        period: SharePeriod.week,
      );

      expect(card!.since, DateTime(2026, 1, 1));
      expect(card.lines.single.gain, 50);
    });

    test('the last-snapshot period spans only the two newest imports', () {
      // Two imports the same day: a week would reach back to the first one.
      final card = builder.build(
        snapshots: [
          snap(DateTime(2026, 1, 18), const {'Hacks': 100}),
          snap(DateTime(2026, 1, 20, 8), const {'Hacks': 150}),
          snap(DateTime(2026, 1, 20, 22), const {'Hacks': 190}),
        ],
        pinned: const ['Hacks'],
        period: SharePeriod.lastSnapshot,
      );

      expect(card!.lines.single.gain, 40);
      expect(card.since, DateTime(2026, 1, 20, 8));
    });

    test('the last-snapshot period measures each counter from its own '
        'previous value', () {
      // The previous import did not carry Hacks, so its gain runs from the
      // import before, and the card is dated from there.
      final card = builder.build(
        snapshots: [
          snap(DateTime(2026, 1, 10), const {'Hacks': 100, 'Lifetime AP': 1}),
          snap(DateTime(2026, 1, 15), const {'Lifetime AP': 5}),
          snap(DateTime(2026, 1, 20), const {'Hacks': 130, 'Lifetime AP': 9}),
        ],
        pinned: const ['Lifetime AP', 'Hacks'],
        period: SharePeriod.lastSnapshot,
      );

      expect(card!.lines.map((line) => line.gain), [4, 30]);
      expect(card.since, DateTime(2026, 1, 10));
    });

    test('the last-snapshot period shows no gain with a single import', () {
      final card = builder.build(
        snapshots: [
          snap(DateTime(2026, 1, 20), const {'Hacks': 130}),
        ],
        pinned: const ['Hacks'],
        period: SharePeriod.lastSnapshot,
      );

      expect(card!.lines.single.gain, isNull);
      expect(card.since, isNull);
    });
  });
}
