import '../../domain/changelog.dart';
import '../../domain/models/changelog_release.dart';
import '../../domain/repositories/settings_repository.dart';
import 'changelog_loader.dart';

/// Ties the bundled release notes to what a device has already seen (§9, #45).
class ChangelogService {
  ChangelogService({
    required this.settings,
    this.loader = const ChangelogLoader(),
  });

  final SettingsRepository settings;
  final ChangelogLoader loader;

  /// Releases introduced since this device last recorded a seen build,
  /// recording [installedVersionCode] as seen in the process — a look that is
  /// only ever taken once per build, whether or not it turns anything up.
  ///
  /// A fresh install — nothing stored yet — records the current build and
  /// returns nothing: there is no "before" to compare against.
  Future<List<ChangelogRelease>> checkForUpdate(int installedVersionCode) async {
    final stored = await settings.read(SettingKeys.changelogLastSeenBuild);
    final lastSeen = stored == null ? null : int.tryParse(stored);

    await settings.write(
      SettingKeys.changelogLastSeenBuild,
      '$installedVersionCode',
    );

    if (lastSeen == null) return const [];

    final all = await loader.loadAll();
    return unseenReleases(
      all: all,
      installedVersionCode: installedVersionCode,
      lastSeenVersionCode: lastSeen,
    );
  }

  /// The notes for exactly the running build, regardless of what has already
  /// been seen — for "Settings > About > What's new", reachable at any time so
  /// that dismissing the dialog in a hurry does not lose it for good.
  Future<List<ChangelogRelease>> currentReleaseNotes(
    int installedVersionCode,
  ) async {
    final all = await loader.loadAll();
    return all.where((r) => r.versionCode == installedVersionCode).toList();
  }
}
