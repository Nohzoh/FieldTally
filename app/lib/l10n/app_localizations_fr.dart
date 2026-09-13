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
  String get close => 'Fermer';

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
  String get notEnoughHistory => '1 relevé';

  @override
  String get chartNeedsTwoSnapshots =>
      'Il faut au moins deux relevés pour tracer un graphique.';

  @override
  String chartSemantics(String first, String last, int count) {
    return 'Graphique de $first à $last, $count points.';
  }

  @override
  String chartTargetGoal(String value) {
    return 'Objectif · $value';
  }

  @override
  String chartTargetBadge(String tier, String value) {
    return '$tier · $value';
  }

  @override
  String chartTargetSemantics(String target) {
    return 'Une ligne pointillée marque $target.';
  }

  @override
  String get rangeWeek => 'Semaine';

  @override
  String get rangeMonth => 'Mois';

  @override
  String get rangeAll => 'Tout';

  @override
  String rangeGain(String gain) {
    return '$gain sur cette période';
  }

  @override
  String get rangeNoData => 'Rien d\'enregistré sur cette période.';

  @override
  String get activityTitle => 'Activité';

  @override
  String get activitySubtitle =>
      'AP gagnés, au jour du relevé qui les a mesurés.';

  @override
  String get activityEmpty =>
      'Il faut deux relevés pour que l\'activité apparaisse.';

  @override
  String activitySummary(int days, String peak) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours de progression',
      one: '1 jour de progression',
    );
    return '$_temp0 · meilleur jour $peak AP';
  }

  @override
  String get chartAxisDateFormat => 'd MMM';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsDataSection => 'Catégorisation des compteurs';

  @override
  String get settingsOnlineUpdates => 'Mettre à jour en ligne';

  @override
  String get settingsOnlineUpdatesDetail =>
      'Télécharge depuis le site du projet la liste publique des noms et catégories de compteurs, pour que les nouveaux compteurs d\'anomalie soient nommés sans attendre une mise à jour de l\'app. Rien te concernant, ni concernant ton appareil, n\'est envoyé. Désactive-le pour garder l\'app totalement hors-ligne.';

  @override
  String settingsRegistryCounters(int count) {
    return '$count compteurs connus';
  }

  @override
  String settingsRegistryUpdatedAt(String date) {
    return 'Version $date';
  }

  @override
  String settingsVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get settingsBuildUnknown => 'Construit depuis une copie de travail';

  @override
  String get settingsCopyVersion =>
      'Appuie pour copier, à coller dans un rapport de bug';

  @override
  String get settingsVersionCopied => 'Version copiée.';

  @override
  String get settingsWhatsNew => 'Nouveautés';

  @override
  String get settingsWhatsNewDetail =>
      'Relire ce qui a changé dans cette version.';

  @override
  String get settingsWhatsNewNone => 'Aucune note fournie pour cette version.';

  @override
  String get settingsAuthor => 'Auteur';

  @override
  String get settingsAuthorDetail => 'Nohzoh, sur GitHub.';

  @override
  String get settingsSourceCode => 'Code source';

  @override
  String get settingsSourceCodeDetail =>
      'L\'app entière, sous licence AGPL v3.';

  @override
  String get settingsSupport => 'Soutenir le projet';

  @override
  String get settingsSupportDetail =>
      'FieldTally est gratuite, sans publicité et ne collecte rien. Rien n\'est attendu — mais un café fait toujours plaisir.';

  @override
  String get settingsLinkFailed => 'Aucune application ne peut ouvrir ce lien.';

  @override
  String get settingsAboutSection => 'À propos';

  @override
  String get importCsvTitle => 'Importer depuis Agent Stats';

  @override
  String get importCsvAction => 'Importer depuis Agent Stats';

  @override
  String get importCsvInstructions =>
      'Colle l\'export CSV d\'Agent Stats. Tout ton historique arrive d\'un coup — rien n\'est enregistré tant que tu n\'as pas confirmé.';

  @override
  String get importCsvField => 'CSV Agent Stats';

  @override
  String importCsvSummary(int count, int counters) {
    return '$count relevés, $counters compteurs';
  }

  @override
  String importCsvRange(String from, String to) {
    return 'Du $from au $to';
  }

  @override
  String get importCsvNoTimeSpan =>
      'Ce format ne porte pas de colonne de période : seule la vérification de cohérence protège l\'import. Toutes les paires de lignes ont été vérifiées.';

  @override
  String importCsvConfirm(int count) {
    return 'Importer $count relevés';
  }

  @override
  String importCsvDone(int count) {
    return '$count relevés importés.';
  }

  @override
  String get importCsvAnomalyTitle => 'Lignes incohérentes dans ce fichier';

  @override
  String importCsvAnomaly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compteurs reculent',
      one: '1 compteur recule',
    );
    return '$_temp0 à l\'intérieur de ce fichier, ce qui n\'arrive normalement jamais. L\'importer fausserait ton historique à partir de cette date.';
  }

  @override
  String importCsvAnomalyLine(
    String date,
    String counter,
    int previous,
    int current,
  ) {
    return '$date · $counter : $previous → $current';
  }

  @override
  String get unknownValue => '—';

  @override
  String get projectionTitle => 'Prochaine médaille';

  @override
  String get projectionTier_bronze => 'Bronze';

  @override
  String get projectionTier_silver => 'Argent';

  @override
  String get projectionTier_gold => 'Or';

  @override
  String get projectionTier_platinum => 'Platine';

  @override
  String get projectionTier_onyx => 'Onyx';

  @override
  String projectionRemaining(String remaining, String tier) {
    return '$remaining restants pour $tier';
  }

  @override
  String projectionDate(String date) {
    return 'Vers le $date à ton rythme récent';
  }

  @override
  String get projectionNoPace =>
      'Pas d\'estimation : ce compteur n\'a pas bougé récemment.';

  @override
  String get projectionTooFar =>
      'Pas d\'estimation : trop loin à ton rythme récent.';

  @override
  String get projectionComplete => 'Onyx atteint — plus rien à viser.';

  @override
  String get projectionBelowFirst => 'Pas encore commencé';

  @override
  String projectionPace(String rate, String window) {
    return '$rate par jour sur $window';
  }

  @override
  String get projectionWindowWeek => 'la dernière semaine';

  @override
  String get projectionWindowMonth => 'le dernier mois';

  @override
  String get projectionPaceWeek => '7 derniers jours';

  @override
  String get projectionPaceMonth => '30 derniers jours';

  @override
  String get editSnapshotTitle => 'Corriger ce relevé';

  @override
  String get editSnapshotTooltip => 'Corriger ce relevé';

  @override
  String get editRecordedAt => 'Relevé du';

  @override
  String get editPickDate => 'Changer la date';

  @override
  String get editPickTime => 'Changer l\'heure';

  @override
  String get editSave => 'Enregistrer la correction';

  @override
  String get editSaved => 'Relevé corrigé.';

  @override
  String get editCounterSection => 'Valeurs des compteurs';

  @override
  String get editInvalidValue => 'Nombres entiers uniquement';

  @override
  String get editAnomalyTitle => 'Cette correction casse la séquence';

  @override
  String editAnomaly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compteurs reculeraient',
      one: '1 compteur reculerait',
    );
    return '$_temp0 par rapport aux relevés voisins.';
  }

  @override
  String get exportCsv => 'Exporter l\'historique';

  @override
  String get exportCsvSubject => 'Historique FieldTally';

  @override
  String get exportCsvEmpty => 'Rien à exporter pour l\'instant.';

  @override
  String exportCsvDone(int count) {
    return '$count relevés exportés.';
  }

  @override
  String get goalTitle => 'Objectif personnel';

  @override
  String get goalNone => 'Aucun objectif sur ce compteur.';

  @override
  String get goalSet => 'Définir un objectif';

  @override
  String get goalEdit => 'Modifier';

  @override
  String get goalRemove => 'Retirer';

  @override
  String get goalTarget => 'Valeur visée';

  @override
  String get goalDeadline => 'Échéance';

  @override
  String get goalNoDeadline => 'Sans échéance';

  @override
  String get goalPickDeadline => 'Choisir une date';

  @override
  String get goalClearDeadline => 'Retirer';

  @override
  String get goalSave => 'Enregistrer l\'objectif';

  @override
  String get goalSaved => 'Objectif enregistré.';

  @override
  String get goalRemoved => 'Objectif retiré.';

  @override
  String get goalInvalid => 'Doit dépasser la valeur actuelle';

  @override
  String goalRemaining(String remaining, String target) {
    return '$remaining restants, sur $target';
  }

  @override
  String get goalReached => 'Atteint.';

  @override
  String goalOnTrack(String date) {
    return 'Dans les temps pour le $date';
  }

  @override
  String goalBehind(String date) {
    return 'En retard pour le $date';
  }

  @override
  String goalMissed(String date) {
    return 'Échéance du $date dépassée.';
  }

  @override
  String get goalNoOpinion => 'Pas d\'estimation à ton rythme récent.';

  @override
  String get goalsTitle => 'Objectifs';

  @override
  String get goalsEmpty =>
      'Définis un objectif depuis un compteur pour le voir ici.';

  @override
  String get shareCardTitle => 'Carte à partager';

  @override
  String get shareCardAction => 'Partager mes stats';

  @override
  String get shareCardShare => 'Partager l\'image';

  @override
  String shareCardSince(String date) {
    return 'Progression depuis le $date';
  }

  @override
  String get shareCardNoPeriod =>
      'Un seul relevé pour l\'instant — pas encore de progression à montrer.';

  @override
  String get shareCardFooter => 'Réalisé avec FieldTally';

  @override
  String get shareCardDisclaimer => 'Non-officiel · sans lien avec Niantic';

  @override
  String get shareCardSubject => 'Mes stats Ingress';

  @override
  String get shareCardEmptyTitle => 'Rien à partager pour l\'instant';

  @override
  String get shareCardEmptyDetail =>
      'Enregistre un relevé et ta carte sera prête.';

  @override
  String get shareCardFailed => 'L\'image n\'a pas pu être produite.';

  @override
  String get settingsAppearanceSection => 'Apparence';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Système';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsFactionColours => 'Couleurs de faction';

  @override
  String get settingsFactionColoursDetail =>
      'Teinte l\'app avec la couleur de ta faction, lue sur ton dernier relevé. Désactivé, l\'app garde la sienne.';

  @override
  String get settingsFactionUnknown =>
      'Aucun relevé pour l\'instant, donc aucune faction à suivre.';

  @override
  String get settingsNotificationsSection => 'Rappels';

  @override
  String get settingsNotifications => 'Notifications locales';

  @override
  String get settingsNotificationsDetail =>
      'Te rappelle quand aucun relevé n\'a été enregistré depuis un moment, et t\'annonce le franchissement d\'un palier de médaille. Tout est planifié sur l\'appareil ; rien n\'est envoyé nulle part.';

  @override
  String get settingsNotificationsDenied =>
      'Android a refusé l\'autorisation de notification. Autorise-la pour FieldTally dans les réglages système.';

  @override
  String settingsReminderDelay(int days) {
    return 'Me rappeler après $days jours sans relevé';
  }

  @override
  String get notificationReminderTitle => 'C\'est l\'heure d\'un relevé';

  @override
  String notificationReminderBody(int days) {
    return 'Rien d\'enregistré depuis $days jours. Partage tes stats depuis Ingress pour que ton historique continue.';
  }

  @override
  String notificationMilestoneTitle(String tier) {
    return '$tier atteint';
  }

  @override
  String notificationMilestoneBody(String counter, String value) {
    return '$counter est maintenant à $value.';
  }

  @override
  String notificationMilestoneMore(String counter, int count) {
    return '$counter et $count autres médailles atteintes.';
  }

  @override
  String changelogDialogTitle(String version) {
    return 'Nouveautés de la version $version';
  }

  @override
  String get changelogNewHeading => '✨ Nouveautés';

  @override
  String get changelogFixedHeading => '🐛 Corrections';
}
