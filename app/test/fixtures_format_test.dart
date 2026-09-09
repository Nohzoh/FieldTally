// Tests de FORMAT des fixtures d'export Ingress.
//
// Périmètre volontairement limité (voir §3.1.1) : on vérifie seulement que les
// deux fixtures se lisent bien comme du TSV et portent les en-têtes attendus.
// Le vrai parser métier (mapping des compteurs, garde-fous du §3.1.3) n'existe
// pas encore et sera testé séparément à l'itération suivante.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Une ligne d'export découpée en TSV, indexée par nom d'en-tête.
///
/// Volontairement minimal : ce n'est pas le parser métier, juste de quoi
/// vérifier que le format tabulé est intact.
class TsvExport {
  TsvExport(this.headers, this.rows);

  final List<String> headers;
  final List<List<String>> rows;

  static TsvExport read(String path) {
    final lines = File(path)
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final headers = lines.first.split('\t');
    final rows = lines.skip(1).map((line) => line.split('\t')).toList();
    return TsvExport(headers, rows);
  }

  String value(int row, String header) => rows[row][headers.indexOf(header)];
}

/// Colonnes de métadonnées du relevé, par opposition aux colonnes de
/// compteurs qui sont « tout le reste » (§3.1.1).
const metadataHeaders = <String>[
  'Time Span',
  'Agent Name',
  'Agent Faction',
  'Date (yyyy-mm-dd)',
  'Time (hh:mm:ss)',
];

const fixturesDir = 'test/fixtures';
const allTimePath = '$fixturesDir/sample_export_all_time.tsv';
const weekPath = '$fixturesDir/sample_export_week.tsv';

void main() {
  group('fixtures d\'export Ingress', () {
    for (final entry in {
      'ALL TIME': allTimePath,
      'WEEK': weekPath,
    }.entries) {
      final expectedTimeSpan = entry.key;
      final path = entry.value;

      group('$path ($expectedTimeSpan)', () {
        late TsvExport export;

        setUp(() => export = TsvExport.read(path));

        test('le fichier existe et contient un en-tête + un relevé', () {
          expect(File(path).existsSync(), isTrue,
              reason: 'fixture manquante : $path');
          expect(export.rows, hasLength(1));
        });

        test('les en-têtes sont non vides et sans doublon', () {
          expect(export.headers, isNotEmpty);
          expect(export.headers.any((h) => h.trim().isEmpty), isFalse,
              reason: 'un en-tête vide fausserait le mapping par nom');
          expect(export.headers.toSet(), hasLength(export.headers.length),
              reason: 'des en-têtes en doublon rendraient le mapping ambigu');
        });

        test('chaque ligne a autant de champs que d\'en-têtes', () {
          for (final row in export.rows) {
            expect(row, hasLength(export.headers.length));
          }
        });

        test('les colonnes de métadonnées attendues sont présentes', () {
          for (final header in metadataHeaders) {
            expect(export.headers, contains(header));
          }
          // 'Level' est bien présent mais suivi comme un compteur à part
          // entière côté registre (Annexe A), pas comme une métadonnée.
          expect(export.headers, contains('Level'));
        });

        test('Time Span vaut $expectedTimeSpan', () {
          expect(export.value(0, 'Time Span'), expectedTimeSpan);
        });

        test('la date et l\'heure sont au format attendu', () {
          expect(export.value(0, 'Date (yyyy-mm-dd)'),
              matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
          expect(export.value(0, 'Time (hh:mm:ss)'),
              matches(RegExp(r'^\d{2}:\d{2}:\d{2}$')));
        });

        test('toutes les colonnes de compteurs sont des entiers', () {
          final counterHeaders = export.headers
              .where((h) => !metadataHeaders.contains(h))
              .toList();
          expect(counterHeaders, isNotEmpty);

          for (final header in counterHeaders) {
            final raw = export.value(0, header);
            expect(int.tryParse(raw), isNotNull,
                reason: 'colonne "$header" : valeur non entière ("$raw")');
          }
        });

        test('la fixture est anonymisée (§3.1.3)', () {
          expect(export.value(0, 'Agent Name'), 'AgentDemo',
              reason: 'aucun pseudo Ingress réel ne doit être versionné');
        });
      });
    }

    test('les deux fixtures partagent exactement les mêmes en-têtes', () {
      expect(TsvExport.read(weekPath).headers,
          equals(TsvExport.read(allTimePath).headers));
    });

    test(
      'Level, Lifetime AP et Current AP sont identiques entre ALL TIME et WEEK',
      () {
        // Constat du §3.1.3 : ces trois champs ne sont jamais périodisés par
        // Ingress. Le garde-fou comportemental ne peut donc pas s'appuyer
        // dessus — d'où ce test qui fige l'observation.
        final allTime = TsvExport.read(allTimePath);
        final week = TsvExport.read(weekPath);

        for (final header in ['Level', 'Lifetime AP', 'Current AP']) {
          expect(week.value(0, header), allTime.value(0, header),
              reason: '"$header" ne devrait pas varier selon la période');
        }
      },
    );

    test('les compteurs périodisés sont bien réduits sur l\'export WEEK', () {
      final allTime = TsvExport.read(allTimePath);
      final week = TsvExport.read(weekPath);

      // Contre-épreuve du test précédent : au moins un compteur périodisé doit
      // être strictement inférieur, sinon la fixture WEEK n'apporte rien.
      final periodized = allTime.headers.where(
        (h) =>
            !metadataHeaders.contains(h) &&
            !['Level', 'Lifetime AP', 'Current AP'].contains(h),
      );

      final reduced = periodized.where((h) =>
          int.parse(week.value(0, h)) < int.parse(allTime.value(0, h)));

      expect(reduced, isNotEmpty,
          reason: 'la fixture WEEK doit bien couvrir une période partielle');
      expect(int.parse(week.value(0, 'Unique Portals Visited')),
          lessThan(int.parse(allTime.value(0, 'Unique Portals Visited'))));
    });
  });
}
