import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/repositories/drift_snapshot_repository.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

StatSnapshot snapshotAt(DateTime date, Map<String, int> counters) => StatSnapshot(
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

  test('une base neuve est vide', () async {
    expect(await repository.all(), isEmpty);
    expect(await repository.latest(), isNull);
  });

  test('enregistre un relevé et le relit à l\'identique', () async {
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

  test('conserve les compteurs à zéro', () async {
    await repository.save(snapshotAt(DateTime(2026, 1, 15), const {'Seer Points': 0}));

    final read = (await repository.all()).single.snapshot;
    expect(read.counters['Seer Points'], 0);
    expect(read.counters.containsKey('Seer Points'), isTrue);
  });

  test('chaque relevé reçoit un identifiant distinct', () async {
    final a = await repository.save(snapshotAt(DateTime(2026, 1, 1), const {'Hacks': 1}));
    final b = await repository.save(snapshotAt(DateTime(2026, 1, 2), const {'Hacks': 2}));

    expect(a.id, isNot(b.id));
  });

  test('trie du plus récent au plus ancien, quel que soit l\'ordre d\'insertion',
      () async {
    await repository.save(snapshotAt(DateTime(2026, 1, 10), const {'Hacks': 10}));
    await repository.save(snapshotAt(DateTime(2026, 1, 30), const {'Hacks': 30}));
    await repository.save(snapshotAt(DateTime(2026, 1, 20), const {'Hacks': 20}));

    final dates = (await repository.all()).map((s) => s.snapshot.recordedAt);
    expect(dates, [
      DateTime(2026, 1, 30),
      DateTime(2026, 1, 20),
      DateTime(2026, 1, 10),
    ]);
  });

  test('latest() renvoie le relevé le plus récent par date de relevé', () async {
    // Volontairement inséré en dernier alors qu'il est le plus ancien : c'est
    // la date du relevé qui compte pour le garde-fou, pas l'ordre d'import.
    await repository.save(snapshotAt(DateTime(2026, 1, 30), const {'Hacks': 30}));
    await repository.save(snapshotAt(DateTime(2026, 1, 10), const {'Hacks': 10}));

    final latest = await repository.latest();
    expect(latest!.snapshot.recordedAt, DateTime(2026, 1, 30));
    expect(latest.snapshot.counters['Hacks'], 30);
  });

  test('supprimer un relevé emporte ses compteurs', () async {
    final stored =
        await repository.save(snapshotAt(DateTime(2026, 1, 15), const {'Hacks': 1}));

    await repository.delete(stored.id);

    expect(await repository.all(), isEmpty);
    // Sans `PRAGMA foreign_keys = ON`, les valeurs resteraient orphelines.
    expect(await db.select(db.counterValues).get(), isEmpty);
  });

  test('deux relevés ne mélangent pas leurs compteurs', () async {
    await repository.save(snapshotAt(DateTime(2026, 1, 1), const {'Hacks': 10}));
    await repository.save(
        snapshotAt(DateTime(2026, 1, 2), const {'Hacks': 20, 'Orion Tokens': 5}));

    final all = await repository.all();
    expect(all.first.snapshot.counters, {'Hacks': 20, 'Orion Tokens': 5});
    expect(all.last.snapshot.counters, {'Hacks': 10});
  });

  test('le flux réactif émet après chaque écriture', () async {
    final emissions = <int>[];
    final subscription =
        repository.watchAll().listen((list) => emissions.add(list.length));

    await repository.save(snapshotAt(DateTime(2026, 1, 1), const {'Hacks': 1}));
    await repository.save(snapshotAt(DateTime(2026, 1, 2), const {'Hacks': 2}));
    await Future<void>.delayed(Duration.zero);

    await subscription.cancel();
    expect(emissions.last, 2);
  });

  test('une période partielle enregistrée reste identifiable', () async {
    // Si l'utilisateur passe outre un garde-fou, le relevé doit garder la
    // trace de ce qu'il était : on ne réécrit pas l'histoire.
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
