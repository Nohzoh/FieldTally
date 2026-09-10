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
}
