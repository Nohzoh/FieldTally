import '../models/stat_snapshot.dart';

/// A snapshot as it exists once saved: the parsed data, plus what only storage
/// knows about.
///
/// [StatSnapshot] stays deliberately unaware of storage — it is the parser's
/// output, nothing more. Keeping them apart avoids a domain model carrying a
/// null identifier until it happens to be saved.
class StoredSnapshot {
  const StoredSnapshot({
    required this.id,
    required this.importedAt,
    required this.snapshot,
  });

  /// UUID assigned on save (§6).
  final String id;

  /// When the snapshot was added to the app, as opposed to
  /// `snapshot.recordedAt`, which is the date of the snapshot itself.
  final DateTime importedAt;

  final StatSnapshot snapshot;
}

/// Access to snapshots.
///
/// This interface is the decoupling point called for by §5.2: screens talk to
/// it and never to Drift. Introducing cloud sync in v2 will therefore only
/// require a new implementation, not a rewrite of the user interface.
abstract interface class SnapshotRepository {
  /// Most recent first.
  Future<List<StoredSnapshot>> all();

  /// The most recent snapshot, or null if there is none.
  ///
  /// This is the reference for the behavioural guard (§3.1.3): without it,
  /// there is nothing to compare against.
  Future<StoredSnapshot?> latest();

  Future<StoredSnapshot> save(StatSnapshot snapshot);

  /// Replaces an existing snapshot wholesale.
  ///
  /// §3.2 requires being able to correct a field entered by mistake. Every
  /// view recomputes from the snapshots, so a correction propagates on its own
  /// — which is exactly why nothing derived is ever stored.
  Future<StoredSnapshot> update(String id, StatSnapshot snapshot);

  Future<void> delete(String id);

  /// Reactive stream of the list, so screens refresh themselves after an
  /// insert or a delete.
  Stream<List<StoredSnapshot>> watchAll();
}
