import 'models/changelog_release.dart';

/// Which releases a device has not seen the notes for yet (§9, #45).
///
/// Pure and platform-independent so the two rules that matter are each one
/// line to test directly, without a database or the asset bundle:
///
/// - **A fresh install sees nothing.** [lastSeenVersionCode] absent means
///   there is no "before" to compare against, not that everything shipped is
///   new.
/// - **Skipping versions shows everything missed**, not just the latest: a
///   device on 1.0.0 that jumps to 1.2.0 gets 1.1.0's notes and 1.2.0's,
///   oldest first.
List<ChangelogRelease> unseenReleases({
  required List<ChangelogRelease> all,
  required int installedVersionCode,
  required int? lastSeenVersionCode,
}) {
  if (lastSeenVersionCode == null) return const [];

  final unseen = all.where(
    (release) =>
        release.versionCode > lastSeenVersionCode &&
        release.versionCode <= installedVersionCode,
  ).toList();
  unseen.sort((a, b) => a.versionCode.compareTo(b.versionCode));
  return unseen;
}
