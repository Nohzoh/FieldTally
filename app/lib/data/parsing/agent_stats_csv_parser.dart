import '../../domain/models/counter_registry.dart';
import '../../domain/models/stat_snapshot.dart';
import '../../domain/models/time_span.dart';
import 'parse_exception.dart';

/// What reading a pasted export produced (#133).
///
/// The counts matter as much as the snapshots. A paste taken off a web page
/// carries a banner, a pagination line and a header, and tolerating them is
/// only safe if what was skipped is said out loud — otherwise a damaged row
/// disappears as quietly as the banner does.
typedef AgentStatsParse = ({
  /// Chronological, oldest first.
  List<StatSnapshot> snapshots,

  /// Lines that carried no data row and were passed over.
  int ignoredLines,

  /// True when a header was found but did not account for the values a row
  /// carries, so the documented column order was used instead.
  bool headerIgnored,
});

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

  /// Reads a pasted export, oldest row first.
  ///
  /// Agent Stats offers no download, so the data arrives as a selection off a
  /// web page and brings its surroundings with it — a banner, a count of
  /// points, a pagination strip, a header whose cells do not all have values
  /// (#133). A line is a data row when it starts with a date, and that is the
  /// only thing this keys on: it does not care what the page looks like, which
  /// is the part most likely to change.
  ///
  /// Every line passed over is counted and reported, because skipping what is
  /// not understood is the same family of fault as misreading it.
  AgentStatsParse parse(String raw, {String agentName = ''}) {
    final lines = raw
        .replaceFirst('\u{FEFF}', '')
        .split(RegExp(r'\r\n|\r|\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw const ExportParseException(ParseErrorKind.emptyText);
    }

    final rows = <({String line, int number})>[];
    final others = <({String line, int number})>[];
    for (var i = 0; i < lines.length; i++) {
      final entry = (line: lines[i], number: i + 1);
      (_looksLikeDataRow(lines[i]) ? rows : others).add(entry);
    }

    final headerLine = others
        .where((o) => _looksLikeHeader(o.line))
        .firstOrNull;

    if (rows.isEmpty) {
      throw ExportParseException(
        headerLine == null
            ? ParseErrorKind.emptyText
            : ParseErrorKind.headerOnly,
      );
    }

    // A header that accounts for the values wins over the documented order: it
    // is the only thing that survives the format gaining or losing a column.
    // One that does not account for them is damaged — a rotated `Date` copied
    // as `ate`, a row-number column whose cells did not come (#132) — and the
    // documented order is the better of the two sources, not a guess. Saying
    // so is what keeps that from being silent.
    List<String>? header;
    var headerIgnored = false;
    if (headerLine != null) {
      final candidate = _fields(headerLine.line)
          .map((f) => f.value.toLowerCase())
          .where((f) => !_isDateColumn(f) && !_isTimeColumn(f))
          .toList();
      if (_headerFits(candidate, rows.first.line)) {
        header = candidate;
      } else {
        headerIgnored = true;
      }
    }

    final snapshots = [
      for (final row in rows)
        _parseRow(row.line, row.number, header ?? columns, agentName),
    ];

    snapshots.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return (
      snapshots: snapshots,
      ignoredLines: others.length - (header == null ? 0 : 1),
      headerIgnored: headerIgnored,
    );
  }

  /// Whether a line is *meant* to be a data row, valid or not.
  ///
  /// The distinction that keeps tolerance from swallowing a defect: a line
  /// beginning with a digit was trying to be a snapshot, so a date it gets
  /// wrong is still reported at its line, as loudly as before. A banner, a
  /// count of points and a pagination strip begin with a letter or a chevron
  /// and are passed over.
  ///
  /// Without this, `15/01/2026 …` — a real date in the wrong format — would
  /// be discarded as page furniture and the paste would read as empty.
  bool _looksLikeDataRow(String line) {
    final fields = _fields(line);
    return fields.isNotEmpty && _startsWithDigit.hasMatch(fields.first.value);
  }

  static final _startsWithDigit = RegExp(r'^\d');

  /// Whether a header accounts for exactly the values a data row carries.
  ///
  /// This is the comparison whose absence let a whole history import one
  /// column to the left, twice, from two different copies of the same page
  /// (#132): once when a rotated `Date` header came back as `ate` and was
  /// taken for a counter, once when the row-number column `#` came across
  /// while its cells did not. Both times the header held one entry more than
  /// the row had values, and nothing compared the two.
  ///
  /// Counted without the comment on either side, since Appendix B makes it
  /// optional and its absence is not a misalignment.
  bool _headerFits(List<String> header, String firstRow) {
    final named = header.where((h) => h != 'comment').length;
    final fields = _fields(firstRow);
    final values = fields
        .sublist(_valueStart(fields))
        .where((f) => !f.quoted)
        .length;
    return named == values;
  }

  /// Where a row's counter values begin: past the date, and past the time when
  /// one is there. The time is optional (Appendix B) and tells itself apart by
  /// its colons.
  int _valueStart(List<({String value, bool quoted})> fields) =>
      fields.length > 1 && _timePattern.hasMatch(fields[1].value) ? 2 : 1;

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
    final index = _valueStart(fields);
    final time = index == 2 ? fields[1].value : '';

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
