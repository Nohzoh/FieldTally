import 'dart:io';

import 'package:fieldtally/data/parsing/ingress_tsv_parser.dart';
import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';
const allTimePath = 'test/fixtures/sample_export_all_time.tsv';

void main() {
  const loader = CounterRegistryLoader();
  late CounterRegistry registry;

  setUp(() {
    registry = loader.parse(File(seedPath).readAsStringSync());
  });

  group('bundled registry', () {
    test('loads with its 59 counters and its categories', () {
      expect(registry.length, 59);
      expect(registry.categories, contains('discovery'));
      expect(registry.categories, contains(CounterRegistry.fallbackCategoryKey));
      expect(registry.schemaVersion, greaterThan(0));
    });

    test('covers exactly the counters of the real fixture', () {
      final snapshot = const IngressTsvParser()
          .parseSingle(File(allTimePath).readAsStringSync());

      final unknown = snapshot.counters.keys
          .where((h) => registry.forExportHeader(h) == null)
          .toList();

      expect(unknown, isEmpty,
          reason: 'these columns have no enrichment entry');
    });

    test('maps to the right category and carries both labels', () {
      final explorer = registry.forExportHeader('Unique Portals Visited')!;

      expect(explorer.key, 'explorer');
      expect(explorer.categoryKey, 'discovery');
      expect(explorer.label('en'), 'Unique Portals Visited');
      expect(explorer.label('fr'), isNotEmpty);
      expect(explorer.label('fr'), isNot(explorer.label('en')));
    });

    test('files anomaly counters under Events, like the game does', () {
      // The game does not isolate them on a separate screen, and neither does
      // the app.
      for (final header in [
        'Orion Tokens',
        'Apollo Tokens',
        'Mission Day(s) Attended',
      ]) {
        expect(registry.forExportHeader(header)!.categoryKey, 'events',
            reason: header);
      }
    });

    test('marks Level, Lifetime AP and Current AP as non periodized', () {
      for (final header in ['Level', 'Lifetime AP', 'Current AP']) {
        expect(registry.isPeriodized(header), isFalse, reason: header);
      }
    });

    test('carries badge thresholds for the medals that have them', () {
      // Supplied by hand rather than invented: a wrong threshold produces a
      // wrong projection date in silence, which is worse than none at all.
      final hacks = registry.forExportHeader('Hacks')!.tiers;

      expect(hacks, hasLength(5));
      expect(hacks.map((t) => t.name),
          ['bronze', 'silver', 'gold', 'platinum', 'onyx']);
      expect(hacks.map((t) => t.value),
          [2000, 10000, 30000, 100000, 200000]);
    });

    test('leaves counters that are not medals without thresholds', () {
      // Anomaly counters never had a badge, and never will.
      expect(registry.forExportHeader('Orion Tokens')!.tiers, isEmpty);
      expect(registry.forExportHeader('Current AP')!.tiers, isEmpty);
    });
  });

  group('unknown counter (§3.1.2)', () {
    test('has no entry, falls into "other" and stays periodized', () {
      expect(registry.forExportHeader('Zeta Anomaly Tokens'), isNull);
      expect(
        registry.categoryKeyFor('Zeta Anomaly Tokens'),
        CounterRegistry.fallbackCategoryKey,
      );
      // Periodized by default, so the behavioural guard watches it — the
      // cautious side.
      expect(registry.isPeriodized('Zeta Anomaly Tokens'), isTrue);
    });
  });

  group('display order', () {
    test('follows the game categories, then the order within each', () {
      final sorted = registry.sortHeaders([
        'Recursions',
        'Hacks',
        'Unique Portals Visited',
        'Resonators Deployed',
        'Level',
      ]);

      expect(sorted, [
        'Level', // core, first
        'Unique Portals Visited', // discovery
        'Resonators Deployed', // building
        'Hacks', // resource gathering
        'Recursions', // recursion, last
      ]);
    });

    test('pushes unknown counters to the end of the list', () {
      final sorted = registry.sortHeaders([
        'Zeta Anomaly Tokens',
        'Hacks',
        'Alpha Unknown',
      ]);

      expect(sorted.first, 'Hacks');
      // Among unknowns, alphabetical order keeps the display stable.
      expect(sorted.sublist(1), ['Alpha Unknown', 'Zeta Anomaly Tokens']);
    });
  });

  group('resilience to a broken registry', () {
    test('an empty registry does not bring the app down', () {
      final empty = CounterRegistry.empty();

      expect(empty.length, 0);
      expect(empty.forExportHeader('Hacks'), isNull);
      expect(empty.categoryKeyFor('Hacks'), CounterRegistry.fallbackCategoryKey);
      expect(empty.isPeriodized('Hacks'), isTrue);
      expect(empty.sortHeaders(['B', 'A']), ['A', 'B']);
    });
  });
}
