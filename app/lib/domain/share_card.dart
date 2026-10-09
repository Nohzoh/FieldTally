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

/// Period the shareable card covers (§3.8).
///
/// The chart ranges, plus one only the card needs: what the most recent import
/// added, which is what an agent posts right after a session.
enum SharePeriod {
  lastSnapshot,
  week,
  month,
  all;

  /// The chart range measuring the same thing, or null for [lastSnapshot],
  /// which counts imports rather than days.
  ChartRange? get chartRange => switch (this) {
    SharePeriod.lastSnapshot => null,
    SharePeriod.week => ChartRange.week,
    SharePeriod.month => ChartRange.month,
    SharePeriod.all => ChartRange.all,
  };
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
    required this.period,
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

  final SharePeriod period;

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
  /// [period] is measured back from the newest snapshot for the same reason
  /// every other period in this app is (§3.5): an agent who stopped importing
  /// has not stopped playing, the app stopped hearing about it.
  ///
  /// [SharePeriod.lastSnapshot] spans each counter's two most recent values,
  /// so a counter the previous import did not carry is measured from the last
  /// import that did, and the footer dates the card from that earlier value.
  ShareCardData? build({
    required List<StatSnapshot> snapshots,
    required List<String> pinned,
    SharePeriod period = SharePeriod.month,
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

      final series = _series(builder, sorted, header, period);
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
      period: period,
      lines: lines,
    );
  }

  CounterSeries _series(
    CounterSeriesBuilder builder,
    List<StatSnapshot> sorted,
    String header,
    SharePeriod period,
  ) {
    final range = period.chartRange;
    if (range != null) {
      return builder.series(
        snapshots: sorted,
        exportHeader: header,
        range: range,
      );
    }

    final all = builder.series(snapshots: sorted, exportHeader: header);
    final points = all.points;
    return CounterSeries(
      points: points.length > 2 ? points.sublist(points.length - 2) : points,
      range: all.range,
    );
  }
}
