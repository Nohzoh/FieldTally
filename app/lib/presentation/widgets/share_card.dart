import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/counter_registry.dart';
import '../../domain/share_card.dart';
import '../../l10n/app_localizations.dart';
import '../faction.dart';

/// The image an agent posts (§3.8).
///
/// Deliberately carries its own palette instead of following the app theme: a
/// card shared on Reddit is read by people whose phones are set to anything,
/// and an image that came out washed out because the author happened to be in
/// light mode is a bad souvenir of a good week.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.data,
    required this.registry,
    required this.language,
  });

  final ShareCardData data;

  /// Null before the registry has resolved; headers then stand in for labels.
  final CounterRegistry? registry;

  final String language;

  /// Logical width of the card. Captured at a higher pixel ratio, so this is
  /// the shape of the image rather than its resolution.
  static const width = 360.0;

  static const _background = Color(0xFF0E2624);
  static const _panel = Color(0xFF153935);
  static const _accent = Color(0xFF5FD3C4);
  static const _text = Color(0xFFF2F7F6);
  static const _muted = Color(0xFF9BB8B3);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final numbers = NumberFormat.decimalPattern(language);
    final dates = DateFormat(l10n.shortDateFormat, locale.toString());
    // Read from the export rather than from the appearance setting (§3.9):
    // the card states what the snapshot said, whatever the app is painted.
    final faction = factionColour(data.faction) ?? _accent;

    // The app honours the system text size (§3.9), but this card does not: it
    // becomes an image other people look at, and an agent reading at 200%
    // would hand out a PNG with enormous text and truncated labels. Fixed
    // width, fixed palette, fixed text size — the image comes out the same for
    // everyone, which is the whole point of it.
    return MediaQuery.withNoTextScaling(
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _panel),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(l10n, dates, faction),
                const SizedBox(height: 16),
                for (final line in data.lines) ...[
                  _Line(
                    label: registry
                            ?.forExportHeader(line.exportHeader)
                            ?.label(language) ??
                        line.exportHeader,
                    value: numbers.format(line.value),
                    gain: line.gain == null
                        ? null
                        : '+${numbers.format(line.gain)}',
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 2),
                _footer(l10n, dates),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n, DateFormat dates, Color faction) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.agentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: faction,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${data.faction} · ${dates.format(data.recordedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // No level chip at all rather than one reading "—": the Agent Stats
          // migration CSV has no level column (Appendix B), and an empty badge
          // looks like a bug on a public image.
          if (data.level != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${l10n.fieldLevel} ${data.level}',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      );

  Widget _footer(AppLocalizations l10n, DateFormat dates) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: _panel),
          const SizedBox(height: 12),
          Text(
            data.since == null
                ? l10n.shareCardNoPeriod
                : l10n.shareCardSince(dates.format(data.since!)),
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          // The notice travels with the image: the card is the part that
          // leaves the app, so it is the part that has to carry it.
          Text(
            '${l10n.shareCardFooter} · ${l10n.shareCardDisclaimer}',
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.gain});

  final String label;
  final String value;

  /// Null when the period holds nothing to compare against.
  final String? gain;

  @override
  Widget build(BuildContext context) {
    return Row(
      // Aligned on the value rather than on the bottom of the column: bottom
      // alignment put the label level with the gain underneath, and it read as
      // if the label belonged to the small green number.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ShareCard._muted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: ShareCard._text,
                fontSize: 19,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (gain != null)
              Text(
                gain!,
                maxLines: 1,
                style: const TextStyle(
                  color: ShareCard._accent,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
