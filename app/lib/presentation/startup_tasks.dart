import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'providers/providers.dart';

/// Work kicked off once when the app starts.
///
/// Two tasks: refreshing the counter registry from GitHub Pages (§3.1.4), and
/// re-arming the "nothing recorded lately" reminder (§3.7). Both are
/// deliberately fire-and-forget — nothing on screen waits for them, and they
/// fail silently, because neither is worth delaying a frame or showing an
/// error over.
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

  @override
  Widget build(BuildContext context) => widget.child;
}
