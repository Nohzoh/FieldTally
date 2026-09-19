import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/build_info.dart';
import '../../data/changelog/changelog_service.dart';
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
import '../../domain/counter_pace.dart';
import '../../domain/counter_series.dart';
import '../../domain/dashboard.dart';
import '../../domain/guards/import_guards.dart';
import '../../domain/models/changelog_release.dart';
import '../../domain/models/counter_registry.dart';
import '../../domain/models/tracked_counter.dart';
import '../../domain/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/pinned_counter_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/snapshot_repository.dart';
import '../../data/updates/update_check_service.dart';
import '../../domain/badges_within_reach.dart';
import '../../domain/pace_change.dart';
import '../../domain/share_card.dart';
import '../../domain/snapshot_changes.dart';
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
  (ref) =>
      CounterRegistryService(settings: ref.watch(settingsRepositoryProvider)),
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
    final refreshed = await ref.read(counterRegistryServiceProvider).refresh();

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

/// Counters the agent pinned that started or stopped moving (#149).
///
/// Empty is the ordinary answer and must stay cheap to render: most months
/// nothing has changed, and the dashboard shows nothing rather than a heading
/// over an empty space.
final paceChangesProvider = Provider<List<CounterShift>>((ref) {
  final snapshots = ref.watch(snapshotsProvider).asData?.value ?? const [];
  final pinned = ref.watch(pinnedCountersProvider).asData?.value ?? const [];

  return const PaceChangeFinder().find(
    snapshots: [for (final stored in snapshots) stored.snapshot],
    pinned: pinned,
  );
});

/// Asks the project site whether a newer release exists (#34).
final updateCheckServiceProvider = Provider<UpdateCheckService>(
  (ref) => UpdateCheckService(settings: ref.watch(settingsRepositoryProvider)),
);

/// The newer release to offer, or null — which is the normal case.
///
/// Reads the cache rather than the network, so Settings answers instantly and
/// answers the same offline. The refresh that fills that cache runs at startup
/// and at most once a day.
///
/// Watched rather than read once: the startup check can land while Settings is
/// already open, and a line that only appears after a restart would be a worse
/// answer than no line at all.
final availableUpdateProvider = FutureProvider<LatestRelease?>((ref) async {
  ref.watch(_cachedLatestReleaseProvider);

  final build = await ref.watch(buildInfoProvider.future);
  final installed = int.tryParse(build.build);
  if (installed == null) return null;

  return ref.watch(updateCheckServiceProvider).newerThan(installed);
});

/// Only there to make [availableUpdateProvider] recompute when the cached file
/// changes. Its value is deliberately unused — the service reads the row.
final _cachedLatestReleaseProvider = StreamProvider<String?>(
  (ref) =>
      ref.watch(settingsRepositoryProvider).watch(SettingKeys.latestRelease),
);

/// Badges the recent pace puts within reach, soonest first (#148).
///
/// Empty rather than absent when nothing qualifies: "no honest estimate" is a
/// normal state of this list, not a failure to load.
final withinReachProvider = Provider<List<ReachableBadge>>((ref) {
  final snapshots = ref.watch(snapshotsProvider).asData?.value ?? const [];
  final registry = ref.watch(counterRegistryProvider).asData?.value;

  return const WithinReachBuilder().build(
    snapshots: [for (final stored in snapshots) stored.snapshot],
    registry: registry,
  );
});

/// What one snapshot recorded that the one before it had not (#147).
///
/// Null when the id names the earliest snapshot, which has nothing before it —
/// and, for the same reason and with the same answer, when it names no
/// snapshot at all. The screen is reached by tapping a row, so an unknown id
/// is not a state an agent can arrive in.
///
/// Ordered here rather than trusting the repository's order: the pair is
/// "this snapshot and the one recorded before it", which is a fact about
/// `recordedAt` and not about the order rows came back in.
final snapshotChangesProvider = Provider.family<SnapshotChanges?, String>((
  ref,
  id,
) {
  final stored = ref.watch(snapshotsProvider).asData?.value ?? const [];
  final registry = ref.watch(counterRegistryProvider).asData?.value;

  final sorted = [...stored]
    ..sort((a, b) => a.snapshot.recordedAt.compareTo(b.snapshot.recordedAt));
  final index = sorted.indexWhere((s) => s.id == id);
  if (index <= 0) return null;

  return SnapshotChangesBuilder(
    registry: registry,
  ).between(earlier: sorted[index - 1].snapshot, later: sorted[index].snapshot);
});

/// Counter state derived from the whole history (§3.1.2, §3.2).
///
/// Recomputed from the snapshots rather than stored, so it stays correct when
/// a snapshot is edited or deleted.
final trackedCountersProvider = Provider<AsyncValue<List<TrackedCounter>>>(
  (ref) => ref
      .watch(snapshotsProvider)
      .whenData(
        (stored) =>
            const CounterTracker().track([for (final s in stored) s.snapshot]),
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

  void showMedalsOnly(bool value) => state = state.copyWith(medalsOnly: value);

  void measureOver(ProgressWindow window) =>
      state = state.copyWith(window: window);
}

final counterQueryProvider =
    NotifierProvider<CounterQueryNotifier, CounterQuery>(
      CounterQueryNotifier.new,
    );

/// Each counter's pace over the window the list is currently measuring (#89).
///
/// Derived from the whole history rather than from the tracked counters: a
/// window needs the value at a date, which a counter's last two values cannot
/// give.
final counterPaceProvider = Provider<Map<String, CounterPace>>((ref) {
  final window = ref.watch(counterQueryProvider).window;
  final snapshots = ref.watch(snapshotsProvider).asData?.value ?? const [];

  return paceByCounter([for (final s in snapshots) s.snapshot], window);
});

final pinnedCounterRepositoryProvider = Provider<PinnedCounterRepository>(
  (ref) => DriftPinnedCounterRepository(ref.watch(databaseProvider)),
);

/// Counters shown on the dashboard, falling back to the defaults until the
/// agent has picked their own (§3.3).
final pinnedCountersProvider = StreamProvider<List<String>>(
  (ref) => ref
      .watch(pinnedCounterRepositoryProvider)
      .watchPinned()
      .map(
        (pinned) => pinned.isEmpty ? PinnedCounterRepository.defaults : pinned,
      ),
);

/// The dashboard cards, rebuilt whenever the history or the selection changes.
final dashboardProvider = Provider<AsyncValue<List<DashboardCard>>>((ref) {
  final snapshots = ref.watch(snapshotsProvider);
  final pinned = ref.watch(pinnedCountersProvider);

  if (snapshots.isLoading || pinned.isLoading) {
    return const AsyncValue.loading();
  }

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

  if (snapshots.isLoading || pinned.isLoading) {
    return const AsyncValue.loading();
  }

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
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.themeMode)
      .map(
        (value) => switch (value) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
      ),
);

/// Language the agent chose, or null to follow the system (§3.10).
///
/// Null is the default and the interesting case: the app has two translations
/// and should use whichever the phone asks for, rather than imposing one.
final localeProvider = StreamProvider<Locale?>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.locale)
      .map((value) => value == null || value.isEmpty ? null : Locale(value)),
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
  (ref) =>
      ref.watch(snapshotsProvider).asData?.value.firstOrNull?.snapshot.faction,
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

final changelogServiceProvider = Provider<ChangelogService>(
  (ref) => ChangelogService(settings: ref.watch(settingsRepositoryProvider)),
);

/// Release notes introduced since this device last recorded a seen build
/// (§9). A one-shot check: it also records the running build as seen, so it
/// must only ever be read once per app session — the dashboard does that, on
/// its first frame.
final changelogCheckProvider = FutureProvider<List<ChangelogRelease>>((
  ref,
) async {
  final build = await ref.watch(buildInfoProvider.future);
  final versionCode = int.tryParse(build.build);
  if (versionCode == null) return const [];

  return ref.watch(changelogServiceProvider).checkForUpdate(versionCode);
});
