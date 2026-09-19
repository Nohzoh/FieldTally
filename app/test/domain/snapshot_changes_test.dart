import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/snapshot_changes.dart';
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

List<String> headersOf(SnapshotChanges changes) => [
  for (final section in changes.sections)
    ...section.changes.map((c) => c.exportHeader),
];

CounterChange changeFor(SnapshotChanges changes, String header) => [
  for (final section in changes.sections) ...section.changes,
].firstWhere((c) => c.exportHeader == header);

void main() {
  late CounterRegistry registry;
  late SnapshotChangesBuilder builder;

  setUp(() {
    registry = const CounterRegistryLoader().parse(
      File(seedPath).readAsStringSync(),
    );
    builder = SnapshotChangesBuilder(registry: registry);
  });

  final morning = DateTime(2026, 6, 13, 9, 12);
  final evening = DateTime(2026, 6, 13, 18, 40);

  group('what counts as a change', () {
    test('a counter that moved is reported with both of its ends', () {
      final changes = builder.between(
        earlier: at(morning, const {'Hacks': 38}),
        later: at(evening, const {'Hacks': 52}),
      );

      final hacks = changeFor(changes, 'Hacks');
      expect(hacks.from, 38);
      expect(hacks.to, 52);
      expect(hacks.delta, 14);
    });

    test('a counter that did not move is left out', () {
      final changes = builder.between(
        earlier: at(morning, const {'Hacks': 38, 'Links Created': 7}),
        later: at(evening, const {'Hacks': 52, 'Links Created': 7}),
      );

      expect(headersOf(changes), ['Hacks']);
    });

    test('a counter absent from the earlier snapshot has no delta', () {
      // The whole point: its value is not this interval's gain. It was simply
      // not reported before (§3.1.2).
      final changes = builder.between(
        earlier: at(morning, const {'Hacks': 38}),
        later: at(evening, const {'Hacks': 38, 'Orion Tokens': 4000}),
      );

      expect(headersOf(changes), isEmpty);
    });

    test('a counter absent from the later snapshot is not a drop to zero', () {
      // What Ingress does to a counter once its event is over: the column is
      // removed outright. That is an absence, not a loss.
      final changes = builder.between(
        earlier: at(morning, const {'Hacks': 38, 'Orion Tokens': 4000}),
        later: at(evening, const {'Hacks': 52}),
      );

      expect(headersOf(changes), ['Hacks']);
    });

    test('a negative delta is reported, not hidden', () {
      // Current AP genuinely goes down on recursion, and Level with it.
      final changes = builder.between(
        earlier: at(morning, const {'Current AP': 24800000, 'Level': 16}),
        later: at(evening, const {'Current AP': 0, 'Level': 1}),
      );

      expect(changeFor(changes, 'Current AP').delta, -24800000);
      expect(changeFor(changes, 'Level').delta, -15);
    });

    test('nothing moved at all is empty rather than a list of zeros', () {
      final changes = builder.between(
        earlier: at(morning, const {'Hacks': 38}),
        later: at(evening, const {'Hacks': 38}),
      );

      expect(changes.isEmpty, isTrue);
      expect(changes.changedCount, 0);
    });
  });

  group('order and grouping', () {
    test('follows the in-game order, not the order of the export map', () {
      // Fed deliberately out of order: Hacks sits in a later category than
      // Lifetime AP, whatever order the map iterates in.
      final changes = builder.between(
        earlier: at(morning, const {'Hacks': 1, 'Lifetime AP': 1}),
        later: at(evening, const {'Hacks': 2, 'Lifetime AP': 2}),
      );

      expect(headersOf(changes), ['Lifetime AP', 'Hacks']);
    });

    test('a counter the registry does not know lands in the last section', () {
      final changes = builder.between(
        earlier: at(morning, const {'Hacks': 1, 'Some New Counter': 1}),
        later: at(evening, const {'Hacks': 2, 'Some New Counter': 5}),
      );

      expect(headersOf(changes).last, 'Some New Counter');
      expect(
        changes.sections.last.categoryKey,
        CounterRegistry.fallbackCategoryKey,
      );
    });

    test('each category appears once, with its counters together', () {
      final changes = builder.between(
        earlier: at(morning, const {
          'Hacks': 1,
          'Resonators Deployed': 1,
          'Lifetime AP': 1,
        }),
        later: at(evening, const {
          'Hacks': 2,
          'Resonators Deployed': 2,
          'Lifetime AP': 2,
        }),
      );

      final keys = [for (final s in changes.sections) s.categoryKey];
      expect(keys.toSet().length, keys.length, reason: 'no category twice');
      expect(changes.changedCount, 3);
    });

    test('without a registry the changes come out alphabetically', () {
      const bare = SnapshotChangesBuilder();
      final changes = bare.between(
        earlier: at(morning, const {'Hacks': 1, 'Lifetime AP': 1}),
        later: at(evening, const {'Hacks': 2, 'Lifetime AP': 2}),
      );

      expect(headersOf(changes), ['Hacks', 'Lifetime AP']);
    });
  });

  group('the interval itself', () {
    test('carries both moments and the real span between them', () {
      final changes = builder.between(
        earlier: at(morning, const {'Hacks': 38}),
        later: at(evening, const {'Hacks': 52}),
      );

      expect(changes.from, morning);
      expect(changes.to, evening);
      expect(changes.span, const Duration(hours: 9, minutes: 28));
    });

    test('a span of weeks is reported as it is, not rounded to a day', () {
      final changes = builder.between(
        earlier: at(DateTime(2026, 5, 1, 8), const {'Hacks': 38}),
        later: at(DateTime(2026, 6, 13, 18, 40), const {'Hacks': 52}),
      );

      expect(changes.span.inDays, 43);
    });
  });
}
