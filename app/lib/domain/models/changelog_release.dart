/// Release notes bundled at build time (§9, #45).
///
/// A release is identified by its Android `versionCode`, since that is what
/// orders releases unambiguously and is compared against the last one a
/// device has seen. The display [version] (e.g. `1.1.0`) is only for the
/// dialog's title.
library;

class ChangelogRelease {
  const ChangelogRelease({
    required this.versionCode,
    required this.version,
    required this.featureNotes,
    required this.fixNotes,
  });

  final int versionCode;
  final String version;

  /// Notes by language code (`en`, `fr`), as the registry stores its labels.
  final Map<String, List<String>> featureNotes;
  final Map<String, List<String>> fixNotes;

  /// What is new in this release, in [languageCode], falling back to English.
  List<String> features(String languageCode) =>
      featureNotes[languageCode] ?? featureNotes['en'] ?? const [];

  /// What was fixed in this release, in [languageCode], falling back to
  /// English.
  List<String> fixes(String languageCode) =>
      fixNotes[languageCode] ?? fixNotes['en'] ?? const [];

  factory ChangelogRelease.fromJson(String versionCode, Map<String, dynamic> json) =>
      ChangelogRelease(
        versionCode: int.parse(versionCode),
        version: json['version'] as String,
        featureNotes: _stringListMap(json['features']),
        fixNotes: _stringListMap(json['fixes']),
      );

  static Map<String, List<String>> _stringListMap(Object? json) => {
        for (final entry in (json as Map? ?? const {}).entries)
          entry.key as String: List<String>.from(entry.value as List),
      };
}
