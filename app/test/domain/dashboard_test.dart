import 'package:fieldtally/domain/dashboard.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

StatSnapshot at(DateTime date, Map<String, int> counters) => StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: date,
      level: 9,
      counters: counters,
    );

void main() {
  const builder = DashboardBuilder();

  test('no snapshot means no card', () {
    expect(
      builder.build(snapshots: const [], pinned: const ['Hacks']),
      isEmpty,
    );
  });

  test('nothing pinned means no card', () {
    expect(
      builder.build(
        snapshots: [at(DateTime(2026, 1, 1), const {'Hacks': 10})],
        pinned: const [],
      ),
      isEmpty,
    );
  });

  test('cards follow the pinned order, not the registry order', () {
    // The dashboard is the agent's arrangement; the in-game ordering belongs
    // to the counter list (§3.4).
    final cards = builder.build(
      snapshots: [
        at(DateTime(2026, 1, 1), const {'Hacks': 10, 'Links Created': 3}),
      ],
      pinned: const ['Links Created', 'Hacks'],
    );

    expect(
      cards.map((c) => c.counter.exportHeader),
      ['Links Created', 'Hacks'],
    );
  });

  test('a pinned counter that never appeared is skipped', () {
    // Usually means it was pinned on a previous phone, or left the game.
    final cards = builder.build(
      snapshots: [at(DateTime(2026, 1, 1), const {'Hacks': 10})],
      pinned: const ['Hacks', 'Orion Tokens'],
    );

    expect(cards.map((c) => c.counter.exportHeader), ['Hacks']);
  });

  group('sparkline series', () {
    test('is chronological regardless of the order given', () {
      final cards = builder.build(
        snapshots: [
          at(DateTime(2026, 1, 20), const {'Hacks': 30}),
          at(DateTime(2026, 1, 1), const {'Hacks': 10}),
          at(DateTime(2026, 1, 10), const {'Hacks': 20}),
        ],
        pinned: const ['Hacks'],
      );

      expect(cards.single.series, [10, 20, 30]);
    });

    test('skips snapshots that did not carry the counter', () {
      // A gap in the imports is not a dip to zero (§3.1.2), and drawing it as
      // one would be a lie the eye reads instantly.
      final cards = builder.build(
        snapshots: [
          at(DateTime(2026, 1, 1), const {'Orion Tokens': 100}),
          at(DateTime(2026, 1, 10), const {'Hacks': 5}),
          at(DateTime(2026, 1, 20), const {'Orion Tokens': 160}),
        ],
        pinned: const ['Orion Tokens'],
      );

      expect(cards.single.series, [100, 160]);
    });

    test('a single point draws nothing', () {
      final cards = builder.build(
        snapshots: [at(DateTime(2026, 1, 1), const {'Hacks': 10})],
        pinned: const ['Hacks'],
      );

      expect(cards.single.series, [10]);
      expect(cards.single.hasSparkline, isFalse);
    });

    test('keeps only the most recent points', () {
      const short = DashboardBuilder(maxSeriesPoints: 3);
      final cards = short.build(
        snapshots: [
          for (var day = 1; day <= 6; day++)
            at(DateTime(2026, 1, day), {'Hacks': day * 10}),
        ],
        pinned: const ['Hacks'],
      );

      expect(cards.single.series, [40, 50, 60]);
    });
  });

  test('the card carries the progress since the previous snapshot', () {
    final cards = builder.build(
      snapshots: [
        at(DateTime(2026, 1, 1), const {'Hacks': 10}),
        at(DateTime(2026, 1, 10), const {'Hacks': 34}),
      ],
      pinned: const ['Hacks'],
    );

    expect(cards.single.counter.lastValue, 34);
    expect(cards.single.counter.delta, 24);
  });
}
