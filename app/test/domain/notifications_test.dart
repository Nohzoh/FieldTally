import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/notifications.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';

StatSnapshot snap(Map<String, int> counters, {int? level}) => StatSnapshot(
  timeSpan: TimeSpan.allTime,
  agentName: 'AgentDemo',
  faction: 'Enlightened',
  recordedAt: DateTime(2026, 1, 1),
  level: level,
  counters: counters,
);

void main() {
  late CounterRegistry registry;

  setUp(() {
    registry = const CounterRegistryLoader().parse(
      File(seedPath).readAsStringSync(),
    );
  });

  group('badge tiers crossed (§3.7)', () {
    const detector = MilestoneDetector();

    List<TierReached> between(
      Map<String, int> before,
      Map<String, int> after,
    ) => detector
        .since(current: snap(after), previous: snap(before), registry: registry)
        .whereType<TierReached>()
        .toList();

    test('announces a tier the new snapshot reached', () {
      // Explorer silver sits at 1000.
      final crossings = between(
        const {'Unique Portals Visited': 900},
        const {'Unique Portals Visited': 1100},
      );

      expect(crossings, hasLength(1));
      expect(crossings.single.tier.name, 'silver');
      expect(crossings.single.exportHeader, 'Unique Portals Visited');
      expect(crossings.single.value, 1100);
    });

    test('landing exactly on a threshold counts as crossing it', () {
      expect(
        between(
          const {'Unique Portals Visited': 999},
          const {'Unique Portals Visited': 1000},
        ),
        hasLength(1),
      );
    });

    test('says nothing when no threshold was passed', () {
      expect(
        between(
          const {'Unique Portals Visited': 1100},
          const {'Unique Portals Visited': 1200},
        ),
        isEmpty,
      );
    });

    test('several tiers in one jump are all reported, biggest first', () {
      // Bronze 100, silver 1000, gold 2000 — a long-awaited import.
      final crossings = between(
        const {'Unique Portals Visited': 50},
        const {'Unique Portals Visited': 2500},
      );

      expect(crossings.map((c) => c.tier.name), ['gold', 'silver', 'bronze']);
    });

    test('the first snapshot ever announces nothing', () {
      // Someone importing years of history at once does not want a burst of
      // notifications for badges earned long ago.
      expect(
        const MilestoneDetector().since(
          current: snap(const {'Unique Portals Visited': 9000}),
          previous: null,
          registry: registry,
        ),
        isEmpty,
      );
    });

    test('a counter absent from the earlier snapshot crosses nothing', () {
      // It was not reported, which is not the same as having been at zero.
      expect(
        between(const {'Hacks': 10}, const {'Unique Portals Visited': 5000}),
        isEmpty,
      );
    });

    test('counters without thresholds are ignored', () {
      expect(
        between(const {'XM Collected': 10}, const {'XM Collected': 99999}),
        isEmpty,
      );
    });
  });

  group('a further multiple of a top tier (#104)', () {
    const detector = MilestoneDetector();

    List<MultipleReached> between(
      Map<String, int> before,
      Map<String, int> after,
    ) => detector
        .since(current: snap(after), previous: snap(before), registry: registry)
        .whereType<MultipleReached>()
        .toList();

    // Explorer onyx sits at 30,000.
    test('announces the multiple reached', () {
      final found = between(
        const {'Unique Portals Visited': 59000},
        const {'Unique Portals Visited': 61000},
      );

      expect(found, hasLength(1));
      expect(found.single.multiple, 2);
      expect(found.single.tier.name, 'onyx');
      expect(found.single.value, 61000);
    });

    test('several passed at once are one piece of news, not several', () {
      // The case the burst guard could not catch: previous is not null, so
      // every import is a real crossing. x 2 through x 9 is one achievement.
      final found = between(
        const {'Unique Portals Visited': 40000},
        const {'Unique Portals Visited': 280000},
      );

      expect(found, hasLength(1));
      expect(found.single.multiple, 9);
    });

    test('the first multiple is not announced', () {
      // Reaching onyx is announced as a tier. Saying "one time over" beside
      // it would be the same news twice.
      expect(
        between(
          const {'Unique Portals Visited': 29000},
          const {'Unique Portals Visited': 31000},
        ),
        isEmpty,
      );
    });

    test('and never is, whatever the jump', () {
      // Straight from below onyx to nine times over: the tier is the news,
      // and the multiple has no earlier one to exceed.
      expect(
        between(
          const {'Unique Portals Visited': 100},
          const {'Unique Portals Visited': 280000},
        ),
        isEmpty,
      );
    });

    test('a value climbing inside one multiple says nothing', () {
      expect(
        between(
          const {'Unique Portals Visited': 61000},
          const {'Unique Portals Visited': 89000},
        ),
        isEmpty,
      );
    });

    test('a ladder that ends never multiplies', () {
      // The game stops counting at a seasonal top tier, so there is nothing
      // to announce past it (#99). Read from topTierMultiple, which is where
      // the rule lives.
      final seasonal = const CounterRegistryLoader().parse(
        File(seedPath).readAsStringSync().replaceFirst(
          '"apollo_mod_battle_points": {',
          '"apollo_mod_battle_points": {'
              '"tiers": [{"name": "gold", "value": 1000}],'
              '"ends_at": "2026-09-16T18:00:00Z",',
        ),
      );

      final found = const MilestoneDetector()
          .since(
            current: snap(const {'Apollo Mod Battle Points': 9000}),
            previous: snap(const {'Apollo Mod Battle Points': 1500}),
            registry: seasonal,
          )
          .whereType<MultipleReached>();

      expect(found, isEmpty);
    });
  });

  group('a new level (#105)', () {
    const detector = MilestoneDetector();

    List<Milestone> between(int? before, int? after) => detector.since(
      current: snap(const {}, level: after),
      previous: snap(const {}, level: before),
      registry: registry,
    );

    test('announces the level reached', () {
      final found = between(12, 13).whereType<LevelReached>();

      expect(found, hasLength(1));
      expect(found.single.level, 13);
    });

    test('several at once are one piece of news', () {
      final found = between(9, 13).whereType<LevelReached>().toList();

      expect(found, hasLength(1));
      expect(
        found.single.level,
        13,
        reason: 'the level reached, not each step',
      );
    });

    test('a recursion says nothing on the way down', () {
      expect(between(16, 1), isEmpty);
    });

    test('but climbing back is celebrated again', () {
      // Settled deliberately: from the agent's side they did it again. A
      // stored high-water mark would have made a recursion permanently
      // silent, on top of going stale when a snapshot is corrected.
      final found = between(12, 13).whereType<LevelReached>();

      expect(found.single.level, 13);
    });

    test('an unknown level on either side is silence, not level zero', () {
      // The Agent Stats migration CSV carries no level column at all.
      expect(between(null, 13), isEmpty);
      expect(between(12, null), isEmpty);
      expect(between(null, null), isEmpty);
    });

    test('standing still says nothing', () {
      expect(between(13, 13), isEmpty);
    });
  });

  group('what comes first', () {
    test('the level leads, then the badges', () {
      // The level is the one an agent asks about, and only the first few are
      // shown before the rest are summarised.
      final found = const MilestoneDetector().since(
        current: snap(const {'Unique Portals Visited': 2500}, level: 13),
        previous: snap(const {'Unique Portals Visited': 50}, level: 12),
        registry: registry,
      );

      expect(found.first, isA<LevelReached>());
      expect(found.skip(1).every((m) => m is TierReached), isTrue);
    });
  });

  group('the reminder (§3.7)', () {
    const planner = ReminderPlanner();

    test('is due a week after the last snapshot', () {
      final next = planner.nextReminder(
        latestSnapshot: DateTime(2026, 1, 1, 9),
        now: DateTime(2026, 1, 2),
      );

      expect(next, DateTime(2026, 1, 8, 9));
    });

    test('is not scheduled at all when nothing was ever recorded', () {
      // Someone who has not started has not lapsed, and nagging them about a
      // habit they never had would be rude.
      expect(
        planner.nextReminder(latestSnapshot: null, now: DateTime(2026, 1, 2)),
        isNull,
      );
    });

    test(
      'an overdue reminder is pushed just ahead rather than into the past',
      () {
        // A time in the past is either fired instantly or dropped, depending on
        // the platform; neither is what was meant.
        final now = DateTime(2026, 3, 1, 12);
        final next = planner.nextReminder(
          latestSnapshot: DateTime(2026, 1, 1),
          now: now,
        );

        expect(next!.isAfter(now), isTrue);
        expect(next.difference(now).inMinutes, lessThanOrEqualTo(5));
      },
    );

    test('the delay is configurable', () {
      const patient = ReminderPlanner(after: Duration(days: 30));

      expect(
        patient.nextReminder(
          latestSnapshot: DateTime(2026, 1, 1),
          now: DateTime(2026, 1, 2),
        ),
        DateTime(2026, 1, 31),
      );
    });
  });
}
