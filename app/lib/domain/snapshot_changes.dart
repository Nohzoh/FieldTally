import 'models/counter_registry.dart';
import 'models/stat_snapshot.dart';

/// One counter's movement between two snapshots (#147).
class CounterChange {
  const CounterChange({
    required this.exportHeader,
    required this.from,
    required this.to,
  });

  final String exportHeader;

  /// Both ends are kept rather than only their difference: `38 → 52` says
  /// something `+14` does not, and it is what makes a negative delta legible
  /// as a fact rather than as a bug.
  final int from;
  final int to;

  /// Negative for the handful of counters that genuinely go down. `Current AP`
  /// and `Level` both drop on recursion, which is real data — the behavioural
  /// guard already skips them for exactly that reason (§3.1.3).
  int get delta => to - from;
}

/// A block of changes, headed by its category.
class ChangeSection {
  const ChangeSection({required this.categoryKey, required this.changes});

  final String categoryKey;
  final List<CounterChange> changes;
}

/// What one snapshot recorded that the one before it had not (#147).
///
/// The app's other views answer "where do I stand". This one answers "what did
/// that afternoon produce", which is the same data read between two points
/// instead of at one.
class SnapshotChanges {
  const SnapshotChanges({
    required this.from,
    required this.to,
    required this.sections,
  });

  /// The earlier snapshot's own moment, and the later one's. Not rounded to a
  /// day: two snapshots either side of a Saturday afternoon are the interval,
  /// and saying "13 June" would throw away the part that makes it one.
  final DateTime from;
  final DateTime to;

  final List<ChangeSection> sections;

  /// The real interval between the two snapshots, which is not a duration the
  /// agent chose — it is whenever they happened to record.
  Duration get span => to.difference(from);

  bool get isEmpty => sections.isEmpty;

  /// How many counters moved, across every section.
  int get changedCount =>
      sections.fold(0, (total, section) => total + section.changes.length);
}

/// Reads one snapshot against the one before it.
///
/// Pure logic, kept out of the widgets like the counter list builder beside
/// it: what counts as a change is worth testing without pumping a screen.
class SnapshotChangesBuilder {
  const SnapshotChangesBuilder({this.registry});

  /// Only used to group and order the result the way the in-game stats screen
  /// does. Without it the changes come out as one alphabetical block.
  final CounterRegistry? registry;

  SnapshotChanges between({
    required StatSnapshot earlier,
    required StatSnapshot later,
  }) {
    final changes = <String, CounterChange>{};

    for (final entry in later.counters.entries) {
      final before = earlier.counters[entry.key];

      // A counter missing from either snapshot has no delta. It was not
      // reported, which is not the same as not having moved (§3.1.2) —
      // counting its whole value as this interval's gain would be the same
      // lie the dashboard already refuses to draw when it declines to show a
      // gap as a dip to zero.
      if (before == null) continue;

      // Zero is left out rather than shown as "+0": this screen is about what
      // happened, and a list where most rows say nothing happened buries the
      // ones that do.
      if (before == entry.value) continue;

      changes[entry.key] = CounterChange(
        exportHeader: entry.key,
        from: before,
        to: entry.value,
      );
    }

    // `sortHeaders` already orders by category and then by rank within it,
    // with unknown counters last and alphabetical. Grouping consecutive
    // headers is therefore enough to build the sections.
    final ordered =
        registry?.sortHeaders(changes.keys) ?? (changes.keys.toList()..sort());

    final grouped = <String, List<CounterChange>>{};
    for (final header in ordered) {
      final category =
          registry?.categoryKeyFor(header) ??
          CounterRegistry.fallbackCategoryKey;
      grouped.putIfAbsent(category, () => []).add(changes[header]!);
    }

    return SnapshotChanges(
      from: earlier.recordedAt,
      to: later.recordedAt,
      sections: [
        for (final entry in grouped.entries)
          ChangeSection(categoryKey: entry.key, changes: entry.value),
      ],
    );
  }
}
