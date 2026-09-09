import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/parsing/ingress_tsv_parser.dart';
import '../../data/registry/counter_registry_loader.dart';
import '../../data/repositories/drift_snapshot_repository.dart';
import '../../data/sharing/incoming_share.dart';
import '../../domain/counter_list.dart';
import '../../domain/guards/import_guards.dart';
import '../../domain/models/counter_registry.dart';
import '../../domain/models/tracked_counter.dart';
import '../../domain/repositories/snapshot_repository.dart';

/// Local database. Overridden with an in-memory one in tests.
final databaseProvider = Provider<FieldTallyDatabase>((ref) {
  final db = FieldTallyDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Screens depend on this interface only, never on Drift (§5.2).
final snapshotRepositoryProvider = Provider<SnapshotRepository>(
  (ref) => DriftSnapshotRepository(ref.watch(databaseProvider)),
);

final parserProvider = Provider((ref) => const IngressTsvParser());

/// Text shared into the app from Ingress (§3.1). Overridden in tests, where no
/// real Android share can be produced.
final incomingShareProvider = Provider<IncomingShareSource>(
  (ref) => const PluginIncomingShareSource(),
);

final importGuardsProvider = Provider((ref) => const ImportGuards());

/// Counter enrichment registry (§3.1.2).
///
/// Cannot fail: the loader falls back to an empty registry if the bundled copy
/// is unreadable, in which case every counter shows under its raw label.
/// Degraded, but never blocking.
final counterRegistryProvider = FutureProvider<CounterRegistry>(
  (ref) => const CounterRegistryLoader().loadSeed(),
);

/// Snapshot history, refreshed on its own after every write.
final snapshotsProvider = StreamProvider<List<StoredSnapshot>>(
  (ref) => ref.watch(snapshotRepositoryProvider).watchAll(),
);

/// Counter state derived from the whole history (§3.1.2, §3.2).
///
/// Recomputed from the snapshots rather than stored, so it stays correct when
/// a snapshot is edited or deleted.
final trackedCountersProvider = Provider<AsyncValue<List<TrackedCounter>>>(
  (ref) => ref.watch(snapshotsProvider).whenData(
        (stored) => const CounterTracker()
            .track([for (final s in stored) s.snapshot]),
      ),
);

/// What the counter list is currently filtered and sorted by (§3.4).
class CounterQueryNotifier extends Notifier<CounterQuery> {
  @override
  CounterQuery build() => const CounterQuery();

  void search(String value) => state = state.copyWith(search: value);

  void sortBy(CounterSort sort) => state = state.copyWith(sort: sort);

  void showInactive(bool value) =>
      state = state.copyWith(includeInactive: value);
}

final counterQueryProvider =
    NotifierProvider<CounterQueryNotifier, CounterQuery>(
  CounterQueryNotifier.new,
);
