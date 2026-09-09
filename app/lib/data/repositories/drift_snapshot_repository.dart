import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/stat_snapshot.dart';
import '../../domain/models/time_span.dart';
import '../../domain/repositories/snapshot_repository.dart';
import '../db/database.dart';

/// Implémentation Drift de [SnapshotRepository].
///
/// Toute la connaissance du schéma SQL s'arrête ici : au-dessus, on ne
/// manipule que des [StoredSnapshot].
class DriftSnapshotRepository implements SnapshotRepository {
  DriftSnapshotRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final FieldTallyDatabase _db;
  final Uuid _uuid;

  @override
  Future<List<StoredSnapshot>> all() async {
    final rows = await (_db.select(_db.snapshots)
          ..orderBy([(s) => OrderingTerm.desc(s.recordedAt)]))
        .get();
    return _hydrate(rows);
  }

  @override
  Future<StoredSnapshot?> latest() async {
    final row = await (_db.select(_db.snapshots)
          ..orderBy([(s) => OrderingTerm.desc(s.recordedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return (await _hydrate([row])).first;
  }

  @override
  Future<StoredSnapshot> save(StatSnapshot snapshot) async {
    final id = _uuid.v4();
    final importedAt = DateTime.now();

    // Le relevé et ses compteurs entrent ensemble ou pas du tout : un relevé
    // sans ses valeurs fausserait tous les calculs qui en dérivent.
    await _db.transaction(() async {
      await _db.into(_db.snapshots).insert(
            SnapshotsCompanion.insert(
              id: id,
              agentName: snapshot.agentName,
              faction: snapshot.faction,
              timeSpan: snapshot.timeSpan.name,
              recordedAt: snapshot.recordedAt,
              level: snapshot.level,
              importedAt: importedAt,
            ),
          );

      await _db.batch((batch) {
        batch.insertAll(_db.counterValues, [
          for (final entry in snapshot.counters.entries)
            CounterValuesCompanion.insert(
              snapshotId: id,
              exportHeader: entry.key,
              value: entry.value,
            ),
        ]);
      });
    });

    return StoredSnapshot(id: id, importedAt: importedAt, snapshot: snapshot);
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.snapshots)..where((s) => s.id.equals(id))).go();
  }

  @override
  Stream<List<StoredSnapshot>> watchAll() {
    return (_db.select(_db.snapshots)
          ..orderBy([(s) => OrderingTerm.desc(s.recordedAt)]))
        .watch()
        .asyncMap(_hydrate);
  }

  /// Recharge les compteurs de plusieurs relevés en une seule requête, pour
  /// éviter une requête par relevé quand l'historique grandit.
  Future<List<StoredSnapshot>> _hydrate(List<Snapshot> rows) async {
    if (rows.isEmpty) return const [];

    final ids = rows.map((r) => r.id).toList();
    final values = await (_db.select(_db.counterValues)
          ..where((c) => c.snapshotId.isIn(ids)))
        .get();

    final bySnapshot = <String, Map<String, int>>{};
    for (final value in values) {
      (bySnapshot[value.snapshotId] ??= {})[value.exportHeader] = value.value;
    }

    return [
      for (final row in rows)
        StoredSnapshot(
          id: row.id,
          importedAt: row.importedAt,
          snapshot: StatSnapshot(
            // Le nom de l'enum a été stocké tel quel ; une valeur devenue
            // inconnue après une mise à jour retombe sur `unknown`, ce qui est
            // le comportement prudent (§3.1.3).
            timeSpan: TimeSpan.values.firstWhere(
              (t) => t.name == row.timeSpan,
              orElse: () => TimeSpan.unknown,
            ),
            agentName: row.agentName,
            faction: row.faction,
            recordedAt: row.recordedAt,
            level: row.level,
            counters: bySnapshot[row.id] ?? const {},
          ),
        ),
    ];
  }
}
