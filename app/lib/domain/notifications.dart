import 'badge_projection.dart';
import 'models/counter_registry.dart';
import 'models/stat_snapshot.dart';

/// Something worth telling the agent about, found between two snapshots (§3.7).
sealed class Milestone {
  const Milestone();
}

/// A badge tier newly reached.
class TierReached extends Milestone {
  const TierReached({
    required this.exportHeader,
    required this.tier,
    required this.value,
  });

  final String exportHeader;
  final CounterTier tier;

  /// The value that crossed it.
  final int value;
}

/// A further whole multiple of a top tier the game keeps counting past (#87).
///
/// One per counter however many multiples were passed at once: an agent who
/// catches up after a long gap has reached x 31, not x 15 through x 31, and
/// thirty-one of anything is not a celebration.
class MultipleReached extends Milestone {
  const MultipleReached({
    required this.exportHeader,
    required this.tier,
    required this.multiple,
    required this.value,
  });

  final String exportHeader;

  /// The top tier being multiplied — onyx, for every badge in the game today.
  final CounterTier tier;

  final int multiple;
  final int value;
}

/// A new level, from the export's own Level column.
///
/// One per import, at the level actually reached: gaining three at once is one
/// piece of news, not three.
class LevelReached extends Milestone {
  const LevelReached(this.level);

  final int level;
}

/// Finds what a new snapshot achieved that the one before it had not (§3.7).
///
/// Deliberately compares snapshot to snapshot rather than tracking a "highest
/// reached" number somewhere: everything in this app recomputes from the
/// snapshots, so a snapshot corrected or deleted later cannot leave a stale
/// milestone behind.
///
/// That choice has a second consequence, settled deliberately: an agent who
/// recurses and climbs back through a level hears about it again. From their
/// side they did it again, and a stored ceiling would have made a recursion
/// permanently silent on top of going stale.
class MilestoneDetector {
  const MilestoneDetector();

  /// What [current] reached that [previous] had not.
  ///
  /// [previous] null means a first snapshot: nothing is announced then. An
  /// agent importing years of history at once does not want a burst of
  /// notifications for badges they earned long ago.
  List<Milestone> since({
    required StatSnapshot current,
    StatSnapshot? previous,
    required CounterRegistry registry,
  }) {
    if (previous == null) return const [];

    return [
      ..._level(current, previous),
      ..._badges(current, previous, registry),
    ];
  }

  /// The level an agent reached, if it went up.
  ///
  /// Null on either side means silence: the Agent Stats migration CSV carries
  /// no level at all, and "not known" is not "level 0". A fall is silence too
  /// — a recursion is not a milestone, though climbing back is.
  Iterable<Milestone> _level(StatSnapshot current, StatSnapshot previous) {
    final before = previous.level;
    final after = current.level;
    if (before == null || after == null || after <= before) return const [];

    return [LevelReached(after)];
  }

  List<Milestone> _badges(
    StatSnapshot current,
    StatSnapshot previous,
    CounterRegistry registry,
  ) {
    final tiers = <TierReached>[];
    final multiples = <MultipleReached>[];

    for (final entry in current.counters.entries) {
      final enrichment = registry.forExportHeader(entry.key);
      if (enrichment == null || enrichment.tiers.isEmpty) continue;

      // A counter absent from the earlier snapshot has not "crossed" anything
      // — it was simply not reported (§3.1.2).
      final before = previous.counters[entry.key];
      if (before == null) continue;

      for (final tier in enrichment.tiers) {
        if (before < tier.value && entry.value >= tier.value) {
          tiers.add(
            TierReached(
              exportHeader: entry.key,
              tier: tier,
              value: entry.value,
            ),
          );
        }
      }

      // topTierMultiple is null for a ladder that ends, so a seasonal medal
      // never reports one — the game stops counting at its top (#99).
      // Both sides must already be past the top: reaching it for the first
      // time is announced as a tier, and saying "one time over" beside that
      // would be the same news twice. Which also means the multiple here is
      // always at least two — `was` is one or more, and `now` exceeds it — so
      // there is no floor to check.
      final was = topTierMultiple(enrichment, before);
      final now = topTierMultiple(enrichment, entry.value);
      if (was != null && now != null && now > was) {
        multiples.add(
          MultipleReached(
            exportHeader: entry.key,
            tier: enrichment.tiers.reduce((a, b) => b.value > a.value ? b : a),
            multiple: now,
            value: entry.value,
          ),
        );
      }
    }

    // Biggest milestone first: crossing bronze and silver in one import is
    // possible, and onyx is the one worth reading.
    tiers.sort((a, b) => b.tier.value.compareTo(a.tier.value));
    multiples.sort((a, b) => b.multiple.compareTo(a.multiple));

    return [...tiers, ...multiples];
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
