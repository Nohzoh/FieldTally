import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'providers/providers.dart';

/// Work kicked off once when the app starts.
///
/// Three fire-and-forget tasks kicked off once: refreshing the counter
/// registry from GitHub Pages (§3.1.4), asking the same site whether a newer
/// release exists (#34), and re-arming the "nothing recorded lately" reminder
/// (§3.7). Nothing on screen waits for them, and they fail silently, because
/// none is worth delaying a frame or showing an error over.
///
/// A fourth task is not fire-once but standing: keeping the home screen
/// widget in step with the history (#154). That one is a `ref.listen` in
/// [build] rather than a post-frame callback, because it has to fire again
/// on every later change too, not just at launch.
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
      // Its own preference is the registry's, and its own interval keeps this
      // to one request a day whatever an agent does with the app.
      unawaited(ref.read(updateCheckServiceProvider).refresh());
      unawaited(_armReminder());
    });
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

  /// Debounced by nothing but Riverpod itself: `snapshotsProvider` and
  /// `pinnedCountersProvider` only emit when the underlying Drift query's
  /// result actually changes, so an edit that leaves a pinned counter's value
  /// untouched does not trigger a rewrite.
  void _syncHomeWidget() {
    final snapshots = ref.read(snapshotsProvider);
    final pinned = ref.read(pinnedCountersProvider);
    if (!snapshots.hasValue || !pinned.hasValue) return;

    unawaited(_writeHomeWidget());
  }

  Future<void> _writeHomeWidget() async {
    try {
      final l10n = AppLocalizations.of(context);
      final locale = Localizations.localeOf(context);
      final summary = ref.read(homeWidgetSummaryProvider);
      final registry = ref.read(counterRegistryProvider).asData?.value;

      await ref
          .read(homeWidgetCoordinatorProvider)
          .sync(
            summary: summary,
            l10n: l10n,
            languageCode: locale.languageCode,
            registry: registry,
          );
    } catch (_) {
      // Silent by design, like everything else here: a widget one refresh
      // behind is a stale home screen, not a broken app.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(snapshotsProvider, (_, _) => _syncHomeWidget());
    ref.listen(pinnedCountersProvider, (_, _) => _syncHomeWidget());
    return widget.child;
  }
}
