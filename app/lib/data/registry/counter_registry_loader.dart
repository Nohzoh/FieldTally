import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/counter_registry.dart';

/// Charge la couche d'enrichissement des compteurs (§3.1.4).
///
/// En v1, seule la copie embarquée au build est lue. La récupération en ligne
/// depuis GitHub Pages viendra ensuite : elle est explicitement conçue comme
/// une **amélioration progressive**, jamais un prérequis — si elle échoue,
/// l'app continue silencieusement avec ce qu'elle connaît déjà.
class CounterRegistryLoader {
  const CounterRegistryLoader();

  /// Copie de secours embarquée, générée depuis `docs/registry/counters.json`
  /// par `tool/sync_registry_seed.dart`.
  static const seedAssetPath = 'assets/counters_registry_seed.json';

  /// Lit le registre embarqué.
  ///
  /// Ne relance jamais : un registre illisible dégrade l'affichage (tous les
  /// compteurs tombent dans « Autres »), il ne doit pas empêcher l'app de
  /// démarrer ni d'importer un relevé.
  Future<CounterRegistry> loadSeed() async {
    try {
      return parse(await rootBundle.loadString(seedAssetPath));
    } catch (_) {
      return CounterRegistry.empty();
    }
  }

  /// Décode un registre depuis son JSON brut.
  ///
  /// Séparé de [loadSeed] pour être testable sans dépendre du bundle Flutter,
  /// et réutilisable tel quel par le futur fetch réseau.
  CounterRegistry parse(String rawJson) =>
      CounterRegistry.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
}
