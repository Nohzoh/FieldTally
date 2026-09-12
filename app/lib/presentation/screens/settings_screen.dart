import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/build_info.dart';
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

  /// Written in their own language on purpose — see the dropdown below.
  static const _languages = {'fr': 'Français', 'en': 'English'};

  static final _koFi = Uri.parse('https://ko-fi.com/tarnaud');
  static final _repository = Uri.parse('https://github.com/Nohzoh/FieldTally');
  static final _author = Uri.parse('https://github.com/Nohzoh');

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
    final locale = ref.watch(localeProvider).asData?.value;
    final build = ref.watch(buildInfoProvider).asData?.value;

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
            title: Text(l10n.settingsLanguage),
            trailing: DropdownButton<String?>(
              value: locale?.languageCode,
              onChanged: (value) => ref.read(settingsRepositoryProvider).write(
                    SettingKeys.locale,
                    value ?? '',
                  ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.settingsLanguageSystem),
                ),
                // Each language in its own language, never translated:
                // someone who lands in one they cannot read still needs to
                // recognise their own in the list.
                for (final entry in _languages.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
              ],
            ),
          ),
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
          // The first question on any bug report is "which version?", so the
          // answer is one tap away and lands in the clipboard ready to paste.
          ListTile(
            title: Text(
              build == null
                  ? l10n.settingsAboutSection
                  : l10n.settingsVersion(build.version, build.build),
            ),
            subtitle: Text(
              build?.commit ?? l10n.settingsBuildUnknown,
            ),
            trailing: const Icon(Icons.copy_all_outlined),
            onTap: build == null ? null : () => _copyVersion(context, build),
          ),
          ListTile(
            title: Text(l10n.settingsAuthor),
            subtitle: Text(l10n.settingsAuthorDetail),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _open(context, _author),
          ),
          ListTile(
            title: Text(l10n.settingsSupport),
            subtitle: Text(l10n.settingsSupportDetail),
            isThreeLine: true,
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _open(context, _koFi),
          ),
          ListTile(
            title: Text(l10n.settingsSourceCode),
            subtitle: Text(l10n.settingsSourceCodeDetail),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _open(context, _repository),
          ),
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

  Future<void> _copyVersion(BuildContext context, BuildInfo build) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await Clipboard.setData(ClipboardData(text: build.summary));
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsVersionCopied)),
    );
  }

  /// Says so rather than failing silently: a device with no browser is rare,
  /// but a tap that does nothing at all looks like a broken app.
  Future<void> _open(BuildContext context, Uri url) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsLinkFailed)),
      );
    }
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
