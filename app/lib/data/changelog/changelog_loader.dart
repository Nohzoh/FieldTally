import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/changelog_release.dart';

/// Loads the bundled release notes (§9, #45).
///
/// Bundled rather than fetched, unlike the counter registry: the app promises
/// to work with no network, and a screen that only appears right after an
/// update must not depend on being online.
class ChangelogLoader {
  const ChangelogLoader();

  static const assetPath = 'assets/changelog.json';

  /// Reads every release the app was built with notes for.
  ///
  /// Never rethrows: a missing or malformed file must not stop the app from
  /// starting. It simply means nobody sees a changelog dialog, which is the
  /// same outcome as before this feature existed.
  Future<List<ChangelogRelease>> loadAll() async {
    try {
      return parse(await rootBundle.loadString(assetPath));
    } catch (_) {
      return const [];
    }
  }

  /// Decodes the releases from raw JSON, keyed by `versionCode`.
  ///
  /// Kept separate from [loadAll] so it can be tested without the Flutter
  /// asset bundle.
  List<ChangelogRelease> parse(String rawJson) {
    final json = jsonDecode(rawJson) as Map<String, dynamic>;
    return [
      for (final entry in json.entries)
        ChangelogRelease.fromJson(entry.key, entry.value as Map<String, dynamic>),
    ];
  }
}
