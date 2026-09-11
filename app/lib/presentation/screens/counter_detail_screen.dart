import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../domain/badge_projection.dart';
import '../../domain/counter_series.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/badge_projection_card.dart';
import '../widgets/counter_chart.dart';

/// Detail view for one counter (§3.4, §3.5).
///
/// The chart is scaled to this counter alone — the point of §3.5, since the
/// audit found Agent Stats unreadable for sharing one axis between sixty
/// series. Per §3.9 the numbers stay listed underneath: the chart is never the
/// only way to read the data.
class CounterDetailScreen extends ConsumerStatefulWidget {
  const CounterDetailScreen({super.key, required this.exportHeader});

  /// Stable identity of the counter, as it appears in the export.
  final String exportHeader;

  @override
  ConsumerState<CounterDetailScreen> createState() =>
      _CounterDetailScreenState();
}

class _CounterDetailScreenState extends ConsumerState<CounterDetailScreen> {
  ChartRange _range = ChartRange.all;
  ProjectionWindow _window = ProjectionWindow.month;

  @override
  Widget build(BuildContext context) {
    final exportHeader = widget.exportHeader;
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(language);
    final dates = DateFormat(l10n.shortDateFormat, locale);

    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final enrichment = registry?.forExportHeader(exportHeader);
    final label = enrichment?.label(language) ?? exportHeader;

    final snapshots = ref.watch(snapshotsProvider).asData?.value ?? const [];

    // Oldest first so the history reads chronologically, and so each delta can
    // be computed against the previous point that actually carried the value.
    final points = [
      for (final stored in snapshots.reversed)
        if (stored.snapshot.counters.containsKey(exportHeader))
          (stored.snapshot.recordedAt, stored.snapshot.counters[exportHeader]!),
    ];

    // Projections read the whole history, not the visible range: the badge is
    // reached against the total, whatever window the chart happens to show.
    final full = const CounterSeriesBuilder().series(
      snapshots: [for (final stored in snapshots) stored.snapshot],
      exportHeader: exportHeader,
    );
    final projection = const BadgeProjector().project(
      points: full.points,
      enrichment: enrichment,
      window: _window,
    );

    final series = const CounterSeriesBuilder().series(
      snapshots: [for (final stored in snapshots) stored.snapshot],
      exportHeader: exportHeader,
      range: _range,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.counters),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Row(
                    label: l10n.counterCurrentValue,
                    value: points.isEmpty
                        ? '—'
                        : numbers.format(points.last.$2),
                  ),
                  if (points.isNotEmpty) ...[
                    _Row(
                      label: l10n.counterFirstSeen,
                      value: dates.format(points.first.$1),
                    ),
                    _Row(
                      label: l10n.counterLastSeen,
                      value: dates.format(points.last.$1),
                    ),
                  ],
                  // The raw export header is worth surfacing: it is what a
                  // contributor needs to declare the counter in the registry.
                  _Row(label: l10n.counterExportHeader, value: exportHeader),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<ChartRange>(
            segments: [
              ButtonSegment(value: ChartRange.week, label: Text(l10n.rangeWeek)),
              ButtonSegment(
                  value: ChartRange.month, label: Text(l10n.rangeMonth)),
              ButtonSegment(value: ChartRange.all, label: Text(l10n.rangeAll)),
            ],
            selected: {_range},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _range = selection.first),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: series.isEmpty
                ? Center(
                    child: Text(
                      l10n.rangeNoData,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  )
                : CounterChart(series: series),
          ),
          if (series.gain != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.rangeGain(
                '${series.gain! >= 0 ? '+' : '−'}'
                '${numbers.format(series.gain!.abs())}',
              ),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
          if (projection != null) ...[
            const SizedBox(height: 16),
            BadgeProjectionCard(
              projection: projection,
              measuredFrom: full.points.last.at,
              onWindowChanged: (window) => setState(() => _window = window),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              l10n.counterNoTiers,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
          const SizedBox(height: 24),
          Text(l10n.counterHistory, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = points.length - 1; i >= 0; i--)
            ListTile(
              dense: true,
              title: Text(dates.format(points[i].$1)),
              trailing: Text(
                numbers.format(points[i].$2),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              subtitle: i == 0
                  ? null
                  : Text(_delta(numbers, points[i].$2 - points[i - 1].$2)),
            ),
        ],
      ),
    );
  }

  String _delta(NumberFormat numbers, int delta) {
    final formatted = numbers.format(delta.abs());
    return delta >= 0 ? '+$formatted' : '−$formatted';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
