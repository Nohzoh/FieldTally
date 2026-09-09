import '../models/counter_registry.dart';
import '../models/stat_snapshot.dart';
import '../models/time_span.dart';

/// A monotonic counter that went down between two snapshots.
///
/// Almost never a real regression by the player: in practice it means the
/// wrong period was imported, a typo, or a manual edit.
class CounterRegression {
  const CounterRegression({
    required this.exportHeader,
    required this.previous,
    required this.current,
  });

  final String exportHeader;
  final int previous;
  final int current;

  /// Always positive: how far the counter went back.
  int get drop => previous - current;

  @override
  String toString() => '$exportHeader: $previous -> $current (-$drop)';
}

/// Verdict of both guards, to be shown before anything is saved.
///
/// Deliberately free of user facing wording: this is domain logic, and the
/// sentences shown to the user belong to the localisation layer. Callers get
/// structured facts and render them as they see fit.
class ImportCheck {
  const ImportCheck({
    required this.declaredTimeSpan,
    required this.regressions,
    required this.comparedAgainstPrevious,
  });

  /// Period declared by the export. `unknown` when the source provides none
  /// (the migration CSV, Appendix B).
  final TimeSpan declaredTimeSpan;

  /// Monotonic counters that went down, largest drop first.
  final List<CounterRegression> regressions;

  /// False when no earlier snapshot existed: the behavioural guard then had
  /// nothing to compare against, and its silence is not an endorsement.
  final bool comparedAgainstPrevious;

  /// Guard 1 — declarative. See [TimeSpan]: strict allowlist.
  bool get isPartialPeriod =>
      declaredTimeSpan != TimeSpan.unknown && !declaredTimeSpan.isCumulative;

  /// Guard 2 — behavioural.
  bool get hasRegressions => regressions.isNotEmpty;

  /// The import must be refused by default. Overriding stays possible, but it
  /// has to be an explicit and clearly separate action, never a "force" button
  /// sitting next to the message (§3.1.3).
  bool get isBlocked => isPartialPeriod || hasRegressions;
}

/// Applies both guards against importing a partial period (§3.1.3).
///
/// They complement each other and neither replaces the other: the `Time Span`
/// column is absent from the migration CSV, and conversely a correct
/// `Time Span` does not rule out another source of error. Consistency between
/// values remains the final safety net.
class ImportGuards {
  const ImportGuards({this.tolerance = 0});

  /// Drop tolerated before a counter is flagged.
  ///
  /// The default is **0**: Ingress counters are cumulative integers, so there
  /// is no rounding to absorb and any decrease is a signal. The parameter
  /// exists for the day a counter turns out not to be strictly monotonic — not
  /// to damp noise that does not exist.
  final int tolerance;

  /// Compares a candidate snapshot against the latest known one.
  ///
  /// [previous] may be null (first import): only the declarative guard applies
  /// then.
  ImportCheck check(
    StatSnapshot candidate, {
    StatSnapshot? previous,
    CounterRegistry? registry,
  }) {
    final regressions = <CounterRegression>[];

    if (previous != null) {
      for (final entry in candidate.counters.entries) {
        final header = entry.key;

        // Level, Lifetime AP and Current AP are never scoped to the selected
        // period, so watching them would say nothing: a WEEK import leaves
        // them identical. The signal is elsewhere.
        final periodized = registry?.isPeriodized(header) ??
            !StatSnapshot.nonPeriodizedHeaders.contains(header);
        if (!periodized) continue;

        // A counter missing from the previous snapshot did not "go down": it
        // just appeared. And the reverse — present before, absent now — is not
        // a reset to zero either (§3.1.2).
        final before = previous.counters[header];
        if (before == null) continue;

        final drop = before - entry.value;
        if (drop > tolerance) {
          regressions.add(
            CounterRegression(
              exportHeader: header,
              previous: before,
              current: entry.value,
            ),
          );
        }
      }

      // Largest drop first: that is the one that makes the mistake obvious at
      // a glance.
      regressions.sort((a, b) => b.drop.compareTo(a.drop));
    }

    return ImportCheck(
      declaredTimeSpan: candidate.timeSpan,
      regressions: regressions,
      comparedAgainstPrevious: previous != null,
    );
  }
}
