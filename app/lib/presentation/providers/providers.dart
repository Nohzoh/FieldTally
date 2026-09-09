import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/parsing/ingress_tsv_parser.dart';
import '../../data/registry/counter_registry_loader.dart';
import '../../data/repositories/drift_snapshot_repository.dart';
import '../../domain/guards/import_guards.dart';
import '../../domain/models/counter_registry.dart';
import '../../domain/repositories/snapshot_repository.dart';

/// Base locale. Surchargée dans les tests par une base en mémoire.
final databaseProvider = Provider<FieldTallyDatabase>((ref) {
  final db = FieldTallyDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Les écrans ne dépendent que de cette interface, jamais de Drift (§5.2).
final snapshotRepositoryProvider = Provider<SnapshotRepository>(
  (ref) => DriftSnapshotRepository(ref.watch(databaseProvider)),
);

final parserProvider = Provider((ref) => const IngressTsvParser());

final importGuardsProvider = Provider((ref) => const ImportGuards());

/// Registre d'enrichissement (§3.1.2).
///
/// Ne peut pas échouer : le chargeur retombe sur un registre vide si la copie
/// embarquée est illisible, auquel cas tous les compteurs s'affichent sous
/// leur libellé brut. Dégradé, mais jamais bloquant.
final counterRegistryProvider = FutureProvider<CounterRegistry>(
  (ref) => const CounterRegistryLoader().loadSeed(),
);

/// Historique des relevés, remis à jour tout seul après chaque écriture.
final snapshotsProvider = StreamProvider<List<StoredSnapshot>>(
  (ref) => ref.watch(snapshotRepositoryProvider).watchAll(),
);
