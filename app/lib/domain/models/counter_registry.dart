/// Couche d'enrichissement des compteurs (§3.1.2, §3.1.4).
///
/// **Ce n'est pas la liste des compteurs supportés.** L'app suit tout compteur
/// qu'elle rencontre dans un export, connu ou non. Le registre n'ajoute que du
/// confort : une catégorie, un libellé traduit, un ordre d'affichage et, quand
/// ils sont connus, des seuils de palier. Un compteur absent d'ici reste
/// pleinement fonctionnel, affiché sous son libellé brut dans la catégorie
/// [CounterRegistry.fallbackCategoryKey], en fin de liste.
///
/// Le fichier source est `docs/registry/counters.json`, servi par GitHub Pages
/// et récupéré au démarrage, avec une copie embarquée en repli.
library;

/// Une catégorie d'affichage, reprise telle quelle de l'écran de stats
/// d'Ingress Prime plutôt qu'inventée.
class CounterCategory {
  const CounterCategory({
    required this.key,
    required this.order,
    required this.labels,
  });

  final String key;
  final int order;

  /// Libellés par code langue (`en`, `fr`).
  final Map<String, String> labels;

  String label(String languageCode) =>
      labels[languageCode] ?? labels['en'] ?? key;

  factory CounterCategory.fromJson(Map<String, dynamic> json) =>
      CounterCategory(
        key: json['key'] as String,
        order: json['order'] as int,
        labels: Map<String, String>.from(json['label'] as Map),
      );
}

/// Un seuil de palier de médaille (bronze, argent, or, platine, onyx) ou de
/// niveau d'agent, utilisé par les projections du §3.6.
class CounterTier {
  const CounterTier({required this.name, required this.value});

  final String name;
  final num value;

  factory CounterTier.fromJson(Map<String, dynamic> json) => CounterTier(
        name: json['name'] as String,
        value: json['value'] as num,
      );
}

/// L'entrée d'enrichissement d'un compteur.
class CounterEnrichment {
  const CounterEnrichment({
    required this.key,
    required this.exportHeader,
    required this.categoryKey,
    required this.order,
    required this.labels,
    this.periodized = true,
    this.tiers = const [],
  });

  /// Clé technique (`explorer`), distincte de l'en-tête d'export
  /// (`Unique Portals Visited`). Elle sert aux libellés stables et à
  /// l'import CSV de migration, dont les colonnes portent ces noms (Annexe B).
  final String key;

  /// Nom exact de la colonne dans l'export TSV. C'est par lui que se fait la
  /// correspondance avec un relevé.
  final String exportHeader;

  final String categoryKey;
  final int order;
  final Map<String, String> labels;

  /// `false` pour les trois champs qu'Ingress ne réduit jamais à la période
  /// sélectionnée (§3.1.3). Le garde-fou comportemental les ignore.
  final bool periodized;

  /// Vide tant que les seuils ne sont pas connus : aucune projection de palier
  /// n'est alors calculée, seul l'historique brut est affiché.
  final List<CounterTier> tiers;

  String label(String languageCode) =>
      labels[languageCode] ?? labels['en'] ?? exportHeader;

  factory CounterEnrichment.fromJson(String key, Map<String, dynamic> json) =>
      CounterEnrichment(
        key: key,
        exportHeader: json['export_header'] as String,
        categoryKey: json['category'] as String,
        order: json['order'] as int,
        labels: Map<String, String>.from(json['label'] as Map),
        periodized: json['periodized'] as bool? ?? true,
        tiers: [
          for (final tier in (json['tiers'] as List? ?? const []))
            CounterTier.fromJson(tier as Map<String, dynamic>),
        ],
      );
}

/// Le registre chargé, prêt à répondre sur un en-tête d'export.
class CounterRegistry {
  CounterRegistry({
    required this.schemaVersion,
    required this.updatedAt,
    required List<CounterCategory> categories,
    required List<CounterEnrichment> counters,
  })  : categories = {for (final c in categories) c.key: c},
        _byExportHeader = {for (final c in counters) c.exportHeader: c},
        _byKey = {for (final c in counters) c.key: c};

  /// Catégorie de repli pour tout compteur pas encore enrichi.
  static const fallbackCategoryKey = 'other';

  final int schemaVersion;
  final String updatedAt;
  final Map<String, CounterCategory> categories;

  final Map<String, CounterEnrichment> _byExportHeader;
  final Map<String, CounterEnrichment> _byKey;

  /// Registre vide : tout compteur y est inconnu. Utile comme repli si même la
  /// copie embarquée est illisible — l'app doit rester fonctionnelle.
  factory CounterRegistry.empty() => CounterRegistry(
        schemaVersion: 0,
        updatedAt: '',
        categories: const [],
        counters: const [],
      );

  factory CounterRegistry.fromJson(Map<String, dynamic> json) {
    final counters = <CounterEnrichment>[];
    final raw = json['counters'] as Map<String, dynamic>? ?? const {};
    for (final entry in raw.entries) {
      counters.add(
        CounterEnrichment.fromJson(entry.key, entry.value as Map<String, dynamic>),
      );
    }

    return CounterRegistry(
      schemaVersion: json['schema_version'] as int? ?? 0,
      updatedAt: json['updated_at'] as String? ?? '',
      categories: [
        for (final c in (json['categories'] as List? ?? const []))
          CounterCategory.fromJson(c as Map<String, dynamic>),
      ],
      counters: counters,
    );
  }

  int get length => _byExportHeader.length;

  /// `null` si le compteur n'est pas encore enrichi — ce qui est un cas normal
  /// et attendu, pas une erreur.
  CounterEnrichment? forExportHeader(String header) => _byExportHeader[header];

  CounterEnrichment? forKey(String key) => _byKey[key];

  /// Catégorie d'affichage d'un en-tête, avec repli sur `other`.
  String categoryKeyFor(String header) =>
      _byExportHeader[header]?.categoryKey ?? fallbackCategoryKey;

  /// Les trois champs non périodisés sont marqués comme tels dans le registre.
  /// En l'absence d'entrée, on suppose le compteur périodisé : c'est le cas de
  /// l'immense majorité, et cette valeur par défaut fait pencher le garde-fou
  /// comportemental du côté prudent (il surveille plutôt que d'ignorer).
  bool isPeriodized(String header) => _byExportHeader[header]?.periodized ?? true;

  /// Ordonne des en-têtes comme l'écran de stats du jeu : par catégorie, puis
  /// par ordre interne. Les compteurs inconnus se retrouvent en fin de liste,
  /// triés alphabétiquement pour rester stables d'un affichage à l'autre.
  List<String> sortHeaders(Iterable<String> headers) {
    final sorted = headers.toList();
    sorted.sort((a, b) {
      final ea = _byExportHeader[a];
      final eb = _byExportHeader[b];

      if (ea == null && eb == null) return a.compareTo(b);
      if (ea == null) return 1;
      if (eb == null) return -1;

      final ca = categories[ea.categoryKey]?.order ?? 1 << 30;
      final cb = categories[eb.categoryKey]?.order ?? 1 << 30;
      if (ca != cb) return ca.compareTo(cb);
      if (ea.order != eb.order) return ea.order.compareTo(eb.order);
      return a.compareTo(b);
    });
    return sorted;
  }
}
