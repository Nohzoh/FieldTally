import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/counter_registry.dart';
import '../../domain/repositories/settings_repository.dart';
import 'counter_registry_loader.dart';

/// Keeps the counter enrichment layer up to date (§3.1.4).
///
/// The registry lives in the project repository and is served by GitHub Pages,
/// so declaring a new anomaly counter is a pull request rather than a release.
/// The app fetches it in the background at startup.
///
/// Three rules govern this, and they are the reason the code below looks
/// defensive:
///
/// 1. **It is a progressive enhancement, never a prerequisite.** Every failure
///    — no network, GitHub down, malformed JSON — is swallowed, and the app
///    carries on with the newest thing it already has: the cached copy, or the
///    snapshot bundled at build time.
/// 2. **It is invisible when it fails.** A background refresh of counter
///    labels is not worth an error message.
/// 3. **It is scoped to this one file.** Not a general purpose remote config
///    channel, which is how a "no backend" app quietly acquires one.
class CounterRegistryService {
  CounterRegistryService({
    required this.settings,
    this.client,
    this.loader = const CounterRegistryLoader(),
    this.endpoint = defaultEndpoint,
    this.minimumInterval = const Duration(hours: 24),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// GitHub Pages rather than raw.githubusercontent.com: a real CDN with
  /// standard HTTP caching, and no aggressive rate limiting for many clients.
  static const defaultEndpoint =
      'https://nohzoh.github.io/FieldTally/registry/counters.json';

  final SettingsRepository settings;

  /// Injected in tests; in production each refresh opens and closes its own.
  final http.Client? client;
  final CounterRegistryLoader loader;
  final String endpoint;

  /// How long to wait between attempts, successful or not.
  final Duration minimumInterval;

  final DateTime Function() _now;

  /// The registry to use right now: the cached copy if there is one, otherwise
  /// the copy bundled at build time.
  ///
  /// Never throws. A registry that cannot be read degrades the display — every
  /// counter falls back to its raw label — but must not stop the app.
  Future<CounterRegistry> load() async {
    try {
      final cached = await settings.read(SettingKeys.cachedRegistry);
      if (cached != null) return loader.parse(cached);
    } catch (_) {
      // A corrupt cache is not worth failing over: fall through to the seed.
    }
    return loader.loadSeed();
  }

  /// Whether the network refresh is allowed. Absent means enabled, which is
  /// the documented default (§3.1.4).
  Future<bool> onlineUpdatesEnabled() async =>
      await settings.read(SettingKeys.onlineRegistryUpdates) != 'false';

  Future<void> setOnlineUpdatesEnabled(bool enabled) => settings.write(
        SettingKeys.onlineRegistryUpdates,
        enabled ? 'true' : 'false',
      );

  /// Attempts a refresh, honouring the preference and the interval.
  ///
  /// Returns the registry to use — refreshed if the fetch brought something
  /// newer, otherwise exactly what [load] would have returned. Callers do not
  /// need to distinguish the two, and deliberately cannot tell whether the
  /// network was involved.
  Future<CounterRegistry> refresh() async {
    if (!await _shouldAttempt()) return load();

    // Recorded before the request: an attempt that hangs or fails must still
    // count, otherwise a device with no network retries on every launch.
    await settings.write(SettingKeys.lastFetchAttempt, _now().toIso8601String());

    final http.Client httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return load();

      final body = utf8.decode(response.bodyBytes);

      // Parse before storing: a malformed file served by mistake must never
      // replace a good cache. This is the client-side half of the guarantee
      // the CI validation makes on the other end (§7.3).
      final fetched = loader.parse(body);
      if (fetched.length == 0) return load();

      final currentStamp =
          await settings.read(SettingKeys.cachedRegistryUpdatedAt);
      if (currentStamp == fetched.updatedAt) return load();

      await settings.write(SettingKeys.cachedRegistry, body);
      await settings.write(
        SettingKeys.cachedRegistryUpdatedAt,
        fetched.updatedAt,
      );
      return fetched;
    } catch (_) {
      // Silent by design: see rule 2 above.
      return load();
    } finally {
      if (client == null) httpClient.close();
    }
  }

  Future<bool> _shouldAttempt() async {
    if (!await onlineUpdatesEnabled()) return false;

    final last = await settings.read(SettingKeys.lastFetchAttempt);
    if (last == null) return true;

    final parsed = DateTime.tryParse(last);
    if (parsed == null) return true;

    return _now().difference(parsed) >= minimumInterval;
  }
}
