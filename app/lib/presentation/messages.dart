import '../data/parsing/parse_exception.dart';
import '../domain/guards/import_guards.dart';
import '../domain/models/time_span.dart';
import '../l10n/app_localizations.dart';

/// Turns domain and parsing outcomes into sentences for the user.
///
/// This lives in the presentation layer on purpose. The parser and the guards
/// return structured facts — a [ParseErrorKind], an [ImportCheck] — and know
/// nothing about wording or language; putting the phrasing here is what lets
/// every user visible string sit in the `.arb` files (§3.10).
extension TimeSpanMessages on TimeSpan {
  String label(AppLocalizations l10n) => switch (this) {
        TimeSpan.allTime => l10n.timeSpanAllTime,
        TimeSpan.week => l10n.timeSpanWeek,
        TimeSpan.month => l10n.timeSpanMonth,
        TimeSpan.now => l10n.timeSpanNow,
        TimeSpan.unknown => l10n.timeSpanUnknown,
      };
}

extension ImportCheckMessages on ImportCheck {
  /// Headline shown on the anomaly card.
  String title(AppLocalizations l10n) => isPartialPeriod
      ? l10n.anomalyPartialPeriodTitle
      : l10n.anomalyRegressionTitle;

  /// Explanation of why the import is blocked, or null when it is not.
  ///
  /// A declared partial period takes precedence: it already explains every
  /// regression, so showing the cause beats listing its consequences.
  String? message(AppLocalizations l10n) {
    if (isPartialPeriod) {
      return l10n.anomalyPartialPeriod(declaredTimeSpan.label(l10n));
    }
    if (hasRegressions) return l10n.anomalyRegression(regressions.length);
    return null;
  }
}

extension ParseExceptionMessages on ExportParseException {
  String message(AppLocalizations l10n) => switch (kind) {
        ParseErrorKind.emptyText => l10n.parseErrorEmptyText,
        ParseErrorKind.headerOnly => l10n.parseErrorHeaderOnly,
        ParseErrorKind.notTabSeparated => l10n.parseErrorNotTabSeparated,
        ParseErrorKind.blankHeader =>
          l10n.parseErrorBlankHeader(position ?? 0),
        ParseErrorKind.duplicateHeader =>
          l10n.parseErrorDuplicateHeader(column ?? ''),
        ParseErrorKind.columnCountMismatch => l10n.parseErrorColumnCountMismatch(
            position ?? 0,
            actual ?? 0,
            expected ?? 0,
          ),
        ParseErrorKind.missingColumn =>
          l10n.parseErrorMissingColumn(column ?? ''),
        ParseErrorKind.emptyValue => l10n.parseErrorEmptyValue(column ?? ''),
        ParseErrorKind.notAnInteger => l10n.parseErrorNotAnInteger(column ?? ''),
        ParseErrorKind.outOfRange => l10n.parseErrorOutOfRange(column ?? ''),
        ParseErrorKind.invalidDate => l10n.parseErrorInvalidDate(rawValue ?? ''),
        ParseErrorKind.invalidTime => l10n.parseErrorInvalidTime(rawValue ?? ''),
        ParseErrorKind.nonExistentDate =>
          l10n.parseErrorNonExistentDate(rawValue ?? ''),
        ParseErrorKind.tooManyRows => l10n.parseErrorTooManyRows(actual ?? 0),
      };

  /// The offending raw value, when there is one worth showing alongside the
  /// message so the user can spot what to fix.
  String? rawValueHint(AppLocalizations l10n) {
    final value = rawValue;
    if (value == null || value.isEmpty) return null;
    return switch (kind) {
      ParseErrorKind.emptyValue ||
      ParseErrorKind.notAnInteger ||
      ParseErrorKind.outOfRange =>
        l10n.parseErrorRawValue(value),
      _ => null,
    };
  }
}
