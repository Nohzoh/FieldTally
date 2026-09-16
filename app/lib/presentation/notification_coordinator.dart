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
    this.detector = const MilestoneDetector(),
  });

  final NotificationService service;
  final SettingsRepository settings;
  final MilestoneDetector detector;

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

  /// Announces what the new snapshot achieved.
  ///
  /// A level, badge tiers, and further multiples of a top tier — in that
  /// order, because the level is the one an agent asks about.
  Future<void> announceMilestones({
    required StatSnapshot current,
    required StatSnapshot? previous,
    required CounterRegistry registry,
    required AppLocalizations l10n,
    required String language,
  }) async {
    if (!await isEnabled()) return;

    final found = detector.since(
      current: current,
      previous: previous,
      registry: registry,
    );
    if (found.isEmpty) return;

    final numbers = NumberFormat.decimalPattern(language);
    final shown = found.take(maxMilestones).toList();
    final extra = found.length - maxMilestones;

    for (var i = 0; i < shown.length; i++) {
      final milestone = shown[i];
      final isLast = i == shown.length - 1;

      // The overflow line replaces the body of the last one shown, so the
      // count of what was left out is read exactly once.
      final summarised = isLast && extra > 0;

      await service.show(
        id: PluginNotificationService.milestoneBaseId + i,
        title: _title(milestone, l10n, language, registry),
        body: summarised
            ? l10n.notificationMilestoneMore(
                _label(milestone, language, registry),
                extra,
              )
            : _body(milestone, l10n, numbers),
      );
    }
  }

  String _title(
    Milestone milestone,
    AppLocalizations l10n,
    String language,
    CounterRegistry registry,
  ) => switch (milestone) {
    LevelReached(:final level) => l10n.notificationLevelTitle(level),
    TierReached(:final tier) => l10n.notificationMilestoneTitle(
      _label(milestone, language, registry),
      tierLabel(l10n, tier.name),
    ),
    MultipleReached(:final tier, :final multiple) =>
      l10n.notificationMultipleTitle(
        tierLabel(l10n, tier.name),
        multiple,
        _label(milestone, language, registry),
      ),
  };

  String _body(
    Milestone milestone,
    AppLocalizations l10n,
    NumberFormat numbers,
  ) => switch (milestone) {
    LevelReached() => l10n.notificationLevelBody,
    TierReached(:final value) || MultipleReached(:final value) =>
      l10n.notificationMilestoneBody(numbers.format(value)),
  };

  /// The counter's own name, for the surfaces that need it.
  String _label(
    Milestone milestone,
    String language,
    CounterRegistry registry,
  ) => switch (milestone) {
    LevelReached() => '',
    TierReached(:final exportHeader) || MultipleReached(:final exportHeader) =>
      registry.forExportHeader(exportHeader)?.label(language) ?? exportHeader,
  };
}
