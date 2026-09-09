import 'dart:io';

import 'package:fieldtally/data/parsing/ingress_tsv_parser.dart';
import 'package:fieldtally/domain/guards/import_guards.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

const allTimePath = 'test/fixtures/sample_export_all_time.tsv';
const weekPath = 'test/fixtures/sample_export_week.tsv';

StatSnapshot load(String path) =>
    const IngressTsvParser().parseSingle(File(path).readAsStringSync());

StatSnapshot snapshotWith({
  TimeSpan timeSpan = TimeSpan.allTime,
  required Map<String, int> counters,
  DateTime? recordedAt,
}) =>
    StatSnapshot(
      timeSpan: timeSpan,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: recordedAt ?? DateTime(2026, 1, 15),
      level: 9,
      counters: counters,
    );

void main() {
  const guards = ImportGuards();

  group('garde-fou n°1 — déclaratif, en liste blanche', () {
    test('un export ALL TIME passe', () {
      final check = guards.check(load(allTimePath));

      expect(check.isPartialPeriod, isFalse);
      expect(check.isBlocked, isFalse);
      expect(check.message, isNull);
    });

    test('un export WEEK est bloqué, avec un message qui nomme la période', () {
      final check = guards.check(load(weekPath));

      expect(check.isPartialPeriod, isTrue);
      expect(check.isBlocked, isTrue);
      expect(check.message, contains('WEEK'));
      expect(check.message, contains('All Time'));
    });

    for (final span in [TimeSpan.week, TimeSpan.month, TimeSpan.now]) {
      test('${span.name} est refusé', () {
        final check =
            guards.check(snapshotWith(timeSpan: span, counters: const {}));
        expect(check.isBlocked, isTrue);
      });
    }

    test('une granularité future et inconnue est refusée par défaut', () {
      // Le cœur du choix « liste blanche plutôt que liste noire » : ce qu'on
      // ne connaît pas est traité comme partiel, jamais supposé cumulatif.
      expect(TimeSpan.parse('THIS QUARTER'), TimeSpan.unknown);
      expect(TimeSpan.parse('THIS QUARTER').isCumulative, isFalse);
    });

    test('la reconnaissance est insensible à la casse et aux espaces', () {
      for (final raw in ['all time', 'ALL TIME', '  All Time  ', 'all_time']) {
        expect(TimeSpan.parse(raw), TimeSpan.allTime, reason: raw);
      }
    });
  });

  group('garde-fou n°2 — comportemental', () {
    test('sans relevé antérieur, il n\'a rien à comparer et le dit', () {
      final check = guards.check(load(allTimePath));

      expect(check.comparedAgainstPrevious, isFalse);
      expect(check.regressions, isEmpty);
    });

    test('deux relevés cohérents ne déclenchent rien', () {
      final previous = snapshotWith(counters: const {'Hacks': 100});
      final check = guards.check(
        snapshotWith(counters: const {'Hacks': 120}),
        previous: previous,
      );

      expect(check.hasRegressions, isFalse);
      expect(check.isBlocked, isFalse);
    });

    test('un compteur qui recule est signalé avec son ampleur', () {
      final check = guards.check(
        snapshotWith(counters: const {'Hacks': 80}),
        previous: snapshotWith(counters: const {'Hacks': 100}),
      );

      expect(check.regressions, hasLength(1));
      expect(check.regressions.single.exportHeader, 'Hacks');
      expect(check.regressions.single.previous, 100);
      expect(check.regressions.single.current, 80);
      expect(check.regressions.single.drop, 20);
      expect(check.isBlocked, isTrue);
    });

    test('les reculs sont triés du plus gros au plus petit', () {
      final check = guards.check(
        snapshotWith(counters: const {'Hacks': 90, 'Links Created': 10}),
        previous: snapshotWith(counters: const {'Hacks': 100, 'Links Created': 500}),
      );

      expect(
        check.regressions.map((r) => r.exportHeader),
        ['Links Created', 'Hacks'],
      );
    });

    test('un compteur qui apparaît n\'est pas une régression', () {
      final check = guards.check(
        snapshotWith(counters: const {'Hacks': 100, 'Zeta Tokens': 5}),
        previous: snapshotWith(counters: const {'Hacks': 100}),
      );

      expect(check.hasRegressions, isFalse);
    });

    test('un compteur qui disparaît n\'est jamais lu comme un retour à 0', () {
      // Règle du §3.1.2 : l'absence n'est pas un zéro. Un compteur d'anomalie
      // terminée ne doit pas polluer l'écran d'anomalie à chaque import.
      final check = guards.check(
        snapshotWith(counters: const {'Hacks': 100}),
        previous: snapshotWith(counters: const {'Hacks': 100, 'Orion Tokens': 14204}),
      );

      expect(check.hasRegressions, isFalse);
    });

    test('le message énumère et s\'accorde au nombre de compteurs', () {
      final one = guards.check(
        snapshotWith(counters: const {'Hacks': 80}),
        previous: snapshotWith(counters: const {'Hacks': 100}),
      );
      expect(one.message, contains('1 compteur a diminué'));

      final many = guards.check(
        snapshotWith(counters: const {'Hacks': 80, 'Links Created': 1}),
        previous: snapshotWith(counters: const {'Hacks': 100, 'Links Created': 9}),
      );
      expect(many.message, contains('2 compteurs ont diminué'));
    });

    test('le garde-fou déclaratif prime dans le message quand les deux sautent', () {
      // Une période partielle explique déjà tous les reculs : montrer d'abord
      // la cause plutôt que ses conséquences.
      final check = guards.check(
        snapshotWith(timeSpan: TimeSpan.week, counters: const {'Hacks': 80}),
        previous: snapshotWith(counters: const {'Hacks': 100}),
      );

      expect(check.isPartialPeriod, isTrue);
      expect(check.hasRegressions, isTrue);
      expect(check.message, contains('WEEK'));
    });

    test('la tolérance, quand elle est réglée, absorbe les petits reculs', () {
      const tolerant = ImportGuards(tolerance: 5);
      final previous = snapshotWith(counters: const {'Hacks': 100});

      expect(
        tolerant.check(snapshotWith(counters: const {'Hacks': 96}), previous: previous)
            .hasRegressions,
        isFalse,
      );
      expect(
        tolerant.check(snapshotWith(counters: const {'Hacks': 94}), previous: previous)
            .hasRegressions,
        isTrue,
      );
    });
  });

  group('le cas qui justifie les deux garde-fous ensemble (§3.1.3)', () {
    test('un WEEK importé après un ALL TIME déclenche le garde-fou n°2', () {
      final check = guards.check(load(weekPath), previous: load(allTimePath));

      expect(check.hasRegressions, isTrue);
      expect(
        check.regressions.map((r) => r.exportHeader),
        contains('Unique Portals Visited'),
      );
    });

    test(
      'mais Level, Lifetime AP et Current AP ne donnent aucun signal',
      () {
        // Découverte du §3.1.3 : Ingress ne périodise jamais ces trois champs.
        // Un garde-fou qui ne surveillerait que l'AP laisserait donc passer un
        // import WEEK sans broncher. C'est précisément ce que ce test verrouille.
        final check = guards.check(load(weekPath), previous: load(allTimePath));

        expect(
          check.regressions.map((r) => r.exportHeader),
          isNot(anyElement(isIn(StatSnapshot.nonPeriodizedHeaders))),
        );
      },
    );

    test('surveiller le seul AP ne détecterait rien — démonstration', () {
      final allTime = load(allTimePath);
      final week = load(weekPath);

      for (final header in StatSnapshot.nonPeriodizedHeaders) {
        expect(week.counters[header], allTime.counters[header], reason: header);
      }
    });

    test('le garde-fou n°2 protège le CSV, qui n\'a pas de Time Span', () {
      // Sur ce chemin (Annexe B), le garde-fou déclaratif est aveugle : la
      // colonne n'existe pas. La monotonie est alors la seule protection, ce
      // qui est une raison de plus pour ne jamais la désactiver.
      final check = guards.check(
        snapshotWith(timeSpan: TimeSpan.unknown, counters: const {'Hacks': 40}),
        previous: snapshotWith(counters: const {'Hacks': 78735}),
      );

      expect(check.isPartialPeriod, isFalse);
      expect(check.hasRegressions, isTrue);
      expect(check.isBlocked, isTrue);
    });
  });
}
