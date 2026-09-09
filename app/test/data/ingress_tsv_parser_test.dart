import 'dart:io';

import 'package:fieldtally/data/parsing/ingress_tsv_parser.dart';
import 'package:fieldtally/data/parsing/parse_exception.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

const allTimePath = 'test/fixtures/sample_export_all_time.tsv';
const weekPath = 'test/fixtures/sample_export_week.tsv';

String fixture(String path) => File(path).readAsStringSync();

/// Reconstruit un export à partir d'en-têtes et de valeurs.
String buildExport(List<String> headers, List<String> values) =>
    '${headers.join('\t')}\n${values.join('\t')}\n';

/// Découpe une fixture en (en-têtes, valeurs).
(List<String>, List<String>) split(String raw) {
  final lines = raw.trim().split('\n');
  return (lines[0].split('\t'), lines[1].split('\t'));
}

void main() {
  const parser = IngressTsvParser();

  group('export ALL TIME réel', () {
    test('extrait les métadonnées du relevé', () {
      final snapshot = parser.parseSingle(fixture(allTimePath));

      expect(snapshot.timeSpan, TimeSpan.allTime);
      expect(snapshot.agentName, 'AgentDemo');
      expect(snapshot.faction, 'Enlightened');
      expect(snapshot.level, 9);
      expect(snapshot.recordedAt, DateTime(2026, 1, 15, 13, 7, 39));
    });

    test('extrait les 59 compteurs', () {
      final snapshot = parser.parseSingle(fixture(allTimePath));

      // 64 colonnes au total, dont 5 de métadonnées pures. `Level` est compté
      // comme compteur : il est suivi dans le temps (Annexe A).
      expect(snapshot.counters, hasLength(59));
      expect(snapshot.counters['Lifetime AP'], 101542335);
      expect(snapshot.counters['Unique Portals Visited'], 9756);
      expect(snapshot.counters['Recursions'], 1);
      expect(snapshot.counters['Level'], 9);
    });

    test('conserve les compteurs à zéro plutôt que de les omettre', () {
      final snapshot = parser.parseSingle(fixture(allTimePath));

      // Un zéro est une information : « jamais fait », pas « inconnu ».
      expect(snapshot.counters['OPR Live Events'], 0);
      expect(snapshot.counters.containsKey('OPR Live Events'), isTrue);
    });
  });

  group('export WEEK réel', () {
    test('expose la période déclarée sans la corriger', () {
      // Le parser ne juge pas : il rapporte fidèlement. C'est le garde-fou
      // (§3.1.3) qui décide de bloquer.
      expect(parser.parseSingle(fixture(weekPath)).timeSpan, TimeSpan.week);
    });
  });

  group('mapping par nom d\'en-tête, jamais par position (§3.1.1)', () {
    test('un export aux colonnes réordonnées donne le même résultat', () {
      final (headers, values) = split(fixture(allTimePath));

      // On inverse complètement l'ordre des colonnes : un parser positionnel
      // produirait n'importe quoi, celui-ci doit être insensible.
      final indices = List.generate(headers.length, (i) => i).reversed.toList();
      final shuffled = buildExport(
        [for (final i in indices) headers[i]],
        [for (final i in indices) values[i]],
      );

      final original = parser.parseSingle(fixture(allTimePath));
      final reordered = parser.parseSingle(shuffled);

      expect(reordered.agentName, original.agentName);
      expect(reordered.level, original.level);
      expect(reordered.recordedAt, original.recordedAt);
      expect(reordered.counters, equals(original.counters));
    });

    test('une colonne inconnue devient un compteur suivi (§3.1.2)', () {
      final (headers, values) = split(fixture(allTimePath));
      final raw = buildExport(
        [...headers, 'Zeta Anomaly Tokens'],
        [...values, '4242'],
      );

      final snapshot = parser.parseSingle(raw);

      // Aucune liste codée en dur : un compteur inédit est suivi dès sa
      // première apparition, sans attendre une mise à jour de l'app.
      expect(snapshot.counters['Zeta Anomaly Tokens'], 4242);
      expect(snapshot.counters, hasLength(60));
    });

    test('la disparition d\'un compteur ne casse pas le parsing', () {
      final (headers, values) = split(fixture(allTimePath));
      final index = headers.indexOf('Orion Tokens');
      headers.removeAt(index);
      values.removeAt(index);

      final snapshot = parser.parseSingle(buildExport(headers, values));

      expect(snapshot.counters.containsKey('Orion Tokens'), isFalse);
      expect(snapshot.counters, hasLength(58));
      expect(snapshot.counters['Apollo Tokens'], 12802);
    });

    test('tolère un suffixe de format changeant sur Date et Time', () {
      final (headers, values) = split(fixture(allTimePath));
      headers[headers.indexOf('Date (yyyy-mm-dd)')] = 'Date';
      headers[headers.indexOf('Time (hh:mm:ss)')] = 'Time';

      final snapshot = parser.parseSingle(buildExport(headers, values));

      expect(snapshot.recordedAt, DateTime(2026, 1, 15, 13, 7, 39));
    });
  });

  group('formats numériques locaux (§6)', () {
    for (final entry in {
      'espace fine': '101 542 335',
      'virgule anglo-saxonne': '101,542,335',
      'point allemand': '101.542.335',
      'apostrophe suisse': "101'542'335",
    }.entries) {
      test('accepte un séparateur de milliers : ${entry.key}', () {
        final (headers, values) = split(fixture(allTimePath));
        values[headers.indexOf('Lifetime AP')] = entry.value;

        final snapshot = parser.parseSingle(buildExport(headers, values));

        expect(snapshot.counters['Lifetime AP'], 101542335);
      });
    }
  });

  group('échecs propres (§3.1)', () {
    test('texte vide', () {
      expect(() => parser.parse(''), throwsA(isA<ExportParseException>()));
    });

    test('en-têtes sans ligne de valeurs', () {
      final (headers, _) = split(fixture(allTimePath));
      expect(
        () => parser.parse('${headers.join('\t')}\n'),
        throwsA(isA<ExportParseException>()),
      );
    });

    test('texte non tabulé', () {
      expect(
        () => parser.parse('bonjour\nceci n\'est pas un export'),
        throwsA(isA<ExportParseException>()),
      );
    });

    test('colonne de métadonnée absente', () {
      final (headers, values) = split(fixture(allTimePath));
      final index = headers.indexOf('Agent Name');
      headers.removeAt(index);
      values.removeAt(index);

      expect(
        () => parser.parseSingle(buildExport(headers, values)),
        throwsA(
          isA<ExportParseException>()
              .having((e) => e.column, 'column', 'Agent Name'),
        ),
      );
    });

    test('en-têtes en doublon', () {
      final raw = buildExport(
        ['Time Span', 'Agent Name', 'Agent Faction', 'Date', 'Time', 'Level', 'Hacks', 'Hacks'],
        ['ALL TIME', 'AgentDemo', 'Enlightened', '2026-01-15', '13:07:39', '9', '1', '2'],
      );

      expect(
        () => parser.parseSingle(raw),
        throwsA(isA<ExportParseException>().having(
          (e) => e.toString(),
          'message',
          contains('deux colonnes'),
        )),
      );
    });

    test('nombre de valeurs incohérent avec les en-têtes', () {
      final (headers, values) = split(fixture(allTimePath));
      values.removeLast();

      expect(
        () => parser.parseSingle(buildExport(headers, values)),
        throwsA(isA<ExportParseException>()),
      );
    });

    test('valeur non numérique, signalée avec sa colonne et sa valeur brute', () {
      final (headers, values) = split(fixture(allTimePath));
      values[headers.indexOf('Hacks')] = 'beaucoup';

      expect(
        () => parser.parseSingle(buildExport(headers, values)),
        throwsA(
          isA<ExportParseException>()
              .having((e) => e.column, 'column', 'Hacks')
              .having((e) => e.rawValue, 'rawValue', 'beaucoup'),
        ),
      );
    });

    test('date inexistante', () {
      final (headers, values) = split(fixture(allTimePath));
      values[headers.indexOf('Date (yyyy-mm-dd)')] = '2026-02-30';

      expect(
        () => parser.parseSingle(buildExport(headers, values)),
        throwsA(isA<ExportParseException>()
            .having((e) => e.column, 'column', 'Date')),
      );
    });

    test('rien n\'est enregistré à moitié en cas d\'erreur', () {
      final (headers, values) = split(fixture(allTimePath));
      values[headers.indexOf('Hacks')] = '';

      // Le parser lève plutôt que de renvoyer un relevé partiel : mieux vaut
      // un échec visible qu'un historique faussé en silence.
      expect(
        () => parser.parseSingle(buildExport(headers, values)),
        throwsA(isA<ExportParseException>()),
      );
    });
  });

  group('robustesse du copier-coller', () {
    test('supporte les fins de ligne Windows et un BOM', () {
      final raw = '﻿${fixture(allTimePath).replaceAll('\n', '\r\n')}';

      expect(parser.parseSingle(raw).agentName, 'AgentDemo');
    });

    test('ignore les lignes vides en fin de texte', () {
      expect(
        parser.parseSingle('${fixture(allTimePath)}\n\n  \n').level,
        9,
      );
    });

    test('l\'heure est optionnelle et vaut minuit par défaut (Annexe B)', () {
      final (headers, values) = split(fixture(allTimePath));
      values[headers.indexOf('Time (hh:mm:ss)')] = '';

      final snapshot = parser.parseSingle(buildExport(headers, values));

      expect(snapshot.recordedAt, DateTime(2026, 1, 15));
    });
  });
}
