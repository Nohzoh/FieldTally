import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/updates/play_update_service.dart';
import '../l10n/app_localizations.dart';
import 'home_widget_sync.dart';
import 'providers/providers.dart';

/// Work kicked off once when the app starts.
///
/// Five fire-and-forget tasks kicked off once: refreshing the counter
/// registry from GitHub Pages (§3.1.4), offering the newer version Play is
/// holding (#195), re-arming the "nothing recorded lately" reminder (§3.7),
/// the one-time widget-selection migration, and the removed-instance cleanup
/// below (#181). Nothing on screen waits for them, and they fail silently,
/// because none is worth delaying a frame or showing an error over.
///
/// A sixth task is not fire-once but standing: keeping every placed home
/// screen widget instance in step with the history (#154, #181). That one is
/// a `ref.listen` in [build] rather than a post-frame callback, because it
/// has to fire again on every later change too, not just at launch.
class StartupTasks extends ConsumerStatefulWidget {
  const StartupTasks({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StartupTasks> createState() => _StartupTasksState();
}

class _StartupTasksState extends ConsumerState<StartupTasks> {
  @override
  void initState() {
    super.initState();
    // After the first frame: the registry the app starts with is the local
    // one, and swapping it mid-build would be a wasted rebuild at best.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(counterRegistryProvider.notifier).refreshFromNetwork(),
      );
      unawaited(_offerPlayUpdate());
      unawaited(_armReminder());
      unawaited(_migrateLegacyWidgetSelection());
      unawaited(_cleanUpRemovedWidgetInstances());
    });
  }

  /// Offers the newer version Play already has (#195).
  ///
  /// Three steps, and the app owns only the last one: Play asks, Play
  /// downloads in the background, and the app says one line when the file is
  /// there, because installing is the single step Android will not take
  /// unasked. Nothing is shown at any other moment, and nothing is shown at
  /// all in the ordinary case, which is that the running version is the
  /// newest one.
  ///
  /// Asked again on the next launch if it is declined, and not remembered in
  /// between: a preference row for something Play already re-asks in its own
  /// way would be a second switch governing the same decision.
  Future<void> _offerPlayUpdate() async {
    final service = ref.read(playUpdateServiceProvider);

    final update = await service.check();
    if (update == PlayUpdate.none) return;
    if (update == PlayUpdate.available && !await service.download()) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // A banner rather than a snack bar: this one waits for an answer, and a
    // line that vanishes after four seconds is one nobody reading their
    // dashboard would catch.
    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(l10n.updateDownloaded),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: Text(l10n.updateLater),
          ),
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              unawaited(service.install());
            },
            child: Text(l10n.updateRestart),
          ),
        ],
      ),
    );
  }

  /// The reminder is relative to the newest snapshot, so it is re-armed on
  /// every launch: a device that was off when it should have fired, or a
  /// history changed elsewhere, would otherwise leave a stale schedule.
  ///
  /// Deliberately does not ask for the notification permission — that belongs
  /// to the moment the agent switches reminders on in Settings, not to a cold
  /// start.
  Future<void> _armReminder() async {
    try {
      final l10n = AppLocalizations.of(context);
      final coordinator = ref.read(notificationCoordinatorProvider);
      if (!await coordinator.isEnabled()) return;

      final latest = await ref.read(snapshotRepositoryProvider).latest();
      if (!mounted) return;

      await coordinator.rescheduleReminder(
        latestSnapshot: latest?.snapshot.recordedAt,
        l10n: l10n,
      );
    } catch (_) {
      // Silent by design: a reminder that could not be scheduled is not worth
      // interrupting anyone over.
    }
  }

  /// One-time upgrade step (#181). Before #181 the widget had a single
  /// selection shared by every instance, in what is now the legacy
  /// `widget_pinned_counters` table. Copies it into any already-placed
  /// instance that has no per-instance configuration of its own yet, then
  /// clears the legacy table so this does not run again.
  ///
  /// A schema migration cannot do this itself: knowing which `appWidgetId`s
  /// currently exist means asking Android, and a `MigrationStrategy` callback
  /// has no platform channel to ask it with.
  Future<void> _migrateLegacyWidgetSelection() async {
    try {
      final db = ref.read(databaseProvider);
      final legacyRows = await (db.select(
        db.widgetPinnedCounters,
      )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
      if (legacyRows.isEmpty) return;

      final legacy = [for (final row in legacyRows) row.exportHeader];
      final ids = await ref.read(homeWidgetGatewayProvider).instanceIds();
      final perInstance = ref.read(widgetInstanceCounterRepositoryProvider);

      var migratedAny = false;
      for (final id in ids) {
        if ((await perInstance.pinnedFor(id)).isEmpty) {
          await perInstance.setPinnedFor(id, legacy);
          migratedAny = true;
        }
      }

      await db.delete(db.widgetPinnedCounters).go();

      // The per-instance change above is not itself observed by anything
      // that would trigger a widget refresh — `_syncHomeWidget` only reacts
      // to the history, not to the selection — so without this an instance
      // that just inherited the old selection would show it only once the
      // history next changes.
      if (migratedAny && mounted) await _writeHomeWidget();
    } catch (_) {
      // Silent by design, like the rest of this file: a migration that could
      // not run leaves an upgrading install exactly as unconfigured as a
      // fresh one, rather than broken.
    }
  }

  /// Drops any instance's rows once it is no longer on a home screen (#181)
  /// — otherwise the per-instance table only ever grows, one orphaned
  /// configuration per widget ever removed.
  ///
  /// Reconciled once per launch against whatever Android currently reports,
  /// rather than a native `AppWidgetProvider.onDeleted` override reacting to
  /// the removal itself: that callback runs from a `BroadcastReceiver` with
  /// no Flutter engine guaranteed alive to reach this database from, and an
  /// orphaned row is otherwise harmless — nothing reads the table except by
  /// `appWidgetId`, and `_writeHomeWidget` already only ever writes the
  /// instances Android currently reports. The trade-off is a removed
  /// instance's rows outliving it until the app's next launch, which costs
  /// nothing anyone would notice.
  Future<void> _cleanUpRemovedWidgetInstances() async {
    try {
      final placedIds =
          (await ref.read(homeWidgetGatewayProvider).instanceIds()).toSet();
      final db = ref.read(databaseProvider);
      final configuredIds = {
        for (final row in await db.select(db.widgetInstanceCounters).get())
          row.appWidgetId,
      };

      final repository = ref.read(widgetInstanceCounterRepositoryProvider);
      for (final id in configuredIds.difference(placedIds)) {
        await repository.deleteFor(id);
      }
    } catch (_) {
      // Silent by design, like the rest of this file: a cleanup that could
      // not run just leaves the table exactly as it was, not broken.
    }
  }

  /// Debounced by nothing but Riverpod itself: `snapshotsProvider` only
  /// emits when the underlying Drift query's result actually changes, so an
  /// edit that leaves every counter's value untouched does not trigger a
  /// rewrite.
  void _syncHomeWidget() {
    final snapshots = ref.read(snapshotsProvider);
    if (!snapshots.hasValue) return;

    unawaited(_writeHomeWidget());
  }

  /// Writes every currently-placed widget instance from its own selection
  /// (#181) — there is no single shared summary any more.
  ///
  /// Reads each instance's selection with a plain one-shot
  /// `pinnedFor` (inside [writeHomeWidgetInstance]) rather than watching
  /// `widgetInstanceCountersProvider` (a `StreamProvider.family`): this runs
  /// imperatively, not from a widget's `build`, so nothing would ever prompt
  /// a second read if the first one landed on that family provider's initial
  /// `AsyncLoading`.
  Future<void> _writeHomeWidget() async {
    try {
      final l10n = AppLocalizations.of(context);
      final languageCode = Localizations.localeOf(context).languageCode;
      final container = ProviderScope.containerOf(context, listen: false);
      final ids = await ref.read(homeWidgetGatewayProvider).instanceIds();
      if (!mounted || ids.isEmpty) return;

      for (final id in ids) {
        await writeHomeWidgetInstance(
          container,
          appWidgetId: id,
          l10n: l10n,
          languageCode: languageCode,
        );
      }
    } catch (_) {
      // Silent by design, like everything else here: a widget one refresh
      // behind is a stale home screen, not a broken app.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(snapshotsProvider, (_, _) => _syncHomeWidget());
    return widget.child;
  }
}
