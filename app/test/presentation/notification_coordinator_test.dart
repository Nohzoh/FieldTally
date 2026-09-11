import 'dart:io';

import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/data/repositories/drift_settings_repository.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/repositories/settings_repository.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/l10n/app_localizations_en.dart';
import 'package:fieldtally/presentation/notification_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notification_service.dart';

const seedPath = 'assets/counters_registry_seed.json';

StatSnapshot snap(Map<String, int> counters) => StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: DateTime(2026, 1, 1),
      counters: counters,
    );

void main() {
  late FieldTallyDatabase db;
  late SettingsRepository settings;
  late FakeNotificationService service;
  late NotificationCoordinator coordinator;
  late CounterRegistry registry;

  final AppLocalizations l10n = AppLocalizationsEn();

  setUp(() {
    db = FieldTallyDatabase(NativeDatabase.memory());
    settings = DriftSettingsRepository(db);
    service = FakeNotificationService();
    coordinator =
        NotificationCoordinator(service: service, settings: settings);
    registry =
        const CounterRegistryLoader().parse(File(seedPath).readAsStringSync());
  });

  tearDown(() => db.close());

  group('preferences (§3.7)', () {
    test('notifications are off until switched on', () async {
      // Android 13 grants the permission to nobody by default: anything but
      // opt-in would be a promise the system does not keep.
      expect(await coordinator.isEnabled(), isFalse);

      await coordinator.setEnabled(true);
      expect(await coordinator.isEnabled(), isTrue);
    });

    test('switching off drops any pending reminder', () async {
      await coordinator.setEnabled(true);
      await coordinator.setEnabled(false);

      // Leaving a scheduled alarm behind after the agent said no would be the
      // one thing an off switch must not do.
      expect(service.cancels, 1);
    });

    test('the reminder delay is seven days until changed', () async {
      expect(await coordinator.reminderDays(), 7);

      await coordinator.setReminderDays(3);
      expect(await coordinator.reminderDays(), 3);
    });
  });

  group('reminder scheduling (§3.7)', () {
    setUp(() => coordinator.setEnabled(true));

    test('schedules the delay after the latest snapshot', () async {
      final latest = DateTime(2026, 3, 1, 9);

      await coordinator.rescheduleReminder(
        latestSnapshot: latest,
        l10n: l10n,
        now: DateTime(2026, 3, 2),
      );

      expect(service.scheduled.single.at, DateTime(2026, 3, 8, 9));
      expect(service.scheduled.single.body, contains('7 days'));
    });

    test('follows the configured delay', () async {
      await coordinator.setReminderDays(3);

      await coordinator.rescheduleReminder(
        latestSnapshot: DateTime(2026, 3, 1, 9),
        l10n: l10n,
        now: DateTime(2026, 3, 2),
      );

      expect(service.scheduled.single.at, DateTime(2026, 3, 4, 9));
      expect(service.scheduled.single.body, contains('3 days'));
    });

    test('cancels instead of scheduling when nothing was ever recorded',
        () async {
      await coordinator.rescheduleReminder(latestSnapshot: null, l10n: l10n);

      expect(service.scheduled, isEmpty);
      expect(service.cancels, 1);
    });

    test('cancels instead of scheduling when notifications are off', () async {
      await coordinator.setEnabled(false);
      service.cancels = 0;

      await coordinator.rescheduleReminder(
        latestSnapshot: DateTime(2026, 3, 1),
        l10n: l10n,
      );

      expect(service.scheduled, isEmpty);
    });
  });

  group('milestone announcements (§3.7)', () {
    setUp(() => coordinator.setEnabled(true));

    Future<void> announce(
      Map<String, int> before,
      Map<String, int> after,
    ) =>
        coordinator.announceMilestones(
          current: snap(after),
          previous: snap(before),
          registry: registry,
          l10n: l10n,
          language: 'en',
        );

    test('names the tier, the counter and the value', () async {
      // Explorer silver sits at 1000.
      await announce(
        const {'Unique Portals Visited': 900},
        const {'Unique Portals Visited': 1100},
      );

      final posted = service.shown.single;
      expect(posted.title, contains('Silver'));
      expect(posted.body, contains('Unique Portals Visited'));
      expect(posted.body, contains('1,100'));
    });

    test('says nothing when notifications are off', () async {
      await coordinator.setEnabled(false);

      await announce(
        const {'Unique Portals Visited': 900},
        const {'Unique Portals Visited': 1100},
      );

      expect(service.shown, isEmpty);
    });

    test('says nothing when no tier was crossed', () async {
      await announce(
        const {'Unique Portals Visited': 900},
        const {'Unique Portals Visited': 950},
      );

      expect(service.shown, isEmpty);
    });

    test('caps a burst and counts the rest into the last one', () async {
      // Bronze, silver, gold and platinum in one jump: four crossings, and
      // four separate congratulations would be a mess.
      await announce(
        const {'Unique Portals Visited': 0},
        const {'Unique Portals Visited': 12000},
      );

      expect(service.shown, hasLength(NotificationCoordinator.maxMilestones));
      expect(service.shown.last.body, contains('1 other'));
      // Biggest first: platinum leads, bronze is the one folded away.
      expect(service.shown.first.title, contains('Platinum'));
    });

    test('gives each milestone its own notification id', () async {
      await announce(
        const {'Unique Portals Visited': 0},
        const {'Unique Portals Visited': 12000},
      );

      expect(
        service.shown.map((n) => n.id).toSet(),
        hasLength(service.shown.length),
      );
    });
  });
}
