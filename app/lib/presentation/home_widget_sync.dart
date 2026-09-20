import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/home_widget_summary.dart';
import '../l10n/app_localizations.dart';
import 'providers/providers.dart';

/// Writes one home screen widget instance from its own selection (#181).
///
/// Shared by [StartupTasks] (which calls this for every placed instance, on
/// launch and again on every later history change) and
/// [ConfigureWidgetScreen] (which calls it for just the one instance being
/// configured, so it shows real data the moment it lands on the home screen
/// rather than waiting for the next history change to happen to trigger a
/// sync).
Future<void> writeHomeWidgetInstance(
  WidgetRef ref, {
  required int appWidgetId,
  required AppLocalizations l10n,
  required String languageCode,
}) async {
  final snapshots = ref.read(snapshotsProvider).asData?.value ?? const [];
  final registry = ref.read(counterRegistryProvider).asData?.value;
  final repository = ref.read(widgetInstanceCounterRepositoryProvider);
  final coordinator = ref.read(homeWidgetCoordinatorProvider);
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
