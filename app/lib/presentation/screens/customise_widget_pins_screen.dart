import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../domain/counter_list.dart';
import '../../domain/repositories/widget_pinned_counter_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';

/// Picks which counters the home screen widget shows (#174), independently
/// of the dashboard's own pins.
///
/// A copy of [CustomisePinsScreen]'s shape — same search-plus-checkbox
/// pattern, different repository and bounds (#177's row plafond rather than
/// §3.3's dashboard bounds).
class CustomiseWidgetPinsScreen extends ConsumerStatefulWidget {
  const CustomiseWidgetPinsScreen({super.key});

  @override
  ConsumerState<CustomiseWidgetPinsScreen> createState() =>
      _CustomiseWidgetPinsScreenState();
}

class _CustomiseWidgetPinsScreenState
    extends ConsumerState<CustomiseWidgetPinsScreen> {
  /// Edited locally and committed on save, so backing out leaves the widget
  /// untouched.
  List<String>? _selection;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;

    final counters =
        ref.watch(trackedCountersProvider).asData?.value ?? const [];
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final pinned = ref.watch(widgetPinnedCountersProvider);

    final selection = _selection ??= [...pinned];
    final builder = CounterListBuilder(registry: registry, language: language);

    final sections = builder.build(
      counters,
      CounterQuery(search: _search, sort: CounterSort.category),
    );
    final tooFew = selection.length < WidgetPinnedCounterRepository.minPinned;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customiseWidgetTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(Routes.settings),
        ),
        actions: [
          TextButton(
            onPressed: tooFew ? null : () => _save(selection),
            child: Text(l10n.save),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.customiseWidgetHint(
                    WidgetPinnedCounterRepository.minPinned,
                    WidgetPinnedCounterRepository.maxPinned,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    labelText: l10n.searchCounters,
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: 8),
                Text(
                  tooFew
                      ? l10n.customiseTooFew(
                          WidgetPinnedCounterRepository.minPinned,
                        )
                      : l10n.customiseSelected(
                          selection.length,
                          WidgetPinnedCounterRepository.maxPinned,
                        ),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tooFew
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final section in sections)
                  for (final counter in section.counters)
                    CheckboxListTile(
                      value: selection.contains(counter.exportHeader),
                      title: Text(builder.labelFor(counter)),
                      // Past the maximum, the remaining boxes go flat rather
                      // than silently dropping an earlier choice.
                      onChanged:
                          selection.length >=
                                  WidgetPinnedCounterRepository.maxPinned &&
                              !selection.contains(counter.exportHeader)
                          ? null
                          : (checked) => setState(() {
                              if (checked ?? false) {
                                selection.add(counter.exportHeader);
                              } else {
                                selection.remove(counter.exportHeader);
                              }
                            }),
                    ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(List<String> selection) async {
    await ref.read(widgetPinnedCounterRepositoryProvider).setPinned(selection);
    if (mounted) context.go(Routes.settings);
  }
}
