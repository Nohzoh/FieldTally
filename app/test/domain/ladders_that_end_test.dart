// Badge ladders that stop being earnable (#99).
//
// Every ladder the app knew was permanent. A seasonal medal is not: it has a
// deadline, after which the medal already earned stays and the chase does not.
// Two things the app said about such a ladder were false — a projected date
// past the deadline, and a multiplier on a top tier the game stops counting
// past.
//
// The numbers here are the real ones, from Niantic's own announcements.

import 'package:fieldtally/domain/badge_projection.dart';
import 'package:fieldtally/domain/counter_series.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Orion Global Op: 24 April to 11 May 2026, closed long ago.
final orionClosed = DateTime.utc(2026, 5, 11, 18);

/// Apollo Season: claimable until 1 October 2026, still open.
final apolloCloses = DateTime.utc(2026, 10, 1, 23, 59);

CounterEnrichment ladder({
  required String key,
  required List<(String, int)> tiers,
  DateTime? endsAt,
}) => CounterEnrichment(
  key: key,
  exportHeader: key,
  categoryKey: 'events',
  order: 0,
  labels: const {'en': 'x', 'fr': 'x'},
  tiers: [
    for (final (name, value) in tiers) CounterTier(name: name, value: value),
  ],
  endsAt: endsAt,
);

final orionGlobalOp = ladder(
  key: 'Orion Link And Field Points',
  tiers: const [('bronze', 1000), ('silver', 2500), ('gold', 6000)],
  endsAt: orionClosed,
);

final apolloSeason = ladder(
  key: 'Apollo Tokens',
  tiers: const [('bronze', 4000), ('silver', 8000), ('gold', 16000)],
  endsAt: apolloCloses,
);

/// A permanent ladder, for the contrast: three tiers and no deadline.
final permanent = ladder(
  key: 'Hacks',
  tiers: const [('bronze', 100), ('silver', 500), ('gold', 1000)],
);

List<SeriesPoint> climb(DateTime from, List<int> values) => [
  for (var i = 0; i < values.length; i++)
    (at: from.add(Duration(days: i)), value: values[i]),
];

void main() {
  const projector = BadgeProjector();

  group('a ladder whose window has closed', () {
    final measured = DateTime.utc(2026, 5, 1);
    final today = DateTime.utc(2026, 9, 16);

    test('climbed to the top, it says so instead of inventing a target', () {
      final projection = projector.project(
        points: climb(measured, [5000, 6500]),
        enrichment: orionGlobalOp,
        now: today,
      )!;

      expect(projection.current!.name, 'gold');
      expect(projection.isFinished, isTrue);
      expect(projection.isOver, isTrue);
      expect(projection.progress, 1, reason: 'the bar is full, not empty');
      expect(projection.projectedDate(measured), isNull);
    });

    test('left unfinished, the target is out of reach rather than ahead', () {
      // 3,000 points: silver behind, gold at 6,000 never reached.
      final projection = projector.project(
        points: climb(measured, [1000, 3000]),
        enrichment: orionGlobalOp,
        now: today,
      )!;

      expect(projection.current!.name, 'silver');
      expect(projection.next!.name, 'gold');
      expect(projection.isOver, isTrue);
      expect(projection.isFinished, isFalse);
      expect(projection.remaining, 3000, reason: 'still a fact about the past');
      expect(projection.projectedDate(measured), isNull);
      expect(
        projection.missesDeadline(measured),
        isFalse,
        reason: 'the window did not shut on a pace, it shut on a date',
      );
    });

    test('the deadline is the instant, not the day', () {
      for (final (now, over) in [
        (orionClosed.subtract(const Duration(minutes: 1)), false),
        (orionClosed, true),
        (orionClosed.add(const Duration(minutes: 1)), true),
      ]) {
        final projection = projector.project(
          points: climb(measured, [1000, 3000]),
          enrichment: orionGlobalOp,
          now: now,
        )!;
        expect(projection.isOver, over, reason: '$now');
      }
    });

    test('measured against the calendar, not against the last snapshot', () {
      // The agent stopped importing in April, before the op even closed. The
      // pace is measured from their last snapshot (§3.5); whether the window
      // is shut is a fact about the world.
      final projection = projector.project(
        points: climb(DateTime.utc(2026, 4, 25), [1000, 3000]),
        enrichment: orionGlobalOp,
        now: today,
      )!;

      expect(projection.isOver, isTrue);
    });
  });

  group('a ladder still open', () {
    final measured = DateTime.utc(2026, 9, 16);

    test('a date before the deadline is offered as usual', () {
      // 200 tokens a day from 7,000 reaches silver at 8,000 in five days.
      final projection = projector.project(
        points: climb(measured.subtract(const Duration(days: 5)), [
          6000,
          6200,
          6400,
          6600,
          6800,
          7000,
        ]),
        enrichment: apolloSeason,
        now: measured,
      )!;

      final date = projection.projectedDate(measured);
      expect(date, isNotNull);
      expect(date!.isBefore(apolloCloses), isTrue);
    });

    test('a date past the deadline is refused, and says why', () {
      // One token a day from 7,000: silver at 8,000 is a thousand days away,
      // long past 1 October.
      final projection = projector.project(
        points: climb(measured.subtract(const Duration(days: 5)), [
          6996,
          6997,
          6998,
          6999,
          7000,
        ]),
        enrichment: apolloSeason,
        now: measured,
      )!;

      expect(projection.next!.name, 'silver');
      expect(projection.projectedDate(measured), isNull);
      expect(
        projection.missesDeadline(measured),
        isTrue,
        reason:
            'reachable at this pace, but not in time — which is not the '
            'same silence as no pace at all',
      );
    });

    test('climbed to the top before closing, there is nothing further', () {
      final projection = projector.project(
        points: climb(measured, [15000, 20000]),
        enrichment: apolloSeason,
        now: measured,
      )!;

      expect(projection.current!.name, 'gold');
      expect(projection.isFinished, isTrue);
      expect(projection.isOver, isFalse, reason: 'the window is still open');
      expect(projection.topMultiple, isNull);
      expect(projection.progress, 1);
    });
  });

  group('the multiplier belongs to a summit, not a terminus', () {
    final measured = DateTime.utc(2026, 9, 16);

    test('the standalone reading agrees with the projection', () {
      // Two ways to ask the same question — the tile asks the first, the card
      // the second — and #63's rule is that they can never disagree.
      for (final value in [3000, 16000, 40000, 64000]) {
        final projection = projector.project(
          points: climb(measured, [0, value]),
          enrichment: apolloSeason,
          now: measured,
        )!;
        expect(
          topTierMultiple(apolloSeason, value),
          projection.topMultiple,
          reason: '$value tokens',
        );
      }
    });

    test('a seasonal top tier never multiplies', () {
      // 64,000 tokens is four times gold. The game stops counting at gold.
      final projection = projector.project(
        points: climb(measured, [60000, 64000]),
        enrichment: apolloSeason,
        now: measured,
      )!;

      expect(projection.topMultiple, isNull);
    });

    test('a permanent one still does, with the same number of tiers', () {
      // Same three-tier shape, no deadline: the multiplier is back.
      final projection = projector.project(
        points: climb(measured, [3000, 4000]),
        enrichment: permanent,
        now: measured,
      )!;

      expect(projection.isFinished, isFalse);
      expect(projection.topMultiple, 4);
      expect(projection.target, 5000);
    });
  });

  group('the registry reads the date', () {
    test('an ISO instant in UTC', () {
      final parsed = CounterEnrichment.fromJson('x', {
        'export_header': 'x',
        'category': 'events',
        'order': 0,
        'label': {'en': 'x', 'fr': 'x'},
        'ends_at': '2026-09-16T18:00:00Z',
      });

      expect(parsed.endsAt, DateTime.utc(2026, 9, 16, 18));
    });

    test('an offset is normalised to UTC', () {
      final parsed = CounterEnrichment.fromJson('x', {
        'export_header': 'x',
        'category': 'events',
        'order': 0,
        'label': {'en': 'x', 'fr': 'x'},
        'ends_at': '2026-09-16T20:00:00+02:00',
      });

      expect(parsed.endsAt, DateTime.utc(2026, 9, 16, 18));
    });

    test('nonsense is read as no deadline, not as a broken counter', () {
      // The registry is fetched over the network (§3.1.4). A bad date in it
      // must not take the counter down with it — the validator is where a
      // contribution mistake gets caught, not an agent's phone.
      final parsed = CounterEnrichment.fromJson('x', {
        'export_header': 'x',
        'category': 'events',
        'order': 0,
        'label': {'en': 'x', 'fr': 'x'},
        'ends_at': 'the end of the op',
      });

      expect(parsed.endsAt, isNull);
      expect(parsed.exportHeader, 'x');
    });

    test('a permanent counter has none', () {
      expect(permanent.endsAt, isNull);
      expect(permanent.endedBy(DateTime.utc(2099)), isFalse);
    });
  });
}
