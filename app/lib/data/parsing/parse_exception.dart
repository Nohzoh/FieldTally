/// Why an Ingress export could not be read.
///
/// The exception carries a *kind* plus structured details rather than a ready
/// made sentence. Two reasons: user facing wording belongs to the
/// localisation layer, not to the parser, and a caller that wants to react to
/// a specific failure can switch on the kind instead of matching on text.
enum ParseErrorKind {
  emptyText,
  headerOnly,
  notTabSeparated,
  blankHeader,
  duplicateHeader,
  columnCountMismatch,
  missingColumn,
  emptyValue,
  notAnInteger,
  outOfRange,
  invalidDate,
  invalidTime,
  nonExistentDate,
  tooManyRows,
}

/// Raised when an Ingress export cannot be parsed.
///
/// The format is undocumented and may change without notice (§3.1, §6), so the
/// rule is to fail **cleanly and loudly**: never guess a value, never silently
/// store wrong data. Every instance carries enough detail to build a helpful
/// message and, later on, to offer a manual correction.
class ExportParseException implements Exception {
  const ExportParseException(
    this.kind, {
    this.column,
    this.rawValue,
    this.position,
    this.expected,
    this.actual,
  });

  final ParseErrorKind kind;

  /// Header of the offending column, when the failure is localised to one.
  final String? column;

  /// Rejected raw value, so the user can see what was actually read.
  final String? rawValue;

  /// 1-based row or column position, depending on [kind].
  final int? position;

  /// Expected and actual counts, for mismatches.
  final int? expected;
  final int? actual;

  @override
  String toString() {
    final details = [
      if (column != null) 'column "$column"',
      if (rawValue != null) 'value "$rawValue"',
    ];
    return details.isEmpty
        ? 'ExportParseException(${kind.name})'
        : 'ExportParseException(${kind.name}: ${details.join(', ')})';
  }
}
