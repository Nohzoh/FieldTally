// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'FieldTally';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get homeEmptyTitle => 'Aucun relevé pour l\'instant';

  @override
  String get homeEmptyDetail =>
      'Partage tes stats depuis Ingress, ou colle le texte exporté pour créer ton premier relevé.';

  @override
  String get homeLoadError => 'Impossible de lire l\'historique';

  @override
  String get snapshotDateFormat => 'd MMMM y \'à\' HH:mm';

  @override
  String snapshotSubtitle(int count, String agent) {
    return '$count compteurs • $agent';
  }

  @override
  String get deleteSnapshotTooltip => 'Supprimer ce relevé';

  @override
  String get deleteSnapshotTitle => 'Supprimer ce relevé ?';

  @override
  String get deleteSnapshotBody =>
      'Il disparaîtra de l\'historique et des graphiques. Cette action est définitive.';

  @override
  String get addSnapshotTitle => 'Ajouter un relevé';

  @override
  String get addSnapshotAction => 'Ajouter un relevé';

  @override
  String get instructionsTitle => 'Depuis Ingress';

  @override
  String get instructionsBody =>
      'Écran de stats → sélectionne « All Time » → Partager. Vérifie bien la période : un export « This Week » fausserait ton historique.';

  @override
  String get pasteFieldLabel => 'Texte exporté par Ingress';

  @override
  String get pasteFieldHint =>
      'Colle ici le texte partagé depuis l\'écran de stats…';

  @override
  String get analyze => 'Analyser';

  @override
  String get previewTitle => 'Aperçu';

  @override
  String get previewNotSavedYet =>
      'Rien n\'est enregistré tant que tu n\'as pas confirmé.';

  @override
  String get previewDetailedDateFormat => 'd MMMM y \'à\' HH:mm:ss';

  @override
  String get fieldAgent => 'Agent';

  @override
  String get fieldFaction => 'Faction';

  @override
  String get fieldPeriod => 'Période';

  @override
  String get fieldRecordedAt => 'Relevé du';

  @override
  String get fieldLevel => 'Niveau';

  @override
  String get fieldCounterCount => 'Compteurs détectés';

  @override
  String get detectedValues => 'Valeurs détectées';

  @override
  String counterCount(int count) {
    return '$count compteurs';
  }

  @override
  String get fallbackCategory => 'Autres';

  @override
  String get saveSnapshot => 'Enregistrer ce relevé';

  @override
  String get doNotSave => 'Ne pas enregistrer';

  @override
  String get saveAnyway => 'Enregistrer quand même…';

  @override
  String get saveAnywayTitle => 'Enregistrer malgré l\'anomalie ?';

  @override
  String get saveAnywayBody =>
      'Ce relevé est incohérent avec ton historique. L\'enregistrer faussera durablement tes diffs, tes graphiques et tes projections de paliers.\n\nNe continue que si tu sais précisément pourquoi.';

  @override
  String get saveAnywayConfirm => 'Enregistrer quand même';

  @override
  String get snapshotSaved => 'Relevé enregistré.';

  @override
  String get anomalyPartialPeriodTitle => 'Période partielle détectée';

  @override
  String get anomalyRegressionTitle => 'Incohérence avec ton historique';

  @override
  String anomalyPartialPeriod(String period) {
    return 'Ce relevé correspond à la période « $period » et non à un total depuis toujours — l\'ajouter fausserait ton historique. Vérifie que tu as bien sélectionné « All Time » dans Ingress avant d\'exporter.';
  }

  @override
  String anomalyRegression(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compteurs ont diminué',
      one: '1 compteur a diminué',
    );
    return '$_temp0 depuis ton dernier relevé, ce qui n\'arrive normalement jamais. C\'est presque toujours le signe d\'un import de la mauvaise période. Vérifie la liste ci-dessous avant de confirmer.';
  }

  @override
  String anomalyRegressionLine(
    String counter,
    int previous,
    int current,
    int drop,
  ) {
    return '$counter : $previous → $current (−$drop)';
  }

  @override
  String anomalyRegressionMore(int count) {
    return '… et $count autres.';
  }

  @override
  String get timeSpanAllTime => 'ALL TIME';

  @override
  String get timeSpanWeek => 'WEEK';

  @override
  String get timeSpanMonth => 'MONTH';

  @override
  String get timeSpanNow => 'NOW';

  @override
  String get timeSpanUnknown => 'inconnue';

  @override
  String get parseErrorTitle => 'Lecture impossible';

  @override
  String get parseErrorEmptyText =>
      'Le texte collé est vide — rien à importer.';

  @override
  String get parseErrorHeaderOnly =>
      'L\'export ne contient qu\'une ligne d\'en-têtes, sans aucune valeur. Vérifie que tu as bien copié le texte entier depuis Ingress.';

  @override
  String get parseErrorNotTabSeparated =>
      'Ce texte ne ressemble pas à un export Ingress : aucune colonne tabulée n\'a été trouvée. Utilise le bouton de partage d\'Ingress plutôt qu\'une copie manuelle depuis l\'écran.';

  @override
  String parseErrorBlankHeader(int position) {
    return 'L\'export contient une colonne sans nom (position $position), ce qui rend l\'association des valeurs ambiguë.';
  }

  @override
  String parseErrorDuplicateHeader(String column) {
    return 'L\'export contient deux colonnes nommées « $column ». Impossible de savoir laquelle utiliser.';
  }

  @override
  String parseErrorColumnCountMismatch(int row, int values, int headers) {
    return 'Ligne $row : $values valeurs pour $headers colonnes. Le texte a probablement été tronqué à la copie.';
  }

  @override
  String parseErrorMissingColumn(String column) {
    return 'La colonne « $column » est absente de l\'export. Le format d\'Ingress a peut-être changé — signale-le avec un extrait anonymisé.';
  }

  @override
  String parseErrorEmptyValue(String column) {
    return 'La colonne « $column » est vide.';
  }

  @override
  String parseErrorNotAnInteger(String column) {
    return 'La colonne « $column » ne contient pas un nombre entier.';
  }

  @override
  String parseErrorOutOfRange(String column) {
    return 'La valeur de « $column » est hors des limites acceptables.';
  }

  @override
  String parseErrorInvalidDate(String value) {
    return 'La date « $value » n\'est pas au format attendu (aaaa-mm-jj).';
  }

  @override
  String parseErrorInvalidTime(String value) {
    return 'L\'heure « $value » n\'est pas au format attendu (hh:mm:ss).';
  }

  @override
  String parseErrorNonExistentDate(String value) {
    return 'La date « $value » n\'existe pas.';
  }

  @override
  String parseErrorTooManyRows(int count) {
    return 'L\'export contient $count relevés alors qu\'un seul est attendu ici.';
  }

  @override
  String parseErrorRawValue(String value) {
    return 'Valeur lue : « $value »';
  }

  @override
  String get disclaimer =>
      'Outil non-officiel, sans lien avec Niantic. « Ingress » est une marque de Niantic, Inc.';

  @override
  String get countersTitle => 'Tous les compteurs';

  @override
  String get countersAction => 'Tous les compteurs';

  @override
  String get countersEmpty =>
      'Les compteurs apparaissent une fois un relevé enregistré.';

  @override
  String get searchCounters => 'Rechercher un compteur';

  @override
  String get sortLabel => 'Trier';

  @override
  String get sortByCategory => 'Ordre du jeu';

  @override
  String get sortByName => 'Nom';

  @override
  String get sortByRecentProgress => 'Progression récente';

  @override
  String get showInactive => 'Afficher les compteurs inactifs';

  @override
  String inactiveSince(String date) {
    return 'inactif depuis le $date';
  }

  @override
  String get shortDateFormat => 'd MMM y';

  @override
  String get noDelta => 'pas encore de comparaison';

  @override
  String deltaSince(String delta) {
    return '$delta depuis le relevé précédent';
  }

  @override
  String get counterHistory => 'Historique';

  @override
  String get counterFirstSeen => 'Première apparition';

  @override
  String get counterLastSeen => 'Dernière apparition';

  @override
  String get counterCurrentValue => 'Valeur actuelle';

  @override
  String get counterNoTiers =>
      'Aucun seuil de palier n\'est connu pour ce compteur, donc aucune projection n\'est calculée.';

  @override
  String counterSearchEmpty(String search) {
    return 'Aucun compteur ne correspond à « $search ».';
  }

  @override
  String get counterExportHeader => 'Nom de colonne à l\'export';

  @override
  String get dashboardTitle => 'FieldTally';

  @override
  String get dashboardEmptyTitle => 'Rien à afficher pour l\'instant';

  @override
  String get dashboardEmptyDetail =>
      'Ajoute un relevé et tes compteurs épinglés apparaîtront ici.';

  @override
  String get customise => 'Personnaliser';

  @override
  String get customiseTitle => 'Compteurs épinglés';

  @override
  String customiseHint(int min, int max) {
    return 'Choisis entre $min et $max compteurs à afficher sur le tableau de bord.';
  }

  @override
  String customiseSelected(int count, int max) {
    return '$count sur $max sélectionnés';
  }

  @override
  String customiseTooFew(int min) {
    return 'Choisis-en au moins $min.';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String get snapshotsTitle => 'Relevés';

  @override
  String get notEnoughHistory => 'un seul relevé';
}
