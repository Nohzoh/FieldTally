import 'counter_series.dart';
import 'models/stat_snapshot.dart';

/// One line of the shareable card (§3.8).
class ShareCardLine {
  const ShareCardLine({
    required this.exportHeader,
    required this.value,
    this.gain,
  });

  final String exportHeader;

  /// Latest known value.
  final int value;

  /// Progress across the period, or null when the counter has no earlier
  /// value to measure from inside it.
  final int? gain;
}

/// Everything the shareable card shows (§3.8).
///
/// Assembled here rather than in the widget so what ends up in a public PNG
/// is decided by testable logic: a card posted to Reddit cannot be corrected
/// once it is out.
class ShareCardData {
  const ShareCardData({
    required this.agentName,
    required this.faction,
    required this.level,
    required this.recordedAt,
    required this.since,
    required this.range,
    required this.lines,
  });

  final String agentName;
  final String faction;

  /// Null when no import carried it (Appendix B has no level column).
  final int? level;

  /// When the newest snapshot was taken. The card is dated by the data, not by
  /// the moment the image was made: an agent sharing on Sunday a Friday
  /// snapshot should not claim Sunday's numbers.
  final DateTime recordedAt;

  /// Start of the period the gains cover, or null when there is nothing to
  /// compare against.
  final DateTime? since;

  final ChartRange range;

  final List<ShareCardLine> lines;

  /// True once at least one line can show progress.
  bool get hasGains => lines.any((line) => line.gain != null);
}

/// Builds the shareable card from the history (§3.8).
class ShareCardBuilder {
  const ShareCardBuilder({this.maxLines = 6});

  /// How many counters fit before the card stops being readable at the size
  /// it is posted. The dashboard selection drives which ones (§3.3).
  final int maxLines;

  /// Null when there is nothing to show: no snapshot, or none carrying any of
  /// the chosen counters.
  ///
  /// [range] is measured back from the newest snapshot for the same reason
  /// every other period in this app is (§3.5): an agent who stopped importing
  /// has not stopped playing, the app stopped hearing about it.
  ShareCardData? build({
    required List<StatSnapshot> snapshots,
    required List<String> pinned,
    ChartRange range = ChartRange.month,
  }) {
    if (snapshots.isEmpty) return null;

    final sorted = [...snapshots]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final latest = sorted.last;

    const builder = CounterSeriesBuilder();
    final lines = <ShareCardLine>[];
    DateTime? since;

    for (final header in pinned) {
      if (lines.length == maxLines) break;

      final series = builder.series(
        snapshots: sorted,
        exportHeader: header,
        range: range,
      );
      // A counter absent from every import is skipped rather than shown at
      // zero: the agent usually pinned it on a previous phone (§3.1.2).
      if (series.isEmpty) continue;

      lines.add(
        ShareCardLine(
          exportHeader: header,
          value: series.points.last.value,
          gain: series.gain,
        ),
      );

      // The card states one period for every line, so it is the earliest one
      // actually covered — claiming a month while a counter only has a week of
      // data would overstate the numbers next to it.
      final first = series.points.first.at;
      if (series.isPlottable && (since == null || first.isBefore(since))) {
        since = first;
      }
    }

    if (lines.isEmpty) return null;

    return ShareCardData(
      agentName: latest.agentName,
      faction: latest.faction,
      level: latest.level,
      recordedAt: latest.recordedAt,
      since: since,
      range: range,
      lines: lines,
    );
  }
}
