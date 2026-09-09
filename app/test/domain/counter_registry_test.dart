import 'dart:io';

import 'package:fieldtally/data/parsing/ingress_tsv_parser.dart';
import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';
const allTimePath = 'test/fixtures/sample_export_all_time.tsv';

void main() {
  const loader = CounterRegistryLoader();
  late CounterRegistry registry;

  setUp(() {
    registry = loader.parse(File(seedPath).readAsStringSync());
  });

  group('registre embarqué', () {
    test('se charge avec ses 59 compteurs et ses catégories', () {
      expect(registry.length, 59);
      expect(registry.categories, contains('discovery'));
      expect(registry.categories, contains(CounterRegistry.fallbackCategoryKey));
      expect(registry.schemaVersion, greaterThan(0));
    });

    test('couvre exactement les compteurs de la fixture réelle', () {
      final snapshot =
          const IngressTsvParser().parseSingle(File(allTimePath).readAsStringSync());

      final unknown = snapshot.counters.keys
          .where((h) => registry.forExportHeader(h) == null)
          .toList();

      expect(unknown, isEmpty,
          reason: 'ces colonnes n\'ont pas d\'entrée d\'enrichissement');
    });

    test('associe la bonne catégorie et les deux libellés', () {
      final explorer = registry.forExportHeader('Unique Portals Visited')!;

      expect(explorer.key, 'explorer');
      expect(explorer.categoryKey, 'discovery');
      expect(explorer.label('en'), 'Unique Portals Visited');
      expect(explorer.label('fr'), isNotEmpty);
      expect(explorer.label('fr'), isNot(explorer.label('en')));
    });

    test('range les compteurs d\'anomalie dans Events, comme le jeu', () {
      // Le jeu ne les isole pas dans un écran à part : l'app fait pareil.
      for (final header in ['Orion Tokens', 'Apollo Tokens', 'Mission Day(s) Attended']) {
        expect(registry.forExportHeader(header)!.categoryKey, 'events',
            reason: header);
      }
    });

    test('marque Level, Lifetime AP et Current AP comme non périodisés', () {
      for (final header in ['Level', 'Lifetime AP', 'Current AP']) {
        expect(registry.isPeriodized(header), isFalse, reason: header);
      }
    });

    test('aucun seuil de palier n\'est encore renseigné', () {
      // L'Annexe A n'en fournit pas : les inventer serait pire que l'absence,
      // puisque les projections du §3.6 s'appuieraient dessus.
      expect(
        registry.forExportHeader('Hacks')!.tiers,
        isEmpty,
      );
    });
  });

  group('compteur inconnu (§3.1.2)', () {
    test('n\'a pas d\'entrée, tombe dans « Autres » et reste périodisé', () {
      expect(registry.forExportHeader('Zeta Anomaly Tokens'), isNull);
      expect(registry.categoryKeyFor('Zeta Anomaly Tokens'),
          CounterRegistry.fallbackCategoryKey);
      // Périodisé par défaut : le garde-fou comportemental le surveille donc,
      // ce qui est le côté prudent.
      expect(registry.isPeriodized('Zeta Anomaly Tokens'), isTrue);
    });
  });

  group('ordre d\'affichage', () {
    test('suit les catégories du jeu puis l\'ordre interne', () {
      final sorted = registry.sortHeaders([
        'Recursions',
        'Hacks',
        'Unique Portals Visited',
        'Resonators Deployed',
        'Level',
      ]);

      expect(sorted, [
        'Level', // core, en tête
        'Unique Portals Visited', // discovery
        'Resonators Deployed', // building
        'Hacks', // resource gathering
        'Recursions', // recursion, en fin
      ]);
    });

    test('relègue les compteurs inconnus en fin de liste', () {
      final sorted = registry.sortHeaders([
        'Zeta Anomaly Tokens',
        'Hacks',
        'Alpha Unknown',
      ]);

      expect(sorted.first, 'Hacks');
      // Entre inconnus, tri alphabétique pour un affichage stable.
      expect(sorted.sublist(1), ['Alpha Unknown', 'Zeta Anomaly Tokens']);
    });
  });

  group('résistance à un registre cassé', () {
    test('un registre vide ne fait pas tomber l\'app', () {
      final empty = CounterRegistry.empty();

      expect(empty.length, 0);
      expect(empty.forExportHeader('Hacks'), isNull);
      expect(empty.categoryKeyFor('Hacks'), CounterRegistry.fallbackCategoryKey);
      expect(empty.isPeriodized('Hacks'), isTrue);
      expect(empty.sortHeaders(['B', 'A']), ['A', 'B']);
    });
  });
}
