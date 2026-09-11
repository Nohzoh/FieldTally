import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FieldTally'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No snapshot yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'Share your stats from Ingress, or paste the exported text to create your first snapshot.'**
  String get homeEmptyDetail;

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read your history'**
  String get homeLoadError;

  /// No description provided for @snapshotDateFormat.
  ///
  /// In en, this message translates to:
  /// **'d MMMM y \'at\' HH:mm'**
  String get snapshotDateFormat;

  /// No description provided for @snapshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} counters • {agent}'**
  String snapshotSubtitle(int count, String agent);

  /// No description provided for @deleteSnapshotTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete this snapshot'**
  String get deleteSnapshotTooltip;

  /// No description provided for @deleteSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this snapshot?'**
  String get deleteSnapshotTitle;

  /// No description provided for @deleteSnapshotBody.
  ///
  /// In en, this message translates to:
  /// **'It will disappear from your history and charts. This cannot be undone.'**
  String get deleteSnapshotBody;

  /// No description provided for @addSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a snapshot'**
  String get addSnapshotTitle;

  /// No description provided for @addSnapshotAction.
  ///
  /// In en, this message translates to:
  /// **'Add a snapshot'**
  String get addSnapshotAction;

  /// No description provided for @instructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'From Ingress'**
  String get instructionsTitle;

  /// No description provided for @instructionsBody.
  ///
  /// In en, this message translates to:
  /// **'Stats screen → select \"All Time\" → Share. Double-check the period: a \"This Week\" export would skew your history.'**
  String get instructionsBody;

  /// No description provided for @pasteFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Text exported from Ingress'**
  String get pasteFieldLabel;

  /// No description provided for @pasteFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the text shared from the stats screen here…'**
  String get pasteFieldHint;

  /// No description provided for @analyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyze;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTitle;

  /// No description provided for @previewNotSavedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing is saved until you confirm.'**
  String get previewNotSavedYet;

  /// No description provided for @previewDetailedDateFormat.
  ///
  /// In en, this message translates to:
  /// **'d MMMM y \'at\' HH:mm:ss'**
  String get previewDetailedDateFormat;

  /// No description provided for @fieldAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get fieldAgent;

  /// No description provided for @fieldFaction.
  ///
  /// In en, this message translates to:
  /// **'Faction'**
  String get fieldFaction;

  /// No description provided for @fieldPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get fieldPeriod;

  /// No description provided for @fieldRecordedAt.
  ///
  /// In en, this message translates to:
  /// **'Recorded on'**
  String get fieldRecordedAt;

  /// No description provided for @fieldLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get fieldLevel;

  /// No description provided for @fieldCounterCount.
  ///
  /// In en, this message translates to:
  /// **'Counters detected'**
  String get fieldCounterCount;

  /// No description provided for @detectedValues.
  ///
  /// In en, this message translates to:
  /// **'Detected values'**
  String get detectedValues;

  /// No description provided for @counterCount.
  ///
  /// In en, this message translates to:
  /// **'{count} counters'**
  String counterCount(int count);

  /// No description provided for @fallbackCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get fallbackCategory;

  /// No description provided for @saveSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Save this snapshot'**
  String get saveSnapshot;

  /// No description provided for @doNotSave.
  ///
  /// In en, this message translates to:
  /// **'Do not save'**
  String get doNotSave;

  /// No description provided for @saveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway…'**
  String get saveAnyway;

  /// No description provided for @saveAnywayTitle.
  ///
  /// In en, this message translates to:
  /// **'Save despite the anomaly?'**
  String get saveAnywayTitle;

  /// No description provided for @saveAnywayBody.
  ///
  /// In en, this message translates to:
  /// **'This snapshot is inconsistent with your history. Saving it will durably skew your diffs, charts and badge projections.\n\nOnly continue if you know exactly why.'**
  String get saveAnywayBody;

  /// No description provided for @saveAnywayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get saveAnywayConfirm;

  /// No description provided for @snapshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Snapshot saved.'**
  String get snapshotSaved;

  /// No description provided for @anomalyPartialPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Partial period detected'**
  String get anomalyPartialPeriodTitle;

  /// No description provided for @anomalyRegressionTitle.
  ///
  /// In en, this message translates to:
  /// **'Inconsistent with your history'**
  String get anomalyRegressionTitle;

  /// No description provided for @anomalyPartialPeriod.
  ///
  /// In en, this message translates to:
  /// **'This snapshot covers the \"{period}\" period rather than an all-time total — adding it would skew your history. Make sure you selected \"All Time\" in Ingress before exporting.'**
  String anomalyPartialPeriod(String period);

  /// No description provided for @anomalyRegression.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 counter has gone down} other{{count} counters have gone down}} since your last snapshot, which normally never happens. It is almost always a sign that the wrong period was imported. Check the list below before confirming.'**
  String anomalyRegression(int count);

  /// No description provided for @anomalyRegressionLine.
  ///
  /// In en, this message translates to:
  /// **'{counter}: {previous} → {current} (−{drop})'**
  String anomalyRegressionLine(
    String counter,
    int previous,
    int current,
    int drop,
  );

  /// No description provided for @anomalyRegressionMore.
  ///
  /// In en, this message translates to:
  /// **'… and {count} more.'**
  String anomalyRegressionMore(int count);

  /// No description provided for @timeSpanAllTime.
  ///
  /// In en, this message translates to:
  /// **'ALL TIME'**
  String get timeSpanAllTime;

  /// No description provided for @timeSpanWeek.
  ///
  /// In en, this message translates to:
  /// **'WEEK'**
  String get timeSpanWeek;

  /// No description provided for @timeSpanMonth.
  ///
  /// In en, this message translates to:
  /// **'MONTH'**
  String get timeSpanMonth;

  /// No description provided for @timeSpanNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get timeSpanNow;

  /// No description provided for @timeSpanUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get timeSpanUnknown;

  /// No description provided for @parseErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not read this text'**
  String get parseErrorTitle;

  /// No description provided for @parseErrorEmptyText.
  ///
  /// In en, this message translates to:
  /// **'The pasted text is empty — there is nothing to import.'**
  String get parseErrorEmptyText;

  /// No description provided for @parseErrorHeaderOnly.
  ///
  /// In en, this message translates to:
  /// **'The export only contains a header row, without any values. Make sure you copied the whole text from Ingress.'**
  String get parseErrorHeaderOnly;

  /// No description provided for @parseErrorNotTabSeparated.
  ///
  /// In en, this message translates to:
  /// **'This does not look like an Ingress export: no tab-separated columns were found. Use the Ingress share button rather than copying from the screen by hand.'**
  String get parseErrorNotTabSeparated;

  /// No description provided for @parseErrorBlankHeader.
  ///
  /// In en, this message translates to:
  /// **'The export contains a column without a name (position {position}), which makes matching values ambiguous.'**
  String parseErrorBlankHeader(int position);

  /// No description provided for @parseErrorDuplicateHeader.
  ///
  /// In en, this message translates to:
  /// **'The export contains two columns named \"{column}\". There is no way to tell which one to use.'**
  String parseErrorDuplicateHeader(String column);

  /// No description provided for @parseErrorColumnCountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {values} values for {headers} columns. The text was most likely truncated while copying.'**
  String parseErrorColumnCountMismatch(int row, int values, int headers);

  /// No description provided for @parseErrorMissingColumn.
  ///
  /// In en, this message translates to:
  /// **'The \"{column}\" column is missing from the export. The Ingress format may have changed — please report it with an anonymised sample.'**
  String parseErrorMissingColumn(String column);

  /// No description provided for @parseErrorEmptyValue.
  ///
  /// In en, this message translates to:
  /// **'The \"{column}\" column is empty.'**
  String parseErrorEmptyValue(String column);

  /// No description provided for @parseErrorNotAnInteger.
  ///
  /// In en, this message translates to:
  /// **'The \"{column}\" column does not contain a whole number.'**
  String parseErrorNotAnInteger(String column);

  /// No description provided for @parseErrorOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'The value of \"{column}\" is outside the acceptable range.'**
  String parseErrorOutOfRange(String column);

  /// No description provided for @parseErrorInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'The date \"{value}\" is not in the expected format (yyyy-mm-dd).'**
  String parseErrorInvalidDate(String value);

  /// No description provided for @parseErrorInvalidTime.
  ///
  /// In en, this message translates to:
  /// **'The time \"{value}\" is not in the expected format (hh:mm:ss).'**
  String parseErrorInvalidTime(String value);

  /// No description provided for @parseErrorNonExistentDate.
  ///
  /// In en, this message translates to:
  /// **'The date \"{value}\" does not exist.'**
  String parseErrorNonExistentDate(String value);

  /// No description provided for @parseErrorTooManyRows.
  ///
  /// In en, this message translates to:
  /// **'The export contains {count} snapshots when only one is expected here.'**
  String parseErrorTooManyRows(int count);

  /// No description provided for @parseErrorRawValue.
  ///
  /// In en, this message translates to:
  /// **'Value read: \"{value}\"'**
  String parseErrorRawValue(String value);

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Unofficial tool, not affiliated with Niantic. \"Ingress\" is a trademark of Niantic, Inc.'**
  String get disclaimer;

  /// No description provided for @countersTitle.
  ///
  /// In en, this message translates to:
  /// **'All counters'**
  String get countersTitle;

  /// No description provided for @countersAction.
  ///
  /// In en, this message translates to:
  /// **'All counters'**
  String get countersAction;

  /// No description provided for @countersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Counters appear once you have saved a snapshot.'**
  String get countersEmpty;

  /// No description provided for @searchCounters.
  ///
  /// In en, this message translates to:
  /// **'Search a counter'**
  String get searchCounters;

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortLabel;

  /// No description provided for @sortByCategory.
  ///
  /// In en, this message translates to:
  /// **'In-game order'**
  String get sortByCategory;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortByRecentProgress.
  ///
  /// In en, this message translates to:
  /// **'Recent progress'**
  String get sortByRecentProgress;

  /// No description provided for @showInactive.
  ///
  /// In en, this message translates to:
  /// **'Show inactive counters'**
  String get showInactive;

  /// No description provided for @inactiveSince.
  ///
  /// In en, this message translates to:
  /// **'inactive since {date}'**
  String inactiveSince(String date);

  /// No description provided for @shortDateFormat.
  ///
  /// In en, this message translates to:
  /// **'d MMM y'**
  String get shortDateFormat;

  /// No description provided for @noDelta.
  ///
  /// In en, this message translates to:
  /// **'no comparison yet'**
  String get noDelta;

  /// No description provided for @deltaSince.
  ///
  /// In en, this message translates to:
  /// **'{delta} since the previous snapshot'**
  String deltaSince(String delta);

  /// No description provided for @counterHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get counterHistory;

  /// No description provided for @counterFirstSeen.
  ///
  /// In en, this message translates to:
  /// **'First seen'**
  String get counterFirstSeen;

  /// No description provided for @counterLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get counterLastSeen;

  /// No description provided for @counterCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current value'**
  String get counterCurrentValue;

  /// No description provided for @counterNoTiers.
  ///
  /// In en, this message translates to:
  /// **'No badge threshold is known for this counter yet, so no projection is computed.'**
  String get counterNoTiers;

  /// No description provided for @counterSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No counter matches “{search}”.'**
  String counterSearchEmpty(String search);

  /// No description provided for @counterExportHeader.
  ///
  /// In en, this message translates to:
  /// **'Export header'**
  String get counterExportHeader;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'FieldTally'**
  String get dashboardTitle;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'Add a snapshot and your pinned counters will appear here.'**
  String get dashboardEmptyDetail;

  /// No description provided for @customise.
  ///
  /// In en, this message translates to:
  /// **'Customise'**
  String get customise;

  /// No description provided for @customiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pinned counters'**
  String get customiseTitle;

  /// No description provided for @customiseHint.
  ///
  /// In en, this message translates to:
  /// **'Pick between {min} and {max} counters to show on the dashboard.'**
  String customiseHint(int min, int max);

  /// No description provided for @customiseSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} selected'**
  String customiseSelected(int count, int max);

  /// No description provided for @customiseTooFew.
  ///
  /// In en, this message translates to:
  /// **'Pick at least {min}.'**
  String customiseTooFew(int min);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @snapshotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Snapshots'**
  String get snapshotsTitle;

  /// No description provided for @notEnoughHistory.
  ///
  /// In en, this message translates to:
  /// **'1 snapshot'**
  String get notEnoughHistory;

  /// No description provided for @chartNeedsTwoSnapshots.
  ///
  /// In en, this message translates to:
  /// **'At least two snapshots are needed to draw a chart.'**
  String get chartNeedsTwoSnapshots;

  /// No description provided for @chartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Chart from {first} to {last}, {count} points.'**
  String chartSemantics(String first, String last, int count);

  /// No description provided for @rangeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get rangeWeek;

  /// No description provided for @rangeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get rangeMonth;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rangeAll;

  /// No description provided for @rangeGain.
  ///
  /// In en, this message translates to:
  /// **'{gain} over this period'**
  String rangeGain(String gain);

  /// No description provided for @rangeNoData.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded over this period.'**
  String get rangeNoData;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'AP gained, on the day each snapshot was taken.'**
  String get activitySubtitle;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Two snapshots are needed before activity shows up.'**
  String get activityEmpty;

  /// No description provided for @activitySummary.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day with progress} other{{days} days with progress}} · best day {peak} AP'**
  String activitySummary(int days, String peak);

  /// Axis labels: no year, the chart is too narrow for it
  ///
  /// In en, this message translates to:
  /// **'d MMM'**
  String get chartAxisDateFormat;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDataSection.
  ///
  /// In en, this message translates to:
  /// **'Counter categorisation'**
  String get settingsDataSection;

  /// No description provided for @settingsOnlineUpdates.
  ///
  /// In en, this message translates to:
  /// **'Update online'**
  String get settingsOnlineUpdates;

  /// No description provided for @settingsOnlineUpdatesDetail.
  ///
  /// In en, this message translates to:
  /// **'Downloads the public list of counter names and categories from the project site, so new anomaly counters are labelled without waiting for an app update. Nothing about you or your device is sent. Turn it off to keep the app entirely offline.'**
  String get settingsOnlineUpdatesDetail;

  /// No description provided for @settingsRegistryCounters.
  ///
  /// In en, this message translates to:
  /// **'{count} counters known'**
  String settingsRegistryCounters(int count);

  /// No description provided for @settingsRegistryUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Version {date}'**
  String settingsRegistryUpdatedAt(String date);

  /// No description provided for @settingsAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutSection;

  /// No description provided for @importCsvTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Agent Stats'**
  String get importCsvTitle;

  /// No description provided for @importCsvAction.
  ///
  /// In en, this message translates to:
  /// **'Import from Agent Stats'**
  String get importCsvAction;

  /// No description provided for @importCsvInstructions.
  ///
  /// In en, this message translates to:
  /// **'Paste the CSV export from Agent Stats. Your whole history comes across at once — nothing is saved until you confirm.'**
  String get importCsvInstructions;

  /// No description provided for @importCsvField.
  ///
  /// In en, this message translates to:
  /// **'Agent Stats CSV'**
  String get importCsvField;

  /// No description provided for @importCsvSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} snapshots, {counters} counters'**
  String importCsvSummary(int count, int counters);

  /// No description provided for @importCsvRange.
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to}'**
  String importCsvRange(String from, String to);

  /// No description provided for @importCsvNoTimeSpan.
  ///
  /// In en, this message translates to:
  /// **'This format carries no period column, so only the consistency check protects the import. Every pair of rows has been checked.'**
  String get importCsvNoTimeSpan;

  /// No description provided for @importCsvConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import {count} snapshots'**
  String importCsvConfirm(int count);

  /// No description provided for @importCsvDone.
  ///
  /// In en, this message translates to:
  /// **'{count} snapshots imported.'**
  String importCsvDone(int count);

  /// No description provided for @importCsvAnomalyTitle.
  ///
  /// In en, this message translates to:
  /// **'Inconsistent rows in this file'**
  String get importCsvAnomalyTitle;

  /// No description provided for @importCsvAnomaly.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 counter goes backwards} other{{count} counters go backwards}} inside this file, which normally never happens. Importing it would skew your history from that date onwards.'**
  String importCsvAnomaly(int count);

  /// No description provided for @importCsvAnomalyLine.
  ///
  /// In en, this message translates to:
  /// **'{date} · {counter}: {previous} → {current}'**
  String importCsvAnomalyLine(
    String date,
    String counter,
    int previous,
    int current,
  );

  /// No description provided for @unknownValue.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get unknownValue;

  /// No description provided for @projectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Next badge'**
  String get projectionTitle;

  /// No description provided for @projectionTier_bronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get projectionTier_bronze;

  /// No description provided for @projectionTier_silver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get projectionTier_silver;

  /// No description provided for @projectionTier_gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get projectionTier_gold;

  /// No description provided for @projectionTier_platinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get projectionTier_platinum;

  /// No description provided for @projectionTier_onyx.
  ///
  /// In en, this message translates to:
  /// **'Onyx'**
  String get projectionTier_onyx;

  /// No description provided for @projectionRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} to go for {tier}'**
  String projectionRemaining(String remaining, String tier);

  /// No description provided for @projectionDate.
  ///
  /// In en, this message translates to:
  /// **'Around {date} at your recent pace'**
  String projectionDate(String date);

  /// No description provided for @projectionNoPace.
  ///
  /// In en, this message translates to:
  /// **'No estimate: this counter has not moved lately.'**
  String get projectionNoPace;

  /// No description provided for @projectionTooFar.
  ///
  /// In en, this message translates to:
  /// **'No estimate: too far off at your recent pace.'**
  String get projectionTooFar;

  /// No description provided for @projectionComplete.
  ///
  /// In en, this message translates to:
  /// **'Onyx reached — nothing left to chase.'**
  String get projectionComplete;

  /// No description provided for @projectionBelowFirst.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get projectionBelowFirst;

  /// No description provided for @projectionPace.
  ///
  /// In en, this message translates to:
  /// **'{rate} per day over the last {window}'**
  String projectionPace(String rate, String window);

  /// No description provided for @projectionWindowWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get projectionWindowWeek;

  /// No description provided for @projectionWindowMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get projectionWindowMonth;

  /// No description provided for @projectionPaceWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get projectionPaceWeek;

  /// No description provided for @projectionPaceMonth.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get projectionPaceMonth;

  /// No description provided for @editSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Correct this snapshot'**
  String get editSnapshotTitle;

  /// No description provided for @editSnapshotTooltip.
  ///
  /// In en, this message translates to:
  /// **'Correct this snapshot'**
  String get editSnapshotTooltip;

  /// No description provided for @editRecordedAt.
  ///
  /// In en, this message translates to:
  /// **'Recorded on'**
  String get editRecordedAt;

  /// No description provided for @editPickDate.
  ///
  /// In en, this message translates to:
  /// **'Change the date'**
  String get editPickDate;

  /// No description provided for @editPickTime.
  ///
  /// In en, this message translates to:
  /// **'Change the time'**
  String get editPickTime;

  /// No description provided for @editSave.
  ///
  /// In en, this message translates to:
  /// **'Save the correction'**
  String get editSave;

  /// No description provided for @editSaved.
  ///
  /// In en, this message translates to:
  /// **'Snapshot corrected.'**
  String get editSaved;

  /// No description provided for @editCounterSection.
  ///
  /// In en, this message translates to:
  /// **'Counter values'**
  String get editCounterSection;

  /// No description provided for @editInvalidValue.
  ///
  /// In en, this message translates to:
  /// **'Whole numbers only'**
  String get editInvalidValue;

  /// No description provided for @editAnomalyTitle.
  ///
  /// In en, this message translates to:
  /// **'This correction breaks the sequence'**
  String get editAnomalyTitle;

  /// No description provided for @editAnomaly.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 counter would go backwards} other{{count} counters would go backwards}} compared with the neighbouring snapshots.'**
  String editAnomaly(int count);

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export the history'**
  String get exportCsv;

  /// No description provided for @exportCsvSubject.
  ///
  /// In en, this message translates to:
  /// **'FieldTally history'**
  String get exportCsvSubject;

  /// No description provided for @exportCsvEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet.'**
  String get exportCsvEmpty;

  /// No description provided for @exportCsvDone.
  ///
  /// In en, this message translates to:
  /// **'{count} snapshots exported.'**
  String exportCsvDone(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
