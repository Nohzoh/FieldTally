/// Échec de parsing d'un export Ingress.
///
/// Le format n'est pas documenté par Niantic et peut changer sans préavis
/// (§3.1, §6). La règle est donc d'échouer **proprement et bruyamment** :
/// jamais de valeur devinée, jamais d'enregistrement silencieux de données
/// fausses. Chaque exception porte de quoi construire un message
/// compréhensible et, à terme, proposer une correction manuelle.
class ExportParseException implements Exception {
  const ExportParseException(this.message, {this.column, this.rawValue});

  /// Message destiné à être montré tel quel à l'utilisateur.
  final String message;

  /// En-tête de la colonne fautive, quand l'erreur est localisée.
  final String? column;

  /// Valeur brute rejetée, pour que l'utilisateur puisse la corriger.
  final String? rawValue;

  @override
  String toString() {
    final details = [
      if (column != null) 'colonne "$column"',
      if (rawValue != null) 'valeur "$rawValue"',
    ];
    return details.isEmpty ? message : '$message (${details.join(', ')})';
  }
}
