/// Période couverte par un relevé, telle que déclarée par la colonne
/// `Time Span` de l'export Ingress (§3.1.3).
///
/// Le principe directeur est une **liste blanche** : seul `ALL TIME` est
/// accepté. Toute autre valeur — connue (`WEEK`, `MONTH`, `NOW`) ou inconnue,
/// y compris une granularité qu'Ingress ajouterait demain — est traitée comme
/// une période partielle et bloque l'import. Une liste noire laisserait passer
/// toute nouveauté, ce qui fausserait silencieusement l'historique.
enum TimeSpan {
  /// Total depuis toujours : la seule valeur exploitable pour l'historique.
  allTime,

  /// Période partielle connue.
  week,
  month,
  now,

  /// Valeur non reconnue. Traitée exactement comme une période partielle : on
  /// refuse par défaut plutôt que de supposer qu'elle vaut `ALL TIME`.
  unknown;

  /// Reconnaît la valeur brute d'un export, insensible à la casse et aux
  /// espaces superflus.
  ///
  /// Ingress écrit `ALL TIME` avec une espace, mais on tolère aussi `ALLTIME`
  /// et `ALL_TIME` : ces variantes ne changent rien au sens et une exigence
  /// trop stricte transformerait un export valide en faux positif.
  factory TimeSpan.parse(String raw) {
    final normalized = raw.trim().toUpperCase().replaceAll(RegExp(r'[\s_-]+'), '');
    return switch (normalized) {
      'ALLTIME' => TimeSpan.allTime,
      'WEEK' || 'THISWEEK' => TimeSpan.week,
      'MONTH' || 'THISMONTH' => TimeSpan.month,
      'NOW' => TimeSpan.now,
      _ => TimeSpan.unknown,
    };
  }

  /// `true` uniquement pour `ALL TIME`. C'est le garde-fou déclaratif du
  /// §3.1.3 réduit à son expression la plus simple.
  bool get isCumulative => this == TimeSpan.allTime;
}
