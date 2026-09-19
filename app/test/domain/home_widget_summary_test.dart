// What a home screen widget can show, built from pinned counters (#154).

import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/home_widget_summary.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';

StatSnapshot at(DateTime date, Map<String, int> counters) => StatSnapshot(
  timeSpan: TimeSpan.allTime,
  agentName: 'AgentDemo',
  faction: 'Enlightened',
  recordedAt: date,
  level: 9,
  counters: counters,
);

List<String> headersOf(HomeWidgetSummary summary) => [
  for (final line in summary.lines) line.exportHeader,
];

void main() {
  late CounterRegistry registry;
  late HomeWidgetSummaryBuilder builder;

  setUp(() {
    registry = const CounterRegistryLoader().parse(
      File(seedPath).readAsStringSync(),
    );
    builder = HomeWidgetSummaryBuilder(registry: registry);
  });

  group('the two states with nothing to show', () {
    test('nothing pinned is distinct from pinned with no data yet', () {
      final unpinned = builder.build(snapshots: const [], pinned: const []);
      expect(unpinned.hasAnyPinned, isFalse);
      expect(unpinned.lines, isEmpty);

      // Default pins can exist before any snapshot does (a fresh install).
      // The two states read differently to an agent: "pin something" versus
      // "go import something" — collapsing them would say the wrong one.
      final pinnedButEmpty = builder.build(
        snapshots: const [],
        pinned: const ['Hacks'],
      );
      expect(pinnedButEmpty.hasAnyPinned, isTrue);
      expect(pinnedButEmpty.lines, isEmpty);
    });
  });

  group('what a line carries', () {
    test('value and the delta since the previous snapshot', () {
      final summary = builder.build(
        snapshots: [
          at(DateTime(2026, 1, 1), const {'Hacks': 100}),
          at(DateTime(2026, 1, 2), const {'Hacks': 140}),
        ],
        pinned: const ['Hacks'],
      );

      expect(summary.lines.single.value, 140);
      expect(summary.lines.single.delta, 40);
    });

    test('no delta on a single snapshot, not a delta of zero', () {
      final summary = builder.build(
        snapshots: [
          at(DateTime(2026, 1, 1), const {'Hacks': 100}),
        ],
        pinned: const ['Hacks'],
      );

      expect(summary.lines.single.delta, isNull);
    });

    test('the tier still ahead, and how far it is', () {
      // Hacks: bronze at 2 000 in the real registry.
      final summary = builder.build(
        snapshots: [
          at(DateTime(2026, 1, 1), const {'Hacks': 1500}),
        ],
        pinned: const ['Hacks'],
      );

      expect(summary.lines.single.nextTier, 'bronze');
      expect(summary.lines.single.remainingToNextTier, 500);
    });

    test('no next tier for a counter the registry gives no thresholds', () {
      final summary = builder.build(
        snapshots: [
          at(DateTime(2026, 1, 1), const {'Some Untiered Counter': 3}),
        ],
        pinned: const ['Some Untiered Counter'],
      );

      expect(summary.lines.single.nextTier, isNull);
      expect(summary.lines.single.remainingToNextTier, isNull);
    });

    test('no next tier once every named tier is behind', () {
      // Hacks tops out at onyx, 200 000 in the real registry. Past it the
      // game counts in multiples, which a widget line has no room to name.
      final summary = builder.build(
        snapshots: [
          at(DateTime(2026, 1, 1), const {'Hacks': 250000}),
        ],
        pinned: const ['Hacks'],
      );

      expect(summary.lines.single.nextTier, isNull);
    });

    test('without a registry there is a value but no tier', () {
      final bare = const HomeWidgetSummaryBuilder().build(
        snapshots: [
          at(DateTime(2026, 1, 1), const {'Hacks': 1500}),
        ],
        pinned: const ['Hacks'],
      );

      expect(bare.lines.single.value, 1500);
      expect(bare.lines.single.nextTier, isNull);
    });
  });

  group('how many lines', () {
    test('follows the pinned order, like the dashboard', () {
      final summary = builder.build(
        snapshots: [
          at(DateTime(2026, 1, 1), const {'Hacks': 10, 'Links Created': 3}),
        ],
        pinned: const ['Links Created', 'Hacks'],
      );

      expect(headersOf(summary), ['Links Created', 'Hacks']);
    });

    test('never more than the cap, however many are pinned', () {
      final summary = const HomeWidgetSummaryBuilder(maxLines: 2).build(
        snapshots: [
          at(DateTime(2026, 1, 1), const {
            'Hacks': 10,
            'Links Created': 3,
            'Resonators Deployed': 5,
          }),
        ],
        pinned: const ['Hacks', 'Links Created', 'Resonators Deployed'],
      );

      expect(summary.lines.length, 2);
    });

    test(
      "the default cap admits four, the native layout's own plafond (#177)",
      () {
        final summary = builder.build(
          snapshots: [
            at(DateTime(2026, 1, 1), const {
              'Hacks': 1,
              'Links Created': 2,
              'Resonators Deployed': 3,
              'Unique Portals Visited': 4,
              'Distance Walked': 5,
            }),
          ],
          pinned: const [
            'Hacks',
            'Links Created',
            'Resonators Deployed',
            'Unique Portals Visited',
            'Distance Walked',
          ],
        );

        expect(summary.lines.length, 4);
      },
    );

    test('a pinned counter absent from every snapshot yields no line', () {
      // The same rule DashboardBuilder already enforces: an agent who pinned
      // this from another phone, or a counter that left the game.
      final summary = builder.build(
        snapshots: [
          at(DateTime(2026, 1, 1), const {'Hacks': 10}),
        ],
        pinned: const ['Never Imported'],
      );

      expect(summary.hasAnyPinned, isTrue);
      expect(summary.lines, isEmpty);
    });
  });
}
