import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/badge_projection.dart';
import 'package:fieldtally/domain/counter_series.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';

List<SeriesPoint> daily(DateTime from, List<int> values) => [
  for (var i = 0; i < values.length; i++)
    (at: from.add(Duration(days: i)), value: values[i]),
];

void main() {
  const projector = BadgeProjector();
  late CounterRegistry registry;

  setUp(() {
    registry = const CounterRegistryLoader().parse(
      File(seedPath).readAsStringSync(),
    );
  });

  CounterEnrichment enrichment(String header) =>
      registry.forExportHeader(header)!;

  group('where a counter stands', () {
    test('below bronze there is no tier reached yet', () {
      // Explorer: bronze at 100.
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [10, 20]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.current, isNull);
      expect(projection.next!.name, 'bronze');
      expect(projection.remaining, 80);
    });

    test('between two tiers, both ends are known', () {
      // Explorer: silver 1000, gold 2000.
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [1400, 1500]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.current!.name, 'silver');
      expect(projection.next!.name, 'gold');
      expect(projection.remaining, 500);
      expect(projection.progress, closeTo(0.5, 0.001));
    });

    test('exactly on a threshold counts as reached', () {
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [900, 1000]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.current!.name, 'silver');
      expect(projection.next!.name, 'gold');
    });

    test('past onyx every tier is behind, but the chase continues', () {
      // Explorer: onyx at 30,000. What used to be a dead end — no next, no
      // remaining, no date — is now the next whole multiple (#87).
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [40000, 41000]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.current!.name, 'onyx');
      expect(projection.isComplete, isTrue, reason: 'every named tier');
      expect(projection.next, isNull, reason: 'there is no sixth tier');

      expect(projection.topMultiple, 1);
      expect(projection.target, 60000);
      expect(projection.remaining, 19000);
      expect(
        projection.projectedDate(DateTime(2026, 1, 2)),
        isNotNull,
        reason: 'a pace of 1,000 a day reaches 60,000 in nineteen days',
      );
    });
  });

  group("Connector's thresholds (#76)", () {
    // Pinned by value, which the other sixteen are deliberately not: the
    // registry is refreshed from the network (§3.1.4) so that a threshold can
    // be corrected without a release, and freezing every ladder here would
    // fight that. This one shipped with four of its five thresholds wrong and
    // onyx ten times too low, and the cost was not a wrong number on a screen
    // — see below.

    test('every threshold is where the game puts it', () {
      // Read off the badge screen in game: 50, 1,000, 5,000, 25,000, 100,000.
      expect(
        [for (final t in enrichment('Links Created').tiers) t.value],
        [50, 1000, 5000, 25000, 100000],
      );
    });

    test('26,459 links is platinum, with onyx still ahead', () {
      // The value that exposed it. With onyx at 10,000 the app handed out the
      // top medal — drawn as a solid disc (#63), and carried onto the
      // shareable card (#73) — to an agent who had not earned it.
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [26237, 26459]),
        enrichment: enrichment('Links Created'),
      )!;

      expect(projection.current!.name, 'platinum');
      expect(projection.next!.name, 'onyx');
      expect(projection.isComplete, isFalse);
      expect(projection.remaining, 100000 - 26459);
    });

    test('900 links is bronze, not silver', () {
      // Silver was recorded at 100, so anything past a hundred links claimed
      // it. The real threshold is a thousand.
      expect(tierReached(enrichment('Links Created'), 900)!.name, 'bronze');
      expect(tierReached(enrichment('Links Created'), 1000)!.name, 'silver');
    });

    test('and the card no longer says there is nothing left to chase', () {
      // The worse half of the bug: with no tier above the value, next is null
      // and the projection card reads "Onyx reached — nothing left to chase",
      // which is a false statement about the agent's own game on the screen
      // whose job is to say what is left.
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [26237, 26459]),
        enrichment: enrichment('Links Created'),
      )!;

      expect(projection.isComplete, isFalse);
    });
  });

  group('the tier a value has reached', () {
    // Same rule as the projection above, reached from a single number: this
    // is what the medal beside a counter is drawn from (#63).

    test('is null below the first threshold', () {
      expect(tierReached(enrichment('Unique Portals Visited'), 99), isNull);
    });

    test('is the threshold itself once it is met exactly', () {
      expect(
        tierReached(enrichment('Unique Portals Visited'), 100)!.name,
        'bronze',
      );
    });

    test('is the highest one passed, not the first', () {
      expect(
        tierReached(enrichment('Unique Portals Visited'), 1999)!.name,
        'silver',
      );
    });

    test('stays on onyx once every threshold is behind', () {
      final onyx = enrichment('Unique Portals Visited').tiers.last;
      expect(
        tierReached(
          enrichment('Unique Portals Visited'),
          (onyx.value * 10).round(),
        )!.name,
        'onyx',
      );
    });

    test('is null for a counter the registry gives no thresholds', () {
      expect(tierReached(enrichment('Lifetime AP'), 1000000000), isNull);
    });

    test('is null when the registry knows nothing about the counter', () {
      expect(tierReached(null, 1000), isNull);
    });

    test('agrees with the projection it was split out of', () {
      // The medal and the card read the same history; they must never
      // disagree about which tier the agent is on.
      for (final value in [0, 99, 100, 1000, 2000, 6666, 100000]) {
        final projection = projector.project(
          points: daily(DateTime(2026, 1, 1), [value, value]),
          enrichment: enrichment('Unique Portals Visited'),
        )!;
        expect(
          projection.current?.name,
          tierReached(enrichment('Unique Portals Visited'), value)?.name,
          reason: 'at $value',
        );
      }
    });
  });

  group('counters without thresholds', () {
    test('yield no projection at all', () {
      // Most counters have none, and Orion Tokens never will.
      expect(
        projector.project(
          points: daily(DateTime(2026, 1, 1), [10, 20]),
          enrichment: enrichment('Orion Tokens'),
        ),
        isNull,
      );
    });

    test('an unknown counter yields none either', () {
      expect(
        projector.project(
          points: daily(DateTime(2026, 1, 1), [10, 20]),
          enrichment: null,
        ),
        isNull,
      );
    });
  });

  group('the projected date', () {
    test('follows the recent pace', () {
      // Ten a day, 500 to go: fifty days.
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [
          1400,
          1410,
          1420,
          1430,
          1440,
          1450,
        ]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.perDay, closeTo(10, 0.001));
      expect(projection.remaining, 550);
      expect(projection.daysToNext, closeTo(55, 0.001));

      final from = DateTime(2026, 1, 6);
      expect(projection.projectedDate(from)!.difference(from).inDays, 55);
    });

    test('a stalled counter gets no date rather than a wrong one', () {
      // "Not at this pace" is the truthful answer; a made-up date is worse
      // than none.
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [1400, 1400, 1400]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.perDay, 0);
      expect(projection.daysToNext, isNull);
      expect(projection.projectedDate(DateTime(2026, 1, 3)), isNull);
    });

    test('a shrinking counter gets no date either', () {
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [1500, 1400]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.perDay, lessThan(0));
      expect(projection.projectedDate(DateTime(2026, 1, 2)), isNull);
    });

    test('a single snapshot gives no pace to go on', () {
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [1400]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.perDay, isNull);
      expect(projection.projectedDate(DateTime(2026, 1, 1)), isNull);
    });

    test('a date centuries away is withheld', () {
      // One a day against the 25 million XM of Recharger onyx: printing an
      // exact day in the 2090s would be false precision, not information.
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [100, 101]),
        enrichment: enrichment('XM Recharged'),
      )!;

      expect(projection.daysToNext, greaterThan(365 * 5));
      expect(projection.projectedDate(DateTime(2026, 1, 2)), isNull);
    });
  });

  group('the pace window', () {
    final history = daily(
      DateTime(2026, 1, 1),
      // Slow for three weeks, then a burst in the last few days.
      [for (var d = 0; d < 28; d++) 1000 + d] + [1100, 1200, 1300],
    );

    test('a week reflects the recent burst', () {
      final projection = projector.project(
        points: history,
        enrichment: enrichment('Unique Portals Visited'),
        window: ProjectionWindow.week,
      )!;

      expect(projection.perDay, greaterThan(20));
    });

    test('a month smooths it out', () {
      final week = projector.project(
        points: history,
        enrichment: enrichment('Unique Portals Visited'),
        window: ProjectionWindow.week,
      )!;
      final month = projector.project(
        points: history,
        enrichment: enrichment('Unique Portals Visited'),
        window: ProjectionWindow.month,
      )!;

      expect(month.perDay, lessThan(week.perDay!));
      expect(month.perDay, greaterThan(0));
    });

    test('the window is measured from the last snapshot, not from today', () {
      // An agent who stopped importing weeks ago has not slowed down; the app
      // simply stopped hearing about it (§3.5 does the same).
      final old = daily(DateTime(2020, 1, 1), [1400, 1410, 1420]);

      final projection = projector.project(
        points: old,
        enrichment: enrichment('Unique Portals Visited'),
        window: ProjectionWindow.week,
      )!;

      expect(projection.perDay, closeTo(10, 0.001));
    });
  });

  group('the multiplier past the top tier (#87)', () {
    // The rule, confirmed by an agent reading the game's own achievement
    // sheet: the number beside a completed badge is how many whole times the
    // top threshold has been reached.

    test('reproduces the reported sheet exactly', () {
      // 351,056,060 XM against Recharger's onyx of 25,000,000 shows "x 14" in
      // game. Nothing else in that sheet produces 14, which is what settled
      // the reading.
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [350000000, 351056060]),
        enrichment: enrichment('XM Recharged'),
      )!;

      expect(projection.topMultiple, 14);
      expect(projection.target, 375000000);
      expect(projection.remaining, 23943940);
    });

    test('rounds down, never up', () {
      // 14.04 is x 14. Rounding up would hand out a multiple the agent has
      // not reached — the same error as a threshold set too low (#76).
      final onyx = enrichment('XM Recharged').tiers.last.value;
      expect(onyx, 25000000);

      for (final value in [
        (onyx * 14).round(),
        (onyx * 14).round() + 1,
        (onyx * 15).round() - 1,
      ]) {
        expect(
          topTierMultiple(enrichment('XM Recharged'), value),
          14,
          reason: '\$value',
        );
      }
      expect(
        topTierMultiple(enrichment('XM Recharged'), (onyx * 15).round()),
        15,
      );
    });

    test('exactly on the top threshold is x 1, not x 0', () {
      final onyx = enrichment('Unique Portals Visited').tiers.last.value;
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [1, onyx.round()]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.topMultiple, 1);
      expect(projection.target, onyx * 2);
      expect(projection.progress, 0, reason: 'the stretch has just started');
    });

    test('there is no multiplier while a tier is still ahead', () {
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [1400, 1500]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.next!.name, 'gold');
      expect(projection.topMultiple, isNull);
      expect(
        topTierMultiple(enrichment('Unique Portals Visited'), 1500),
        isNull,
      );
    });

    test('progress measures the current stretch, not the whole climb', () {
      // Halfway from x 1 to x 2 is 0.5 — measuring from zero would pin the
      // bar at 1 forever.
      final onyx = enrichment('Unique Portals Visited').tiers.last.value;
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [1, (onyx * 1.5).round()]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.topMultiple, 1);
      expect(projection.progress, closeTo(0.5, 0.001));
    });

    test('the standalone reading agrees with the projection', () {
      // Same rule as #63 for the tier: a tile showing a multiplier and a card
      // computing one must never disagree.
      final counter = enrichment('Links Created');
      for (final value in [49, 50, 99999, 100000, 250000, 1000000]) {
        final projection = projector.project(
          points: daily(DateTime(2026, 1, 1), [0, value]),
          enrichment: counter,
        )!;
        expect(
          topTierMultiple(counter, value),
          projection.topMultiple,
          reason: '\$value links',
        );
      }
    });

    test('a counter with no thresholds has no multiplier', () {
      expect(topTierMultiple(null, 1000), isNull);
      expect(
        topTierMultiple(registry.forExportHeader('Orion Tokens'), 1000000),
        isNull,
      );
    });
  });
}
