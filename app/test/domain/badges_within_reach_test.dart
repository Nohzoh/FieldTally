// Ranking badges by how long they would take, across every counter (#148).
//
// The counter list can already sort by proximity to the next tier, measured as
// the share of the stretch already crossed. These tests exist because that is
// a different question: the numbers below are chosen so the two orderings
// disagree, and the wrong one would look perfectly reasonable on screen.

import 'package:fieldtally/domain/badge_projection.dart';
import 'package:fieldtally/domain/badges_within_reach.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

CounterEnrichment ladder({
  required String header,
  required List<(String, int)> tiers,
  DateTime? endsAt,
  int order = 0,
}) => CounterEnrichment(
  key: header,
  exportHeader: header,
  categoryKey: 'core',
  order: order,
  labels: {'en': header, 'fr': header},
  tiers: [
    for (final (name, value) in tiers) CounterTier(name: name, value: value),
  ],
  endsAt: endsAt,
);

CounterRegistry registryOf(List<CounterEnrichment> counters) => CounterRegistry(
  schemaVersion: 1,
  updatedAt: '2026-01-01',
  categories: const [
    CounterCategory(
      key: 'core',
      order: 0,
      labels: {'en': 'Core', 'fr': 'Base'},
    ),
  ],
  counters: counters,
);

StatSnapshot at(DateTime date, Map<String, int> counters) => StatSnapshot(
  timeSpan: TimeSpan.allTime,
  agentName: 'AgentDemo',
  faction: 'Enlightened',
  recordedAt: date,
  level: 9,
  counters: counters,
);

/// Two snapshots ten days apart, which is what sets every pace below.
List<StatSnapshot> tenDays(Map<String, (int, int)> counters) {
  final start = DateTime(2026, 6, 1);
  return [
    at(start, {for (final e in counters.entries) e.key: e.value.$1}),
    at(start.add(const Duration(days: 10)), {
      for (final e in counters.entries) e.key: e.value.$2,
    }),
  ];
}

List<String> headersOf(List<ReachableBadge> badges) => [
  for (final b in badges) b.exportHeader,
];

void main() {
  const builder = WithinReachBuilder();

  // 0 → 60 in ten days is 6/day, so bronze at 100 is about seven days away,
  // with 60 % of the stretch crossed.
  const fast = 'Fast';
  // 940 → 950 in ten days is 1/day, so bronze at 1000 is fifty days away,
  // with 95 % of the stretch crossed.
  const slow = 'Slow';

  final twoCounters = registryOf([
    ladder(header: fast, tiers: const [('bronze', 100)]),
    ladder(header: slow, tiers: const [('bronze', 1000)], order: 1),
  ]);

  group('the ranking this exists for', () {
    test('orders by time, not by share of the stretch crossed', () {
      final badges = builder.build(
        snapshots: tenDays(const {fast: (0, 60), slow: (940, 950)}),
        registry: twoCounters,
      );

      expect(headersOf(badges), [fast, slow]);
      expect(badges.first.days, closeTo(6.7, 0.2));
      expect(badges.last.days, closeTo(50, 1));
    });

    test('and the existing sort really does disagree, which is the point', () {
      // Falsifies the premise rather than trusting it: if #90's ordering
      // already answered this question, this whole builder would be dead
      // weight. It puts the counter fifty days out first.
      final crossed = {
        for (final header in [fast, slow])
          header: tierProgress(
            twoCounters.forExportHeader(header),
            header == fast ? 60 : 950,
          ),
      };

      expect(crossed[slow]! > crossed[fast]!, isTrue);
    });
  });

  group('what never enters the list', () {
    test('a counter that has stalled', () {
      final badges = builder.build(
        snapshots: tenDays(const {fast: (60, 60)}),
        registry: twoCounters,
      );

      expect(badges, isEmpty);
    });

    test('a counter going backwards', () {
      final badges = builder.build(
        snapshots: tenDays(const {fast: (60, 40)}),
        registry: twoCounters,
      );

      expect(badges, isEmpty);
    });

    test('a counter the registry gives no thresholds', () {
      final badges = builder.build(
        snapshots: tenDays(const {'Untiered': (0, 60)}),
        registry: registryOf([
          CounterEnrichment(
            key: 'Untiered',
            exportHeader: 'Untiered',
            categoryKey: 'core',
            order: 0,
            labels: const {'en': 'Untiered', 'fr': 'Untiered'},
          ),
        ]),
      );

      expect(badges, isEmpty);
    });

    test('a tier the pace only reaches after the ladder has closed', () {
      // Apollo-shaped: the pace does get there, but not before the deadline.
      // The projection already refuses to name that date, and so does this.
      final badges = builder.build(
        snapshots: tenDays(const {'Season': (0, 100)}),
        registry: registryOf([
          ladder(
            header: 'Season',
            tiers: const [('bronze', 4000)],
            endsAt: DateTime(2026, 6, 20),
          ),
        ]),
      );

      expect(badges, isEmpty);
    });

    test('a ladder that has already closed', () {
      final badges = builder.build(
        snapshots: tenDays(const {'Season': (0, 60)}),
        registry: registryOf([
          ladder(
            header: 'Season',
            tiers: const [('bronze', 100)],
            endsAt: DateTime(2026, 5, 1),
          ),
        ]),
        now: DateTime(2026, 6, 11),
      );

      expect(badges, isEmpty);
    });

    test('a counter already past every named tier', () {
      // Past the top the game counts in multiples (#87). A multiple is the
      // same medal counting higher, not a badge left to finish.
      final badges = builder.build(
        snapshots: tenDays(const {fast: (200, 260)}),
        registry: twoCounters,
      );

      expect(badges, isEmpty);
    });

    test('a history of one snapshot, which sets no pace at all', () {
      final badges = builder.build(
        snapshots: [
          at(DateTime(2026, 6, 1), const {fast: 60}),
        ],
        registry: twoCounters,
      );

      expect(badges, isEmpty);
    });
  });

  group('the shape of the answer', () {
    test('keeps only as many as asked for, soonest first', () {
      final registry = registryOf([
        for (var i = 0; i < 5; i++)
          ladder(header: 'C$i', tiers: [('bronze', 100 + i * 10)], order: i),
      ]);

      final badges = const WithinReachBuilder(limit: 2).build(
        snapshots: tenDays({for (var i = 0; i < 5; i++) 'C$i': (0, 60)}),
        registry: registry,
      );

      expect(headersOf(badges), ['C0', 'C1']);
    });

    test('two counters at the same distance keep a stable order', () {
      final registry = registryOf([
        ladder(header: 'Beta', tiers: const [('bronze', 100)]),
        ladder(header: 'Alpha', tiers: const [('bronze', 100)], order: 1),
      ]);

      final badges = builder.build(
        snapshots: tenDays(const {'Beta': (0, 60), 'Alpha': (0, 60)}),
        registry: registry,
      );

      expect(headersOf(badges), ['Alpha', 'Beta']);
    });

    test('carries the tier being worked towards, for the screen to name', () {
      final badges = builder.build(
        snapshots: tenDays(const {fast: (0, 60)}),
        registry: twoCounters,
      );

      expect(badges.single.projection.next?.name, 'bronze');
      expect(badges.single.date.isAfter(DateTime(2026, 6, 11)), isTrue);
    });
  });

  group('nothing to rank', () {
    test('no snapshot', () {
      expect(
        builder.build(snapshots: const [], registry: twoCounters),
        isEmpty,
      );
    });

    test('no registry, so no thresholds anywhere', () {
      expect(builder.build(snapshots: tenDays(const {fast: (0, 60)})), isEmpty);
    });
  });
}
