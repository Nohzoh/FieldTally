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

  /// Releases introduced since this device last recorded a seen build.
  ///
  /// When there is nothing to show, [installedVersionCode] is recorded as
  /// seen straight away. When there is, nothing is recorded: the caller does
  /// that with [markSeen] once the notes have actually been dismissed. A
  /// launch that ends before then, because the process was killed or the
  /// activity recreated under the dialog, shows the same notes again on the
  /// next one instead of losing them.
  ///
  /// A fresh install — nothing stored yet — records the current build and
  /// returns nothing: there is no "before" to compare against.
  Future<List<ChangelogRelease>> checkForUpdate(
    int installedVersionCode,
  ) async {
    final stored = await settings.read(SettingKeys.changelogLastSeenBuild);
    final lastSeen = stored == null ? null : int.tryParse(stored);

    final unseen = lastSeen == null
        ? const <ChangelogRelease>[]
        : unseenReleases(
            all: await loader.loadAll(),
            installedVersionCode: installedVersionCode,
            lastSeenVersionCode: lastSeen,
          );

    if (unseen.isEmpty) await markSeen(installedVersionCode);
    return unseen;
  }

  /// Records [installedVersionCode] as seen, so its notes are not offered
  /// again on a later launch.
  Future<void> markSeen(int installedVersionCode) => settings.write(
    SettingKeys.changelogLastSeenBuild,
    '$installedVersionCode',
  );

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
