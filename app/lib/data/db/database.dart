import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Un relevé daté (§3.2).
///
/// L'identifiant est un UUID généré par l'app, pas un entier auto-incrémenté.
/// C'est une précaution prise dès la v1 en prévision d'une éventuelle
/// synchronisation en v2 (§6) : deux appareils qui créent des relevés hors
/// ligne ne doivent pas produire d'identifiants qui se télescopent.
class Snapshots extends Table {
  TextColumn get id => text()();
  TextColumn get agentName => text()();
  TextColumn get faction => text()();

  /// Période déclarée à l'import, conservée telle quelle : elle documente la
  /// provenance du relevé, y compris quand l'utilisateur a passé outre un
  /// garde-fou.
  TextColumn get timeSpan => text()();

  DateTimeColumn get recordedAt => dateTime()();
  IntColumn get level => integer()();

  /// Date d'insertion, distincte de [recordedAt] : un import de migration peut
  /// créer aujourd'hui un relevé daté d'il y a deux ans.
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// La valeur d'un compteur pour un relevé donné.
///
/// Table séparée plutôt qu'une colonne par compteur : la liste des compteurs
/// n'est pas connue à l'avance et change au fil des saisons du jeu (§3.1.2).
/// Un schéma large obligerait à une migration à chaque nouvelle anomalie.
class CounterValues extends Table {
  TextColumn get snapshotId =>
      text().references(Snapshots, #id, onDelete: KeyAction.cascade)();

  /// Identité stable du compteur : son en-tête d'export.
  TextColumn get exportHeader => text()();

  IntColumn get value => integer()();

  @override
  Set<Column> get primaryKey => {snapshotId, exportHeader};
}

@DriftDatabase(tables: [Snapshots, CounterValues])
class FieldTallyDatabase extends _$FieldTallyDatabase {
  FieldTallyDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'fieldtally'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // Sans ça, `onDelete: cascade` est ignoré par SQLite : supprimer un
          // relevé laisserait ses valeurs de compteurs orphelines.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
