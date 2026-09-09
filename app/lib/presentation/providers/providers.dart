import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/parsing/ingress_tsv_parser.dart';
import '../../data/registry/counter_registry_loader.dart';
import '../../data/repositories/drift_snapshot_repository.dart';
import '../../domain/guards/import_guards.dart';
import '../../domain/models/counter_registry.dart';
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
