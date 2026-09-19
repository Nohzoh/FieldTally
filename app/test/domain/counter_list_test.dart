import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/counter_list.dart';
import 'package:fieldtally/domain/counter_pace.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/tracked_counter.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';

TrackedCounter counter(
  String header, {
  int last = 10,
  int? previous,
  CounterStatus status = CounterStatus.active,
  DateTime? firstSeen,
  bool hasEverMoved = true,
}) => TrackedCounter(
  exportHeader: header,
  firstSeen: firstSeen ?? DateTime(2026, 1, 1),
  lastSeen: DateTime(2026, 1, 20),
  lastValue: last,
  previousValue: previous,
  status: status,
  hasEverMoved: hasEverMoved,
);

List<String> headersOf(List<CounterSection> sections) => [
  for (final s in sections) ...s.counters.map((c) => c.exportHeader),
];

/// A pace map of the shape [paceByCounter] returns, from plain rates.
Map<String, CounterPace> paces(Map<String, double> perDay) => {
  for (final entry in perDay.entries)
    entry.key: (gain: (entry.value * 7).round(), days: 7, perDay: entry.value),
};

void main() {
  late CounterRegistry registry;
  late CounterListBuilder builder;

  setUp(() {
    registry = const CounterRegistryLoader().parse(
      File(seedPath).readAsStringSync(),
    );
    builder = CounterListBuilder(registry: registry, language: 'en');
  });

  group('labels', () {
    test('uses the enriched translation when there is one', () {
      expect(
        CounterListBuilder(
          registry: registry,
          language: 'fr',
        ).labelFor(counter('Unique Portals Visited')),
        'Portails uniques visités',
      );
    });

    test('falls back to the raw export header for an unknown counter', () {
      expect(builder.labelFor(counter('Zeta Tokens')), 'Zeta Tokens');
    });
  });

  group('ordering by category (the default)', () {
    test('groups counters and follows the in-game category order', () {
      final sections = builder.build([
        counter('Recursions'),
        counter('Hacks'),
        counter('Unique Portals Visited'),
        counter('Level'),
      ], const CounterQuery());

      expect(
        [for (final s in sections) s.categoryKey],
        ['core', 'discovery', 'resource_gathering', 'recursion'],
      );
    });

    test('unknown counters land in the fallback category, at the end', () {
      final sections = builder.build([
        counter('Zeta Tokens'),
        counter('Hacks'),
      ], const CounterQuery());

      expect(sections.last.categoryKey, CounterRegistry.fallbackCategoryKey);
      expect(sections.last.counters.single.exportHeader, 'Zeta Tokens');
    });
  });

  group('ordering by name', () {
    test(
      'produces one flat section, alphabetically on the displayed label',
      () {
        final sections = builder.build([
          counter('Recursions'),
          counter('Hacks'),
          counter('Drone Hacks'),
        ], const CounterQuery(sort: CounterSort.name));

        expect(sections, hasLength(1));
        expect(sections.single.categoryKey, isNull);
        expect(headersOf(sections), ['Drone Hacks', 'Hacks', 'Recursions']);
      },
    );
  });

  group('ordering by recent progress', () {
    CounterListBuilder builderWith(Map<String, double> perDay) =>
        CounterListBuilder(
          registry: registry,
          language: 'en',
          pace: paces(perDay),
        );

    test('fastest first', () {
      final sections =
          builderWith({
            'Hacks': 10,
            'Links Created': 57,
            'Recursions': 0,
          }).build([
            counter('Hacks', last: 110, previous: 100),
            counter('Links Created', last: 500, previous: 100),
            counter('Recursions', last: 2, previous: 2),
          ], const CounterQuery(sort: CounterSort.recentProgress));

      expect(headersOf(sections), ['Links Created', 'Hacks', 'Recursions']);
    });

    test('a counter with no measurable pace sorts last', () {
      // "Not known yet" is not "zero progress": a brand new counter should not
      // be buried among the flat ones, nor claim a rank it has not earned.
      // Named so it would sort *first* alphabetically, or the assertion would
      // pass for the wrong reason.
      final sections = builderWith({'Hacks': 10, 'Recursions': 0}).build([
        counter('Hacks', last: 110, previous: 100),
        counter('Aegis Tokens', last: 9999),
        counter('Recursions', last: 2, previous: 2),
      ], const CounterQuery(sort: CounterSort.recentProgress));

      expect(headersOf(sections).last, 'Aegis Tokens');
    });

    test('the unmeasurable block is ordered by label, not by chance', () {
      final sections = builderWith(const {}).build([
        counter('Zeta Tokens'),
        counter('Aegis Tokens'),
        counter('Hacks'),
      ], const CounterQuery(sort: CounterSort.recentProgress));

      expect(headersOf(sections), ['Aegis Tokens', 'Hacks', 'Zeta Tokens']);
    });
  });

  group('search', () {
    test('matches the displayed label, case insensitively', () {
      final sections = builder.build([
        counter('Unique Portals Visited'),
        counter('Hacks'),
      ], const CounterQuery(search: 'portals'));

      expect(headersOf(sections), ['Unique Portals Visited']);
    });

    test('also matches the raw export header when the UI is translated', () {
      // A French-speaking agent may well type the English name they saw in the
      // game.
      final french = CounterListBuilder(registry: registry, language: 'fr');
      final sections = french.build([
        counter('Unique Portals Visited'),
        counter('Hacks'),
      ], const CounterQuery(search: 'Unique Portals'));

      expect(headersOf(sections), ['Unique Portals Visited']);
    });

    test('surrounding whitespace is ignored', () {
      final sections = builder.build([
        counter('Hacks'),
      ], const CounterQuery(search: '  hacks  '));

      expect(headersOf(sections), ['Hacks']);
    });

    test('no match yields empty sections rather than everything', () {
      final sections = builder.build([
        counter('Hacks'),
      ], const CounterQuery(search: 'zzz'));

      expect(headersOf(sections), isEmpty);
    });
  });

  group('inactive counters', () {
    test('are shown by default, as the game does (§3.1.2)', () {
      final sections = builder.build([
        counter('Hacks'),
        counter('Orion Tokens', status: CounterStatus.inactive),
      ], const CounterQuery());

      expect(headersOf(sections), contains('Orion Tokens'));
    });

    test('can be hidden on demand', () {
      final sections = builder.build([
        counter('Hacks'),
        counter('Orion Tokens', status: CounterStatus.inactive),
      ], const CounterQuery(includeInactive: false));

      expect(headersOf(sections), ['Hacks']);
    });
  });

  group('without a registry', () {
    test(
      'still lists everything, alphabetically, under the fallback category',
      () {
        const bare = CounterListBuilder(registry: null, language: 'en');
        final sections = bare.build([
          counter('Hacks'),
          counter('Alpha'),
        ], const CounterQuery());

        expect(headersOf(sections), ['Alpha', 'Hacks']);
        expect(
          sections.single.categoryKey,
          CounterRegistry.fallbackCategoryKey,
        );
      },
    );
  });

  group('the medal filter (#88)', () {
    test('keeps only counters the registry gives thresholds', () {
      // Seventeen of the fifty-nine counters carry tiers. Hacks and Links
      // Created do; Recursions and an unknown token do not.
      final sections = builder.build([
        counter('Hacks'),
        counter('Links Created'),
        counter('Recursions'),
        counter('Zeta Tokens'),
      ], const CounterQuery(medalsOnly: true));

      expect(headersOf(sections)..sort(), ['Hacks', 'Links Created']);
    });

    test('composes with the search rather than replacing it', () {
      final sections = builder.build([
        counter('Hacks'),
        counter('Links Created'),
      ], const CounterQuery(medalsOnly: true, search: 'links'));

      expect(headersOf(sections), ['Links Created']);
    });

    test('composes with the inactive filter too', () {
      final sections = builder.build([
        counter('Hacks'),
        counter('Links Created', status: CounterStatus.inactive),
      ], const CounterQuery(medalsOnly: true, includeInactive: false));

      expect(headersOf(sections), ['Hacks']);
    });

    test('off by default, so the list is unchanged for anyone ignoring it', () {
      final sections = builder.build([
        counter('Hacks'),
        counter('Recursions'),
      ], const CounterQuery());

      expect(headersOf(sections)..sort(), ['Hacks', 'Recursions']);
    });

    test('with no registry nothing carries a medal', () {
      // The screen disables the chip in this state rather than emptying the
      // list silently; the builder still answers honestly.
      final bare = CounterListBuilder(registry: null, language: 'en');
      final sections = bare.build([
        counter('Hacks'),
        counter('Links Created'),
      ], const CounterQuery(medalsOnly: true));

      expect(headersOf(sections), isEmpty);
    });
  });

  group('the never-moved filter (#165)', () {
    test('keeps only counters whose value has never changed', () {
      final sections = builder.build([
        counter('Hacks', hasEverMoved: false),
        counter('Links Created', hasEverMoved: true),
        counter('Recursions', hasEverMoved: false),
      ], const CounterQuery(neverMovedOnly: true));

      expect(headersOf(sections)..sort(), ['Hacks', 'Recursions']);
    });

    test('composes with the search rather than replacing it', () {
      final sections = builder.build([
        counter('Hacks', hasEverMoved: false),
        counter('Links Created', hasEverMoved: false),
      ], const CounterQuery(neverMovedOnly: true, search: 'links'));

      expect(headersOf(sections), ['Links Created']);
    });

    test('composes with the inactive filter too', () {
      final sections = builder.build([
        counter('Hacks', hasEverMoved: false),
        counter(
          'Links Created',
          hasEverMoved: false,
          status: CounterStatus.inactive,
        ),
      ], const CounterQuery(neverMovedOnly: true, includeInactive: false));

      expect(headersOf(sections), ['Hacks']);
    });

    test('off by default, so the list is unchanged for anyone ignoring it', () {
      final sections = builder.build([
        counter('Hacks', hasEverMoved: false),
        counter('Recursions', hasEverMoved: true),
      ], const CounterQuery());

      expect(headersOf(sections)..sort(), ['Hacks', 'Recursions']);
    });
  });

  group('ordering by proximity to the next tier (#90)', () {
    // Explorer: bronze 100, silver 1,000, gold 2,000, platinum 10,000,
    // onyx 30,000. Hacks: bronze 2,000 … onyx 200,000.

    test('closest first means furthest across the stretch', () {
      // 1,900 of Explorer is 90% of the way from silver to gold; 2,100 hacks
      // is 5% of the way from bronze to silver. The one with less left in
      // absolute terms is the *second* of the two, which is exactly the trap.
      final sections = builder.build([
        counter('Hacks', last: 2100),
        counter('Unique Portals Visited', last: 1900),
      ], const CounterQuery(sort: CounterSort.nextTier));

      expect(headersOf(sections), ['Unique Portals Visited', 'Hacks']);
    });

    test('counters with no thresholds form a block at the end', () {
      final sections = builder.build([
        counter('Zeta Tokens', last: 900000),
        counter('Unique Portals Visited', last: 1900),
        counter('Aegis Tokens', last: 5),
      ], const CounterQuery(sort: CounterSort.nextTier));

      expect(headersOf(sections), [
        'Unique Portals Visited',
        'Aegis Tokens',
        'Zeta Tokens',
      ]);
    });

    test('a counter past onyx is ranked, not discarded', () {
      // Without #87 it would have no next tier and fall in with the counters
      // that have no medal at all — "I have finished this" filed under "there
      // is nothing here".
      final sections = builder.build([
        counter('Unique Portals Visited', last: 59000), // 96.7% of x1 to x2
        counter('Hacks', last: 2100), // 5% of bronze to silver
        counter('Zeta Tokens', last: 10),
      ], const CounterQuery(sort: CounterSort.nextTier));

      expect(headersOf(sections), [
        'Unique Portals Visited',
        'Hacks',
        'Zeta Tokens',
      ]);
    });

    test('below the first threshold counts from zero', () {
      final sections = builder.build([
        counter('Unique Portals Visited', last: 90), // 90% of bronze at 100
        counter('Hacks', last: 100), // 5% of bronze at 2,000
      ], const CounterQuery(sort: CounterSort.nextTier));

      expect(headersOf(sections), ['Unique Portals Visited', 'Hacks']);
    });
  });

  group('how far back the app can see (#100)', () {
    test('is the oldest counter, since the first import carried them all', () {
      expect(
        watchingSince([
          counter('Hacks', firstSeen: DateTime(2026, 3, 4)),
          counter('Unique Portals Visited', firstSeen: DateTime(2026, 1, 9)),
          counter('Apollo Tokens', firstSeen: DateTime(2026, 7, 1)),
        ]),
        DateTime(2026, 1, 9),
      );
    });

    test('a counter that arrived later does not move it', () {
      // The point of the whole thing: Apollo showing up in July says nothing
      // about when the app started looking, and must not be allowed to.
      final counters = [
        counter('Hacks', firstSeen: DateTime(2026, 1, 9)),
        counter('Apollo Tokens', firstSeen: DateTime(2026, 7, 1)),
      ];

      expect(watchingSince(counters), DateTime(2026, 1, 9));
      expect(watchingSince(counters.reversed), DateTime(2026, 1, 9));
    });

    test('nothing imported yet is null, not today', () {
      // Null rather than a fallback date: the screen says nothing at all
      // rather than claiming to have been watching since this morning.
      expect(watchingSince(const []), isNull);
    });
  });
}
