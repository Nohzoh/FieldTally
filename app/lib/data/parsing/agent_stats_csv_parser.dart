import '../../domain/models/counter_registry.dart';
import '../../domain/models/stat_snapshot.dart';
import '../../domain/models/time_span.dart';
import 'parse_exception.dart';

/// Parser for the Agent Stats migration export (Appendix B).
///
/// Exists so an agent with years of history elsewhere can bring it along
/// rather than starting from zero — one of the target users named in §2.
///
/// Two things make this file different from the Ingress export:
///
/// - It carries **no `Time Span` column**, so the declarative guard of §3.1.3
///   is blind here and monotonicity is the only protection left. That is the
///   reason the behavioural guard must never be skipped on this path.
/// - It carries **no level column** either, which is why [StatSnapshot.level]
///   is nullable.
class AgentStatsCsvParser {
  const AgentStatsCsvParser({this.registry});

  /// Used to translate Agent Stats keys into the export headers the rest of
  /// the app identifies counters by. Without it, keys are kept as-is and the
  /// counters simply show under their raw names (§3.1.2).
  final CounterRegistry? registry;

  /// Column order as documented in Appendix B, used when the file carries no
  /// header row.
  ///
  /// Positional parsing is exactly what §3.1.1 argues against — but this is a
  /// frozen third-party format with no header to go by, so there is nothing
  /// else to key on. A header row, when present, always wins.
  static const columns = <String>[
    'ap',
    'lifetime_ap',
    'explorer',
    'drone_explorer',
    'drone_distance',
    'seer',
    'collector',
    'recon',
    'scout',
    'scout_controller',
    'crafter',
    'builder',
    'connector',
    'mind-controller',
    'illuminator',
    'binder',
    'country-master',
    'recharger',
    'liberator',
    'pioneer',
    'engineer',
    'hacker',
    'maverick',
    'translator',
    'overclocker',
    'sojourner',
    'epoch',
    'purifier',
    'neutralizer',
    'disruptor',
    'salvator',
    'bb_combatant',
    'red-disruptor',
    'red-purifier',
    'red-neutralizer',
    'reclaimer',
    'guardian',
    'smuggler',
    'link-master',
    'controller',
    'field-master',
    'drone_recalls',
    'drone_sender',
    'trekker',
    'specops',
    'research_bounties',
    'research_days',
    'missionday',
    'nl-1331-meetups',
    'recruiter',
    'recursions',
    'prime_challenge',
    'stealth_ops',
    'urban_ops',
    'opr_live',
    'ocf',
    'intel_ops',
    'ifs',
    'second_sunday',
    'operation_chronos',
    'cryptic_memories_op',
  ];

  static final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static final _timePattern = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');

  /// Parses a whole file, oldest row first in the output.
  List<StatSnapshot> parse(String raw, {String agentName = ''}) {
    final lines = raw
        .replaceFirst('\u{FEFF}', '')
        .split(RegExp(r'\r\n|\r|\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw const ExportParseException(ParseErrorKind.emptyText);
    }

    // A header row wins over the documented order whenever it is there: it is
    // the only thing that survives the format gaining or losing a column.
    List<String>? header;
    var start = 0;
    if (_looksLikeHeader(lines.first)) {
      header = _fields(lines.first)
          .map((f) => f.value.toLowerCase())
          .where((f) => !_isDateColumn(f) && !_isTimeColumn(f))
          .toList();
      start = 1;
    }

    if (lines.length <= start) {
      throw const ExportParseException(ParseErrorKind.headerOnly);
    }

    final snapshots = [
      for (var i = start; i < lines.length; i++)
        _parseRow(lines[i], i + 1, header ?? columns, agentName),
    ];

    snapshots.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return snapshots;
  }

  bool _looksLikeHeader(String line) {
    final lower = line.toLowerCase();
    return lower.contains('lifetime_ap') || lower.contains('date');
  }

  bool _isDateColumn(String field) =>
      field.startsWith('date') || field.startsWith('"date');

  bool _isTimeColumn(String field) =>
      field.startsWith('heure') || field.startsWith('time');

  /// Splits on runs of whitespace, keeping a quoted field — the trailing
  /// `comment` — in one piece.
  ///
  /// Whether a field was quoted is carried along: quotes are how Appendix B
  /// marks the free-text comment, so a quoted field is never a counter even if
  /// it lands where one was expected.
  List<({String value, bool quoted})> _fields(String line) {
    final fields = <({String value, bool quoted})>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    var wasQuoted = false;

    void flush() {
      if (buffer.isEmpty && !wasQuoted) return;
      fields.add((value: buffer.toString(), quoted: wasQuoted));
      buffer.clear();
      wasQuoted = false;
    }

    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      if (char == '"') {
        inQuotes = !inQuotes;
        wasQuoted = true;
        continue;
      }
      if (!inQuotes && (char == ' ' || char == '\t')) {
        flush();
        continue;
      }
      buffer.write(char);
    }
    flush();
    return fields;
  }

  StatSnapshot _parseRow(
    String line,
    int lineNumber,
    List<String> columnNames,
    String agentName,
  ) {
    final fields = _fields(line);
    if (fields.isEmpty) {
      throw ExportParseException(
        ParseErrorKind.columnCountMismatch,
        position: lineNumber,
        actual: 0,
        expected: columnNames.length + 1,
      );
    }

    final date = fields.first.value;
    if (!_datePattern.hasMatch(date)) {
      throw ExportParseException(
        ParseErrorKind.invalidDate,
        column: 'Date',
        rawValue: date,
        position: lineNumber,
      );
    }

    // The time is optional (Appendix B). Whether field 1 is a time or the
    // first value is decided by its shape, which is unambiguous: a time has
    // colons, a counter does not.
    var index = 1;
    var time = '';
    if (fields.length > 1 && _timePattern.hasMatch(fields[1].value)) {
      time = fields[1].value;
      index = 2;
    }

    final values = fields.sublist(index);
    final counters = <String, int>{};

    for (var i = 0; i < values.length && i < columnNames.length; i++) {
      final key = columnNames[i];
      // The trailing free-text comment is not a counter; Agent Stats keeps it
      // for the agent's own notes and the app has nowhere to put it. Quotes
      // settle it whatever the column order says.
      if (key == 'comment' || values[i].quoted) continue;

      final parsed = _parseInt(values[i].value, key, lineNumber);
      if (parsed == null) continue;

      counters[_headerFor(key)] = parsed;
    }

    if (counters.isEmpty) {
      throw ExportParseException(
        ParseErrorKind.columnCountMismatch,
        position: lineNumber,
        actual: values.length,
        expected: columnNames.length,
      );
    }

    return StatSnapshot(
      // No Time Span column exists here, and pretending otherwise would let a
      // partial-period file through the declarative guard (§3.1.3).
      timeSpan: TimeSpan.unknown,
      agentName: agentName,
      faction: '',
      recordedAt: _dateTime(date, time, lineNumber),
      counters: counters,
    );
  }

  /// Translates an Agent Stats key into the export header the rest of the app
  /// identifies a counter by.
  ///
  /// Hyphens become underscores first: Agent Stats writes `mind-controller`
  /// where the registry writes `mind_controller`. A key the registry does not
  /// know keeps its own name and shows under it, as §3.1.2 prescribes for any
  /// unknown counter — several columns here belong to counters Niantic has
  /// since retired.
  String _headerFor(String key) {
    final normalized = key.toLowerCase().replaceAll('-', '_');
    return registry?.forKey(normalized)?.exportHeader ?? normalized;
  }

  int? _parseInt(String raw, String column, int lineNumber) {
    final trimmed = raw.trim();
    // Agent Stats leaves a blank or a dash for a counter that did not exist
    // yet at that date. That is an absence, not a zero (§3.1.2).
    if (trimmed.isEmpty || trimmed == '-' || trimmed == 'null') return null;

    final stripped = trimmed.replaceAll(RegExp(r"[\s,.  ']"), '');
    final parsed = int.tryParse(stripped);
    if (parsed == null) {
      throw ExportParseException(
        ParseErrorKind.notAnInteger,
        column: column,
        rawValue: raw,
        position: lineNumber,
      );
    }
    return parsed;
  }

  DateTime _dateTime(String date, String time, int lineNumber) {
    final dateMatch = _datePattern.firstMatch(date)!;
    final month = int.parse(dateMatch.group(2)!);
    final day = int.parse(dateMatch.group(3)!);
    final timeMatch = time.isEmpty ? null : _timePattern.firstMatch(time);

    final parsed = DateTime(
      int.parse(dateMatch.group(1)!),
      month,
      day,
      timeMatch == null ? 0 : int.parse(timeMatch.group(1)!),
      timeMatch == null ? 0 : int.parse(timeMatch.group(2)!),
      timeMatch?.group(3) == null ? 0 : int.parse(timeMatch!.group(3)!),
    );

    if (parsed.month != month || parsed.day != day) {
      throw ExportParseException(
        ParseErrorKind.nonExistentDate,
        column: 'Date',
        rawValue: date,
        position: lineNumber,
      );
    }
    return parsed;
  }
}
