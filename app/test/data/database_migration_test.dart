import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the v1 -> v2 upgrade for real, on a file that genuinely predates
/// the dashboard.
///
/// Worth the trouble: the upgrade runs on every existing install exactly once,
/// and a mistake there is not something a fresh-install test would ever catch.
void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fieldtally_migration');
    file = File('${dir.path}/fieldtally.sqlite');
  });

  tearDown(() => dir.delete(recursive: true));

  /// Builds a database file exactly as v1 shipped it: snapshots and counter
  /// values, no pins, user_version 1.
  ///
  /// Written in raw SQL rather than through drift, so the fixture cannot drift
  /// along with the current schema definition — which would defeat the point.
  void createV1Database() {
    final db = sqlite3.open(file.path);
    db.execute('''
      CREATE TABLE snapshots (
        id TEXT NOT NULL,
        agent_name TEXT NOT NULL,
        faction TEXT NOT NULL,
        time_span TEXT NOT NULL,
        recorded_at INTEGER NOT NULL,
        level INTEGER NOT NULL,
        imported_at INTEGER NOT NULL,
        PRIMARY KEY (id));
    ''');
    db.execute('''
      CREATE TABLE counter_values (
        snapshot_id TEXT NOT NULL REFERENCES snapshots (id) ON DELETE CASCADE,
        export_header TEXT NOT NULL,
        value INTEGER NOT NULL,
        PRIMARY KEY (snapshot_id, export_header));
    ''');
    db.execute(
      "INSERT INTO snapshots VALUES ('legacy-id', 'AgentDemo', 'Enlightened', "
      "'allTime', 1767225600, 9, 1767225600);",
    );
    db.execute(
      "INSERT INTO counter_values VALUES ('legacy-id', 'Hacks', 78735);",
    );
    db.execute('PRAGMA user_version = 1;');
    db.close();
  }

  test('a v1 database opens, gains the pins table and keeps its data',
      () async {
    createV1Database();

    final db = FieldTallyDatabase(NativeDatabase(file));

    // Reading proves the upgrade ran: the table did not exist a moment ago.
    expect(await db.select(db.pinnedCounters).get(), isEmpty);

    final snapshots = await db.select(db.snapshots).get();
    expect(snapshots, hasLength(1));
    expect(snapshots.single.agentName, 'AgentDemo');

    final values = await db.select(db.counterValues).get();
    expect(values.single.value, 78735);

    await db.close();
  });

  test('the upgraded database is usable for writes', () async {
    createV1Database();
    final db = FieldTallyDatabase(NativeDatabase(file));

    await db.into(db.pinnedCounters).insert(
          PinnedCountersCompanion.insert(exportHeader: 'Hacks', position: 0),
        );

    expect((await db.select(db.pinnedCounters).get()).single.exportHeader,
        'Hacks');
    await db.close();
  });
}
