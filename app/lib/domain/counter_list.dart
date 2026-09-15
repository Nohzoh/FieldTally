import 'badge_projection.dart';
import 'counter_pace.dart';
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

  /// Fastest recent progress first, measured over the query's window (#89).
  ///
  /// A pace rather than a bare difference: the window anchors on a real
  /// snapshot, which may sit well before the cutoff, so only dividing by the
  /// span actually measured makes two counters comparable.
  recentProgress,

  /// Closest to its next badge tier first (#90).
  ///
  /// Measured as the share of the current stretch already crossed, which is
  /// the only reading comparable across counters five orders of magnitude
  /// apart. Past onyx the stretch runs to the next multiple (#87), so an agent
  /// who has finished a badge is not lumped in with counters that have none.
  nextTier,
}

/// What the user asked to see.
class CounterQuery {
  const CounterQuery({
    this.search = '',
    this.sort = CounterSort.category,
    this.includeInactive = true,
    this.medalsOnly = false,
    this.window = ProgressWindow.sinceLastSnapshot,
  });

  final String search;
  final CounterSort sort;

  /// Inactive counters stay visible by default: the game shows them, and their
  /// last value is meaningful history rather than noise (§3.1.2).
  final bool includeInactive;

  /// Narrows the list to counters that carry a badge (#88).
  ///
  /// Seventeen of the fifty-nine counters the registry knows have thresholds,
  /// so this hides about seven rows in ten — and what is left is the set the
  /// app has the most to say about: a medal, a tier, a projection, a date.
  final bool medalsOnly;

  /// How far back [CounterSort.recentProgress] measures (#89).
  final ProgressWindow window;

  CounterQuery copyWith({
    String? search,
    CounterSort? sort,
    bool? includeInactive,
    bool? medalsOnly,
    ProgressWindow? window,
  }) =>
      CounterQuery(
        search: search ?? this.search,
        sort: sort ?? this.sort,
        includeInactive: includeInactive ?? this.includeInactive,
        medalsOnly: medalsOnly ?? this.medalsOnly,
        window: window ?? this.window,
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
  const CounterListBuilder({
    required this.registry,
    required this.language,
    this.pace = const {},
  });

  final CounterRegistry? registry;

  /// Each counter's pace over the query's window, from [paceByCounter] (#89).
  ///
  /// Passed in rather than derived here: measuring needs the whole history,
  /// and this builder deliberately sees only the counters. A counter missing
  /// from the map has no measurable pace, which sorts as "not known yet"
  /// rather than as zero.
  final Map<String, CounterPace> pace;

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

    if (query.medalsOnly) {
      // Read from the registry, like the emblems themselves. With no registry
      // nothing qualifies — which is why the screen does not offer the filter
      // until one has loaded, rather than emptying the list without saying so.
      visible = visible.where(carriesMedal);
    }

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
      CounterSort.recentProgress => _byMeasure(
          list,
          (counter) => pace[counter.exportHeader]?.perDay,
        ),
      CounterSort.nextTier => _byMeasure(
          list,
          (counter) => tierProgress(
            registry?.forExportHeader(counter.exportHeader),
            counter.lastValue,
          ),
        ),
    };
  }

  /// True for a counter the registry gives badge thresholds.
  bool carriesMedal(TrackedCounter counter) =>
      registry?.forExportHeader(counter.exportHeader)?.tiers.isNotEmpty ??
      false;

  /// One flat section, largest measure first, with everything the measure
  /// cannot speak about gathered at the end.
  ///
  /// Null is never folded into zero. A counter with no second snapshot has not
  /// made "no progress", and one with no thresholds is not "furthest from its
  /// next tier" — saying either would be a claim the data does not support.
  /// They sit in a block at the bottom, ordered by label so the list is stable
  /// between rebuilds.
  List<CounterSection> _byMeasure(
    List<TrackedCounter> counters,
    double? Function(TrackedCounter) measure,
  ) {
    int byLabel(TrackedCounter a, TrackedCounter b) =>
        labelFor(a).toLowerCase().compareTo(labelFor(b).toLowerCase());

    final sorted = [...counters]..sort((a, b) {
        final ma = measure(a);
        final mb = measure(b);
        if (ma == null && mb == null) return byLabel(a, b);
        if (ma == null) return 1;
        if (mb == null) return -1;
        // Largest first: the closest to its next tier is the one furthest
        // across the stretch, not the one with the least left in absolute
        // terms — easy to write backwards, so it is pinned by a test.
        final compared = mb.compareTo(ma);
        return compared != 0 ? compared : byLabel(a, b);
      });

    return [CounterSection(categoryKey: null, counters: sorted)];
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
