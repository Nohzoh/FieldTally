/// Counter enrichment layer (§3.1.2, §3.1.4).
///
/// **This is not the list of supported counters.** The app tracks every
/// counter it meets in an export, known or not. The registry only adds
/// comfort: a category, a translated label, a display order and, when known,
/// badge thresholds. A counter missing from it stays fully functional, shown
/// under its raw label in the [CounterRegistry.fallbackCategoryKey] category,
/// at the end of the list.
///
/// The source file is `docs/registry/counters.json`, served by GitHub Pages
/// and fetched at startup, with a bundled copy as fallback.
library;

/// A display category, taken as-is from the Ingress Prime stats screen rather
/// than invented.
class CounterCategory {
  const CounterCategory({
    required this.key,
    required this.order,
    required this.labels,
  });

  final String key;
  final int order;

  /// Labels by language code (`en`, `fr`).
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

/// A badge threshold (bronze, silver, gold, platinum, onyx) or agent level,
/// used by the projections of §3.6.
class CounterTier {
  const CounterTier({required this.name, required this.value});

  final String name;
  final num value;

  factory CounterTier.fromJson(Map<String, dynamic> json) => CounterTier(
        name: json['name'] as String,
        value: json['value'] as num,
      );
}

/// The enrichment entry for one counter.
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

  /// Technical key (`explorer`), distinct from the export header
  /// (`Unique Portals Visited`). It provides stable identity for labels and is
  /// also what the migration CSV columns are named after (Appendix B).
  final String key;

  /// Exact column name in the TSV export. This is what a snapshot is matched
  /// against.
  final String exportHeader;

  final String categoryKey;
  final int order;
  final Map<String, String> labels;

  /// False for the three fields Ingress never scopes to the selected period
  /// (§3.1.3). The behavioural guard skips them.
  final bool periodized;

  /// Empty until thresholds are known: no badge projection is computed then,
  /// only the raw history is shown.
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

/// The loaded registry, ready to answer questions about an export header.
class CounterRegistry {
  CounterRegistry({
    required this.schemaVersion,
    required this.updatedAt,
    required List<CounterCategory> categories,
    required List<CounterEnrichment> counters,
  })  : categories = {for (final c in categories) c.key: c},
        _byExportHeader = {for (final c in counters) c.exportHeader: c},
        _byKey = {for (final c in counters) c.key: c};

  /// Fallback category for any counter not yet enriched.
  static const fallbackCategoryKey = 'other';

  final int schemaVersion;
  final String updatedAt;
  final Map<String, CounterCategory> categories;

  final Map<String, CounterEnrichment> _byExportHeader;
  final Map<String, CounterEnrichment> _byKey;

  /// Empty registry: every counter is unknown to it. Useful as a last resort
  /// if even the bundled copy is unreadable — the app has to keep working.
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
        CounterEnrichment.fromJson(
            entry.key, entry.value as Map<String, dynamic>),
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

  /// Null when the counter is not enriched yet — a normal, expected case
  /// rather than an error.
  CounterEnrichment? forExportHeader(String header) => _byExportHeader[header];

  CounterEnrichment? forKey(String key) => _byKey[key];

  /// Display category for a header, falling back to `other`.
  String categoryKeyFor(String header) =>
      _byExportHeader[header]?.categoryKey ?? fallbackCategoryKey;

  /// The three non periodized fields are marked as such in the registry.
  /// Without an entry, a counter is assumed to be periodized: that is true of
  /// the vast majority, and this default tips the behavioural guard towards
  /// caution (it watches rather than ignores).
  bool isPeriodized(String header) =>
      _byExportHeader[header]?.periodized ?? true;

  /// Orders headers the way the in-game stats screen does: by category, then
  /// by order within it. Unknown counters end up last, sorted alphabetically
  /// so the display stays stable between runs.
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
