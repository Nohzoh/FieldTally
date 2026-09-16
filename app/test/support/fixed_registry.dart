import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/presentation/providers/providers.dart';

const seedAssetPath = 'assets/counters_registry_seed.json';

/// A registry that is already resolved and never touches the network.
///
/// Reading the real bundled asset inside a widget test goes through Drift and
/// rootBundle, whose futures depend on timers that do not fire under the
/// widget-test clock. Handing the registry over ready-made keeps every screen
/// test about the screen.
class FixedRegistryNotifier extends CounterRegistryNotifier {
  FixedRegistryNotifier(this.registry);

  final CounterRegistry registry;

  @override
  Future<CounterRegistry> build() async => registry;

  @override
  Future<void> refreshFromNetwork() async {}
}

/// The real seed registry, read straight from disk.
///
/// Used as `counterRegistryProvider.overrideWith(fixedRegistry)`.
FixedRegistryNotifier fixedRegistry() => FixedRegistryNotifier(
  const CounterRegistryLoader().parse(File(seedAssetPath).readAsStringSync()),
);

/// A registry that never resolves, standing in for a first launch that has not
/// read the bundled seed yet (§3.1.4).
///
/// The medal filter reads its thresholds, so this is the state in which the
/// screen must refuse to offer that filter rather than quietly empty the list.
class PendingRegistryNotifier extends CounterRegistryNotifier {
  @override
  Future<CounterRegistry> build() => Completer<CounterRegistry>().future;

  @override
  Future<void> refreshFromNetwork() async {}
}

PendingRegistryNotifier pendingRegistry() => PendingRegistryNotifier();

/// The seed registry with a badge ladder on an event counter that no release
/// has an emblem for (#98).
///
/// Apollo's Global Op medal is measured on `Apollo Mod Battle Points`, a
/// counter the registry already knows. Giving it thresholds is a registry
/// change and reaches an installed app at the next start (§3.1.4), while an
/// emblem could only arrive in a release — so this is not a contrived state,
/// it is the ordinary one for every seasonal medal.
CounterRegistry registryWithEventLadder({DateTime? endsAt}) {
  final doc =
      jsonDecode(File(seedAssetPath).readAsStringSync())
          as Map<String, dynamic>;
  final counters = doc['counters'] as Map<String, dynamic>;
  final entry = counters['apollo_mod_battle_points'] as Map<String, dynamic>;
  entry['tiers'] = [
    {'name': 'bronze', 'value': 50},
    {'name': 'silver', 'value': 500},
    {'name': 'gold', 'value': 1000},
  ];
  if (endsAt != null) {
    entry['ends_at'] = endsAt.toUtc().toIso8601String();
  }

  return const CounterRegistryLoader().parse(jsonEncode(doc));
}

/// Hands [registryWithEventLadder] to the providers.
FixedRegistryNotifier eventLadderRegistry() =>
    FixedRegistryNotifier(registryWithEventLadder());

/// The same ladder, with its window already shut (#99).
///
/// The date is deliberately well in the past rather than a few hours out: the
/// projector reads the real clock, so a deadline still ahead would make a test
/// pass until that hour and fail after it. A ladder still open is covered in
/// the domain instead, where `now` is injected.
FixedRegistryNotifier closedLadderRegistry() => FixedRegistryNotifier(
  registryWithEventLadder(endsAt: DateTime.utc(2026, 5, 11, 18)),
);
