/// Identifies the build precisely enough to act on a bug report.
///
/// The version comes from the platform rather than from a constant compiled
/// in: it is then, by construction, the version Android actually installed,
/// and cannot drift from the APK the person is holding.
///
/// The commit is injected at build time by the release workflow. A build made
/// from a working copy has none, and says so rather than naming a commit that
/// may not contain what is running.
class BuildInfo {
  const BuildInfo({
    required this.version,
    required this.build,
    required this.commit,
  });

  final String version;
  final String build;

  /// Short commit hash, or null outside a release build.
  final String? commit;

  /// Passed as `--dart-define=GIT_COMMIT=<sha>`.
  static const _commit = String.fromEnvironment('GIT_COMMIT');

  static String? get commitFromEnvironment =>
      _commit.isEmpty ? null : _commit;

  /// One line to paste into an issue.
  String get summary =>
      'FieldTally $version ($build)${commit == null ? '' : ' · $commit'}';
}
