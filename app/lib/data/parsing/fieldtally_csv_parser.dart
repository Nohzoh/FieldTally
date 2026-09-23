import '../../domain/history_export.dart';
import '../../domain/models/stat_snapshot.dart';
import '../../domain/models/time_span.dart';
import 'parse_exception.dart';

/// Reads back the CSV this app writes (#191).
///
/// The export existed from the start and nothing could read it: the only
/// import route was the Agent Stats one, which splits on whitespace and
/// expects Appendix B's frozen column order. An exported row arrived as a
/// single field and failed on line 1. The FAQ promised otherwise.
///
/// Two things separate this from the Agent Stats path, and both come from the
/// format being ours:
///
/// - It is **keyed on the header row** (§3.1.1), never on position. A column
///   is a counter because the header says so, so an export made before a
///   counter existed reads exactly as well as one made after.
/// - It carries the period, the agent, the faction and the level, none of
///   which Appendix B has anywhere to put. So the declarative guard of §3.1.3
///   applies here, where on the migration path it is blind.
///
/// The metadata column names come from [HistoryCsvExporter.metadataColumns]
/// rather than being repeated: a writer and a reader that disagree about their
/// own format is the failure this whole issue is about.
class FieldTallyCsvParser {
  const FieldTallyCsvParser();

  static const _date = 'date';
  static const _time = 'time';
  static const _agent = 'agent';
  static const _faction = 'faction';
  static const _timeSpan = 'time_span';
  static const _level = 'level';

  static final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static final _timePattern = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');

  /// Reads a whole export, oldest row first.
  List<StatSnapshot> parse(String raw) {
    final records = _records(raw);
    if (records.isEmpty) {
      throw const ExportParseException(ParseErrorKind.emptyText);
    }

    final header = _header(records.first);
    if (records.length == 1) {
      throw const ExportParseException(ParseErrorKind.headerOnly);
    }

    final snapshots = [
      // The record index is the line number as long as no field carries a
      // newline of its own; when one does, this points at the record rather
      // than at the physical line. Naming the record is the useful half.
      for (var i = 1; i < records.length; i++) _row(records[i], header, i + 1),
    ]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return snapshots;
  }

  /// Validates the header and hands back its columns as written.
  ///
  /// Counter columns keep their exact case: an export header
  /// (`Unique Portals Visited`) is a counter's stable identity (§3.1.2), and
  /// lowercasing it here would file every counter under a name nothing else
  /// in the app uses.
  ///
  /// Which is also why nothing here is compared case-insensitively. The
  /// registry carries a counter whose export header is `Level`, so a real
  /// export holds both `level` — the agent's own level, a metadata column —
  /// and `Level`, the counter. Case is the only thing that tells them apart,
  /// and a loose comparison made every export of that counter unreadable.
  List<String> _header(List<String> cells) {
    if (!cells.any((cell) => _isMetadata(cell, _date))) {
      throw const ExportParseException(
        ParseErrorKind.missingColumn,
        column: _date,
      );
    }

    final seen = <String>{};
    for (var i = 0; i < cells.length; i++) {
      final cell = cells[i].trim();
      if (cell.isEmpty) {
        throw ExportParseException(ParseErrorKind.blankHeader, position: i + 1);
      }
      // A repeated counter column would quietly keep whichever value came
      // last, which is the kind of silent wrong answer §3.1 refuses.
      if (!seen.add(cell)) {
        throw ExportParseException(
          ParseErrorKind.duplicateHeader,
          column: cell,
          position: i + 1,
        );
      }
    }

    return cells;
  }

  StatSnapshot _row(List<String> cells, List<String> header, int position) {
    if (cells.length != header.length) {
      throw ExportParseException(
        ParseErrorKind.columnCountMismatch,
        position: position,
        expected: header.length,
        actual: cells.length,
      );
    }

    var date = '';
    var time = '';
    var agent = '';
    var faction = '';
    var span = TimeSpan.unknown;
    int? level;
    final counters = <String, int>{};

    for (var i = 0; i < header.length; i++) {
      final column = header[i];
      final value = cells[i].trim();

      if (_isMetadata(column, _date)) {
        date = value;
      } else if (_isMetadata(column, _time)) {
        time = value;
      } else if (_isMetadata(column, _agent)) {
        agent = value;
      } else if (_isMetadata(column, _faction)) {
        faction = value;
      } else if (_isMetadata(column, _timeSpan)) {
        // The exporter writes the enum's own name, which round-trips through
        // TimeSpan.parse: `allTime` normalises to ALLTIME. An empty cell is
        // not `allTime` by default — an unknown period is refused, never
        // assumed (§3.1.3).
        span = value.isEmpty ? TimeSpan.unknown : TimeSpan.parse(value);
      } else if (_isMetadata(column, _level)) {
        level = value.isEmpty ? null : _int(value, _level, position);
      } else {
        // A blank counter cell is an absence, not a zero (§3.1.2) — which is
        // exactly what the exporter wrote it as.
        if (value.isEmpty) continue;
        counters[column] = _int(value, column, position);
      }
    }

    if (date.isEmpty || !_datePattern.hasMatch(date)) {
      throw ExportParseException(
        ParseErrorKind.invalidDate,
        column: _date,
        rawValue: date,
        position: position,
      );
    }

    // A dated row carrying no value at all is not a snapshot of anything.
    // Saving it would put an empty point in every chart it touches.
    if (counters.isEmpty) {
      throw ExportParseException(ParseErrorKind.emptyValue, position: position);
    }

    return StatSnapshot(
      timeSpan: span,
      agentName: agent,
      faction: faction,
      recordedAt: _dateTime(date, time, position),
      level: level,
      counters: counters,
    );
  }

  /// Exactly, never loosely — see [_header] for what a loose match cost.
  bool _isMetadata(String column, String name) => column.trim() == name;

  int _int(String raw, String column, int position) {
    // Tolerated for the same reason the migration parser tolerates it: a file
    // that went through a spreadsheet comes back with the locale's grouping
    // separators in it. Counters are integers, so nothing is lost by dropping
    // them.
    final stripped = raw.replaceAll(RegExp(r"[\s,.  ']"), '');
    final parsed = int.tryParse(stripped);
    if (parsed == null) {
      throw ExportParseException(
        ParseErrorKind.notAnInteger,
        column: column,
        rawValue: raw,
        position: position,
      );
    }
    return parsed;
  }

  DateTime _dateTime(String date, String time, int position) {
    final match = _datePattern.firstMatch(date)!;
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);

    final atTime = time.isEmpty ? null : _timePattern.firstMatch(time);
    if (time.isNotEmpty && atTime == null) {
      throw ExportParseException(
        ParseErrorKind.invalidTime,
        column: _time,
        rawValue: time,
        position: position,
      );
    }

    final parsed = DateTime(
      int.parse(match.group(1)!),
      month,
      day,
      atTime == null ? 0 : int.parse(atTime.group(1)!),
      atTime == null ? 0 : int.parse(atTime.group(2)!),
      atTime?.group(3) == null ? 0 : int.parse(atTime!.group(3)!),
    );

    // DateTime rolls 2026-02-30 forward to March rather than refusing it.
    if (parsed.month != month || parsed.day != day) {
      throw ExportParseException(
        ParseErrorKind.nonExistentDate,
        column: _date,
        rawValue: date,
        position: position,
      );
    }
    return parsed;
  }

  /// Splits the file into records of fields.
  ///
  /// A real CSV reader rather than `split(',')`, because the exporter quotes
  /// any field carrying a comma and counter names do:
  /// `Mission Day(s) Attended` is fine, but `Hacks, unique` would not be. A
  /// quoted field can also carry a newline, so records are not lines.
  List<List<String>> _records(String raw) {
    final records = <List<String>>[];
    var record = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    var wasQuoted = false;

    void endField() {
      record.add(buffer.toString());
      buffer.clear();
      wasQuoted = false;
    }

    void endRecord() {
      endField();
      // A trailing newline, or a blank line in the middle, is not a record.
      if (record.length > 1 || record.first.isNotEmpty) records.add(record);
      record = <String>[];
    }

    final text = raw.replaceFirst('\u{FEFF}', '');
    for (var i = 0; i < text.length; i++) {
      final char = text[i];

      if (quoted) {
        if (char == '"') {
          // Doubled inside a quoted field: the escape for a literal quote.
          if (i + 1 < text.length && text[i + 1] == '"') {
            buffer.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          buffer.write(char);
        }
        continue;
      }

      switch (char) {
        case '"':
          quoted = true;
          wasQuoted = true;
        case ',':
          endField();
        case '\r':
          // CRLF counts once; a lone CR ends the record just the same.
          if (i + 1 < text.length && text[i + 1] == '\n') i++;
          endRecord();
        case '\n':
          endRecord();
        default:
          buffer.write(char);
      }
    }

    if (buffer.isNotEmpty || wasQuoted || record.isNotEmpty) endRecord();
    return records;
  }
}
