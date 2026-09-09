import 'time_span.dart';

/// Un relevé daté, produit par un import (collage, partage ou CSV).
///
/// Les valeurs de compteurs sont indexées par **le nom de colonne de l'export**
/// (`Unique Portals Visited`), pas par la clé technique du registre
/// (`explorer`). C'est délibéré, et ça découle du §3.1.2 : un compteur inconnu
/// doit être suivi dès sa première apparition, avant même qu'une entrée
/// d'enrichissement existe pour lui. Si on indexait par clé technique, un
/// compteur suivi sous un identifiant provisoire verrait son historique se
/// rompre le jour où quelqu'un lui donne sa vraie clé dans le registre.
///
/// L'en-tête d'export est en revanche stable dans le temps pour un compteur
/// donné, et c'est aussi lui que le registre référence via `export_header`.
class StatSnapshot {
  const StatSnapshot({
    required this.timeSpan,
    required this.agentName,
    required this.faction,
    required this.recordedAt,
    required this.level,
    required this.counters,
  });

  /// Période déclarée par l'export. Voir [TimeSpan] et le §3.1.3.
  final TimeSpan timeSpan;

  final String agentName;
  final String faction;

  /// Date et heure du relevé, recomposées depuis les colonnes `Date` et `Time`.
  final DateTime recordedAt;

  final int level;

  /// Valeurs brutes, indexées par en-tête d'export.
  final Map<String, int> counters;

  /// Les trois champs qu'Ingress ne périodise **jamais** : ils sont identiques
  /// entre un export `ALL TIME` et un export `WEEK` du même agent au même
  /// moment (constat du §3.1.3).
  ///
  /// Conséquence directe : le garde-fou comportemental ne peut pas s'appuyer
  /// dessus. Un import `WEEK` fait par erreur laisserait l'AP inchangé et
  /// passerait inaperçu si on ne surveillait que lui.
  static const nonPeriodizedHeaders = {'Level', 'Lifetime AP', 'Current AP'};

  @override
  String toString() =>
      'StatSnapshot($agentName, $timeSpan, $recordedAt, ${counters.length} compteurs)';
}
