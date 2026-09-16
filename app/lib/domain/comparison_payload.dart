import 'models/stat_snapshot.dart';
import 'models/time_span.dart';

/// Why a shared text could not be read as another agent's stats.
enum ComparisonPayloadError {
  /// Written by a newer FieldTally than this one.
  unsupportedVersion,

  /// The marker is there, the rest is not what it should be.
  malformed,

  /// Not an all-time total, so putting it next to one would compare a week
  /// against a lifetime (§3.1.3).
  notCumulative,
}

class ComparisonPayloadException implements Exception {
  const ComparisonPayloadException(this.error, {this.detail});

  final ComparisonPayloadError error;

  /// The offending line or value, for a message the agent can act on.
  final String? detail;

  @override
  String toString() =>
      'ComparisonPayloadException(${error.name}'
      '${detail == null ? '' : ': $detail'})';
}

/// The text one agent hands another so their numbers can be put side by side
/// (#64).
///
/// FieldTally's own format rather than a re-emitted Ingress export, for two
/// reasons. A [StatSnapshot] can hold things an export cannot — a level that
/// is simply not known, which is every snapshot migrated from Agent Stats
/// (Appendix B) — and re-using the export shape would tie this format to a
/// column layout Niantic changes every anomaly season. It also means a
/// received payload can never be mistaken for an import: the marker line says
/// what it is, and nothing without that line reaches the comparison screen.
///
/// Deliberately plain text. It travels through Android's own share sheet, the
/// channel the app already listens on (§3.1), so it has to survive being
/// pasted into a messenger — and an agent who reads it before sending should
/// be able to make sense of what they see.
///
///     FieldTally/1 comparison
///     agent<TAB>Nohzoh
///     faction<TAB>Enlightened
///     level<TAB>14
///     recorded<TAB>2026-09-13T10:00:00
///     span<TAB>allTime
///     --
///     Unique Portals Visited<TAB>9756
///     Hacks<TAB>78735
class ComparisonPayload {
  const ComparisonPayload();

  /// Format marker. The version is part of it: a payload from a future
  /// FieldTally is refused by name rather than half-read.
  static const marker = 'FieldTally/1 comparison';

  /// Same shape, any version — so a newer payload is recognised as one of
  /// ours and refused with a useful message instead of being sent to the
  /// Ingress parser, which would fail with something baffling.
  static final _anyVersion = RegExp(r'^FieldTally/(\d+)\s+comparison$');

  /// Separates the metadata from the counters.
  ///
  /// Earns its line: `Level` is both metadata and a counter in its own right
  /// (§3.1.1, Appendix A), so the two halves genuinely cannot be told apart by
  /// their keys.
  static const _separator = '--';

  /// Whether this text is one of ours at all.
  ///
  /// Cheap and total: everything the app receives through a share goes past
  /// this, and anything that is not a comparison carries on to the import
  /// preview exactly as before.
  bool looksLikeComparison(String raw) =>
      _anyVersion.hasMatch(_lines(raw).firstOrNull ?? '');

  String encode(StatSnapshot snapshot) {
    final at = snapshot.recordedAt;
    final lines = <String>[
      marker,
      'agent\t${snapshot.agentName}',
      'faction\t${snapshot.faction}',
      // Omitted rather than zeroed when unknown: "level 0" is a claim, and
      // the receiving side already knows how to show nothing (§3.1.1).
      if (snapshot.level != null) 'level\t${snapshot.level}',
      'recorded\t${_stamp(at)}',
      'span\t${snapshot.timeSpan.name}',
      _separator,
      for (final entry in snapshot.counters.entries)
        '${entry.key}\t${entry.value}',
    ];
    return '${lines.join('\n')}\n';
  }

  /// Throws [ComparisonPayloadException] rather than returning null: by the
  /// time this is called the text has already been recognised as one of ours,
  /// so a failure has a reason worth telling the agent about.
  StatSnapshot decode(String raw) {
    final lines = _lines(raw);
    final header = lines.firstOrNull ?? '';

    final version = _anyVersion.firstMatch(header);
    if (version == null) {
      throw const ComparisonPayloadException(ComparisonPayloadError.malformed);
    }
    if (header != marker) {
      throw ComparisonPayloadException(
        ComparisonPayloadError.unsupportedVersion,
        detail: version.group(1),
      );
    }

    final split = lines.indexOf(_separator);
    if (split < 0) {
      throw const ComparisonPayloadException(
        ComparisonPayloadError.malformed,
        detail: _separator,
      );
    }

    final metadata = <String, String>{};
    for (final line in lines.sublist(1, split)) {
      final (key, value) = _pair(line);
      metadata[key] = value;
    }

    final counters = <String, int>{};
    for (final line in lines.sublist(split + 1)) {
      final (header, value) = _pair(line);
      final parsed = int.tryParse(value);
      if (parsed == null) {
        throw ComparisonPayloadException(
          ComparisonPayloadError.malformed,
          detail: line,
        );
      }
      counters[header] = parsed;
    }

    final span = TimeSpan.parse(metadata['span'] ?? '');
    if (!span.isCumulative) {
      // A week against a lifetime is not a comparison, it is a trap. The same
      // allowlist the import guards run on (§3.1.3), for the same reason.
      throw ComparisonPayloadException(
        ComparisonPayloadError.notCumulative,
        detail: metadata['span'],
      );
    }

    final recorded = DateTime.tryParse(metadata['recorded'] ?? '');
    final agent = metadata['agent'];
    if (recorded == null || agent == null || agent.isEmpty) {
      throw ComparisonPayloadException(
        ComparisonPayloadError.malformed,
        detail: recorded == null ? metadata['recorded'] : 'agent',
      );
    }

    return StatSnapshot(
      timeSpan: span,
      agentName: agent,
      faction: metadata['faction'] ?? '',
      recordedAt: recorded,
      level: int.tryParse(metadata['level'] ?? ''),
      counters: counters,
    );
  }

  /// Splits on the **first** tab only, so a codename that somehow contains one
  /// survives the round trip. Keys never do.
  (String, String) _pair(String line) {
    final tab = line.indexOf('\t');
    if (tab <= 0) {
      throw ComparisonPayloadException(
        ComparisonPayloadError.malformed,
        detail: line,
      );
    }
    return (line.substring(0, tab).trim(), line.substring(tab + 1).trim());
  }

  List<String> _lines(String raw) => raw
      .replaceFirst('﻿', '')
      .split(RegExp(r'\r\n|\r|\n'))
      .map((line) => line.trimRight())
      .where((line) => line.trim().isNotEmpty)
      .toList();

  String _stamp(DateTime at) =>
      '${_pad(at.year, 4)}-${_pad(at.month, 2)}-'
      '${_pad(at.day, 2)}T${_pad(at.hour, 2)}:${_pad(at.minute, 2)}:'
      '${_pad(at.second, 2)}';

  String _pad(int value, int width) => value.toString().padLeft(width, '0');
}
