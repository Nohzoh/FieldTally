import 'package:intl/intl.dart';

import '../data/notifications/notification_service.dart';
import '../domain/models/counter_registry.dart';
import '../domain/models/stat_snapshot.dart';
import '../domain/notifications.dart';
import '../domain/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'tier_labels.dart';

/// Turns the decisions of `domain/notifications.dart` into actual
/// notifications (§3.7).
///
/// Sits in the presentation layer because it phrases things: the domain knows
/// *whether* a tier was crossed, this knows how to say so, and in which
/// language.
class NotificationCoordinator {
  const NotificationCoordinator({
    required this.service,
    required this.settings,
    this.detector = const TierCrossingDetector(),
  });

  final NotificationService service;
  final SettingsRepository settings;
  final TierCrossingDetector detector;

  /// How many milestone notifications to post at once.
  ///
  /// A long-delayed import can cross a dozen tiers, and a dozen notifications
  /// is not a celebration, it is a mess. The rest are summarised into one.
  static const maxMilestones = 3;

  /// Off until switched on. Android 13 and later grant the notification
  /// permission to nobody by default, so defaulting to "on" would promise
  /// reminders the system would never deliver.
  Future<bool> isEnabled() async =>
      await settings.read(SettingKeys.notifications) == 'true';

  Future<void> setEnabled(bool enabled) async {
    await settings.write(SettingKeys.notifications, enabled ? 'true' : 'false');
    if (!enabled) await service.cancelReminder();
  }

  Future<int> reminderDays() async {
    final raw = await settings.read(SettingKeys.reminderDays);
    return int.tryParse(raw ?? '') ?? 7;
  }

  Future<void> setReminderDays(int days) =>
      settings.write(SettingKeys.reminderDays, '$days');

  /// Re-arms the "nothing recorded lately" reminder.
  ///
  /// Called after every change to the history, because the reminder is always
  /// relative to the newest snapshot: saving one should push the nudge back,
  /// not leave yesterday's schedule standing.
  Future<void> rescheduleReminder({
    required DateTime? latestSnapshot,
    required AppLocalizations l10n,
    DateTime? now,
  }) async {
    if (!await isEnabled()) {
      await service.cancelReminder();
      return;
    }

    final days = await reminderDays();
    final at = ReminderPlanner(
      after: Duration(days: days),
    ).nextReminder(latestSnapshot: latestSnapshot, now: now ?? DateTime.now());

    if (at == null) {
      await service.cancelReminder();
      return;
    }

    await service.scheduleReminder(
      at: at,
      title: l10n.notificationReminderTitle,
      body: l10n.notificationReminderBody(days),
    );
  }

  /// Announces any badge tier the new snapshot crossed.
  Future<void> announceMilestones({
    required StatSnapshot current,
    required StatSnapshot? previous,
    required CounterRegistry registry,
    required AppLocalizations l10n,
    required String language,
  }) async {
    if (!await isEnabled()) return;

    final crossings = detector.crossings(
      current: current,
      previous: previous,
      registry: registry,
    );
    if (crossings.isEmpty) return;

    final numbers = NumberFormat.decimalPattern(language);
    final shown = crossings.take(maxMilestones).toList();
    for (var i = 0; i < shown.length; i++) {
      final crossing = shown[i];
      final label =
          registry.forExportHeader(crossing.exportHeader)?.label(language) ??
          crossing.exportHeader;

      final extra = crossings.length - maxMilestones;
      final isLast = i == shown.length - 1;

      await service.show(
        id: PluginNotificationService.milestoneBaseId + i,
        title: l10n.notificationMilestoneTitle(
          tierLabel(l10n, crossing.tier.name),
        ),
        body: isLast && extra > 0
            ? l10n.notificationMilestoneMore(label, extra)
            : l10n.notificationMilestoneBody(
                label,
                numbers.format(crossing.value),
              ),
      );
    }
  }
}
