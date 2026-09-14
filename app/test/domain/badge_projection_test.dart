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
    registry =
        const CounterRegistryLoader().parse(File(seedPath).readAsStringSync());
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

    test('past onyx there is nothing left to chase', () {
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [40000, 41000]),
        enrichment: enrichment('Unique Portals Visited'),
      )!;

      expect(projection.current!.name, 'onyx');
      expect(projection.isComplete, isTrue);
      expect(projection.next, isNull);
      expect(projection.remaining, isNull);
      expect(projection.projectedDate(DateTime(2026, 1, 2)), isNull);
    });
  });

  group("Connector's thresholds (#76)", () {
    // Pinned by value, which the other sixteen are deliberately not: the
    // registry is refreshed from the network (§3.1.4) so that a threshold can
    // be corrected without a release, and freezing every ladder here would
    // fight that. This one shipped with onyx ten times too low, and the cost
    // was not a wrong number on a screen — see below.

    test('platinum and onyx are where the game puts them', () {
      expect(
        [for (final t in enrichment('Links Created').tiers) t.value],
        [50, 100, 800, 25000, 100000],
      );
    });

    test('26,237 links is platinum, with onyx still ahead', () {
      // The value that exposed it. With onyx at 10,000 the app handed out the
      // top medal — drawn as a solid disc (#63), and carried onto the
      // shareable card (#73) — to an agent who had not earned it.
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [26152, 26237]),
        enrichment: enrichment('Links Created'),
      )!;

      expect(projection.current!.name, 'platinum');
      expect(projection.next!.name, 'onyx');
      expect(projection.isComplete, isFalse);
      expect(projection.remaining, 100000 - 26237);
    });

    test('and the card no longer says there is nothing left to chase', () {
      // The worse half of the bug: with no tier above the value, next is null
      // and the projection card reads "Onyx reached — nothing left to chase",
      // which is a false statement about the agent's own game on the screen
      // whose job is to say what is left.
      final projection = projector.project(
        points: daily(DateTime(2026, 1, 1), [26152, 26237]),
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
      expect(tierReached(enrichment('Unique Portals Visited'), 100)!.name,
          'bronze');
    });

    test('is the highest one passed, not the first', () {
      expect(tierReached(enrichment('Unique Portals Visited'), 1999)!.name,
          'silver');
    });

    test('stays on onyx once every threshold is behind', () {
      final onyx = enrichment('Unique Portals Visited').tiers.last;
      expect(
        tierReached(enrichment('Unique Portals Visited'),
            (onyx.value * 10).round())!.name,
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
        points: daily(DateTime(2026, 1, 1), [1400, 1410, 1420, 1430, 1440, 1450]),
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
}
