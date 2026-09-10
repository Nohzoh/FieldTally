import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/parsing/ingress_tsv_parser.dart';
import '../../data/registry/counter_registry_service.dart';
import '../../data/repositories/drift_pinned_counter_repository.dart';
import '../../data/repositories/drift_settings_repository.dart';
import '../../data/repositories/drift_snapshot_repository.dart';
import '../../data/sharing/incoming_share.dart';
import '../../domain/counter_list.dart';
import '../../domain/dashboard.dart';
import '../../domain/guards/import_guards.dart';
import '../../domain/models/counter_registry.dart';
import '../../domain/models/tracked_counter.dart';
import '../../domain/repositories/pinned_counter_repository.dart';
import '../../domain/repositories/settings_repository.dart';
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

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(databaseProvider)),
);

final counterRegistryServiceProvider = Provider<CounterRegistryService>(
  (ref) => CounterRegistryService(
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

/// Counter enrichment registry (§3.1.2, §3.1.4).
///
/// Resolves from what is already on the device — the cached copy, or the one
/// bundled at build time. **It never waits on the network**: §3.1.4 makes the
/// fetch a progressive enhancement, so a slow or absent connection must not
/// delay the first frame.
///
/// The refresh is a startup task rather than something [build] fires off, so
/// that building the provider stays free of side effects and a test only
/// touches the network when it means to.
///
/// Cannot fail: a registry that cannot be read only degrades the display,
/// every counter falling back to its raw export label.
class CounterRegistryNotifier extends AsyncNotifier<CounterRegistry> {
  @override
  Future<CounterRegistry> build() =>
      ref.watch(counterRegistryServiceProvider).load();

  /// Fetches a newer registry if the preference allows it and enough time has
  /// passed. Swallows every failure; call it and forget it.
  Future<void> refreshFromNetwork() async {
    final current = state.asData?.value;
    final refreshed =
        await ref.read(counterRegistryServiceProvider).refresh();

    // Only swap when the fetch actually brought something new, so the UI does
    // not rebuild for nothing on every launch.
    if (current == null || refreshed.updatedAt != current.updatedAt) {
      state = AsyncData(refreshed);
    }
  }
}

final counterRegistryProvider =
    AsyncNotifierProvider<CounterRegistryNotifier, CounterRegistry>(
  CounterRegistryNotifier.new,
);

/// Whether the registry may be refreshed over the network (§3.1.4).
/// Absent means enabled, which is the documented default.
final onlineRegistryUpdatesProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.onlineRegistryUpdates)
      .map((value) => value != 'false'),
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

final pinnedCounterRepositoryProvider = Provider<PinnedCounterRepository>(
  (ref) => DriftPinnedCounterRepository(ref.watch(databaseProvider)),
);

/// Counters shown on the dashboard, falling back to the defaults until the
/// agent has picked their own (§3.3).
final pinnedCountersProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(pinnedCounterRepositoryProvider).watchPinned().map(
        (pinned) =>
            pinned.isEmpty ? PinnedCounterRepository.defaults : pinned,
      ),
);

/// The dashboard cards, rebuilt whenever the history or the selection changes.
final dashboardProvider = Provider<AsyncValue<List<DashboardCard>>>((ref) {
  final snapshots = ref.watch(snapshotsProvider);
  final pinned = ref.watch(pinnedCountersProvider);

  if (snapshots.isLoading || pinned.isLoading) return const AsyncValue.loading();

  return snapshots.whenData(
    (stored) => const DashboardBuilder().build(
      snapshots: [for (final s in stored) s.snapshot],
      pinned: pinned.asData?.value ?? const [],
    ),
  );
});
