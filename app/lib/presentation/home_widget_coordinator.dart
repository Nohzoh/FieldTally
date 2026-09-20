import 'package:intl/intl.dart';

import '../data/widgets/home_widget_gateway.dart';
import '../domain/home_widget_summary.dart';
import '../domain/models/counter_registry.dart';
import '../l10n/app_localizations.dart';
import 'tier_labels.dart';

/// Turns a [HomeWidgetSummary] into what one home screen widget instance
/// actually shows (#154, per-instance since #181).
///
/// Sits in the presentation layer for the same reason
/// `NotificationCoordinator` does: the domain knows *what* the widget has to
/// say, this knows how to say it, and in which language.
class HomeWidgetCoordinator {
  const HomeWidgetCoordinator({required this.gateway});

  final HomeWidgetGateway gateway;

  /// Key roots written to the widget's storage. `_maxLines` lines' worth, plus
  /// one shared state flag the native side switches its layout on — every key
  /// is actually written suffixed with `_$appWidgetId` (see [_key]), since
  /// each instance keeps its own copy of all of them (#181).
  static const _stateKey = 'widget_state';
  static const _titleKey = 'widget_title';
  static const _detailKey = 'widget_detail';
  static const _labelPrefix = 'widget_label_';
  static const _valuePrefix = 'widget_value_';
  static const _linePrefix = 'widget_line_';

  /// The native layout's own row plafond (#177) — must match
  /// `HomeWidgetSummaryBuilder`'s default `maxLines` and the number of
  /// `widget_row_*` blocks in `field_tally_widget.xml`. Kept as its own
  /// constant rather than reading the summary's line count, since a message
  /// state (no lines at all) still has this many slots to clear.
  static const _maxLines = 4;

  /// Namespaces a key root to one instance. Must match the suffix
  /// `FieldTallyWidgetProvider` reads its own keys with on the Kotlin side.
  static String _key(String root, int appWidgetId) => '${root}_$appWidgetId';

  Future<void> sync({
    required int appWidgetId,
    required HomeWidgetSummary summary,
    required AppLocalizations l10n,
    required String languageCode,
    CounterRegistry? registry,
  }) async {
    // The `!summary.hasAnyPinned` branch is real and tested, but not reachable
    // through the app's own wiring today — see the note on hasAnyPinned. Kept
    // because this coordinator, like NotificationCoordinator, phrases whatever
    // it is handed rather than assuming one caller's habits.
    if (!summary.hasAnyPinned) {
      await _writeMessage(
        appWidgetId: appWidgetId,
        state: 'unpinned',
        title: l10n.homeWidgetUnpinnedTitle,
        detail: l10n.homeWidgetUnpinnedDetail,
      );
    } else if (summary.lines.isEmpty) {
      // Pinned counters exist but no snapshot has ever carried one — the
      // fresh-install state, distinct from "nothing pinned" (§ the builder
      // already keeps these apart, on purpose).
      await _writeMessage(
        appWidgetId: appWidgetId,
        state: 'empty',
        title: l10n.homeEmptyTitle,
        detail: l10n.homeEmptyDetail,
      );
    } else {
      await _writeLines(
        appWidgetId: appWidgetId,
        summary: summary,
        l10n: l10n,
        languageCode: languageCode,
        registry: registry,
      );
    }

    await gateway.refresh();
  }

  Future<void> _writeMessage({
    required int appWidgetId,
    required String state,
    required String title,
    required String detail,
  }) async {
    await gateway.write(_key(_stateKey, appWidgetId), state);
    await gateway.write(_key(_titleKey, appWidgetId), title);
    await gateway.write(_key(_detailKey, appWidgetId), detail);
    // A message state shows no lines. Clearing rather than leaving a stale
    // pair behind from before the agent unpinned everything.
    for (var i = 0; i < _maxLines; i++) {
      await gateway.write(_key('$_labelPrefix$i', appWidgetId), null);
      await gateway.write(_key('$_valuePrefix$i', appWidgetId), null);
      await gateway.write(_key('$_linePrefix$i', appWidgetId), null);
    }
  }

  Future<void> _writeLines({
    required int appWidgetId,
    required HomeWidgetSummary summary,
    required AppLocalizations l10n,
    required String languageCode,
    required CounterRegistry? registry,
  }) async {
    await gateway.write(_key(_stateKey, appWidgetId), 'data');
    await gateway.write(_key(_titleKey, appWidgetId), null);
    await gateway.write(_key(_detailKey, appWidgetId), null);

    final numbers = NumberFormat.decimalPattern(languageCode);

    for (var i = 0; i < _maxLines; i++) {
      if (i >= summary.lines.length) {
        await gateway.write(_key('$_labelPrefix$i', appWidgetId), null);
        await gateway.write(_key('$_valuePrefix$i', appWidgetId), null);
        await gateway.write(_key('$_linePrefix$i', appWidgetId), null);
        continue;
      }

      final line = summary.lines[i];
      await gateway.write(
        _key('$_labelPrefix$i', appWidgetId),
        registry?.forExportHeader(line.exportHeader)?.label(languageCode) ??
            line.exportHeader,
      );
      await gateway.write(
        _key('$_valuePrefix$i', appWidgetId),
        numbers.format(line.value),
      );
      await gateway.write(
        _key('$_linePrefix$i', appWidgetId),
        _detail(line, l10n: l10n, numbers: numbers),
      );
    }
  }

  /// The delta and the distance to the next tier, joined — either half
  /// missing when there is nothing to say about it. Never both missing when
  /// this is called: a line with neither would not have been built.
  String _detail(
    HomeWidgetLine line, {
    required AppLocalizations l10n,
    required NumberFormat numbers,
  }) {
    final parts = <String>[];

    final delta = line.delta;
    if (delta != null) {
      final formatted = numbers.format(delta.abs());
      // The sign is a character, not a colour: the widget draws everything in
      // one text colour, so a delta that fell must say so in the text itself.
      parts.add(delta >= 0 ? '+$formatted' : '−$formatted');
    }

    final remaining = line.remainingToNextTier;
    final nextTier = line.nextTier;
    if (remaining != null && nextTier != null) {
      parts.add(
        l10n.homeWidgetRemaining(
          numbers.format(remaining),
          tierLabel(l10n, nextTier),
        ),
      );
    }

    return parts.join(' · ');
  }
}
