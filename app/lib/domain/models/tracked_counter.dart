import 'stat_snapshot.dart';

/// Statut d'un compteur, déterminé **uniquement** par sa présence dans les
/// imports récents (§3.1.2).
///
/// Il n'existe volontairement pas de notion a priori de compteur « éphémère » :
/// au moment où un compteur apparaît pour la première fois, rien ne permet de
/// savoir s'il sera temporaire (façon Orion/Apollo) ou permanent. Une règle
/// unique s'applique donc à tous — compteur d'anomalie qui se termine, compteur
/// du jeu de base retiré par Niantic, ou nouveauté inconnue.
enum CounterStatus { active, inactive }

/// Ce que l'app sait d'un compteur, en plus de son historique de valeurs.
class TrackedCounter {
  const TrackedCounter({
    required this.exportHeader,
    required this.firstSeen,
    required this.lastSeen,
    required this.lastValue,
    required this.status,
    this.isMonotonic = true,
  });

  /// Identité stable du compteur : le nom de sa colonne d'export.
  final String exportHeader;

  final DateTime firstSeen;
  final DateTime lastSeen;

  /// Dernière valeur connue. Reste affichée, figée, quand le compteur passe
  /// inactif — jamais interprétée comme un retour à 0.
  final int lastValue;

  final CounterStatus status;

  /// Alimente le garde-fou comportemental. Vrai par défaut : la quasi-totalité
  /// des compteurs Ingress ne peuvent que croître ou rester stables.
  final bool isMonotonic;

  bool get isActive => status == CounterStatus.active;

  @override
  String toString() =>
      'TrackedCounter($exportHeader, $lastValue, ${status.name}, vu le $lastSeen)';
}

/// Dérive l'état des compteurs à partir de l'historique des relevés.
///
/// Rien n'est stocké en dur : comme toutes les vues du §3.2, ce calcul repart
/// des relevés, pour rester cohérent si l'un d'eux est corrigé ou supprimé.
class CounterTracker {
  const CounterTracker({this.inactivityThreshold = const Duration(days: 45)});

  /// Durée d'absence au bout de laquelle un compteur bascule en inactif.
  final Duration inactivityThreshold;

  /// [snapshots] n'a pas besoin d'être trié.
  ///
  /// L'ancienneté se mesure par rapport au **relevé le plus récent**, pas par
  /// rapport à la date du jour. Sans quoi un agent qui cesse d'importer
  /// pendant deux mois verrait tous ses compteurs basculer en inactif d'un
  /// coup, alors qu'il ne s'est rien passé côté jeu : c'est bien une absence
  /// *dans les imports* que la règle mesure, pas une absence dans le temps.
  List<TrackedCounter> track(List<StatSnapshot> snapshots) {
    if (snapshots.isEmpty) return const [];

    final sorted = [...snapshots]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final reference = sorted.last.recordedAt;

    final firstSeen = <String, DateTime>{};
    final lastSeen = <String, DateTime>{};
    final lastValue = <String, int>{};

    for (final snapshot in sorted) {
      for (final entry in snapshot.counters.entries) {
        firstSeen.putIfAbsent(entry.key, () => snapshot.recordedAt);
        lastSeen[entry.key] = snapshot.recordedAt;
        lastValue[entry.key] = entry.value;
      }
    }

    return [
      for (final header in lastSeen.keys)
        TrackedCounter(
          exportHeader: header,
          firstSeen: firstSeen[header]!,
          lastSeen: lastSeen[header]!,
          lastValue: lastValue[header]!,
          status: reference.difference(lastSeen[header]!) > inactivityThreshold
              ? CounterStatus.inactive
              : CounterStatus.active,
        ),
    ];
  }
}
