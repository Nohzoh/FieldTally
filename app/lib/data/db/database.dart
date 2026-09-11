import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// A dated snapshot (§3.2).
///
/// The identifier is an app generated UUID rather than an auto-incrementing
/// integer. This is a precaution taken in v1 with a possible v2 sync in mind
/// (§6): two devices creating snapshots offline must not produce colliding
/// identifiers.
class Snapshots extends Table {
  TextColumn get id => text()();
  TextColumn get agentName => text()();
  TextColumn get faction => text()();

  /// Period declared at import time, kept verbatim: it documents where the
  /// snapshot came from, including when the user overrode a guard.
  TextColumn get timeSpan => text()();

  DateTimeColumn get recordedAt => dateTime()();
  /// Null when the source did not carry it — the migration CSV of Appendix B
  /// has no level column.
  IntColumn get level => integer().nullable()();

  /// Insertion date, distinct from [recordedAt]: a migration import can create
  /// a snapshot today that is dated two years ago.
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The value of one counter for one snapshot.
///
/// A separate table rather than one column per counter: the counter list is
/// not known upfront and changes with every season of the game (§3.1.2). A
/// wide schema would force a migration on every new anomaly.
class CounterValues extends Table {
  TextColumn get snapshotId =>
      text().references(Snapshots, #id, onDelete: KeyAction.cascade)();

  /// Stable identity of the counter: its export header.
  TextColumn get exportHeader => text()();

  IntColumn get value => integer()();

  @override
  Set<Column> get primaryKey => {snapshotId, exportHeader};
}

/// Counters the user chose to pin on the dashboard (§3.3).
///
/// Stored rather than derived: it is a preference, not something that can be
/// recomputed from the snapshots. [position] keeps the order the user arranged
/// them in.
class PinnedCounters extends Table {
  /// Export header, the stable identity of a counter (§3.1.2).
  TextColumn get exportHeader => text()();

  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {exportHeader};
}

/// Small key/value store for preferences and cached remote content.
///
/// A table rather than shared_preferences: the app already carries a database,
/// and the cached counter registry (§3.1.4) belongs next to the setting that
/// governs it rather than split across two storage mechanisms.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// A personal target on a counter (§3.7).
///
/// One per counter: "reach level 12 before 31 December" is a single intent,
/// and letting an agent stack several targets on one counter would ask the app
/// to decide which one it is reminding them about.
///
/// The row class is named apart from the domain's `Goal`, which is the model
/// the rest of the app works with.
@DataClassName('GoalRow')
class Goals extends Table {
  /// Export header, the stable identity of a counter (§3.1.2).
  TextColumn get exportHeader => text()();

  IntColumn get target => integer()();

  /// Optional: a target with no date is a direction rather than a deadline.
  DateTimeColumn get deadline => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {exportHeader};
}

@DriftDatabase(
  tables: [Snapshots, CounterValues, PinnedCounters, AppSettings, Goals],
)
class FieldTallyDatabase extends _$FieldTallyDatabase {
  FieldTallyDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'fieldtally'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v2 adds the dashboard pins. Nothing to backfill: an empty table
          // simply means the dashboard falls back to its defaults.
          if (from < 2) await m.createTable(pinnedCounters);
          // v3 adds preferences and the cached registry (§3.1.4). Empty means
          // "never fetched", which is exactly the state a fresh install is in.
          if (from < 3) await m.createTable(appSettings);
          // v4 makes `level` nullable: the migration CSV has no such column,
          // and storing 0 would read as "level 0" rather than "not known".
          // SQLite cannot drop a NOT NULL in place, so the table is recreated.
          if (from < 4) {
            await m.alterTable(TableMigration(snapshots));
          }
          // v5 adds personal goals (§3.7). An empty table is the right state
          // for an agent who has not set any.
          if (from < 5) await m.createTable(goals);
        },
        beforeOpen: (details) async {
          // Without this, SQLite ignores `onDelete: cascade`: deleting a
          // snapshot would leave its counter values orphaned.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
