import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/models/tracked_counter.dart';
import 'package:flutter_test/flutter_test.dart';

StatSnapshot at(DateTime date, Map<String, int> counters) => StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: date,
      level: 9,
      counters: counters,
    );

TrackedCounter of(List<TrackedCounter> counters, String header) =>
    counters.firstWhere((c) => c.exportHeader == header);

void main() {
  const tracker = CounterTracker();

  test('sans relevé, il n\'y a rien à suivre', () {
    expect(tracker.track(const []), isEmpty);
  });

  test('retient première apparition, dernière apparition et dernière valeur', () {
    final counters = tracker.track([
      at(DateTime(2026, 1, 1), {'Hacks': 10}),
      at(DateTime(2026, 1, 20), {'Hacks': 30}),
    ]);

    final hacks = of(counters, 'Hacks');
    expect(hacks.firstSeen, DateTime(2026, 1, 1));
    expect(hacks.lastSeen, DateTime(2026, 1, 20));
    expect(hacks.lastValue, 30);
    expect(hacks.isActive, isTrue);
    expect(hacks.isMonotonic, isTrue);
  });

  test('l\'ordre des relevés fournis n\'a pas d\'importance', () {
    final counters = tracker.track([
      at(DateTime(2026, 1, 20), {'Hacks': 30}),
      at(DateTime(2026, 1, 1), {'Hacks': 10}),
    ]);

    expect(of(counters, 'Hacks').lastValue, 30);
    expect(of(counters, 'Hacks').firstSeen, DateTime(2026, 1, 1));
  });

  group('bascule actif → inactif après 45 jours d\'absence (§3.1.2)', () {
    test('un compteur absent depuis moins de 45 jours reste actif', () {
      final counters = tracker.track([
        at(DateTime(2026, 1, 1), {'Hacks': 10, 'Orion Tokens': 500}),
        at(DateTime(2026, 2, 10), {'Hacks': 30}), // 40 jours plus tard
      ]);

      expect(of(counters, 'Orion Tokens').isActive, isTrue);
    });

    test('au-delà de 45 jours, il passe inactif en gardant sa dernière valeur', () {
      final counters = tracker.track([
        at(DateTime(2026, 1, 1), {'Hacks': 10, 'Orion Tokens': 500}),
        at(DateTime(2026, 3, 1), {'Hacks': 30}), // 59 jours plus tard
      ]);

      final orion = of(counters, 'Orion Tokens');
      expect(orion.isActive, isFalse);
      // Figée, jamais ramenée à zéro.
      expect(orion.lastValue, 500);
      expect(of(counters, 'Hacks').isActive, isTrue);
    });

    test('un compteur qui réapparaît reprend son historique là où il l\'avait laissé', () {
      final counters = tracker.track([
        at(DateTime(2026, 1, 1), {'Orion Tokens': 500}),
        at(DateTime(2026, 3, 1), {}), // absent : saison terminée
        at(DateTime(2026, 6, 1), {'Orion Tokens': 800}), // l'anomalie revient
      ]);

      final orion = of(counters, 'Orion Tokens');
      expect(orion.isActive, isTrue);
      expect(orion.firstSeen, DateTime(2026, 1, 1));
      expect(orion.lastValue, 800);
    });

    test(
      'l\'ancienneté se mesure sur le dernier relevé, pas sur la date du jour',
      () {
        // Un agent qui cesse d'importer pendant six mois ne doit pas retrouver
        // tous ses compteurs en inactif : la règle mesure une absence *dans
        // les imports*, pas le simple passage du temps.
        final counters = tracker.track([
          at(DateTime(2020, 1, 1), {'Hacks': 10}),
          at(DateTime(2020, 1, 15), {'Hacks': 20}),
        ]);

        expect(of(counters, 'Hacks').isActive, isTrue);
      },
    );

    test('le seuil est ajustable', () {
      const strict = CounterTracker(inactivityThreshold: Duration(days: 7));
      final counters = strict.track([
        at(DateTime(2026, 1, 1), {'Hacks': 10, 'Orion Tokens': 500}),
        at(DateTime(2026, 1, 20), {'Hacks': 30}),
      ]);

      expect(of(counters, 'Orion Tokens').isActive, isFalse);
    });
  });
}
