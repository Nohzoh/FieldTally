// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FieldTally';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get homeEmptyTitle => 'No snapshot yet';

  @override
  String get homeEmptyDetail =>
      'Share your stats from Ingress, or paste the exported text to create your first snapshot.';

  @override
  String get homeLoadError => 'Could not read your history';

  @override
  String get snapshotDateFormat => 'd MMMM y \'at\' HH:mm';

  @override
  String snapshotSubtitle(int count, String agent) {
    return '$count counters • $agent';
  }

  @override
  String get deleteSnapshotTooltip => 'Delete this snapshot';

  @override
  String get deleteSnapshotTitle => 'Delete this snapshot?';

  @override
  String get deleteSnapshotBody =>
      'It will disappear from your history and charts. This cannot be undone.';

  @override
  String get addSnapshotTitle => 'Add a snapshot';

  @override
  String get addSnapshotAction => 'Add a snapshot';

  @override
  String get instructionsTitle => 'From Ingress';

  @override
  String get instructionsBody =>
      'Stats screen → select \"All Time\" → Share. Double-check the period: a \"This Week\" export would skew your history.';

  @override
  String get pasteFieldLabel => 'Text exported from Ingress';

  @override
  String get pasteFieldHint =>
      'Paste the text shared from the stats screen here…';

  @override
  String get analyze => 'Analyze';

  @override
  String get previewTitle => 'Preview';

  @override
  String get previewNotSavedYet => 'Nothing is saved until you confirm.';

  @override
  String get previewDetailedDateFormat => 'd MMMM y \'at\' HH:mm:ss';

  @override
  String get fieldAgent => 'Agent';

  @override
  String get fieldFaction => 'Faction';

  @override
  String get fieldPeriod => 'Period';

  @override
  String get fieldRecordedAt => 'Recorded on';

  @override
  String get fieldLevel => 'Level';

  @override
  String get fieldCounterCount => 'Counters detected';

  @override
  String get detectedValues => 'Detected values';

  @override
  String counterCount(int count) {
    return '$count counters';
  }

  @override
  String get fallbackCategory => 'Other';

  @override
  String get saveSnapshot => 'Save this snapshot';

  @override
  String get doNotSave => 'Do not save';

  @override
  String get saveAnyway => 'Save anyway…';

  @override
  String get saveAnywayTitle => 'Save despite the anomaly?';

  @override
  String get saveAnywayBody =>
      'This snapshot is inconsistent with your history. Saving it will durably skew your diffs, charts and badge projections.\n\nOnly continue if you know exactly why.';

  @override
  String get saveAnywayConfirm => 'Save anyway';

  @override
  String get snapshotSaved => 'Snapshot saved.';

  @override
  String get anomalyPartialPeriodTitle => 'Partial period detected';

  @override
  String get anomalyRegressionTitle => 'Inconsistent with your history';

  @override
  String anomalyPartialPeriod(String period) {
    return 'This snapshot covers the \"$period\" period rather than an all-time total — adding it would skew your history. Make sure you selected \"All Time\" in Ingress before exporting.';
  }

  @override
  String anomalyRegression(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count counters have gone down',
      one: '1 counter has gone down',
    );
    return '$_temp0 since your last snapshot, which normally never happens. It is almost always a sign that the wrong period was imported. Check the list below before confirming.';
  }

  @override
  String anomalyRegressionLine(
    String counter,
    int previous,
    int current,
    int drop,
  ) {
    return '$counter: $previous → $current (−$drop)';
  }

  @override
  String anomalyRegressionMore(int count) {
    return '… and $count more.';
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
  String get timeSpanUnknown => 'unknown';

  @override
  String get parseErrorTitle => 'Could not read this text';

  @override
  String get parseErrorEmptyText =>
      'The pasted text is empty — there is nothing to import.';

  @override
  String get parseErrorHeaderOnly =>
      'The export only contains a header row, without any values. Make sure you copied the whole text from Ingress.';

  @override
  String get parseErrorNotTabSeparated =>
      'This does not look like an Ingress export: no tab-separated columns were found. Use the Ingress share button rather than copying from the screen by hand.';

  @override
  String parseErrorBlankHeader(int position) {
    return 'The export contains a column without a name (position $position), which makes matching values ambiguous.';
  }

  @override
  String parseErrorDuplicateHeader(String column) {
    return 'The export contains two columns named \"$column\". There is no way to tell which one to use.';
  }

  @override
  String parseErrorColumnCountMismatch(int row, int values, int headers) {
    return 'Row $row: $values values for $headers columns. The text was most likely truncated while copying.';
  }

  @override
  String parseErrorMissingColumn(String column) {
    return 'The \"$column\" column is missing from the export. The Ingress format may have changed — please report it with an anonymised sample.';
  }

  @override
  String parseErrorEmptyValue(String column) {
    return 'The \"$column\" column is empty.';
  }

  @override
  String parseErrorNotAnInteger(String column) {
    return 'The \"$column\" column does not contain a whole number.';
  }

  @override
  String parseErrorOutOfRange(String column) {
    return 'The value of \"$column\" is outside the acceptable range.';
  }

  @override
  String parseErrorInvalidDate(String value) {
    return 'The date \"$value\" is not in the expected format (yyyy-mm-dd).';
  }

  @override
  String parseErrorInvalidTime(String value) {
    return 'The time \"$value\" is not in the expected format (hh:mm:ss).';
  }

  @override
  String parseErrorNonExistentDate(String value) {
    return 'The date \"$value\" does not exist.';
  }

  @override
  String parseErrorTooManyRows(int count) {
    return 'The export contains $count snapshots when only one is expected here.';
  }

  @override
  String parseErrorRawValue(String value) {
    return 'Value read: \"$value\"';
  }

  @override
  String get disclaimer =>
      'Unofficial tool, not affiliated with Niantic. \"Ingress\" is a trademark of Niantic, Inc.';

  @override
  String get countersTitle => 'All counters';

  @override
  String get countersAction => 'All counters';

  @override
  String get countersEmpty => 'Counters appear once you have saved a snapshot.';

  @override
  String get searchCounters => 'Search a counter';

  @override
  String get sortLabel => 'Sort';

  @override
  String get sortByCategory => 'In-game order';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByRecentProgress => 'Recent progress';

  @override
  String get showInactive => 'Show inactive counters';

  @override
  String inactiveSince(String date) {
    return 'inactive since $date';
  }

  @override
  String get shortDateFormat => 'd MMM y';

  @override
  String get noDelta => 'no comparison yet';

  @override
  String deltaSince(String delta) {
    return '$delta since the previous snapshot';
  }

  @override
  String get counterHistory => 'History';

  @override
  String get counterFirstSeen => 'First seen';

  @override
  String get counterLastSeen => 'Last seen';

  @override
  String get counterCurrentValue => 'Current value';

  @override
  String get counterNoTiers =>
      'No badge threshold is known for this counter yet, so no projection is computed.';

  @override
  String counterSearchEmpty(String search) {
    return 'No counter matches “$search”.';
  }

  @override
  String get counterExportHeader => 'Export header';

  @override
  String get dashboardTitle => 'FieldTally';

  @override
  String get dashboardEmptyTitle => 'Nothing to show yet';

  @override
  String get dashboardEmptyDetail =>
      'Add a snapshot and your pinned counters will appear here.';

  @override
  String get customise => 'Customise';

  @override
  String get customiseTitle => 'Pinned counters';

  @override
  String customiseHint(int min, int max) {
    return 'Pick between $min and $max counters to show on the dashboard.';
  }

  @override
  String customiseSelected(int count, int max) {
    return '$count of $max selected';
  }

  @override
  String customiseTooFew(int min) {
    return 'Pick at least $min.';
  }

  @override
  String get save => 'Save';

  @override
  String get snapshotsTitle => 'Snapshots';

  @override
  String get notEnoughHistory => '1 snapshot';

  @override
  String get chartNeedsTwoSnapshots =>
      'At least two snapshots are needed to draw a chart.';

  @override
  String chartSemantics(String first, String last, int count) {
    return 'Chart from $first to $last, $count points.';
  }

  @override
  String get rangeWeek => 'Week';

  @override
  String get rangeMonth => 'Month';

  @override
  String get rangeAll => 'All';

  @override
  String rangeGain(String gain) {
    return '$gain over this period';
  }

  @override
  String get rangeNoData => 'Nothing recorded over this period.';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activitySubtitle =>
      'AP gained, on the day each snapshot was taken.';

  @override
  String get activityEmpty =>
      'Two snapshots are needed before activity shows up.';

  @override
  String activitySummary(int days, String peak) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days with progress',
      one: '1 day with progress',
    );
    return '$_temp0 · best day $peak AP';
  }

  @override
  String get chartAxisDateFormat => 'd MMM';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDataSection => 'Counter categorisation';

  @override
  String get settingsOnlineUpdates => 'Update online';

  @override
  String get settingsOnlineUpdatesDetail =>
      'Downloads the public list of counter names and categories from the project site, so new anomaly counters are labelled without waiting for an app update. Nothing about you or your device is sent. Turn it off to keep the app entirely offline.';

  @override
  String settingsRegistryCounters(int count) {
    return '$count counters known';
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
  String get settingsBuildUnknown => 'Built from a working copy';

  @override
  String get settingsCopyVersion => 'Tap to copy, to paste into a bug report';

  @override
  String get settingsVersionCopied => 'Version copied.';

  @override
  String get settingsAuthor => 'Author';

  @override
  String get settingsAuthorDetail => 'Nohzoh, on GitHub.';

  @override
  String get settingsSourceCode => 'Source code';

  @override
  String get settingsSourceCodeDetail => 'The whole app, under AGPL v3.';

  @override
  String get settingsSupport => 'Support the project';

  @override
  String get settingsSupportDetail =>
      'FieldTally is free, has no ads and collects nothing. Nothing is expected â but a coffee is always welcome.';

  @override
  String get settingsLinkFailed => 'No app could open that link.';

  @override
  String get settingsAboutSection => 'About';

  @override
  String get importCsvTitle => 'Import from Agent Stats';

  @override
  String get importCsvAction => 'Import from Agent Stats';

  @override
  String get importCsvInstructions =>
      'Paste the CSV export from Agent Stats. Your whole history comes across at once — nothing is saved until you confirm.';

  @override
  String get importCsvField => 'Agent Stats CSV';

  @override
  String importCsvSummary(int count, int counters) {
    return '$count snapshots, $counters counters';
  }

  @override
  String importCsvRange(String from, String to) {
    return 'From $from to $to';
  }

  @override
  String get importCsvNoTimeSpan =>
      'This format carries no period column, so only the consistency check protects the import. Every pair of rows has been checked.';

  @override
  String importCsvConfirm(int count) {
    return 'Import $count snapshots';
  }

  @override
  String importCsvDone(int count) {
    return '$count snapshots imported.';
  }

  @override
  String get importCsvAnomalyTitle => 'Inconsistent rows in this file';

  @override
  String importCsvAnomaly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count counters go backwards',
      one: '1 counter goes backwards',
    );
    return '$_temp0 inside this file, which normally never happens. Importing it would skew your history from that date onwards.';
  }

  @override
  String importCsvAnomalyLine(
    String date,
    String counter,
    int previous,
    int current,
  ) {
    return '$date · $counter: $previous → $current';
  }

  @override
  String get unknownValue => '—';

  @override
  String get projectionTitle => 'Next badge';

  @override
  String get projectionTier_bronze => 'Bronze';

  @override
  String get projectionTier_silver => 'Silver';

  @override
  String get projectionTier_gold => 'Gold';

  @override
  String get projectionTier_platinum => 'Platinum';

  @override
  String get projectionTier_onyx => 'Onyx';

  @override
  String projectionRemaining(String remaining, String tier) {
    return '$remaining to go for $tier';
  }

  @override
  String projectionDate(String date) {
    return 'Around $date at your recent pace';
  }

  @override
  String get projectionNoPace =>
      'No estimate: this counter has not moved lately.';

  @override
  String get projectionTooFar =>
      'No estimate: too far off at your recent pace.';

  @override
  String get projectionComplete => 'Onyx reached — nothing left to chase.';

  @override
  String get projectionBelowFirst => 'Not started yet';

  @override
  String projectionPace(String rate, String window) {
    return '$rate per day over the last $window';
  }

  @override
  String get projectionWindowWeek => 'week';

  @override
  String get projectionWindowMonth => 'month';

  @override
  String get projectionPaceWeek => 'Last 7 days';

  @override
  String get projectionPaceMonth => 'Last 30 days';

  @override
  String get editSnapshotTitle => 'Correct this snapshot';

  @override
  String get editSnapshotTooltip => 'Correct this snapshot';

  @override
  String get editRecordedAt => 'Recorded on';

  @override
  String get editPickDate => 'Change the date';

  @override
  String get editPickTime => 'Change the time';

  @override
  String get editSave => 'Save the correction';

  @override
  String get editSaved => 'Snapshot corrected.';

  @override
  String get editCounterSection => 'Counter values';

  @override
  String get editInvalidValue => 'Whole numbers only';

  @override
  String get editAnomalyTitle => 'This correction breaks the sequence';

  @override
  String editAnomaly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count counters would go backwards',
      one: '1 counter would go backwards',
    );
    return '$_temp0 compared with the neighbouring snapshots.';
  }

  @override
  String get exportCsv => 'Export the history';

  @override
  String get exportCsvSubject => 'FieldTally history';

  @override
  String get exportCsvEmpty => 'Nothing to export yet.';

  @override
  String exportCsvDone(int count) {
    return '$count snapshots exported.';
  }

  @override
  String get goalTitle => 'Personal goal';

  @override
  String get goalNone => 'No goal on this counter yet.';

  @override
  String get goalSet => 'Set a goal';

  @override
  String get goalEdit => 'Change';

  @override
  String get goalRemove => 'Remove';

  @override
  String get goalTarget => 'Target value';

  @override
  String get goalDeadline => 'Deadline';

  @override
  String get goalNoDeadline => 'No deadline';

  @override
  String get goalPickDeadline => 'Pick a date';

  @override
  String get goalClearDeadline => 'Clear';

  @override
  String get goalSave => 'Save the goal';

  @override
  String get goalSaved => 'Goal saved.';

  @override
  String get goalRemoved => 'Goal removed.';

  @override
  String get goalInvalid => 'Must be above the current value';

  @override
  String goalRemaining(String remaining, String target) {
    return '$remaining to go, out of $target';
  }

  @override
  String get goalReached => 'Reached.';

  @override
  String goalOnTrack(String date) {
    return 'On track for $date';
  }

  @override
  String goalBehind(String date) {
    return 'Behind for $date';
  }

  @override
  String goalMissed(String date) {
    return 'Deadline of $date passed.';
  }

  @override
  String get goalNoOpinion => 'No estimate at your recent pace.';

  @override
  String get goalsTitle => 'Goals';

  @override
  String get goalsEmpty => 'Set a goal from any counter to see it here.';

  @override
  String get shareCardTitle => 'Shareable card';

  @override
  String get shareCardAction => 'Share my stats';

  @override
  String get shareCardShare => 'Share the image';

  @override
  String shareCardSince(String date) {
    return 'Progress since $date';
  }

  @override
  String get shareCardNoPeriod =>
      'Only one snapshot so far â no progress to show yet.';

  @override
  String get shareCardFooter => 'Made with FieldTally';

  @override
  String get shareCardDisclaimer => 'Unofficial · not affiliated with Niantic';

  @override
  String get shareCardSubject => 'My Ingress stats';

  @override
  String get shareCardEmptyTitle => 'Nothing to share yet';

  @override
  String get shareCardEmptyDetail =>
      'Record a snapshot and your card will be ready.';

  @override
  String get shareCardFailed => 'The image could not be produced.';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsFactionColours => 'Faction colours';

  @override
  String get settingsFactionColoursDetail =>
      'Tints the app with your faction\'s colour, read from your latest snapshot. Off, the app keeps its own.';

  @override
  String get settingsFactionUnknown =>
      'No snapshot yet, so there is no faction to follow.';

  @override
  String get settingsNotificationsSection => 'Reminders';

  @override
  String get settingsNotifications => 'Local notifications';

  @override
  String get settingsNotificationsDetail =>
      'Reminds you when no snapshot has been recorded for a while, and tells you when a new badge tier is reached. Everything is scheduled on the device; nothing is sent anywhere.';

  @override
  String get settingsNotificationsDenied =>
      'Android refused the notification permission. Allow it for FieldTally in the system settings.';

  @override
  String settingsReminderDelay(int days) {
    return 'Remind me after $days days without a snapshot';
  }

  @override
  String get notificationReminderTitle => 'Time for a snapshot';

  @override
  String notificationReminderBody(int days) {
    return 'Nothing recorded for $days days. Share your stats from Ingress to keep your history going.';
  }

  @override
  String notificationMilestoneTitle(String tier) {
    return '$tier reached';
  }

  @override
  String notificationMilestoneBody(String counter, String value) {
    return '$counter is now at $value.';
  }

  @override
  String notificationMilestoneMore(String counter, int count) {
    return '$counter and $count other badges reached.';
  }
}
