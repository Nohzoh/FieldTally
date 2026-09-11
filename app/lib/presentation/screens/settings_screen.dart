import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';

/// Preferences (§3.1.4, §3.7, §3.9).
///
/// Three groups. The first is the one the spec insists on: the single network
/// request the app makes must be switchable off, so anyone who wants a
/// strictly offline app can have one. Then the local notifications, and the
/// appearance. Every wording states plainly what happens and that nothing is
/// sent.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Offered delays, in days. Short enough to build a habit, long enough not
  /// to nag someone who plays once a week.
  static const _reminderChoices = [3, 7, 14, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final enabled = ref.watch(onlineRegistryUpdatesProvider).asData?.value ?? true;
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final notifications =
        ref.watch(notificationsEnabledProvider).asData?.value ?? false;
    final reminderDays = ref.watch(reminderDaysProvider).asData?.value ?? 7;
    final themeMode =
        ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;
    final factionColours =
        ref.watch(factionColoursProvider).asData?.value ?? false;
    final faction = ref.watch(currentFactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.settingsDataSection),
          SwitchListTile(
            value: enabled,
            title: Text(l10n.settingsOnlineUpdates),
            subtitle: Text(l10n.settingsOnlineUpdatesDetail),
            isThreeLine: true,
            onChanged: (value) => ref
                .read(counterRegistryServiceProvider)
                .setOnlineUpdatesEnabled(value),
          ),
          if (registry != null)
            ListTile(
              dense: true,
              title: Text(l10n.settingsRegistryCounters(registry.length)),
              subtitle: registry.updatedAt.isEmpty
                  ? null
                  : Text(l10n.settingsRegistryUpdatedAt(registry.updatedAt)),
            ),
          const Divider(),
          _SectionHeader(title: l10n.settingsNotificationsSection),
          SwitchListTile(
            value: notifications,
            title: Text(l10n.settingsNotifications),
            subtitle: Text(l10n.settingsNotificationsDetail),
            isThreeLine: true,
            onChanged: (value) => _setNotifications(context, ref, value),
          ),
          ListTile(
            // Greyed out rather than hidden when notifications are off: the
            // delay stays readable, so switching them back on holds no
            // surprise.
            enabled: notifications,
            title: Text(l10n.settingsReminderDelay(reminderDays)),
            trailing: DropdownButton<int>(
              value:
                  _reminderChoices.contains(reminderDays) ? reminderDays : null,
              onChanged: notifications
                  ? (value) => _setReminderDays(context, ref, value)
                  : null,
              items: [
                for (final days in _reminderChoices)
                  DropdownMenuItem(value: days, child: Text('$days')),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsAppearanceSection),
          ListTile(
            title: Text(l10n.settingsTheme),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              onChanged: (value) => _setThemeMode(ref, value),
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.settingsThemeSystem),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.settingsThemeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.settingsThemeDark),
                ),
              ],
            ),
          ),
          SwitchListTile(
            value: factionColours,
            title: Text(l10n.settingsFactionColours),
            // The switch still works without a snapshot — it simply has
            // nothing to follow yet, and saying so beats a dead control.
            subtitle: Text(
              faction == null
                  ? l10n.settingsFactionUnknown
                  : l10n.settingsFactionColoursDetail,
            ),
            isThreeLine: faction != null,
            onChanged: (value) => ref.read(settingsRepositoryProvider).write(
                  SettingKeys.factionColours,
                  value ? 'true' : 'false',
                ),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsAboutSection),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              l10n.disclaimer,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setThemeMode(WidgetRef ref, ThemeMode? mode) async {
    if (mode == null) return;
    await ref.read(settingsRepositoryProvider).write(
          SettingKeys.themeMode,
          mode.name,
        );
  }

  /// Switching reminders on asks Android for the permission first: storing
  /// "on" while the system refuses would leave a switch that lies.
  Future<void> _setNotifications(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(notificationServiceProvider);

    if (value && !await service.ensurePermission()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsNotificationsDenied)),
      );
      return;
    }

    await ref.read(notificationCoordinatorProvider).setEnabled(value);
    await _reschedule(ref, l10n);
  }

  Future<void> _setReminderDays(
    BuildContext context,
    WidgetRef ref,
    int? days,
  ) async {
    if (days == null) return;

    final l10n = AppLocalizations.of(context);
    await ref.read(notificationCoordinatorProvider).setReminderDays(days);
    await _reschedule(ref, l10n);
  }

  /// Every change here moves when the reminder is due, so it is re-armed at
  /// once rather than waiting for the next snapshot or the next launch.
  Future<void> _reschedule(WidgetRef ref, AppLocalizations l10n) async {
    final latest = await ref.read(snapshotRepositoryProvider).latest();
    await ref.read(notificationCoordinatorProvider).rescheduleReminder(
          latestSnapshot: latest?.snapshot.recordedAt,
          l10n: l10n,
        );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}
