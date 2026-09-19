// A year read back, built on the device from the history alone (#153).
//
// The roadmap filed this under "would need a server". It does not, and these
// tests are the proof: nothing here fetches anything.
//
// Most of them are about what the recap must refuse to claim. A year is the
// one view where a small dishonesty compounds — it is the thing people post.

import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/year_in_review.dart';
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

List<String> headersOf(YearInReview review) => [
  for (final gain in review.gains) gain.exportHeader,
];

void main() {
  late CounterRegistry registry;
  late YearInReviewBuilder builder;

  setUp(() {
    registry = const CounterRegistryLoader().parse(
      File(seedPath).readAsStringSync(),
    );
    builder = YearInReviewBuilder(registry: registry);
  });

  group('what the year covers', () {
    test('measures from the last snapshot before it, not from 1 January', () {
      // The value on 1 January is whatever the last import said, whenever it
      // was taken. Starting from the first snapshot *inside* the year would
      // silently drop everything gained over the new year.
      final review = builder.build(
        snapshots: [
          at(DateTime(2025, 12, 28), const {'Hacks': 1000}),
          at(DateTime(2026, 6, 1), const {'Hacks': 4000}),
        ],
        year: 2026,
      )!;

      expect(review.from, DateTime(2025, 12, 28));
      expect(review.isPartial, isFalse);
      expect(review.gains.single.from, 1000);
      expect(review.gains.single.to, 4000);
    });

    test('says so when the history does not reach back that far', () {
      // Someone who started in September has a recap covering four months,
      // and it should say that rather than look thin.
      final review = builder.build(
        snapshots: [
          at(DateTime(2026, 9, 1), const {'Hacks': 1000}),
          at(DateTime(2026, 12, 20), const {'Hacks': 4000}),
        ],
        year: 2026,
      )!;

      expect(review.isPartial, isTrue);
      expect(review.from, DateTime(2026, 9, 1));
    });

    test('a year with a single snapshot has nothing to measure', () {
      expect(
        builder.build(
          snapshots: [
            at(DateTime(2026, 6, 1), const {'Hacks': 1000}),
          ],
          year: 2026,
        ),
        isNull,
      );
    });

    test('a year with no snapshot at all is null, not empty', () {
      expect(
        builder.build(
          snapshots: [
            at(DateTime(2025, 6, 1), const {'Hacks': 1000}),
          ],
          year: 2026,
        ),
        isNull,
      );
    });
  });

  group('what the gains may and may not claim', () {
    test('a counter absent from either end has no gain', () {
      // Not reported is not the same as not moved (§3.1.2), and its whole
      // value is certainly not this year's gain.
      final review = builder.build(
        snapshots: [
          at(DateTime(2025, 12, 28), const {'Hacks': 1000}),
          at(DateTime(2026, 12, 20), const {
            'Hacks': 4000,
            'Orion Tokens': 9000,
          }),
        ],
        year: 2026,
      )!;

      expect(headersOf(review), ['Hacks']);
    });

    test('a counter that fell is left out rather than reported as a loss', () {
      // Current AP drops on a recursion (§3.1.3). "You lost 24 million AP this
      // year" is true and says the wrong thing.
      final review = builder.build(
        snapshots: [
          at(DateTime(2025, 12, 28), const {'Current AP': 24800000}),
          at(DateTime(2026, 12, 20), const {'Current AP': 0}),
        ],
        year: 2026,
      )!;

      expect(review.gains, isEmpty);
    });

    test('follows the in-game order and keeps to the count asked for', () {
      final review = const YearInReviewBuilder(maxGains: 2).build(
        snapshots: [
          at(DateTime(2025, 12, 28), const {
            'Hacks': 0,
            'Lifetime AP': 0,
            'Links Created': 0,
          }),
          at(DateTime(2026, 12, 20), const {
            'Hacks': 10,
            'Lifetime AP': 10,
            'Links Created': 10,
          }),
        ],
        year: 2026,
      )!;

      expect(review.gains.length, 2);
    });
  });

  group('medals crossed', () {
    test('names every tier crossed, with the import that first showed it', () {
      // Hacks: bronze at 2 000, silver at 10 000 in the real registry.
      final review = builder.build(
        snapshots: [
          at(DateTime(2025, 12, 28), const {'Hacks': 500}),
          at(DateTime(2026, 4, 1), const {'Hacks': 5000}),
          at(DateTime(2026, 12, 20), const {'Hacks': 12000}),
        ],
        year: 2026,
      )!;

      expect(
        [for (final m in review.medals) m.tier.name],
        ['bronze', 'silver'],
      );
      expect(review.medals.first.seenOn, DateTime(2026, 4, 1));
      expect(review.medals.last.seenOn, DateTime(2026, 12, 20));
    });

    test('announces only the new tier, not the ones underneath it', () {
      // Already bronze on 1 January, silver by December: bronze is not news.
      // Without the guard for this, every tier below the new one would be
      // announced again — and the test above does not catch it, because it
      // starts from no tier at all.
      final review = builder.build(
        snapshots: [
          at(DateTime(2025, 12, 28), const {'Hacks': 5000}),
          at(DateTime(2026, 12, 20), const {'Hacks': 12000}),
        ],
        year: 2026,
      )!;

      expect([for (final m in review.medals) m.tier.name], ['silver']);
    });

    test('says nothing about a tier already held on 1 January', () {
      final review = builder.build(
        snapshots: [
          at(DateTime(2025, 12, 28), const {'Hacks': 5000}),
          at(DateTime(2026, 12, 20), const {'Hacks': 6000}),
        ],
        year: 2026,
      )!;

      expect(review.medals, isEmpty);
    });

    test('without a registry there are no thresholds, so no medals', () {
      final review = const YearInReviewBuilder().build(
        snapshots: [
          at(DateTime(2025, 12, 28), const {'Hacks': 500}),
          at(DateTime(2026, 12, 20), const {'Hacks': 12000}),
        ],
        year: 2026,
      )!;

      expect(review.medals, isEmpty);
      expect(review.gains, isNotEmpty, reason: 'gains do not need one');
    });
  });

  group('the shape of the year', () {
    test('names the month that gained the most AP', () {
      final review = builder.build(
        snapshots: [
          at(DateTime(2025, 12, 28), const {'Lifetime AP': 0}),
          at(DateTime(2026, 3, 15), const {'Lifetime AP': 1000}),
          at(DateTime(2026, 7, 15), const {'Lifetime AP': 900000}),
          at(DateTime(2026, 11, 15), const {'Lifetime AP': 901000}),
        ],
        year: 2026,
      )!;

      expect(review.busiestMonth, 7);
    });

    test('has no busiest month when no AP was ever recorded', () {
      final review = builder.build(
        snapshots: [
          at(DateTime(2025, 12, 28), const {'Hacks': 0}),
          at(DateTime(2026, 6, 1), const {'Hacks': 10}),
        ],
        year: 2026,
      )!;

      expect(review.busiestMonth, isNull);
    });

    test('reports the longest run between two imports', () {
      // The honest caveat on everything else: a recap built from a history
      // with a hole describes what was recorded, not what was done.
      final review = builder.build(
        snapshots: [
          at(DateTime(2026, 1, 1), const {'Hacks': 0}),
          at(DateTime(2026, 1, 10), const {'Hacks': 10}),
          at(DateTime(2026, 5, 10), const {'Hacks': 20}),
        ],
        year: 2026,
      )!;

      expect(review.longestGap!.inDays, 120);
    });
  });
}
