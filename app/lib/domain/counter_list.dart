import 'models/counter_registry.dart';
import 'models/tracked_counter.dart';

/// How the detailed stats list is ordered (§3.4).
enum CounterSort {
  /// The default: the categories and order of the in-game stats screen.
  ///
  /// Chosen over a flat list so the app stays immediately familiar to anyone
  /// who already knows the Ingress stats screen.
  category,

  /// Alphabetical, on the label as displayed.
  name,

  /// Largest progress since the previous snapshot first.
  recentProgress,
}

/// What the user asked to see.
class CounterQuery {
  const CounterQuery({
    this.search = '',
    this.sort = CounterSort.category,
    this.includeInactive = true,
  });

  final String search;
  final CounterSort sort;

  /// Inactive counters stay visible by default: the game shows them, and their
  /// last value is meaningful history rather than noise (§3.1.2).
  final bool includeInactive;

  CounterQuery copyWith({
    String? search,
    CounterSort? sort,
    bool? includeInactive,
  }) =>
      CounterQuery(
        search: search ?? this.search,
        sort: sort ?? this.sort,
        includeInactive: includeInactive ?? this.includeInactive,
      );
}

/// A block of counters in the list.
///
/// [categoryKey] is null when the ordering is not by category, in which case
/// there is a single flat section.
class CounterSection {
  const CounterSection({required this.categoryKey, required this.counters});

  final String? categoryKey;
  final List<TrackedCounter> counters;
}

/// Turns the tracked counters into the sections the list displays.
///
/// Pure logic, deliberately kept out of the widgets: sorting and searching are
/// exactly the kind of thing worth testing without pumping a screen.
class CounterListBuilder {
  const CounterListBuilder({required this.registry, required this.language});

  final CounterRegistry? registry;

  /// Language code used to resolve labels, so searching matches what the user
  /// actually reads on screen.
  final String language;

  /// Label shown for a counter: its enriched translation, or its raw export
  /// header when the registry does not know it yet (§3.1.2).
  String labelFor(TrackedCounter counter) =>
      registry?.forExportHeader(counter.exportHeader)?.label(language) ??
      counter.exportHeader;

  List<CounterSection> build(
    List<TrackedCounter> counters,
    CounterQuery query,
  ) {
    var visible = counters.where((c) => query.includeInactive || c.isActive);

    final search = query.search.trim().toLowerCase();
    if (search.isNotEmpty) {
      // Search both the displayed label and the raw header: an agent may well
      // type the English name they saw in the game even with a French UI.
      visible = visible.where((c) =>
          labelFor(c).toLowerCase().contains(search) ||
          c.exportHeader.toLowerCase().contains(search));
    }

    final list = visible.toList();

    return switch (query.sort) {
      CounterSort.category => _byCategory(list),
      CounterSort.name => [
          CounterSection(
            categoryKey: null,
            counters: list
              ..sort((a, b) => labelFor(a)
                  .toLowerCase()
                  .compareTo(labelFor(b).toLowerCase())),
          ),
        ],
      CounterSort.recentProgress => [
          CounterSection(
            categoryKey: null,
            // A counter with no comparison point yet sorts last: it is not
            // "zero progress", it is "not known yet".
            counters: list
              ..sort((a, b) {
                final da = a.delta;
                final db = b.delta;
                if (da == null && db == null) {
                  return labelFor(a).compareTo(labelFor(b));
                }
                if (da == null) return 1;
                if (db == null) return -1;
                if (da != db) return db.compareTo(da);
                return labelFor(a).compareTo(labelFor(b));
              }),
          ),
        ],
    };
  }

  List<CounterSection> _byCategory(List<TrackedCounter> counters) {
    final registry = this.registry;

    // Reuse the registry's own ordering so the list matches the game exactly,
    // including where unknown counters land.
    final ordered = registry == null
        ? (counters..sort((a, b) => a.exportHeader.compareTo(b.exportHeader)))
        : _orderedByRegistry(counters, registry);

    final sections = <String, List<TrackedCounter>>{};
    for (final counter in ordered) {
      final key = registry?.categoryKeyFor(counter.exportHeader) ??
          CounterRegistry.fallbackCategoryKey;
      (sections[key] ??= []).add(counter);
    }

    return [
      for (final entry in sections.entries)
        CounterSection(categoryKey: entry.key, counters: entry.value),
    ];
  }

  List<TrackedCounter> _orderedByRegistry(
    List<TrackedCounter> counters,
    CounterRegistry registry,
  ) {
    final byHeader = {for (final c in counters) c.exportHeader: c};
    final sortedHeaders = registry.sortHeaders(byHeader.keys);
    return [for (final header in sortedHeaders) byHeader[header]!];
  }
}
