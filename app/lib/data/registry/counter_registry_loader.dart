import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/counter_registry.dart';

/// Loads the counter enrichment layer (§3.1.4).
///
/// In v1 only the copy bundled at build time is read. Fetching it online from
/// GitHub Pages comes next: that is explicitly designed as a **progressive
/// enhancement**, never a prerequisite — if it fails, the app silently carries
/// on with what it already knows.
class CounterRegistryLoader {
  const CounterRegistryLoader();

  /// Bundled fallback copy, generated from `docs/registry/counters.json` by
  /// `tool/sync_registry_seed.dart`.
  static const seedAssetPath = 'assets/counters_registry_seed.json';

  /// Reads the bundled registry.
  ///
  /// Never rethrows: an unreadable registry degrades the display (every
  /// counter falls into "Other"), it must not stop the app from starting or
  /// from importing a snapshot.
  Future<CounterRegistry> loadSeed() async {
    try {
      return parse(await rootBundle.loadString(seedAssetPath));
    } catch (_) {
      return CounterRegistry.empty();
    }
  }

  /// Decodes a registry from its raw JSON.
  ///
  /// Kept separate from [loadSeed] so it can be tested without the Flutter
  /// asset bundle, and reused as-is by the future network fetch.
  CounterRegistry parse(String rawJson) =>
      CounterRegistry.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
}
