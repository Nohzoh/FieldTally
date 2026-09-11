import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/build_info.dart';
import '../../data/db/database.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/parsing/ingress_tsv_parser.dart';
import '../../data/registry/counter_registry_service.dart';
import '../../data/repositories/drift_goal_repository.dart';
import '../../data/repositories/drift_pinned_counter_repository.dart';
import '../../data/repositories/drift_settings_repository.dart';
import '../../data/repositories/drift_snapshot_repository.dart';
import '../../data/sharing/incoming_share.dart';
import '../../domain/counter_list.dart';
import '../../domain/counter_series.dart';
import '../../domain/dashboard.dart';
import '../../domain/guards/import_guards.dart';
import '../../domain/models/counter_registry.dart';
import '../../domain/models/tracked_counter.dart';
import '../../domain/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/pinned_counter_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/snapshot_repository.dart';
import '../../domain/share_card.dart';
import '../faction.dart';
import '../notification_coordinator.dart';

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

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => DriftGoalRepository(ref.watch(databaseProvider)),
);

/// Personal targets (§3.7), refreshed as they are set and removed.
final goalsProvider = StreamProvider<List<Goal>>(
  (ref) => ref.watch(goalRepositoryProvider).watchAll(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => PluginNotificationService(),
);

/// Phrases and posts the notifications of §3.7.
final notificationCoordinatorProvider = Provider<NotificationCoordinator>(
  (ref) => NotificationCoordinator(
    service: ref.watch(notificationServiceProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

/// Whether reminders and milestone alerts may be posted (§3.7). Absent means
/// off: Android 13 grants the permission to nobody by default, so anything
/// else would be a switch that claims more than the system allows.
final notificationsEnabledProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.notifications)
      .map((value) => value == 'true'),
);

/// Days without a snapshot before the reminder fires.
final reminderDaysProvider = StreamProvider<int>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.reminderDays)
      .map((value) => int.tryParse(value ?? '') ?? 7),
);

/// Period the shareable card covers (§3.8). Kept out of the screen so the
/// choice survives a rebuild, and so a test can set it without tapping.
class ShareCardRangeNotifier extends Notifier<ChartRange> {
  @override
  ChartRange build() => ChartRange.month;

  void set(ChartRange range) => state = range;
}

final shareCardRangeProvider =
    NotifierProvider<ShareCardRangeNotifier, ChartRange>(
  ShareCardRangeNotifier.new,
);

/// The card itself, rebuilt when the history, the pinned selection or the
/// chosen period changes. Null inside the data means there is nothing to show.
final shareCardProvider = Provider<AsyncValue<ShareCardData?>>((ref) {
  final snapshots = ref.watch(snapshotsProvider);
  final pinned = ref.watch(pinnedCountersProvider);

  if (snapshots.isLoading || pinned.isLoading) return const AsyncValue.loading();

  return snapshots.whenData(
    (stored) => const ShareCardBuilder().build(
      snapshots: [for (final s in stored) s.snapshot],
      pinned: pinned.asData?.value ?? const [],
      range: ref.watch(shareCardRangeProvider),
    ),
  );
});

/// How the app follows or overrides the system theme (§3.9).
final themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(SettingKeys.themeMode).map(
        (value) => switch (value) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
      ),
);

/// Whether the app is tinted with the agent's faction colour (§3.9).
final factionColoursProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.factionColours)
      .map((value) => value == 'true'),
);

/// The faction the newest snapshot reported, or null before any import.
///
/// Read from the history rather than stored as a preference: an agent who
/// changed faction re-imports, and the app should follow rather than keep
/// painting the old one.
final currentFactionProvider = Provider<String?>(
  (ref) => ref.watch(snapshotsProvider).asData?.value.firstOrNull?.snapshot.faction,
);

/// Colour the whole app is generated from (§3.9).
///
/// Teal is the app's own; the faction colour only takes over when the agent
/// asked for it and a snapshot says which faction they are.
final themeSeedProvider = Provider<Color>((ref) {
  final wanted = ref.watch(factionColoursProvider).asData?.value ?? false;
  if (!wanted) return Colors.teal;

  final faction = ref.watch(currentFactionProvider);
  return (faction == null ? null : factionColour(faction)) ?? Colors.teal;
});

/// Which build is running, for a bug report that can be acted on.
final buildInfoProvider = FutureProvider<BuildInfo>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return BuildInfo(
    version: info.version,
    build: info.buildNumber,
    commit: BuildInfo.commitFromEnvironment,
  );
});
