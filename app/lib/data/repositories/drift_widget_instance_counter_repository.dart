import 'package:drift/drift.dart';

import '../../domain/repositories/widget_instance_counter_repository.dart';
import '../db/database.dart';

/// Drift implementation of [WidgetInstanceCounterRepository].
class DriftWidgetInstanceCounterRepository
    implements WidgetInstanceCounterRepository {
  DriftWidgetInstanceCounterRepository(this._db);

  final FieldTallyDatabase _db;

  @override
  Future<List<String>> pinnedFor(int appWidgetId) async =>
      _headers(await _query(appWidgetId).get());

  @override
  Stream<List<String>> watchPinnedFor(int appWidgetId) =>
      _query(appWidgetId).watch().map(_headers);

  @override
  Future<void> setPinnedFor(int appWidgetId, List<String> exportHeaders) async {
    // Replace wholesale inside one transaction: a half-applied selection
    // would leave this instance in a state the user never asked for.
    await _db.transaction(() async {
      await (_db.delete(
        _db.widgetInstanceCounters,
      )..where((t) => t.appWidgetId.equals(appWidgetId))).go();
      await _db.batch((batch) {
        batch.insertAll(_db.widgetInstanceCounters, [
          for (var i = 0; i < exportHeaders.length; i++)
            WidgetInstanceCountersCompanion.insert(
              appWidgetId: appWidgetId,
              exportHeader: exportHeaders[i],
              position: i,
            ),
        ]);
      });
    });
  }

  @override
  Future<void> deleteFor(int appWidgetId) => (_db.delete(
    _db.widgetInstanceCounters,
  )..where((t) => t.appWidgetId.equals(appWidgetId))).go();

  SimpleSelectStatement<$WidgetInstanceCountersTable, WidgetInstanceCounter>
  _query(int appWidgetId) => _db.select(_db.widgetInstanceCounters)
    ..where((t) => t.appWidgetId.equals(appWidgetId))
    ..orderBy([(t) => OrderingTerm.asc(t.position)]);

  List<String> _headers(List<WidgetInstanceCounter> rows) => [
    for (final row in rows) row.exportHeader,
  ];
}
