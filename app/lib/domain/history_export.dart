import 'models/counter_registry.dart';
import 'repositories/snapshot_repository.dart';

/// Builds a CSV of the whole history (§3.8).
///
/// For portability: a file the agent owns, readable in any spreadsheet, and
/// the thing that makes a future move to a backend (v2) a migration rather
/// than a loss.
///
/// It is **not** the Agent Stats format of Appendix B — that one is fixed,
/// positional, and cannot express counters it never knew about. This export
/// is self-describing instead: one column per counter actually present, named
/// by its export header.
class HistoryCsvExporter {
  const HistoryCsvExporter({this.registry});

  /// Only used to order the columns the way the app displays them. Without it
  /// the counters come out alphabetically.
  final CounterRegistry? registry;

  static const metadataColumns = [
    'date',
    'time',
    'agent',
    'faction',
    'time_span',
    'level',
  ];

  String build(List<StoredSnapshot> stored) {
    if (stored.isEmpty) return '';

    // Oldest first: a history reads forwards, and a spreadsheet chart drawn
    // from it comes out the right way round.
    final sorted = [...stored]
      ..sort((a, b) => a.snapshot.recordedAt.compareTo(b.snapshot.recordedAt));

    final headers = <String>{
      for (final item in sorted) ...item.snapshot.counters.keys,
    }.toList();

    final ordered = registry?.sortHeaders(headers) ?? (headers..sort());

    final rows = <String>[
      [...metadataColumns, ...ordered].map(_escape).join(','),
      for (final item in sorted) _row(item, ordered),
    ];

    return '${rows.join('\n')}\n';
  }

  String _row(StoredSnapshot stored, List<String> headers) {
    final snapshot = stored.snapshot;
    final date = snapshot.recordedAt;

    return [
      _date(date),
      _time(date),
      snapshot.agentName,
      snapshot.faction,
      snapshot.timeSpan.name,
      // Left blank rather than zeroed when unknown, as it is for anything
      // imported from Agent Stats (Appendix B).
      snapshot.level?.toString() ?? '',
      // A counter absent from a snapshot stays blank: a gap is not a zero
      // (§3.1.2), and writing 0 here would invent data on the way out.
      for (final header in headers) snapshot.counters[header]?.toString() ?? '',
    ].map(_escape).join(',');
  }

  String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:'
      '${d.second.toString().padLeft(2, '0')}';

  /// Counter names carry commas and parentheses — `Mission Day(s) Attended`,
  /// for one — so every field is quoted when it needs to be.
  String _escape(String value) {
    if (!value.contains(',') &&
        !value.contains('"') &&
        !value.contains('\n')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  /// Suggested file name, dated so successive exports do not collide.
  String fileNameFor(DateTime now) => 'fieldtally-${_date(now)}.csv';
}
