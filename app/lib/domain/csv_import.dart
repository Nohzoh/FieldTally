import 'guards/import_guards.dart';
import 'models/counter_registry.dart';
import 'models/stat_snapshot.dart';

/// A regression found somewhere in a migration file.
class CsvRegression {
  const CsvRegression({required this.at, required this.regression});

  /// The snapshot that went backwards.
  final DateTime at;

  final CounterRegression regression;
}

/// What importing a migration file would do (Appendix B).
class CsvImportPlan {
  const CsvImportPlan({
    required this.snapshots,
    required this.regressions,
    required this.counterCount,
    this.partialPeriods = const [],
    this.ignoredLines = 0,
    this.headerIgnored = false,
  });

  /// Chronological, oldest first.
  final List<StatSnapshot> snapshots;

  /// Every backwards step found, wherever it sits in the file.
  final List<CsvRegression> regressions;

  /// Rows declaring a period other than `ALL TIME` (§3.1.3).
  ///
  /// Always empty on the migration path, which carries no period column at
  /// all. A FieldTally export does carry one, so the declarative guard is
  /// awake here — and a file that has been through a spreadsheet is exactly
  /// where a `week` row would come from.
  final List<DateTime> partialPeriods;

  /// Distinct counters across the whole file.
  final int counterCount;

  /// Lines of the paste that carried no data row (#133).
  ///
  /// Shown rather than swallowed: a paste off a web page legitimately brings a
  /// banner and a pagination strip, but a damaged row would be skipped by the
  /// same rule, and the agent is the one who can tell the two apart.
  final int ignoredLines;

  /// True when a header was present but did not fit the rows, so the column
  /// order came from Appendix B instead (#132).
  final bool headerIgnored;

  /// Anything worth saying about what was passed over.
  bool get hasNotes => ignoredLines > 0 || headerIgnored;

  bool get isEmpty => snapshots.isEmpty;
  bool get hasRegressions => regressions.isNotEmpty;
  bool get hasPartialPeriods => partialPeriods.isNotEmpty;

  /// The import is refused by default when anything went backwards or any row
  /// declares a partial period, exactly as a single paste would be (§3.1.3).
  bool get isBlocked => hasRegressions || hasPartialPeriods;

  DateTime? get from => snapshots.isEmpty ? null : snapshots.first.recordedAt;
  DateTime? get to => snapshots.isEmpty ? null : snapshots.last.recordedAt;
}

/// Checks a whole migration file before any of it is saved.
///
/// A migration file has no `Time Span` column, so the declarative guard is
/// blind and monotonicity is the only protection left — which is exactly why
/// Appendix B says it must never be skipped here.
///
/// The check runs across **every consecutive pair in the file**, not only the
/// last row: a file carrying years of history can hold a bad row anywhere, and
/// importing it silently would poison the diffs from that date onwards.
class CsvImportPlanner {
  const CsvImportPlanner({this.guards = const ImportGuards()});

  final ImportGuards guards;

  CsvImportPlan plan(
    List<StatSnapshot> snapshots, {
    StatSnapshot? existingLatest,
    CounterRegistry? registry,
    int ignoredLines = 0,
    bool headerIgnored = false,
  }) {
    if (snapshots.isEmpty) {
      return const CsvImportPlan(
        snapshots: [],
        regressions: [],
        counterCount: 0,
      );
    }

    final regressions = <CsvRegression>[];

    // Every row, not only the pairs below: the declarative guard is about one
    // row's own claim, so the first row of a backfill — which is compared
    // against nothing — is as much in scope as any other.
    final partialPeriods = [
      for (final snapshot in snapshots)
        if (guards.check(snapshot, registry: registry).isPartialPeriod)
          snapshot.recordedAt,
    ];

    void collect(StatSnapshot candidate, StatSnapshot? previous) {
      final check = guards.check(
        candidate,
        previous: previous,
        registry: registry,
      );
      for (final regression in check.regressions) {
        regressions.add(
          CsvRegression(at: candidate.recordedAt, regression: regression),
        );
      }
    }

    // Against what is already stored, when the file starts after it. A file
    // that predates the existing history is a legitimate backfill, not a
    // regression, so it is not compared that way.
    final first = snapshots.first;
    if (existingLatest != null &&
        !first.recordedAt.isBefore(existingLatest.recordedAt)) {
      collect(first, existingLatest);
    }

    for (var i = 1; i < snapshots.length; i++) {
      collect(snapshots[i], snapshots[i - 1]);
    }

    final counters = <String>{
      for (final snapshot in snapshots) ...snapshot.counters.keys,
    };

    return CsvImportPlan(
      snapshots: snapshots,
      regressions: regressions,
      counterCount: counters.length,
      partialPeriods: partialPeriods,
      ignoredLines: ignoredLines,
      headerIgnored: headerIgnored,
    );
  }
}
