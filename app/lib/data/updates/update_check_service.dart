import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/repositories/settings_repository.dart';

/// What the project site says the newest release is (#34).
class LatestRelease {
  const LatestRelease({
    required this.version,
    required this.build,
    required this.url,
  });

  /// Version name, without the `v`: `1.8.0`.
  final String version;

  /// The `versionCode` that release shipped.
  ///
  /// Compared rather than the name: the code is what Android itself orders
  /// updates by, so comparing it needs no semver parsing on the device and
  /// cannot disagree with what the platform would allow to install.
  final int build;

  /// Where to read about it. Carried in the file rather than derived, so a
  /// release published somewhere else one day does not need an app update to
  /// be linkable.
  final String url;

  static LatestRelease? tryParse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return null;

      final version = json['version'];
      final build = json['build'];
      final url = json['url'];
      if (version is! String || build is! int || url is! String) return null;
      if (version.isEmpty || !url.startsWith('https://')) return null;

      return LatestRelease(version: version, build: build, url: url);
    } catch (_) {
      return null;
    }
  }
}

/// Tells an agent that a newer release exists (#34).
///
/// FieldTally is installed by sideload, so nothing else will: Android says
/// nothing, and there is no store to do it. The app already fetches one file
/// from the project site at startup — the counter registry (§3.1.4) — and this
/// reads a second, tiny one beside it, under exactly the same rules.
///
/// **Detection only, deliberately.** Handing the APK to Android's package
/// installer would need `REQUEST_INSTALL_PACKAGES`, which adds "can install
/// applications" to the capabilities of an app whose whole argument is that it
/// does almost nothing. Two taps saved is a poor trade for that, so the app
/// opens the release page and the agent performs the taps they already know
/// from their first install.
///
/// Like the registry service, every failure is swallowed and invisible: a
/// version check is a courtesy, never a prerequisite, and an app that cannot
/// reach the site must behave exactly as if there were no newer release.
class UpdateCheckService {
  UpdateCheckService({
    required this.settings,
    this.client,
    this.endpoint = defaultEndpoint,
    this.minimumInterval = const Duration(hours: 24),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Beside the registry, on the same GitHub Pages site, generated at deploy
  /// time from the newest release tag.
  static const defaultEndpoint =
      'https://nohzoh.github.io/FieldTally/latest.json';

  final SettingsRepository settings;
  final http.Client? client;
  final String endpoint;

  /// How long to wait between attempts, successful or not.
  final Duration minimumInterval;

  final DateTime Function() _now;

  /// The newest release the device has heard of, or null if it never has.
  ///
  /// Read from the cache rather than the network, so a screen can ask this
  /// question without waiting and without being online.
  Future<LatestRelease?> known() async {
    final cached = await settings.read(SettingKeys.latestRelease);
    return cached == null ? null : LatestRelease.tryParse(cached);
  }

  /// Whether a newer release than [installedBuild] is known.
  ///
  /// Strictly greater: a device running a build newer than the site knows
  /// about — a local build, or a release whose Pages deploy has not caught up
  /// — is not offered a downgrade.
  Future<LatestRelease?> newerThan(int installedBuild) async {
    final latest = await known();
    if (latest == null) return null;
    return latest.build > installedBuild ? latest : null;
  }

  /// Shares the registry's preference rather than adding a second switch.
  ///
  /// One setting, described as "update online", governs everything this app
  /// fetches. A second toggle for a second file would make the promise harder
  /// to state than it is to keep.
  Future<bool> onlineUpdatesEnabled() async =>
      await settings.read(SettingKeys.onlineRegistryUpdates) != 'false';

  /// Attempts a refresh, honouring the preference and the interval.
  ///
  /// Never throws, and returns nothing: callers read [known] or [newerThan]
  /// afterwards, which work identically whether or not the network was
  /// involved.
  Future<void> refresh() async {
    if (!await onlineUpdatesEnabled()) return;

    final last = await settings.read(SettingKeys.lastUpdateCheck);
    if (last != null) {
      final parsed = DateTime.tryParse(last);
      if (parsed != null && _now().difference(parsed) < minimumInterval) return;
    }

    // Recorded before the request, like the registry's: an attempt that hangs
    // or fails must still count, or a device with no network retries on every
    // single launch.
    await settings.write(SettingKeys.lastUpdateCheck, _now().toIso8601String());

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;

      final body = utf8.decode(response.bodyBytes);

      // Parsed before being stored, so a malformed file served by mistake can
      // never replace a good cache.
      if (LatestRelease.tryParse(body) == null) return;

      await settings.write(SettingKeys.latestRelease, body);
    } catch (_) {
      // Offline, DNS, a timeout, a 500. None of it is worth telling anyone
      // about: the app works exactly as well without this.
    } finally {
      if (client == null) httpClient.close();
    }
  }
}
