import '../../domain/models/stat_snapshot.dart';
import '../../domain/models/time_span.dart';
import 'parse_exception.dart';

/// Parser for the Ingress Prime stats export (§3.1.1).
///
/// The export is tab separated text with an explicit header row. The central
/// design choice here — and the reason the format is workable at all despite
/// being undocumented — is that **every column is found by name, never by
/// position**. Positional mapping would break the moment Niantic adds, removes
/// or reorders a column, which happens every anomaly season.
///
/// The deliberate consequence: anything that is not a known metadata column is
/// a counter, including a name never seen before. That is §3.1.2 — the
/// registry is driven by the data, not by a hard coded list.
class IngressTsvParser {
  const IngressTsvParser();

  /// Accepted names for each metadata column.
  ///
  /// Ingress suffixes some headers with the expected format
  /// (`Date (yyyy-mm-dd)`). Comparison happens on a normalised form —
  /// lowercased, parenthesised part removed — so a change to that suffix does
  /// not break parsing, without resorting to fuzzy matching.
  static const _timeSpanNames = {'time span'};
  static const _agentNameNames = {'agent name'};
  static const _factionNames = {'agent faction'};
  static const _dateNames = {'date'};
  static const _timeNames = {'time'};
  static const _levelNames = {'level'};

  static const _metadataNames = {
    ..._timeSpanNames,
    ..._agentNameNames,
    ..._factionNames,
    ..._dateNames,
    ..._timeNames,
  };

  /// Parses a full export and returns one snapshot per data row.
  ///
  /// An Ingress export only ever holds one, but nothing enforces that and
  /// handling the general case is cheaper than assuming it.
  List<StatSnapshot> parse(String raw) {
    final lines = _splitLines(raw);
    if (lines.isEmpty) {
      throw const ExportParseException(ParseErrorKind.emptyText);
    }
    if (lines.length < 2) {
      throw const ExportParseException(ParseErrorKind.headerOnly);
    }

    final headers = _parseHeaders(lines.first);
    return [
      for (var i = 1; i < lines.length; i++) _parseRow(headers, lines[i], i),
    ];
  }

  /// Shortcut for the common case: one export, one snapshot.
  StatSnapshot parseSingle(String raw) {
    final snapshots = parse(raw);
    if (snapshots.length > 1) {
      throw ExportParseException(
        ParseErrorKind.tooManyRows,
        actual: snapshots.length,
      );
    }
    return snapshots.first;
  }

  List<String> _splitLines(String raw) {
    // Strip a leading BOM: pasting from some apps leaves one behind, and it
    // would stick to the first header.
    final cleaned = raw.replaceFirst('﻿', '');
    return cleaned
        .split(RegExp(r'\r\n|\r|\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }

  /// Splits one line into cells.
  ///
  /// A line that ends with the separator yields a last cell that is empty:
  /// that is punctuation left by the exporter, not a column. Real exports from
  /// the game do end with a tab — both on the header row and on the data row —
  /// and rejecting them for an "unnamed column" made the app unusable with the
  /// actual format while every fixture, which happened to have no trailing
  /// tab, passed.
  ///
  /// Only one trailing cell is dropped, and only when the line really ends
  /// with the separator. An empty cell anywhere else stays: there, the mapping
  /// between names and values is genuinely ambiguous and guessing would be
  /// worse than refusing.
  List<String> _splitCells(String line) {
    final cells = line.split('\t').map((cell) => cell.trim()).toList();
    if (cells.length > 1 && line.endsWith('\t')) cells.removeLast();
    return cells;
  }

  List<String> _parseHeaders(String line) {
    final headers = _splitCells(line);

    if (headers.length < 2) {
      throw const ExportParseException(ParseErrorKind.notTabSeparated);
    }

    final blank = headers.indexWhere((h) => h.isEmpty);
    if (blank >= 0) {
      throw ExportParseException(
        ParseErrorKind.blankHeader,
        position: blank + 1,
      );
    }

    // Duplicate headers would make name based mapping undecidable: we cannot
    // pick a winner on the user's behalf.
    final seen = <String>{};
    for (final header in headers) {
      if (!seen.add(header)) {
        throw ExportParseException(
          ParseErrorKind.duplicateHeader,
          column: header,
        );
      }
    }

    return headers;
  }

  StatSnapshot _parseRow(List<String> headers, String line, int lineNumber) {
    final values = _splitCells(line);

    if (values.length != headers.length) {
      throw ExportParseException(
        ParseErrorKind.columnCountMismatch,
        position: lineNumber,
        actual: values.length,
        expected: headers.length,
      );
    }

    final byName = <String, String>{
      for (var i = 0; i < headers.length; i++) _normalize(headers[i]): values[i],
    };

    final timeSpan = _require(byName, _timeSpanNames, 'Time Span');
    final agentName = _require(byName, _agentNameNames, 'Agent Name');
    final faction = _require(byName, _factionNames, 'Agent Faction');
    final date = _require(byName, _dateNames, 'Date');
    final time = _require(byName, _timeNames, 'Time');
    final level = _require(byName, _levelNames, 'Level');

    // Everything that is not metadata is a counter — including `Level`, which
    // is both snapshot metadata (§3.1.1) and a value tracked over time
    // (Appendix A).
    final counters = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final header = headers[i];
      if (_metadataNames.contains(_normalize(header))) continue;
      counters[header] = _parseInt(values[i], header);
    }

    return StatSnapshot(
      timeSpan: TimeSpan.parse(timeSpan),
      agentName: agentName,
      faction: faction,
      recordedAt: _parseDateTime(date, time),
      level: _parseInt(level, 'Level'),
      counters: counters,
    );
  }

  /// Lowercase, collapsed whitespace, parenthesised format hint removed:
  /// `Date (yyyy-mm-dd)` becomes `date`.
  String _normalize(String header) => header
      .replaceAll(RegExp(r'\([^)]*\)'), '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');

  String _require(Map<String, String> byName, Set<String> names, String label) {
    for (final name in names) {
      final value = byName[name];
      if (value != null) return value;
    }
    throw ExportParseException(ParseErrorKind.missingColumn, column: label);
  }

  /// Thousands separators vary with the phone's language and region (§6):
  /// thin or non breaking space, comma, period, apostrophe.
  ///
  /// Ingress counters are all integers, so none of these characters can be a
  /// decimal mark — removing them is unambiguous. Whatever remains must be
  /// digits only; anything else is rejected rather than guessed.
  static final _separators = RegExp(r"[\s,.  ']");
  static final _integer = RegExp(r'^-?\d+$');

  int _parseInt(String raw, String column) {
    final stripped = raw.replaceAll(_separators, '');

    if (stripped.isEmpty) {
      throw ExportParseException(
        ParseErrorKind.emptyValue,
        column: column,
        rawValue: raw,
      );
    }
    if (!_integer.hasMatch(stripped)) {
      throw ExportParseException(
        ParseErrorKind.notAnInteger,
        column: column,
        rawValue: raw,
      );
    }

    final parsed = int.tryParse(stripped);
    if (parsed == null) {
      // Overflow: a native Dart int is 64 bits, so this means an absurd value
      // rather than a real counter.
      throw ExportParseException(
        ParseErrorKind.outOfRange,
        column: column,
        rawValue: raw,
      );
    }
    return parsed;
  }

  static final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static final _timePattern = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');

  DateTime _parseDateTime(String date, String time) {
    final dateMatch = _datePattern.firstMatch(date);
    if (dateMatch == null) {
      throw ExportParseException(
        ParseErrorKind.invalidDate,
        column: 'Date',
        rawValue: date,
      );
    }

    // Time is optional on the migration CSV path (Appendix B), where it
    // defaults to midnight. The same tolerance applies here.
    final timeMatch = time.isEmpty ? null : _timePattern.firstMatch(time);
    if (time.isNotEmpty && timeMatch == null) {
      throw ExportParseException(
        ParseErrorKind.invalidTime,
        column: 'Time',
        rawValue: time,
      );
    }

    final month = int.parse(dateMatch.group(2)!);
    final day = int.parse(dateMatch.group(3)!);

    final parsed = DateTime(
      int.parse(dateMatch.group(1)!),
      month,
      day,
      timeMatch == null ? 0 : int.parse(timeMatch.group(1)!),
      timeMatch == null ? 0 : int.parse(timeMatch.group(2)!),
      timeMatch?.group(3) == null ? 0 : int.parse(timeMatch!.group(3)!),
    );

    // DateTime silently normalises impossible dates (January 32nd becomes
    // February 1st). Reject rather than store a date the user never entered.
    if (parsed.month != month || parsed.day != day) {
      throw ExportParseException(
        ParseErrorKind.nonExistentDate,
        column: 'Date',
        rawValue: date,
      );
    }

    return parsed;
  }
}
