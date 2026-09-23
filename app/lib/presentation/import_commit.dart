import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/stat_snapshot.dart';
import '../l10n/app_localizations.dart';
import 'providers/providers.dart';

/// Writes a whole import, once the agent has confirmed it (#191).
///
/// Shared by the two import screens rather than written twice: what happens
/// after "yes" is the same whichever format was read, and the one part of it
/// that is easy to get wrong — saying nothing about the milestones it crosses
/// — is exactly the part that would go missing in a second copy.
///
/// Deliberately no milestone notifications: importing a year of history
/// crosses tiers that were earned long ago, and announcing them would be a
/// burst of stale congratulations (§3.7). The reminder is still re-armed,
/// because the newest snapshot has just moved.
Future<void> commitImport(
  WidgetRef ref,
  List<StatSnapshot> snapshots, {
  required AppLocalizations l10n,
}) async {
  final repository = ref.read(snapshotRepositoryProvider);
  for (final snapshot in snapshots) {
    await repository.save(snapshot);
  }

  await ref
      .read(notificationCoordinatorProvider)
      .rescheduleReminder(
        latestSnapshot: (await repository.latest())?.snapshot.recordedAt,
        l10n: l10n,
      );
}
