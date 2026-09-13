import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/agent_comparison.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';

StatSnapshot snapshot(String agent, Map<String, int> counters) => StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: agent,
      faction: 'Enlightened',
      recordedAt: DateTime(2026, 9, 13),
      level: 14,
      counters: counters,
    );

void main() {
  late CounterRegistry registry;

  setUp(() {
    registry =
        const CounterRegistryLoader().parse(File(seedPath).readAsStringSync());
  });

  List<ComparisonRow> flat(List<ComparisonSection> sections) =>
      [for (final section in sections) ...section.rows];

  ComparisonRow rowFor(List<ComparisonSection> sections, String header) =>
      flat(sections).firstWhere((r) => r.exportHeader == header);

  group('putting two agents side by side', () {
    test('reports the difference in my favour when I am ahead', () {
      final sections = AgentComparisonBuilder(registry: registry).build(
        mine: snapshot('Me', const {'Hacks': 100}),
        theirs: snapshot('Them', const {'Hacks': 40}),
      );

      expect(rowFor(sections, 'Hacks').difference, 60);
    });

    test('reports it negative when they are', () {
      final sections = AgentComparisonBuilder(registry: registry).build(
        mine: snapshot('Me', const {'Hacks': 40}),
        theirs: snapshot('Them', const {'Hacks': 100}),
      );

      expect(rowFor(sections, 'Hacks').difference, -60);
      expect(rowFor(sections, 'Hacks').isTied, isFalse);
    });

    test('calls a draw a draw rather than nothing', () {
      final sections = AgentComparisonBuilder(registry: registry).build(
        mine: snapshot('Me', const {'Hacks': 40}),
        theirs: snapshot('Them', const {'Hacks': 40}),
      );

      expect(rowFor(sections, 'Hacks').isTied, isTrue);
      expect(rowFor(sections, 'Hacks').difference, 0);
    });
  });

  group('counters only one of them has', () {
    test('are shown rather than dropped', () {
      // Two agents who last imported either side of an anomaly do not have
      // the same columns, and the one who has the counter should see it.
      final sections = AgentComparisonBuilder(registry: registry).build(
        mine: snapshot('Me', const {'Orion Tokens': 12}),
        theirs: snapshot('Them', const {'Hacks': 40}),
      );

      expect(rowFor(sections, 'Orion Tokens').mine, 12);
      expect(rowFor(sections, 'Orion Tokens').theirs, isNull);
      expect(rowFor(sections, 'Hacks').mine, isNull);
      expect(rowFor(sections, 'Hacks').theirs, 40);
    });

    test('have no difference, because a gap is not a zero', () {
      // Subtracting against an absent counter would invent a lead nobody has
      // (§3.1.2).
      final sections = AgentComparisonBuilder(registry: registry).build(
        mine: snapshot('Me', const {'Orion Tokens': 12}),
        theirs: snapshot('Them', const {'Hacks': 40}),
      );

      expect(rowFor(sections, 'Orion Tokens').difference, isNull);
      expect(rowFor(sections, 'Orion Tokens').isTied, isFalse);
    });
  });

  group('ordering', () {
    test('groups by the in-game categories, like the counter list', () {
      final sections = AgentComparisonBuilder(registry: registry).build(
        mine: snapshot('Me', const {
          'Hacks': 1,
          'Unique Portals Visited': 2,
          'Resonators Destroyed': 3,
        }),
        theirs: snapshot('Them', const {'Hacks': 1}),
      );

      expect(sections.length, greaterThan(1));
      for (final section in sections) {
        expect(section.rows, isNotEmpty);
      }
      // No category appears twice: a second block under the same heading
      // would read as two different things.
      final keys = [for (final s in sections) s.categoryKey];
      expect(keys.toSet(), hasLength(keys.length));
    });

    test('puts a counter the registry does not know in the fallback', () {
      final sections = AgentComparisonBuilder(registry: registry).build(
        mine: snapshot('Me', const {'Vesuvius Tokens': 1}),
        theirs: snapshot('Them', const {'Vesuvius Tokens': 2}),
      );

      expect(sections.single.categoryKey, CounterRegistry.fallbackCategoryKey);
    });

    test('falls back to one alphabetical block with no registry', () {
      // The registry is a comfort, never a requirement (§3.1.2).
      final sections = const AgentComparisonBuilder().build(
        mine: snapshot('Me', const {'Zeta': 1, 'Alpha': 2}),
        theirs: snapshot('Them', const {'Alpha': 1}),
      );

      expect(sections.single.categoryKey, isNull);
      expect(
        [for (final r in sections.single.rows) r.exportHeader],
        ['Alpha', 'Zeta'],
      );
    });
  });
}
