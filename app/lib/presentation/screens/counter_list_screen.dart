import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../domain/counter_list.dart';
import '../../domain/models/counter_registry.dart';
import '../../domain/models/tracked_counter.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/counter_tile.dart';

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

class _CounterList extends ConsumerWidget {
  const _CounterList({required this.counters});

  final List<TrackedCounter> counters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final query = ref.watch(counterQueryProvider);
    final registry = ref.watch(counterRegistryProvider).asData?.value;

    final builder =
        CounterListBuilder(registry: registry, language: language);
    final sections = builder.build(counters, query);
    final isEmpty = sections.every((s) => s.counters.isEmpty);

    return Column(
      children: [
        const _Controls(),
        if (isEmpty)
          Expanded(
            child: _Empty(message: l10n.counterSearchEmpty(query.search)),
          )
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
        CounterTile(
          counter: counter,
          label: builder.labelFor(counter),
          onTap: () => context.go(
            Routes.counterDetail(counter.exportHeader),
          ),
        ),
    ];
  }
}

/// Search field, ordering and the inactive toggle.
class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(counterQueryProvider);
    final notifier = ref.read(counterQueryProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
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
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<CounterSort>(
                  initialValue: query.sort,
                  isDense: true,
                  // Without this the dropdown sizes to its longest label and
                  // overflows next to the toggle on a narrow screen.
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
                  ],
                  onChanged: (sort) {
                    if (sort != null) notifier.sortBy(sort);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Inactive counters stay in place, with a discreet chip, rather
              // than moving to a separate screen (§3.1.2) — but hiding them is
              // one tap away.
              IconButton(
                tooltip: l10n.showInactive,
                isSelected: query.includeInactive,
                icon: const Icon(Icons.visibility_off_outlined),
                selectedIcon: const Icon(Icons.visibility),
                onPressed: () => notifier.showInactive(!query.includeInactive),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
