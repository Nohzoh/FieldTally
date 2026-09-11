import 'models/counter_registry.dart';
import 'models/stat_snapshot.dart';

/// A badge tier crossed by a new snapshot (§3.7).
class TierCrossing {
  const TierCrossing({
    required this.exportHeader,
    required this.tier,
    required this.value,
  });

  final String exportHeader;
  final CounterTier tier;

  /// The value that crossed it.
  final int value;
}

/// Finds badge tiers crossed between two snapshots (§3.7).
///
/// Deliberately compares snapshot to snapshot rather than tracking a "highest
/// reached" number somewhere: everything in this app recomputes from the
/// snapshots, so a snapshot corrected or deleted later cannot leave a stale
/// milestone behind.
class TierCrossingDetector {
  const TierCrossingDetector();

  /// Tiers newly reached by [current] that [previous] had not reached.
  ///
  /// [previous] null means a first snapshot: nothing is announced then. An
  /// agent importing years of history at once does not want a burst of
  /// notifications for badges they earned long ago.
  List<TierCrossing> crossings({
    required StatSnapshot current,
    StatSnapshot? previous,
    required CounterRegistry registry,
  }) {
    if (previous == null) return const [];

    final crossed = <TierCrossing>[];

    for (final entry in current.counters.entries) {
      final enrichment = registry.forExportHeader(entry.key);
      if (enrichment == null || enrichment.tiers.isEmpty) continue;

      // A counter absent from the earlier snapshot has not "crossed" anything
      // — it was simply not reported (§3.1.2).
      final before = previous.counters[entry.key];
      if (before == null) continue;

      for (final tier in enrichment.tiers) {
        if (before < tier.value && entry.value >= tier.value) {
          crossed.add(
            TierCrossing(
              exportHeader: entry.key,
              tier: tier,
              value: entry.value,
            ),
          );
        }
      }
    }

    // Biggest milestone first: crossing bronze and silver in one import is
    // possible, and onyx is the one worth reading.
    crossed.sort((a, b) => b.tier.value.compareTo(a.tier.value));
    return crossed;
  }
}

/// Decides when to nudge an agent who has stopped recording (§3.7).
class ReminderPlanner {
  const ReminderPlanner({this.after = const Duration(days: 7)});

  /// How long without a snapshot before the reminder fires.
  final Duration after;

  /// When the next reminder is due, or null when none should be scheduled.
  ///
  /// Measured from the latest snapshot: the point is to notice a gap, so the
  /// clock starts at the last thing recorded.
  DateTime? nextReminder({
    required DateTime? latestSnapshot,
    required DateTime now,
  }) {
    // Nothing recorded at all is not a lapse — it is someone who has not
    // started, and nagging them about a habit they never had would be rude.
    if (latestSnapshot == null) return null;

    final due = latestSnapshot.add(after);

    // Already overdue: schedule it for a moment from now rather than in the
    // past, which the platform would either fire instantly or drop.
    if (!due.isAfter(now)) return now.add(const Duration(minutes: 1));

    return due;
  }
}
