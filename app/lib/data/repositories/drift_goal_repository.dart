import 'package:drift/drift.dart';

import '../../domain/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../db/database.dart';

class DriftGoalRepository implements GoalRepository {
  DriftGoalRepository(this._db);

  final FieldTallyDatabase _db;

  @override
  Future<List<Goal>> all() async => _map(
        await (_db.select(_db.goals)
              ..orderBy([(g) => OrderingTerm.asc(g.createdAt)]))
            .get(),
      );

  @override
  Future<Goal?> forCounter(String exportHeader) async {
    final row = await (_db.select(_db.goals)
          ..where((g) => g.exportHeader.equals(exportHeader)))
        .getSingleOrNull();
    return row == null ? null : _one(row);
  }

  @override
  Stream<List<Goal>> watchAll() => (_db.select(_db.goals)
        ..orderBy([(g) => OrderingTerm.asc(g.createdAt)]))
      .watch()
      .map(_map);

  @override
  Future<void> set(Goal goal) async {
    await _db.into(_db.goals).insertOnConflictUpdate(
          GoalsCompanion.insert(
            exportHeader: goal.exportHeader,
            target: goal.target,
            deadline: Value(goal.deadline),
            createdAt: goal.createdAt,
          ),
        );
  }

  @override
  Future<void> remove(String exportHeader) async {
    await (_db.delete(_db.goals)
          ..where((g) => g.exportHeader.equals(exportHeader)))
        .go();
  }

  List<Goal> _map(List<GoalRow> rows) => [for (final row in rows) _one(row)];

  Goal _one(GoalRow row) => Goal(
        exportHeader: row.exportHeader,
        target: row.target,
        deadline: row.deadline,
        createdAt: row.createdAt,
      );
}
