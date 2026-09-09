import 'time_span.dart';

/// A dated snapshot, produced by an import (paste, share or CSV).
///
/// Counter values are keyed by **the export column name**
/// (`Unique Portals Visited`), not by the registry's technical key
/// (`explorer`). This is deliberate, and follows from §3.1.2: an unknown
/// counter must be tracked from its very first appearance, before any
/// enrichment entry exists for it. Keying by technical key would break the
/// history of a counter tracked under a provisional identifier the day someone
/// gives it its real key in the registry.
///
/// The export header, by contrast, is stable over time for a given counter,
/// and it is also what the registry references through `export_header`.
class StatSnapshot {
  const StatSnapshot({
    required this.timeSpan,
    required this.agentName,
    required this.faction,
    required this.recordedAt,
    required this.level,
    required this.counters,
  });

  /// Period declared by the export. See [TimeSpan] and §3.1.3.
  final TimeSpan timeSpan;

  final String agentName;
  final String faction;

  /// Snapshot date and time, rebuilt from the `Date` and `Time` columns.
  final DateTime recordedAt;

  final int level;

  /// Raw values, keyed by export header.
  final Map<String, int> counters;

  /// The three fields Ingress **never** scopes to a period: they are identical
  /// between an `ALL TIME` and a `WEEK` export of the same agent at the same
  /// moment (finding of §3.1.3).
  ///
  /// Direct consequence: the behavioural guard cannot rely on them. A `WEEK`
  /// import made by mistake would leave AP untouched and go unnoticed if it
  /// were the only thing being watched.
  static const nonPeriodizedHeaders = {'Level', 'Lifetime AP', 'Current AP'};

  @override
  String toString() =>
      'StatSnapshot($agentName, $timeSpan, $recordedAt, ${counters.length} counters)';
}
