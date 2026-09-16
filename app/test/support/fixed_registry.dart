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

/// The seed registry with a badge ladder put on a named counter.
///
/// Giving a counter thresholds is a registry change and reaches an installed
/// app at the next start (§3.1.4), while the emblem for it could only arrive
/// in a release — so a ladder without a drawing is not a contrived state, it
/// is the ordinary one whenever a Global Op opens.
CounterRegistry registryWithLadderOn(String key, {DateTime? endsAt}) {
  final doc =
      jsonDecode(File(seedAssetPath).readAsStringSync())
          as Map<String, dynamic>;
  final counters = doc['counters'] as Map<String, dynamic>;
  final entry = counters[key] as Map<String, dynamic>;
  entry['tiers'] = [
    {'name': 'bronze', 'value': 50},
    {'name': 'silver', 'value': 500},
    {'name': 'gold', 'value': 1000},
  ];
  // Stated, never inherited: the real registry dates some of these ladders
  // (#99), and inheriting would let 'still open' become 'already shut' on the
  // day the real op ends.
  if (endsAt != null) {
    entry['ends_at'] = endsAt.toUtc().toIso8601String();
  } else {
    entry.remove('ends_at');
  }

  return const CounterRegistryLoader().parse(jsonEncode(doc));
}

/// A ladder on `Apollo Mod Battle Points`, which this release does draw.
CounterRegistry registryWithEventLadder({DateTime? endsAt}) =>
    registryWithLadderOn('apollo_mod_battle_points', endsAt: endsAt);

/// Hands [registryWithEventLadder] to the providers.
FixedRegistryNotifier eventLadderRegistry() =>
    FixedRegistryNotifier(registryWithEventLadder());

/// A ladder on a counter this release draws no emblem for (#98).
///
/// Deliberately not the Apollo counter any more: since #99 drew its emblem,
/// pointing the #98 tests at it would have left them asserting the right
/// things about the wrong case — a row that names its tier because an emblem
/// exists, not because it copes without one. `Anomaly Unique Hacks` is the
/// plausible next ladder and has no drawing.
FixedRegistryNotifier undrawnLadderRegistry() =>
    FixedRegistryNotifier(registryWithLadderOn('anomaly_unique_hacks'));

/// The same ladder, with its window already shut (#99).
///
/// The date is deliberately well in the past rather than a few hours out: the
/// projector reads the real clock, so a deadline still ahead would make a test
/// pass until that hour and fail after it. A ladder still open is covered in
/// the domain instead, where `now` is injected.
FixedRegistryNotifier closedLadderRegistry() => FixedRegistryNotifier(
  registryWithEventLadder(endsAt: DateTime.utc(2026, 5, 11, 18)),
);
