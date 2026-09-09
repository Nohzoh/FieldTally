import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/counter_list.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/tracked_counter.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';

TrackedCounter counter(
  String header, {
  int last = 10,
  int? previous,
  CounterStatus status = CounterStatus.active,
}) =>
    TrackedCounter(
      exportHeader: header,
      firstSeen: DateTime(2026, 1, 1),
      lastSeen: DateTime(2026, 1, 20),
      lastValue: last,
      previousValue: previous,
      status: status,
    );

List<String> headersOf(List<CounterSection> sections) =>
    [for (final s in sections) ...s.counters.map((c) => c.exportHeader)];

void main() {
  late CounterRegistry registry;
  late CounterListBuilder builder;

  setUp(() {
    registry =
        const CounterRegistryLoader().parse(File(seedPath).readAsStringSync());
    builder = CounterListBuilder(registry: registry, language: 'en');
  });

  group('labels', () {
    test('uses the enriched translation when there is one', () {
      expect(
        CounterListBuilder(registry: registry, language: 'fr')
            .labelFor(counter('Unique Portals Visited')),
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
    test('produces one flat section, alphabetically on the displayed label',
        () {
      final sections = builder.build([
        counter('Recursions'),
        counter('Hacks'),
        counter('Drone Hacks'),
      ], const CounterQuery(sort: CounterSort.name));

      expect(sections, hasLength(1));
      expect(sections.single.categoryKey, isNull);
      expect(headersOf(sections), ['Drone Hacks', 'Hacks', 'Recursions']);
    });
  });

  group('ordering by recent progress', () {
    test('largest progress first', () {
      final sections = builder.build([
        counter('Hacks', last: 110, previous: 100),
        counter('Links Created', last: 500, previous: 100),
        counter('Recursions', last: 2, previous: 2),
      ], const CounterQuery(sort: CounterSort.recentProgress));

      expect(headersOf(sections), ['Links Created', 'Hacks', 'Recursions']);
    });

    test('a counter with no comparison point yet sorts last', () {
      // "Not known yet" is not "zero progress": a brand new counter should not
      // be buried among the flat ones, nor claim a rank it has not earned.
      final sections = builder.build([
        counter('Hacks', last: 110, previous: 100),
        counter('Zeta Tokens', last: 9999),
        counter('Recursions', last: 2, previous: 2),
      ], const CounterQuery(sort: CounterSort.recentProgress));

      expect(headersOf(sections).last, 'Zeta Tokens');
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
      final sections = french.build(
        [counter('Unique Portals Visited'), counter('Hacks')],
        const CounterQuery(search: 'Unique Portals'),
      );

      expect(headersOf(sections), ['Unique Portals Visited']);
    });

    test('surrounding whitespace is ignored', () {
      final sections = builder.build(
        [counter('Hacks')],
        const CounterQuery(search: '  hacks  '),
      );

      expect(headersOf(sections), ['Hacks']);
    });

    test('no match yields empty sections rather than everything', () {
      final sections = builder.build(
        [counter('Hacks')],
        const CounterQuery(search: 'zzz'),
      );

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
    test('still lists everything, alphabetically, under the fallback category',
        () {
      const bare = CounterListBuilder(registry: null, language: 'en');
      final sections =
          bare.build([counter('Hacks'), counter('Alpha')], const CounterQuery());

      expect(headersOf(sections), ['Alpha', 'Hacks']);
      expect(sections.single.categoryKey, CounterRegistry.fallbackCategoryKey);
    });
  });
}
