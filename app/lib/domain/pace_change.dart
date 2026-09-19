import 'counter_pace.dart';
import 'models/stat_snapshot.dart';

/// What happened to a counter between one window and the one before it (#149).
///
/// Deliberately not "the pace changed by a factor of N". Every counter's pace
/// changes slightly all the time, and a ratio needs a threshold to become a
/// sentence — a number nobody can defend, below which the remark is noise and
/// above which it is arbitrary. `0.2/day` becoming `0.4/day` has doubled and
/// means nothing.
///
/// These two states need no threshold, because they are facts rather than
/// judgements: a counter was moving and is not, or was not moving and is.
enum PaceShift {
  /// Moved over the previous window, and not at all over the recent one.
  stopped,

  /// Did not move at all over the previous window, and moves now.
  resumed,
}

/// One counter's shift, with both sides of it.
typedef CounterShift = ({
  String exportHeader,
  PaceShift shift,
  CounterPace was,
  CounterPace now,
});

/// Finds the counters that started or stopped moving (#149).
///
/// The app is full of state — where you stand, what is left, when you might
/// get there — and had nothing that noticed a change of behaviour. This is
/// that, kept to what can be said without inventing a threshold.
///
/// Scoped to the counters the agent pinned: they said what they care about,
/// and this reads as a remark under their own dashboard rather than as the app
/// having opinions about counters they never chose.
class PaceChangeFinder {
  const PaceChangeFinder({this.window = ProgressWindow.month, this.limit = 3});

  /// The recent window, and equally the length of the one before it.
  final ProgressWindow window;

  /// At most this many. The point is a remark, not a report — and after a busy
  /// weekend followed by a quiet fortnight, half a dashboard would qualify.
  final int limit;

  List<CounterShift> find({
    required List<StatSnapshot> snapshots,
    required List<String> pinned,
  }) {
    final span = window.span;
    if (span == null || snapshots.length < 2 || pinned.isEmpty) {
      return const [];
    }

    final sorted = [...snapshots]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    // Counted back from the most recent snapshot rather than from today, like
    // every other measurement here (§3.5): an agent who stopped importing
    // three weeks ago has not slowed down, the app stopped hearing about it.
    final reference = sorted.last.recordedAt;

    final now = paceByCounter(sorted, window);
    final was = paceByCounter(sorted, window, asOf: reference.subtract(span));

    // Paired with the pinned position, because Dart's sort is not stable and
    // the ordering below promises that position as a tiebreak.
    final shifts = <(int, CounterShift)>[];
    for (var index = 0; index < pinned.length; index++) {
      final header = pinned[index];
      final recent = now[header];
      final earlier = was[header];

      // Both windows have to have been measured. A counter with no earlier
      // window has not resumed — nothing is known about it yet, which is a
      // different thing and must not be reported as one.
      if (recent == null || earlier == null) continue;

      // Strictly positive on one side and exactly zero on the other, which is
      // also what keeps a recursion out without a guard of its own: Current AP
      // and Level genuinely fall (§3.1.3), and a negative gain is neither
      // `> 0` nor `== 0`, so it matches no branch below. A guard was written
      // for it and removed — it failed to fail, which is the finding.
      final PaceShift? shift;
      if (earlier.gain > 0 && recent.gain == 0) {
        shift = PaceShift.stopped;
      } else if (earlier.gain == 0 && recent.gain > 0) {
        shift = PaceShift.resumed;
      } else {
        shift = null;
      }
      if (shift == null) continue;

      shifts.add((
        index,
        (exportHeader: header, shift: shift, was: earlier, now: recent),
      ));
    }

    // Stops before restarts, and the agent's own pinned order inside each.
    //
    // Deliberately not "biggest movement first": across counters five orders
    // of magnitude apart, AP would win every time, and a raw difference is not
    // a comparison — the same reason the snapshot-changes screen orders by the
    // registry instead. A stop is also the more useful of the two to hear
    // about, being the only one an agent might want to act on.
    int rank(PaceShift shift) => shift == PaceShift.stopped ? 0 : 1;
    shifts.sort((a, b) {
      final byShift = rank(a.$2.shift).compareTo(rank(b.$2.shift));
      return byShift != 0 ? byShift : a.$1.compareTo(b.$1);
    });

    return [for (final entry in shifts.take(limit)) entry.$2];
  }
}
