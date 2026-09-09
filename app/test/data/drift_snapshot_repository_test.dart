import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/repositories/drift_snapshot_repository.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

StatSnapshot snapshotAt(DateTime date, Map<String, int> counters) =>
    StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: date,
      level: 9,
      counters: counters,
    );

void main() {
  late FieldTallyDatabase db;
  late DriftSnapshotRepository repository;

  setUp(() {
    db = FieldTallyDatabase(NativeDatabase.memory());
    repository = DriftSnapshotRepository(db);
  });

  tearDown(() => db.close());

  test('a fresh database is empty', () async {
    expect(await repository.all(), isEmpty);
    expect(await repository.latest(), isNull);
  });

  test('saves a snapshot and reads it back unchanged', () async {
    final original = snapshotAt(DateTime(2026, 1, 15, 13, 7, 39), const {
      'Hacks': 78735,
      'Lifetime AP': 101542335,
      'OPR Live Events': 0,
    });

    final stored = await repository.save(original);
    expect(stored.id, isNotEmpty);

    final all = await repository.all();
    expect(all, hasLength(1));

    final read = all.single.snapshot;
    expect(read.agentName, original.agentName);
    expect(read.faction, original.faction);
    expect(read.timeSpan, original.timeSpan);
    expect(read.recordedAt, original.recordedAt);
    expect(read.level, original.level);
    expect(read.counters, equals(original.counters));
  });

  test('keeps zero valued counters', () async {
    await repository
        .save(snapshotAt(DateTime(2026, 1, 15), const {'Seer Points': 0}));

    final read = (await repository.all()).single.snapshot;
    expect(read.counters['Seer Points'], 0);
    expect(read.counters.containsKey('Seer Points'), isTrue);
  });

  test('every snapshot gets a distinct identifier', () async {
    final a = await repository
        .save(snapshotAt(DateTime(2026, 1, 1), const {'Hacks': 1}));
    final b = await repository
        .save(snapshotAt(DateTime(2026, 1, 2), const {'Hacks': 2}));

    expect(a.id, isNot(b.id));
  });

  test('sorts most recent first, whatever the insertion order', () async {
    await repository
        .save(snapshotAt(DateTime(2026, 1, 10), const {'Hacks': 10}));
    await repository
        .save(snapshotAt(DateTime(2026, 1, 30), const {'Hacks': 30}));
    await repository
        .save(snapshotAt(DateTime(2026, 1, 20), const {'Hacks': 20}));

    final dates = (await repository.all()).map((s) => s.snapshot.recordedAt);
    expect(dates, [
      DateTime(2026, 1, 30),
      DateTime(2026, 1, 20),
      DateTime(2026, 1, 10),
    ]);
  });

  test('latest() returns the newest by snapshot date', () async {
    // Deliberately inserted last while being the oldest: what matters to the
    // guard is the snapshot date, not the import order.
    await repository
        .save(snapshotAt(DateTime(2026, 1, 30), const {'Hacks': 30}));
    await repository
        .save(snapshotAt(DateTime(2026, 1, 10), const {'Hacks': 10}));

    final latest = await repository.latest();
    expect(latest!.snapshot.recordedAt, DateTime(2026, 1, 30));
    expect(latest.snapshot.counters['Hacks'], 30);
  });

  test('deleting a snapshot takes its counters with it', () async {
    final stored = await repository
        .save(snapshotAt(DateTime(2026, 1, 15), const {'Hacks': 1}));

    await repository.delete(stored.id);

    expect(await repository.all(), isEmpty);
    // Without `PRAGMA foreign_keys = ON`, the values would be left orphaned.
    expect(await db.select(db.counterValues).get(), isEmpty);
  });

  test('two snapshots do not mix their counters', () async {
    await repository.save(snapshotAt(DateTime(2026, 1, 1), const {'Hacks': 10}));
    await repository.save(
      snapshotAt(DateTime(2026, 1, 2), const {'Hacks': 20, 'Orion Tokens': 5}),
    );

    final all = await repository.all();
    expect(all.first.snapshot.counters, {'Hacks': 20, 'Orion Tokens': 5});
    expect(all.last.snapshot.counters, {'Hacks': 10});
  });

  test('the reactive stream emits after every write', () async {
    final emissions = <int>[];
    final subscription =
        repository.watchAll().listen((list) => emissions.add(list.length));

    await repository.save(snapshotAt(DateTime(2026, 1, 1), const {'Hacks': 1}));
    await repository.save(snapshotAt(DateTime(2026, 1, 2), const {'Hacks': 2}));
    await Future<void>.delayed(Duration.zero);

    await subscription.cancel();
    expect(emissions.last, 2);
  });

  test('a stored partial period stays identifiable', () async {
    // If the user overrides a guard, the snapshot must keep a record of what
    // it was: we do not rewrite history.
    await repository.save(StatSnapshot(
      timeSpan: TimeSpan.week,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: DateTime(2026, 1, 15),
      level: 9,
      counters: const {'Hacks': 40},
    ));

    expect((await repository.all()).single.snapshot.timeSpan, TimeSpan.week);
  });
}
