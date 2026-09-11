import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/notifications.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';

StatSnapshot snap(Map<String, int> counters) => StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: DateTime(2026, 1, 1),
      counters: counters,
    );

void main() {
  late CounterRegistry registry;

  setUp(() {
    registry =
        const CounterRegistryLoader().parse(File(seedPath).readAsStringSync());
  });

  group('badge tiers crossed (§3.7)', () {
    const detector = TierCrossingDetector();

    List<TierCrossing> between(Map<String, int> before, Map<String, int> after) =>
        detector.crossings(
          current: snap(after),
          previous: snap(before),
          registry: registry,
        );

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
        between(const {'Unique Portals Visited': 999},
            const {'Unique Portals Visited': 1000}),
        hasLength(1),
      );
    });

    test('says nothing when no threshold was passed', () {
      expect(
        between(const {'Unique Portals Visited': 1100},
            const {'Unique Portals Visited': 1200}),
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
        const TierCrossingDetector().crossings(
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
        between(const {'Orion Tokens': 10}, const {'Orion Tokens': 99999}),
        isEmpty,
      );
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

    test('an overdue reminder is pushed just ahead rather than into the past', () {
      // A time in the past is either fired instantly or dropped, depending on
      // the platform; neither is what was meant.
      final now = DateTime(2026, 3, 1, 12);
      final next = planner.nextReminder(
        latestSnapshot: DateTime(2026, 1, 1),
        now: now,
      );

      expect(next!.isAfter(now), isTrue);
      expect(next.difference(now).inMinutes, lessThanOrEqualTo(5));
    });

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
