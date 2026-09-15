import 'dart:async';
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
      const CounterRegistryLoader()
          .parse(File(seedAssetPath).readAsStringSync()),
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
