import '../models/stat_snapshot.dart';

/// Un relevé tel qu'il existe une fois enregistré : les données parsées, plus
/// ce que seul le stockage connaît.
///
/// [StatSnapshot] reste volontairement ignorant du stockage — c'est la sortie
/// du parser, rien de plus. La séparation évite que le modèle métier traîne un
/// identifiant nul tant qu'il n'a pas été sauvegardé.
class StoredSnapshot {
  const StoredSnapshot({
    required this.id,
    required this.importedAt,
    required this.snapshot,
  });

  /// UUID généré à l'enregistrement (§6).
  final String id;

  /// Quand le relevé a été ajouté à l'app, par opposition à
  /// `snapshot.recordedAt` qui est la date du relevé lui-même.
  final DateTime importedAt;

  final StatSnapshot snapshot;
}

/// Accès aux relevés.
///
/// Cette interface est le point de découplage prévu par le §5.2 : les écrans
/// ne parlent qu'à elle, jamais à Drift. Introduire une synchronisation en v2
/// ne demandera donc qu'une nouvelle implémentation, pas une réécriture de
/// l'interface utilisateur.
abstract interface class SnapshotRepository {
  /// Du plus récent au plus ancien.
  Future<List<StoredSnapshot>> all();

  /// Le relevé le plus récent, ou `null` s'il n'y en a aucun.
  ///
  /// C'est la référence du garde-fou comportemental (§3.1.3) : sans lui, il
  /// n'a rien à comparer.
  Future<StoredSnapshot?> latest();

  Future<StoredSnapshot> save(StatSnapshot snapshot);

  Future<void> delete(String id);

  /// Flux réactif de la liste, pour que les écrans se remettent à jour seuls
  /// après un ajout ou une suppression.
  Stream<List<StoredSnapshot>> watchAll();
}
