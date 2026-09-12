/// Small key/value preferences store.
///
/// Behind an interface like the rest (§5.2), so a screen never learns where a
/// preference is kept.
abstract interface class SettingsRepository {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  /// Emits the current value and then every change, for settings a screen
  /// needs to reflect live.
  Stream<String?> watch(String key);
}

/// Keys used by the app. Gathered here so the set stays visible at a glance
/// rather than spread as string literals.
abstract final class SettingKeys {
  /// Whether the counter registry may be refreshed over the network (§3.1.4).
  /// Absent means enabled: that is the documented default.
  static const onlineRegistryUpdates = 'registry.online_updates';

  /// Cached registry JSON, and what it says about itself.
  static const cachedRegistry = 'registry.json';
  static const cachedRegistryUpdatedAt = 'registry.updated_at';

  /// Whether local reminders and milestone alerts may be posted (§3.7).
  /// Absent means disabled: it is switched on from Settings, which is also
  /// where Android is asked for the permission.
  static const notifications = 'notifications.enabled';

  /// Days without a snapshot before the reminder fires. Absent means seven.
  static const reminderDays = 'notifications.reminder_days';

  /// Theme: 'system', 'light' or 'dark' (§3.9). Absent means following the
  /// system, which is the documented default.
  static const themeMode = 'appearance.theme_mode';

  /// Language override: 'fr', 'en', or absent to follow the system (§3.10).
  static const locale = 'appearance.locale';

  /// Whether the app is tinted with the agent's faction colour (§3.9).
  /// Absent means off: the app's own colour is its identity, and it should not
  /// change the day a first snapshot is imported.
  static const factionColours = 'appearance.faction_colours';

  /// When a fetch was last attempted — successful or not. Failures count, so a
  /// device with no network does not retry on every single launch.
  static const lastFetchAttempt = 'registry.last_fetch';
}
