import 'package:drift/drift.dart';

import '../../domain/repositories/pinned_counter_repository.dart';
import '../db/database.dart';

/// Drift implementation of [PinnedCounterRepository].
class DriftPinnedCounterRepository implements PinnedCounterRepository {
  DriftPinnedCounterRepository(this._db);

  final FieldTallyDatabase _db;

  @override
  Future<List<String>> pinned() async => _headers(
        await (_db.select(_db.pinnedCounters)
              ..orderBy([(p) => OrderingTerm.asc(p.position)]))
            .get(),
      );

  @override
  Stream<List<String>> watchPinned() => (_db.select(_db.pinnedCounters)
        ..orderBy([(p) => OrderingTerm.asc(p.position)]))
      .watch()
      .map(_headers);

  @override
  Future<void> setPinned(List<String> exportHeaders) async {
    // Replace wholesale inside one transaction: a half-applied selection would
    // leave the dashboard in a state the user never asked for.
    await _db.transaction(() async {
      await _db.delete(_db.pinnedCounters).go();
      await _db.batch((batch) {
        batch.insertAll(_db.pinnedCounters, [
          for (var i = 0; i < exportHeaders.length; i++)
            PinnedCountersCompanion.insert(
              exportHeader: exportHeaders[i],
              position: i,
            ),
        ]);
      });
    });
  }

  List<String> _headers(List<PinnedCounter> rows) =>
      [for (final row in rows) row.exportHeader];
}
