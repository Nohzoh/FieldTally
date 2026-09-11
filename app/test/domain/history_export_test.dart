import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/history_export.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/repositories/snapshot_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';

StoredSnapshot stored(
  DateTime date,
  Map<String, int> counters, {
  int? level = 9,
  TimeSpan timeSpan = TimeSpan.allTime,
}) =>
    StoredSnapshot(
      id: date.toIso8601String(),
      importedAt: DateTime(2026, 9, 11),
      snapshot: StatSnapshot(
        timeSpan: timeSpan,
        agentName: 'AgentDemo',
        faction: 'Enlightened',
        recordedAt: date,
        level: level,
        counters: counters,
      ),
    );

List<String> rowsOf(String csv) =>
    csv.trim().split('\n').where((l) => l.isNotEmpty).toList();

void main() {
  late CounterRegistry registry;

  setUp(() {
    registry =
        const CounterRegistryLoader().parse(File(seedPath).readAsStringSync());
  });

  test('an empty history exports nothing at all', () {
    expect(const HistoryCsvExporter().build(const []), isEmpty);
  });

  test('writes a header and one row per snapshot, oldest first', () {
    final csv = const HistoryCsvExporter().build([
      stored(DateTime(2026, 2, 1), const {'Hacks': 20}),
      stored(DateTime(2026, 1, 1), const {'Hacks': 10}),
    ]);

    final rows = rowsOf(csv);
    expect(rows, hasLength(3));
    expect(rows.first, startsWith('date,time,agent,faction,time_span,level'));
    expect(rows[1], startsWith('2026-01-01,00:00:00,AgentDemo,Enlightened'));
    expect(rows[1], endsWith('10'));
    expect(rows[2], endsWith('20'));
  });

  test('columns follow the in-game order when the registry is available', () {
    final csv = HistoryCsvExporter(registry: registry).build([
      stored(DateTime(2026, 1, 1),
          const {'Recursions': 1, 'Hacks': 10, 'Unique Portals Visited': 5}),
    ]);

    final header = rowsOf(csv).first;
    expect(
      header,
      endsWith('Unique Portals Visited,Hacks,Recursions'),
    );
  });

  test('a counter missing from one snapshot leaves a blank, not a zero', () {
    // A gap is not a zero (§3.1.2); writing 0 would invent data on the way out.
    final csv = const HistoryCsvExporter().build([
      stored(DateTime(2026, 1, 1), const {'Hacks': 10, 'Orion Tokens': 500}),
      stored(DateTime(2026, 2, 1), const {'Hacks': 20}),
    ]);

    // Without a registry the columns come out alphabetically: Hacks, then
    // Orion Tokens.
    final rows = rowsOf(csv);
    expect(rows[1], endsWith('10,500'));
    expect(rows[2], endsWith('20,'));
  });

  test('an unknown level is blank rather than zero', () {
    final csv = const HistoryCsvExporter()
        .build([stored(DateTime(2026, 1, 1), const {'Hacks': 10}, level: null)]);

    expect(rowsOf(csv)[1], contains('allTime,,10'));
  });

  test('the declared period travels with the snapshot', () {
    // A snapshot saved past a guard stays identifiable in the export.
    final csv = const HistoryCsvExporter().build([
      stored(DateTime(2026, 1, 1), const {'Hacks': 10},
          timeSpan: TimeSpan.week),
    ]);

    expect(rowsOf(csv)[1], contains(',week,'));
  });

  test('counter names carrying a comma are quoted', () {
    final csv = const HistoryCsvExporter()
        .build([stored(DateTime(2026, 1, 1), const {'Odd, name': 3})]);

    expect(rowsOf(csv).first, contains('"Odd, name"'));
  });

  test('the file name is dated so exports do not collide', () {
    expect(
      const HistoryCsvExporter().fileNameFor(DateTime(2026, 9, 11)),
      'fieldtally-2026-09-11.csv',
    );
  });
}
