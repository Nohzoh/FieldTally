import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../domain/badge_projection.dart';
import '../../domain/counter_list.dart';
import '../../domain/counter_pace.dart';
import '../../domain/models/counter_registry.dart';
import '../../domain/models/tracked_counter.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/counter_tile.dart';
import '../widgets/medal_icon.dart';

/// Detailed stats view (§3.4).
///
/// Grouped by category and in the same order as the Ingress Prime stats
/// screen, because that is what makes the app immediately readable to someone
/// who already knows the game. Sorting by name or by recent progress is
/// available, but the in-game arrangement stays the default rather than a flat
/// list of sixty entries.
class CounterListScreen extends ConsumerWidget {
  const CounterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final counters = ref.watch(trackedCountersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.countersTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: counters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (list) => list.isEmpty
            ? _Empty(message: l10n.countersEmpty)
            : _CounterList(counters: list),
      ),
    );
  }
}

/// Why the list came back empty — the three reasons read differently.
///
/// "No counter matches the filters" after narrowing is not the same statement
/// as "the thresholds have not loaded", which is not the app's opinion about
/// the agent's game at all.
String _emptyMessage(
  AppLocalizations l10n,
  CounterQuery query,
  CounterRegistry? registry,
) {
  if (query.medalsOnly && registry == null) return l10n.countersMedalsUnknown;
  if (query.search.trim().isNotEmpty) {
    return l10n.counterSearchEmpty(query.search);
  }
  return l10n.countersFilteredEmpty;
}

class _CounterList extends ConsumerWidget {
  const _CounterList({required this.counters});

  final List<TrackedCounter> counters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final query = ref.watch(counterQueryProvider);
    final registry = ref.watch(counterRegistryProvider).asData?.value;

    final builder = CounterListBuilder(
      registry: registry,
      language: language,
      pace: ref.watch(counterPaceProvider),
    );
    final sections = builder.build(counters, query);
    final isEmpty = sections.every((s) => s.counters.isEmpty);

    return Column(
      children: [
        const _Controls(),
        if (isEmpty)
          Expanded(child: _Empty(message: _emptyMessage(l10n, query, registry)))
        else
          Expanded(
            child: ListView(
              children: [
                for (final section in sections)
                  ..._section(context, section, registry, builder, language),
                const SizedBox(height: 24),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _section(
    BuildContext context,
    CounterSection section,
    CounterRegistry? registry,
    CounterListBuilder builder,
    String language,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return [
      if (section.categoryKey != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            registry?.categories[section.categoryKey]?.label(language) ??
                l10n.fallbackCategory,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
      for (final counter in section.counters)
        _tile(context, counter, registry, builder),
    ];
  }

  /// The emblem is resolved here rather than in the tile: the tier comes from
  /// the registry, and the list already holds it (#63).
  Widget _tile(
    BuildContext context,
    TrackedCounter counter,
    CounterRegistry? registry,
    CounterListBuilder builder,
  ) {
    final enrichment = registry?.forExportHeader(counter.exportHeader);
    final key = enrichment?.key;
    return CounterTile(
      counter: counter,
      label: builder.labelFor(counter),
      // A counter with thresholds but no drawing shows no emblem rather than
      // a bare ring — the registry can name one this release has never seen.
      medalKey: key != null && MedalIcon.existsFor(key) ? key : null,
      tierName: tierReached(enrichment, counter.lastValue)?.name,
      tierMultiple: topTierMultiple(enrichment, counter.lastValue),
      onTap: () => context.go(
        Routes.counterDetail(counter.exportHeader),
      ),
    );
  }
}

/// Search field, ordering, the filters, and the window the ordering measures.
///
/// The filters are named chips rather than bare icon buttons. There was one
/// filter before this — inactive counters — carried by an unlabelled eye,
/// and adding a second would have left the row with two cryptic toggles and
/// no vocabulary for what they do (#88).
class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(counterQueryProvider);
    final notifier = ref.read(counterQueryProvider.notifier);
    // The medal filter reads the registry. Until it has loaded there is
    // nothing to filter on, so the chip is disabled rather than silently
    // emptying the list (§3.1.4).
    final registry = ref.watch(counterRegistryProvider).asData?.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              labelText: l10n.searchCounters,
            ),
            onChanged: notifier.search,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<CounterSort>(
            initialValue: query.sort,
            isDense: true,
            // Without this the dropdown sizes to its longest label and
            // overflows on a narrow screen.
            isExpanded: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              labelText: l10n.sortLabel,
            ),
            items: [
              DropdownMenuItem(
                value: CounterSort.category,
                child: Text(l10n.sortByCategory),
              ),
              DropdownMenuItem(
                value: CounterSort.name,
                child: Text(l10n.sortByName),
              ),
              DropdownMenuItem(
                value: CounterSort.recentProgress,
                child: Text(l10n.sortByRecentProgress),
              ),
              DropdownMenuItem(
                value: CounterSort.nextTier,
                child: Text(l10n.sortByNextTier),
              ),
            ],
            onChanged: (sort) {
              if (sort != null) notifier.sortBy(sort);
            },
          ),
          const SizedBox(height: 8),
          // Wrapped rather than in a Row: the labels are translated, and a
          // French chip is not the width of an English one.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tooltip(
                message: l10n.filterMedalsTooltip,
                child: FilterChip(
                  label: Text(l10n.filterMedals),
                  selected: query.medalsOnly,
                  onSelected: registry == null ? null : notifier.showMedalsOnly,
                ),
              ),
              Tooltip(
                message: l10n.filterInactiveTooltip,
                child: FilterChip(
                  label: Text(l10n.filterInactive),
                  selected: query.includeInactive,
                  onSelected: notifier.showInactive,
                ),
              ),
            ],
          ),
          // Only while something measures across it, so the control is never
          // dead: the other three orderings have no window (#89).
          if (query.sort == CounterSort.recentProgress) ...[
            const SizedBox(height: 8),
            Text(
              l10n.progressWindowLabel,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final window in ProgressWindow.values)
                  ChoiceChip(
                    label: Text(_windowLabel(l10n, window)),
                    selected: query.window == window,
                    onSelected: (_) => notifier.measureOver(window),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _windowLabel(AppLocalizations l10n, ProgressWindow window) =>
      switch (window) {
        ProgressWindow.sinceLastSnapshot => l10n.progressWindowSinceLast,
        ProgressWindow.week => l10n.progressWindowWeek,
        ProgressWindow.month => l10n.progressWindowMonth,
      };
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ),
    );
  }
}
