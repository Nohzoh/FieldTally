import 'package:drift/drift.dart';

import '../../domain/repositories/widget_pinned_counter_repository.dart';
import '../db/database.dart';

/// Drift implementation of [WidgetPinnedCounterRepository].
///
/// A copy of [DriftPinnedCounterRepository]'s shape, backed by its own table
/// — see [WidgetPinnedCounterRepository] for why the two stay separate.
class DriftWidgetPinnedCounterRepository
    implements WidgetPinnedCounterRepository {
  DriftWidgetPinnedCounterRepository(this._db);

  final FieldTallyDatabase _db;

  @override
  Future<List<String>> pinned() async => _headers(
    await (_db.select(
      _db.widgetPinnedCounters,
    )..orderBy([(p) => OrderingTerm.asc(p.position)])).get(),
  );

  @override
  Stream<List<String>> watchPinned() => (_db.select(
    _db.widgetPinnedCounters,
  )..orderBy([(p) => OrderingTerm.asc(p.position)])).watch().map(_headers);

  @override
  Future<void> setPinned(List<String> exportHeaders) async {
    // Replace wholesale inside one transaction: a half-applied selection would
    // leave the widget in a state the user never asked for.
    await _db.transaction(() async {
      await _db.delete(_db.widgetPinnedCounters).go();
      await _db.batch((batch) {
        batch.insertAll(_db.widgetPinnedCounters, [
          for (var i = 0; i < exportHeaders.length; i++)
            WidgetPinnedCountersCompanion.insert(
              exportHeader: exportHeaders[i],
              position: i,
            ),
        ]);
      });
    });
  }

  List<String> _headers(List<WidgetPinnedCounter> rows) => [
    for (final row in rows) row.exportHeader,
  ];
}
