import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/repositories/settings_repository.dart';
import 'package:fieldtally/presentation/faction.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notification_service.dart';

StatSnapshot snap(String faction, DateTime at) => StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: faction,
      recordedAt: at,
      level: 9,
      counters: const {'Hacks': 1},
    );

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ]);
    // Dispose the container before closing the database: Drift hangs on close
    // while a stream query is still subscribed.
    addTearDown(db.close);
    addTearDown(container.dispose);
  });

  group('theme mode (§3.9)', () {
    test('follows the system until the agent overrides it', () async {
      final sub = container.listen(themeModeProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(themeModeProvider.future);

      expect(container.read(themeModeProvider).requireValue, ThemeMode.system);

      await container
          .read(settingsRepositoryProvider)
          .write(SettingKeys.themeMode, 'dark');
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider).requireValue, ThemeMode.dark);
    });

    test('an unreadable stored value falls back to the system', () async {
      // A preference written by a future version, or corrupted, must not leave
      // the app with no theme at all.
      await container
          .read(settingsRepositoryProvider)
          .write(SettingKeys.themeMode, 'neon');

      final sub = container.listen(themeModeProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(themeModeProvider.future);

      expect(container.read(themeModeProvider).requireValue, ThemeMode.system);
    });
  });

  group('faction colours (§3.9)', () {
    Future<void> warm() async {
      final settings = container.listen(factionColoursProvider, (_, _) {});
      final snapshots = container.listen(snapshotsProvider, (_, _) {});
      addTearDown(settings.close);
      addTearDown(snapshots.close);
      await container.read(factionColoursProvider.future);
      await container.read(snapshotsProvider.future);
    }

    test('the app keeps its own colour until asked otherwise', () async {
      await container.read(snapshotRepositoryProvider).save(
            snap('Enlightened', DateTime(2026, 1, 1)),
          );
      await warm();

      expect(container.read(themeSeedProvider), Colors.teal);
    });

    test('once on, it follows the faction of the newest snapshot', () async {
      final repository = container.read(snapshotRepositoryProvider);
      await repository.save(snap('Resistance', DateTime(2026, 1, 1)));
      // An agent who changed faction re-imports, and the app should follow
      // rather than keep painting the old one.
      await repository.save(snap('Enlightened', DateTime(2026, 2, 1)));
      await container
          .read(settingsRepositoryProvider)
          .write(SettingKeys.factionColours, 'true');
      await warm();

      expect(container.read(themeSeedProvider), enlightenedColour);
    });

    test('an unknown faction leaves the app its own colour', () async {
      await container.read(snapshotRepositoryProvider).save(
            snap('Machina', DateTime(2026, 1, 1)),
          );
      await container
          .read(settingsRepositoryProvider)
          .write(SettingKeys.factionColours, 'true');
      await warm();

      expect(container.read(themeSeedProvider), Colors.teal);
    });

    test('no snapshot at all leaves the app its own colour', () async {
      await container
          .read(settingsRepositoryProvider)
          .write(SettingKeys.factionColours, 'true');
      await warm();

      expect(container.read(currentFactionProvider), isNull);
      expect(container.read(themeSeedProvider), Colors.teal);
    });
  });
}
