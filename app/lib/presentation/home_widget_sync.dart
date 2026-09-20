import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/home_widget_summary.dart';
import '../l10n/app_localizations.dart';
import 'providers/providers.dart';

/// Writes one home screen widget instance from its own selection (#181).
///
/// Takes a [ProviderContainer] rather than a `WidgetRef`: [StartupTasks]
/// obtains its own via `ProviderScope.containerOf`, and the
/// pin-from-a-counter's-screen flow on `CounterDetailScreen` (#185) needs
/// one that outlives the screen itself, since its poll for a newly-placed
/// instance has to keep running even if the agent has since navigated away.
///
/// Shared by [StartupTasks] (every placed instance, on launch and on every
/// later history change) and that poll (just the one instance it placed, the
/// moment it appears, so it shows real data immediately rather than waiting
/// for the next history change to happen to trigger a sync).
Future<void> writeHomeWidgetInstance(
  ProviderContainer container, {
  required int appWidgetId,
  required AppLocalizations l10n,
  required String languageCode,
}) async {
  final snapshots = container.read(snapshotsProvider).asData?.value ?? const [];
  final registry = container.read(counterRegistryProvider).asData?.value;
  final repository = container.read(widgetInstanceCounterRepositoryProvider);
  final coordinator = container.read(homeWidgetCoordinatorProvider);
  final builder = HomeWidgetSummaryBuilder(registry: registry);

  final pinned = await repository.pinnedFor(appWidgetId);
  final summary = builder.build(
    snapshots: [for (final stored in snapshots) stored.snapshot],
    pinned: pinned,
  );
  await coordinator.sync(
    appWidgetId: appWidgetId,
    summary: summary,
    l10n: l10n,
    languageCode: languageCode,
    registry: registry,
  );
}
