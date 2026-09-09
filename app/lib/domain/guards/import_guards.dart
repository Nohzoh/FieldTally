import '../models/counter_registry.dart';
import '../models/stat_snapshot.dart';
import '../models/time_span.dart';

/// Un compteur monotone qui a diminué entre deux relevés.
///
/// Presque jamais une vraie régression du joueur : dans les faits, c'est un
/// import de la mauvaise période, une faute de frappe ou une édition manuelle.
class CounterRegression {
  const CounterRegression({
    required this.exportHeader,
    required this.previous,
    required this.current,
  });

  final String exportHeader;
  final int previous;
  final int current;

  /// Toujours positif : de combien le compteur a reculé.
  int get drop => previous - current;

  @override
  String toString() => '$exportHeader : $previous → $current (-$drop)';
}

/// Verdict des deux garde-fous, à présenter avant tout enregistrement.
class ImportCheck {
  const ImportCheck({
    required this.declaredTimeSpan,
    required this.regressions,
    required this.comparedAgainstPrevious,
  });

  /// Période déclarée par l'export. `unknown` si la source n'en fournit pas
  /// (cas du CSV de migration, Annexe B).
  final TimeSpan declaredTimeSpan;

  /// Compteurs monotones ayant reculé, du plus gros recul au plus petit.
  final List<CounterRegression> regressions;

  /// `false` s'il n'existait aucun relevé antérieur : le garde-fou
  /// comportemental n'a alors rien à comparer, et son silence ne vaut pas
  /// validation.
  final bool comparedAgainstPrevious;

  /// Garde-fou n°1 — déclaratif. Voir [TimeSpan] : liste blanche stricte.
  bool get isPartialPeriod =>
      declaredTimeSpan != TimeSpan.unknown && !declaredTimeSpan.isCumulative;

  /// Garde-fou n°2 — comportemental.
  bool get hasRegressions => regressions.isNotEmpty;

  /// L'import doit être refusé par défaut. Passer outre reste possible, mais
  /// ça doit être une action explicite et distincte, jamais un bouton
  /// « forcer » posé à côté du message (§3.1.3).
  bool get isBlocked => isPartialPeriod || hasRegressions;

  /// Message principal, destiné à être montré tel quel.
  String? get message {
    if (isPartialPeriod) {
      return "Ce relevé correspond à la période « $declaredTimeSpanLabel » et non à "
          "un total depuis toujours — l'ajouter fausserait ton historique. "
          "Vérifie que tu as bien sélectionné « All Time » dans Ingress avant "
          "d'exporter.";
    }
    if (hasRegressions) {
      final n = regressions.length;
      return "$n compteur${n > 1 ? 's ont' : ' a'} diminué depuis ton dernier "
          "relevé, ce qui n'arrive normalement jamais. C'est presque toujours "
          "le signe d'un import de la mauvaise période. Vérifie la liste "
          "ci-dessous avant de confirmer.";
    }
    return null;
  }

  String get declaredTimeSpanLabel => switch (declaredTimeSpan) {
        TimeSpan.week => 'WEEK',
        TimeSpan.month => 'MONTH',
        TimeSpan.now => 'NOW',
        TimeSpan.allTime => 'ALL TIME',
        TimeSpan.unknown => 'inconnue',
      };
}

/// Applique les deux garde-fous anti-import de période partielle (§3.1.3).
///
/// Ils se complètent et aucun ne remplace l'autre : le champ `Time Span` est
/// absent du CSV de migration, et à l'inverse un `Time Span` correct n'exclut
/// pas une autre source d'erreur. La cohérence des valeurs entre elles reste
/// le filet de sécurité final.
class ImportGuards {
  const ImportGuards({this.tolerance = 0});

  /// Recul toléré avant de signaler un compteur.
  ///
  /// La valeur par défaut est **0** : les compteurs Ingress sont des entiers
  /// cumulatifs, il n'y a donc aucun arrondi à absorber, et toute diminution
  /// est un signal. Le paramètre existe pour le jour où un compteur se
  /// révélerait non strictement monotone — pas pour amortir du bruit qui
  /// n'existe pas.
  final int tolerance;

  /// Compare un relevé candidat au dernier relevé connu.
  ///
  /// [previous] peut être `null` (premier import) : seul le garde-fou
  /// déclaratif s'applique alors.
  ImportCheck check(
    StatSnapshot candidate, {
    StatSnapshot? previous,
    CounterRegistry? registry,
  }) {
    final regressions = <CounterRegression>[];

    if (previous != null) {
      for (final entry in candidate.counters.entries) {
        final header = entry.key;

        // Level, Lifetime AP et Current AP ne sont jamais réduits à la période
        // sélectionnée : les surveiller ne dirait rien : un import WEEK les
        // laisse identiques. Le signal est ailleurs.
        final periodized =
            registry?.isPeriodized(header) ??
                !StatSnapshot.nonPeriodizedHeaders.contains(header);
        if (!periodized) continue;

        // Un compteur absent du relevé précédent n'a pas « diminué » : il
        // vient d'apparaître. Et l'inverse — présent avant, absent
        // maintenant — ne vaut pas retour à zéro (§3.1.2).
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

      // Le plus gros recul en premier : c'est celui qui rend l'erreur évidente
      // d'un coup d'œil.
      regressions.sort((a, b) => b.drop.compareTo(a.drop));
    }

    return ImportCheck(
      declaredTimeSpan: candidate.timeSpan,
      regressions: regressions,
      comparedAgainstPrevious: previous != null,
    );
  }
}
