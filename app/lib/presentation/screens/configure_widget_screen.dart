import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/counter_list.dart';
import '../../domain/repositories/widget_instance_counter_repository.dart';
import '../../l10n/app_localizations.dart';
import '../home_widget_sync.dart';
import '../providers/providers.dart';

/// Picks one home screen widget instance's counters (#181).
///
/// Reached only through Android's own `APPWIDGET_CONFIGURE` flow —
/// `WidgetConfigureActivity` on the native side starts a small, separate
/// Flutter engine straight into this screen, parameterized by the
/// `appWidgetId` Android hands it, rather than through the app's own router:
/// this runs before the widget is even placed, launched from the home
/// screen, with no app screen underneath to return to.
///
/// A copy of the deleted `CustomiseWidgetPinsScreen`'s search-plus-checkbox
/// shape (#174), aimed at one instance's own selection instead of the single
/// shared one every instance used to follow.
class ConfigureWidgetScreen extends ConsumerStatefulWidget {
  const ConfigureWidgetScreen({super.key, required this.appWidgetId});

  final int appWidgetId;

  @override
  ConsumerState<ConfigureWidgetScreen> createState() =>
      _ConfigureWidgetScreenState();
}

class _ConfigureWidgetScreenState extends ConsumerState<ConfigureWidgetScreen> {
  /// Edited locally and committed on save, so closing without saving leaves
  /// this instance exactly as unconfigured as it was.
  List<String>? _selection;
  String _search = '';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;

    final counters =
        ref.watch(trackedCountersProvider).asData?.value ?? const [];
    final registry = ref.watch(counterRegistryProvider).asData?.value;
    final pinned = ref.watch(
      widgetInstanceCountersProvider(widget.appWidgetId),
    );

    if (_selection == null && !pinned.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final selection = _selection ??= [...?pinned.value];

    final builder = CounterListBuilder(registry: registry, language: language);
    final sections = builder.build(
      counters,
      CounterQuery(search: _search, sort: CounterSort.category),
    );
    final tooFew = selection.length < WidgetInstanceCounterRepository.minPinned;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customiseWidgetTitle),
        // Closing without saving must leave the placement cancelled, the
        // Android default `WidgetConfigureActivity` already set — this just
        // ends the activity, it never calls `finishConfiguring`.
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => SystemNavigator.pop(),
        ),
        actions: [
          TextButton(
            onPressed: tooFew || _saving ? null : () => _save(selection),
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
                    WidgetInstanceCounterRepository.minPinned,
                    WidgetInstanceCounterRepository.maxPinned,
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
                          WidgetInstanceCounterRepository.minPinned,
                        )
                      : l10n.customiseSelected(
                          selection.length,
                          WidgetInstanceCounterRepository.maxPinned,
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
                                  WidgetInstanceCounterRepository.maxPinned &&
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
    setState(() => _saving = true);

    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    await ref
        .read(widgetInstanceCounterRepositoryProvider)
        .setPinnedFor(widget.appWidgetId, selection);
    // Written once, right away, rather than left for the next history change
    // to trigger: without this the newly-placed widget would show its
    // "unpinned" state until something else happened to touch a snapshot.
    await writeHomeWidgetInstance(
      ref,
      appWidgetId: widget.appWidgetId,
      l10n: l10n,
      languageCode: languageCode,
    );
    await ref
        .read(homeWidgetGatewayProvider)
        .finishConfiguring(widget.appWidgetId);
  }
}
