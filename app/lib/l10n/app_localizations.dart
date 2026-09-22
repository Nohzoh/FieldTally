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

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

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

  /// A snapshot's moment in full, for the import preview and the correction screen. Minutes, like every other date-and-time surface: it carried seconds until #81, which was precision the agent could not set — the time picker offers hours and minutes, and a correction silently zeroes the rest.
  ///
  /// In en, this message translates to:
  /// **'d MMMM y \'at\' HH:mm'**
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

  /// Orders the counter list by how far across its current stretch each counter has come — the share of the way from the tier behind to the one ahead, or to the next multiple past onyx (#90). A share rather than what is left in absolute terms: the counters span five orders of magnitude and only a fraction compares between them.
  ///
  /// In en, this message translates to:
  /// **'Closest to next tier'**
  String get sortByNextTier;

  /// No description provided for @filtersLabel.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get filtersLabel;

  /// Filter chip narrowing the list to counters that carry a badge (#88). Seventeen counters of fifty-nine, so roughly seven rows in ten disappear.
  ///
  /// In en, this message translates to:
  /// **'Medals'**
  String get filterMedals;

  /// No description provided for @filterMedalsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Only counters that carry a badge'**
  String get filterMedalsTooltip;

  /// No description provided for @filterInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get filterInactive;

  /// No description provided for @filterInactiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Include counters that no longer appear in imports'**
  String get filterInactiveTooltip;

  /// Filter chip narrowing the list to counters whose value has never changed across the whole tracked history (#165) — the honest version of "what am I not doing", not merely "still at zero".
  ///
  /// In en, this message translates to:
  /// **'Never moved'**
  String get filterNeverMoved;

  /// No description provided for @filterNeverMovedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Only counters whose value has never changed'**
  String get filterNeverMovedTooltip;

  /// Labels the window the recent-progress ordering measures across. Shown only while that ordering is selected, so the control is never dead (#89).
  ///
  /// In en, this message translates to:
  /// **'Measured over'**
  String get progressWindowLabel;

  /// No description provided for @progressWindowSinceLast.
  ///
  /// In en, this message translates to:
  /// **'Since last'**
  String get progressWindowSinceLast;

  /// No description provided for @progressWindowWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get progressWindowWeek;

  /// No description provided for @progressWindowMonth.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get progressWindowMonth;

  /// No description provided for @countersFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'No counter matches the filters.'**
  String get countersFilteredEmpty;

  /// No description provided for @countersMedalsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Badge thresholds have not loaded yet, so no counter can be matched.'**
  String get countersMedalsUnknown;

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

  /// A snapshot's date AND time, for the two places where two snapshots can sit side by side on the same day: the history list under a counter's chart, and the chart's own tooltip (#75). Deliberately separate from shortDateFormat, which is about a day rather than a moment and is shared by goal deadlines, projected dates and the shareable card.
  ///
  /// In en, this message translates to:
  /// **'d MMM y, HH:mm'**
  String get shortDateTimeFormat;

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

  /// No description provided for @countersWatchedSince.
  ///
  /// In en, this message translates to:
  /// **'Watched since {date}. An event whose column had already left the export by then cannot be shown at all.'**
  String countersWatchedSince(String date);

  /// No description provided for @counterExportHeader.
  ///
  /// In en, this message translates to:
  /// **'Export header'**
  String get counterExportHeader;

  /// No description provided for @counterPinWidget.
  ///
  /// In en, this message translates to:
  /// **'Add to home screen'**
  String get counterPinWidget;

  /// No description provided for @counterPinWidgetUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Your home screen doesn\'t support adding a widget this way — long-press it and add FieldTally\'s widget manually instead.'**
  String get counterPinWidgetUnsupported;

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

  /// No description provided for @customiseWidgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Widget counters'**
  String get customiseWidgetTitle;

  /// No description provided for @customiseWidgetHint.
  ///
  /// In en, this message translates to:
  /// **'Pick between {min} and {max} counters to show on the home screen widget.'**
  String customiseWidgetHint(int min, int max);

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

  /// No description provided for @chartTargetGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal · {value}'**
  String chartTargetGoal(String value);

  /// No description provided for @chartTargetBadge.
  ///
  /// In en, this message translates to:
  /// **'{tier} · {value}'**
  String chartTargetBadge(String tier, String value);

  /// No description provided for @chartTargetSemantics.
  ///
  /// In en, this message translates to:
  /// **'A dashed line marks {target}.'**
  String chartTargetSemantics(String target);

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

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String settingsVersion(String version, String build);

  /// No description provided for @settingsBuildUnknown.
  ///
  /// In en, this message translates to:
  /// **'Built from a working copy'**
  String get settingsBuildUnknown;

  /// No description provided for @settingsCopyVersion.
  ///
  /// In en, this message translates to:
  /// **'Tap to copy, to paste into a bug report'**
  String get settingsCopyVersion;

  /// No description provided for @settingsVersionCopied.
  ///
  /// In en, this message translates to:
  /// **'Version copied.'**
  String get settingsVersionCopied;

  /// No description provided for @settingsWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get settingsWhatsNew;

  /// No description provided for @settingsWhatsNewDetail.
  ///
  /// In en, this message translates to:
  /// **'Read again what changed in this version.'**
  String get settingsWhatsNewDetail;

  /// No description provided for @settingsWhatsNewNone.
  ///
  /// In en, this message translates to:
  /// **'No notes bundled for this build.'**
  String get settingsWhatsNewNone;

  /// No description provided for @settingsAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get settingsAuthor;

  /// No description provided for @settingsAuthorDetail.
  ///
  /// In en, this message translates to:
  /// **'Nohzoh, on GitHub.'**
  String get settingsAuthorDetail;

  /// No description provided for @settingsSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get settingsSourceCode;

  /// No description provided for @settingsSourceCodeDetail.
  ///
  /// In en, this message translates to:
  /// **'The whole app, under AGPL v3.'**
  String get settingsSourceCodeDetail;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support the project'**
  String get settingsSupport;

  /// No description provided for @settingsSupportDetail.
  ///
  /// In en, this message translates to:
  /// **'FieldTally is free, has no ads and collects nothing. Nothing is expected — but a coffee is always welcome.'**
  String get settingsSupportDetail;

  /// No description provided for @settingsLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'No app could open that link.'**
  String get settingsLinkFailed;

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

  /// No description provided for @importCsvIgnored.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line was not a snapshot and was skipped.} other{{count} lines were not snapshots and were skipped.}}'**
  String importCsvIgnored(int count);

  /// No description provided for @importCsvHeaderIgnored.
  ///
  /// In en, this message translates to:
  /// **'The column titles did not match the rows, so the documented column order was used instead.'**
  String get importCsvHeaderIgnored;

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

  /// Names the medal a counter has reached, next to its emblem. The tier must be readable as text: colour alone never carries it (§3.9).
  ///
  /// In en, this message translates to:
  /// **'{tier} medal'**
  String medalTier(String tier);

  /// No description provided for @medalNone.
  ///
  /// In en, this message translates to:
  /// **'No medal yet'**
  String get medalNone;

  /// Names the medal once every tier is behind, with the multiplier the game shows: how many whole times the top threshold has been reached (#87). Shown from 2 upwards — a 1 would only repeat what the medal already says.
  ///
  /// In en, this message translates to:
  /// **'{tier} medal ×{count}'**
  String medalTierMultiple(String tier, int count);

  /// Spoken form of medalTierMultiple. The × sign is read out inconsistently by screen readers, or skipped entirely, so the multiplier is spelt out in words here (§3.9).
  ///
  /// In en, this message translates to:
  /// **'{tier} medal, reached {count} times over'**
  String medalTierMultipleSemantics(String tier, int count);

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

  /// Replaces projectionRemaining once every tier is behind: the target is the next whole multiple of the top threshold rather than a tier (#87).
  ///
  /// In en, this message translates to:
  /// **'{remaining} to go for ×{count}'**
  String projectionRemainingMultiple(String remaining, int count);

  /// Spoken form of projectionRemainingMultiple, for the same reason as medalTierMultipleSemantics.
  ///
  /// In en, this message translates to:
  /// **'{remaining} to go to reach {tier} {count} times over'**
  String projectionRemainingMultipleSemantics(
    String remaining,
    String tier,
    int count,
  );

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

  /// Replaces the remaining line once a seasonal ladder has closed (#99). The medal already earned stays; what ends is the chase, so this says the window is shut rather than that the agent failed.
  ///
  /// In en, this message translates to:
  /// **'This one can no longer be earned.'**
  String get projectionEnded;

  /// A ladder that ends, climbed to its top. Unlike onyx there is no further multiple to chase, because the game itself stops counting there.
  ///
  /// In en, this message translates to:
  /// **'Every tier reached.'**
  String get projectionAllTiers;

  /// The pace does reach the target, but only after the ladder's own deadline. Distinct from projectionTooFar, which is about a pace too slow to matter rather than a window about to shut.
  ///
  /// In en, this message translates to:
  /// **'No estimate: not at this pace before it closes.'**
  String get projectionAfterDeadline;

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

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal goal'**
  String get goalTitle;

  /// No description provided for @goalNone.
  ///
  /// In en, this message translates to:
  /// **'No goal on this counter yet.'**
  String get goalNone;

  /// No description provided for @goalSet.
  ///
  /// In en, this message translates to:
  /// **'Set a goal'**
  String get goalSet;

  /// No description provided for @goalEdit.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get goalEdit;

  /// No description provided for @goalRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get goalRemove;

  /// No description provided for @goalTarget.
  ///
  /// In en, this message translates to:
  /// **'Target value'**
  String get goalTarget;

  /// No description provided for @goalDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get goalDeadline;

  /// No description provided for @goalNoDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get goalNoDeadline;

  /// No description provided for @goalPickDeadline.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get goalPickDeadline;

  /// No description provided for @goalClearDeadline.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get goalClearDeadline;

  /// No description provided for @goalSave.
  ///
  /// In en, this message translates to:
  /// **'Save the goal'**
  String get goalSave;

  /// No description provided for @goalSaved.
  ///
  /// In en, this message translates to:
  /// **'Goal saved.'**
  String get goalSaved;

  /// No description provided for @goalRemoved.
  ///
  /// In en, this message translates to:
  /// **'Goal removed.'**
  String get goalRemoved;

  /// No description provided for @goalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Must be above the current value'**
  String get goalInvalid;

  /// No description provided for @goalRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} to go, out of {target}'**
  String goalRemaining(String remaining, String target);

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Reached.'**
  String get goalReached;

  /// No description provided for @goalOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track for {date}'**
  String goalOnTrack(String date);

  /// No description provided for @goalBehind.
  ///
  /// In en, this message translates to:
  /// **'Behind for {date}'**
  String goalBehind(String date);

  /// No description provided for @goalMissed.
  ///
  /// In en, this message translates to:
  /// **'Deadline of {date} passed.'**
  String goalMissed(String date);

  /// No description provided for @goalNoOpinion.
  ///
  /// In en, this message translates to:
  /// **'No estimate at your recent pace.'**
  String get goalNoOpinion;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTitle;

  /// No description provided for @goalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set a goal from any counter to see it here.'**
  String get goalsEmpty;

  /// No description provided for @compareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare with an agent'**
  String get compareTitle;

  /// No description provided for @compareIntro.
  ///
  /// In en, this message translates to:
  /// **'Send your totals to an agent next to you and their app puts your numbers side by side. Nothing goes through a server: the share sheet hands the text straight to their phone.'**
  String get compareIntro;

  /// No description provided for @comparePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'What will be sent'**
  String get comparePreviewTitle;

  /// No description provided for @comparePreviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 counter} other{{count} counters}}, plus your codename, faction, level and the date of this snapshot.'**
  String comparePreviewCount(int count);

  /// No description provided for @compareSend.
  ///
  /// In en, this message translates to:
  /// **'Send my stats'**
  String get compareSend;

  /// No description provided for @compareSendBack.
  ///
  /// In en, this message translates to:
  /// **'Send mine back'**
  String get compareSendBack;

  /// No description provided for @compareSubject.
  ///
  /// In en, this message translates to:
  /// **'My FieldTally totals'**
  String get compareSubject;

  /// No description provided for @compareEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to send yet'**
  String get compareEmptyTitle;

  /// No description provided for @compareEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'Record a snapshot first — there has to be something to compare.'**
  String get compareEmptyDetail;

  /// Heading of the side-by-side view, naming the other agent.
  ///
  /// In en, this message translates to:
  /// **'Against {agent}'**
  String compareAgainst(String agent);

  /// No description provided for @compareAgentLine.
  ///
  /// In en, this message translates to:
  /// **'{faction} · snapshot of {date}'**
  String compareAgentLine(String faction, String date);

  /// Same, for an agent whose level is known. The level is already spelled out, as 'Level 14'.
  ///
  /// In en, this message translates to:
  /// **'{level} · {faction} · snapshot of {date}'**
  String compareAgentLineWithLevel(String level, String faction, String date);

  /// No description provided for @compareColumnMine.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get compareColumnMine;

  /// No description provided for @compareColumnTheirs.
  ///
  /// In en, this message translates to:
  /// **'Them'**
  String get compareColumnTheirs;

  /// No description provided for @compareColumnDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get compareColumnDifference;

  /// No description provided for @compareNotKept.
  ///
  /// In en, this message translates to:
  /// **'Their numbers are not saved. They are gone as soon as you leave this screen, and they never touch your own history.'**
  String get compareNotKept;

  /// No description provided for @compareNoValue.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get compareNoValue;

  /// No description provided for @compareTied.
  ///
  /// In en, this message translates to:
  /// **'Tied'**
  String get compareTied;

  /// No description provided for @compareErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'This could not be read'**
  String get compareErrorTitle;

  /// No description provided for @compareErrorUnsupportedVersion.
  ///
  /// In en, this message translates to:
  /// **'It was written by a newer FieldTally than this one. Updating the app should fix it.'**
  String get compareErrorUnsupportedVersion;

  /// No description provided for @compareErrorNotCumulative.
  ///
  /// In en, this message translates to:
  /// **'Those totals cover a shorter period, so they cannot be set against all-time ones.'**
  String get compareErrorNotCumulative;

  /// No description provided for @compareErrorMalformed.
  ///
  /// In en, this message translates to:
  /// **'It does not look like stats sent from FieldTally.'**
  String get compareErrorMalformed;

  /// No description provided for @shareCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Shareable card'**
  String get shareCardTitle;

  /// No description provided for @shareCardAction.
  ///
  /// In en, this message translates to:
  /// **'Share my stats'**
  String get shareCardAction;

  /// No description provided for @shareCardShare.
  ///
  /// In en, this message translates to:
  /// **'Share the image'**
  String get shareCardShare;

  /// No description provided for @shareCardSince.
  ///
  /// In en, this message translates to:
  /// **'Progress since {date}'**
  String shareCardSince(String date);

  /// No description provided for @shareCardNoPeriod.
  ///
  /// In en, this message translates to:
  /// **'Only one snapshot so far — no progress to show yet.'**
  String get shareCardNoPeriod;

  /// No description provided for @shareCardFooter.
  ///
  /// In en, this message translates to:
  /// **'Made with FieldTally'**
  String get shareCardFooter;

  /// No description provided for @shareCardDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Unofficial · not affiliated with Niantic'**
  String get shareCardDisclaimer;

  /// No description provided for @shareCardSubject.
  ///
  /// In en, this message translates to:
  /// **'My Ingress stats'**
  String get shareCardSubject;

  /// No description provided for @shareCardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to share yet'**
  String get shareCardEmptyTitle;

  /// No description provided for @shareCardEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'Record a snapshot and your card will be ready.'**
  String get shareCardEmptyDetail;

  /// No description provided for @shareCardFailed.
  ///
  /// In en, this message translates to:
  /// **'The image could not be produced.'**
  String get shareCardFailed;

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsFactionColours.
  ///
  /// In en, this message translates to:
  /// **'Faction colours'**
  String get settingsFactionColours;

  /// No description provided for @settingsFactionColoursDetail.
  ///
  /// In en, this message translates to:
  /// **'Tints the app with your faction\'s colour, read from your latest snapshot. Off, the app keeps its own.'**
  String get settingsFactionColoursDetail;

  /// No description provided for @settingsFactionUnknown.
  ///
  /// In en, this message translates to:
  /// **'No snapshot yet, so there is no faction to follow.'**
  String get settingsFactionUnknown;

  /// No description provided for @settingsNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsNotificationsSection;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Local notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsDetail.
  ///
  /// In en, this message translates to:
  /// **'Reminds you when no snapshot has been recorded for a while, and tells you when a new badge tier is reached. Everything is scheduled on the device; nothing is sent anywhere.'**
  String get settingsNotificationsDetail;

  /// No description provided for @settingsNotificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Android refused the notification permission. Allow it for FieldTally in the system settings.'**
  String get settingsNotificationsDenied;

  /// No description provided for @settingsReminderDelay.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Remind me after a day without a snapshot} other{Remind me after {days} days without a snapshot}}'**
  String settingsReminderDelay(int days);

  /// No description provided for @notificationReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for a snapshot'**
  String get notificationReminderTitle;

  /// No description provided for @notificationReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Nothing recorded since yesterday. Share your stats from Ingress to keep your history going.} other{Nothing recorded for {days} days. Share your stats from Ingress to keep your history going.}}'**
  String notificationReminderBody(int days);

  /// Title of a badge milestone. Names the badge as well as the tier: a collapsed notification, a lock screen or a watch shows the title alone, and "Onyx reached" on its own says nothing about what was reached (#103).
  ///
  /// In en, this message translates to:
  /// **'{tier} — {counter}'**
  String notificationMilestoneTitle(String counter, String tier);

  /// Body of a badge milestone. The counter is in the title now (#103), so repeating it here would say the same thing twice on one notification.
  ///
  /// In en, this message translates to:
  /// **'Now at {value}.'**
  String notificationMilestoneBody(String value);

  /// A further whole multiple of a top tier the game keeps counting past (#87). Spelled out in words rather than as ×{count}: a notification is read aloud by the system, and the multiplication sign is read out inconsistently or skipped.
  ///
  /// In en, this message translates to:
  /// **'{tier} {count} times over — {counter}'**
  String notificationMultipleTitle(String tier, int count, String counter);

  /// No description provided for @notificationLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String notificationLevelTitle(int level);

  /// The one place a word of celebration rings true: a level arrives once per import, where a badge can arrive three times in a row. Says nothing about a personal best, because an agent who recursed and climbed back is reaching this level for the second time and it still counts (#105).
  ///
  /// In en, this message translates to:
  /// **'Well played, Agent.'**
  String get notificationLevelBody;

  /// No description provided for @notificationMilestoneMore.
  ///
  /// In en, this message translates to:
  /// **'{counter} and {count} other badges reached.'**
  String notificationMilestoneMore(String counter, int count);

  /// No description provided for @changelogDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new in {version}'**
  String changelogDialogTitle(String version);

  /// No description provided for @changelogNewHeading.
  ///
  /// In en, this message translates to:
  /// **'✨ New'**
  String get changelogNewHeading;

  /// No description provided for @changelogFixedHeading.
  ///
  /// In en, this message translates to:
  /// **'🐛 Fixed'**
  String get changelogFixedHeading;

  /// No description provided for @changelogHeadline.
  ///
  /// In en, this message translates to:
  /// **'{version} — {title}'**
  String changelogHeadline(String version, String title);

  /// No description provided for @changelogFullNotes.
  ///
  /// In en, this message translates to:
  /// **'Read the full notes'**
  String get changelogFullNotes;

  /// Title of the screen reached by tapping a snapshot (#147). Deliberately not "this outing": the app cannot know whether two snapshots bracket an afternoon of play or six idle weeks — the agent chose when to record, and that choice is the only boundary there is.
  ///
  /// In en, this message translates to:
  /// **'What changed'**
  String get snapshotChangesTitle;

  /// No description provided for @snapshotChangesInterval.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String snapshotChangesInterval(String from, String to);

  /// How long the interval lasted. Rounded down to whole days, and saying so below one: an afternoon reads as "less than a day" rather than as zero.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{less than a day} one{1 day} other{{count} days}}'**
  String snapshotChangesSpan(int count);

  /// No description provided for @snapshotChangesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 counter moved} other{{count} counters moved}}'**
  String snapshotChangesCount(int count);

  /// A counter's two ends on one row. Separate from snapshotChangesInterval, which joins two dates: they read the same today and have no reason to stay identical in every language.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String snapshotChangesValues(String from, String to);

  /// No description provided for @snapshotChangesNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing moved between these two snapshots.'**
  String get snapshotChangesNone;

  /// No description provided for @snapshotChangesNoPrevious.
  ///
  /// In en, this message translates to:
  /// **'This is your earliest snapshot, so there is nothing before it to compare against.'**
  String get snapshotChangesNoPrevious;

  /// A ranking of badges by how long each would take at the recent pace, across every counter (#148). Distinct from the counter list's "closest to its next tier" sort, which measures the share of the stretch already crossed — a counter at 95 % of onyx can be four hundred days out.
  ///
  /// In en, this message translates to:
  /// **'Within reach'**
  String get withinReachTitle;

  /// States the window rather than leaving it assumed: the whole ranking changes with it.
  ///
  /// In en, this message translates to:
  /// **'At your pace over the last 30 days'**
  String get withinReachWindow;

  /// No description provided for @withinReachDays.
  ///
  /// In en, this message translates to:
  /// **'{tier} · {count, plural, one{about a day} other{about {count} days}}'**
  String withinReachDays(String tier, int count);

  /// No description provided for @withinReachEmpty.
  ///
  /// In en, this message translates to:
  /// **'No badge is within reach at your recent pace.'**
  String get withinReachEmpty;

  /// No description provided for @withinReachEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'A badge appears here once a counter has moved enough lately to support an honest estimate — and stays out when that estimate would be a guess.'**
  String get withinReachEmptyDetail;

  /// No description provided for @withinReachNeedsHistory.
  ///
  /// In en, this message translates to:
  /// **'Two snapshots are needed before a pace can be measured.'**
  String get withinReachNeedsHistory;

  /// Said under the dashboard when a pinned counter moved over the previous month and not at all over the recent one (#149). A fact, not a judgement: the app deliberately says nothing about a counter that merely sped up or slowed down, because saying that would need a threshold nobody can defend.
  ///
  /// In en, this message translates to:
  /// **'{counter} has not moved in the last month'**
  String paceStopped(String counter);

  /// No description provided for @paceResumed.
  ///
  /// In en, this message translates to:
  /// **'{counter} is moving again'**
  String paceResumed(String counter);

  /// No description provided for @paceChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Since last month'**
  String get paceChangesTitle;

  /// A year read back, built on the device from the history alone (#153). The roadmap filed this under "would need a server"; it does not.
  ///
  /// In en, this message translates to:
  /// **'{year} in review'**
  String yearInReviewTitle(String year);

  /// No description provided for @yearInReviewPartial.
  ///
  /// In en, this message translates to:
  /// **'Your history starts on {date}, so this covers part of the year.'**
  String yearInReviewPartial(String date);

  /// No description provided for @yearInReviewSpan.
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to}'**
  String yearInReviewSpan(String from, String to);

  /// No description provided for @yearInReviewGains.
  ///
  /// In en, this message translates to:
  /// **'What moved'**
  String get yearInReviewGains;

  /// No description provided for @yearInReviewGain.
  ///
  /// In en, this message translates to:
  /// **'+{gain}'**
  String yearInReviewGain(String gain);

  /// No description provided for @yearInReviewMedals.
  ///
  /// In en, this message translates to:
  /// **'Medals crossed'**
  String get yearInReviewMedals;

  /// No description provided for @yearInReviewMedal.
  ///
  /// In en, this message translates to:
  /// **'{counter} · {tier}'**
  String yearInReviewMedal(String counter, String tier);

  /// No description provided for @yearInReviewBusiest.
  ///
  /// In en, this message translates to:
  /// **'Your busiest month was {month}.'**
  String yearInReviewBusiest(String month);

  /// The honest caveat on everything above: a recap built from a history with a hole is describing what was recorded, not what was done.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Your longest stretch without an import was 1 day, so this describes what you recorded.} other{Your longest stretch without an import was {count} days, so this describes what you recorded.}}'**
  String yearInReviewGap(int count);

  /// No description provided for @yearInReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is not enough history in {year} to read it back.'**
  String yearInReviewEmpty(String year);

  /// No description provided for @yearInReviewEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'Two snapshots in the same year is the least it takes.'**
  String get yearInReviewEmptyDetail;

  /// No description provided for @yearInReviewMenu.
  ///
  /// In en, this message translates to:
  /// **'Year in review'**
  String get yearInReviewMenu;

  /// Shown on the home screen widget when nothing is pinned at all (#154), distinct from homeEmptyTitle which covers pinned-but-no-snapshot-yet.
  ///
  /// In en, this message translates to:
  /// **'Pin a counter'**
  String get homeWidgetUnpinnedTitle;

  /// No description provided for @homeWidgetUnpinnedDetail.
  ///
  /// In en, this message translates to:
  /// **'Open FieldTally and pin one from the dashboard.'**
  String get homeWidgetUnpinnedDetail;

  /// Compact form of projectionRemaining for the home screen widget, which has room for a few words rather than a sentence.
  ///
  /// In en, this message translates to:
  /// **'{remaining} to {tier}'**
  String homeWidgetRemaining(String remaining, String tier);

  /// Banner shown once Play has finished downloading a newer version in the background (#195). Play does the asking and the downloading; installing is the one step Android will not take unasked, which is all this line is for.
  ///
  /// In en, this message translates to:
  /// **'A new version has been downloaded.'**
  String get updateDownloaded;

  /// Action on the update banner: installs what was downloaded, which restarts the app.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get updateRestart;

  /// Action on the update banner: dismisses it. Play installs the update on its own schedule anyway, so nothing is lost by saying no.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;
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
