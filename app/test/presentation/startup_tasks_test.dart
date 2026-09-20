// The startup-time wiring that has no other test: whether StartupTasks sits
// where AppLocalizations.of(context) actually resolves, whether it keeps
// every placed home screen widget instance in step with later changes, not
// just the first frame (#154, #181), and the one-time migration off the old
// single shared selection (#181).
//
// This is the one place the real app shell (FieldTallyApp) gets pumped at
// all — every other test builds MaterialApp.router directly and never
// exercises StartupTasks. That gap is exactly what let a real bug through
// once (see main.dart's comment on `builder`): a background task reading
// AppLocalizations.of(context) from one layer too high throws, and the
// catch around it swallows that silently. A test asserting the *outcome*
// (something was written to the gateway) is what would have caught it —
// asserting only "no exception was thrown" would not have, since the
// swallowed exception throws no test failure either.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/repositories/settings_repository.dart';
import 'package:fieldtally/main.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_home_widget_gateway.dart';
import '../support/fake_notification_service.dart';
import '../support/fixed_registry.dart';

const widgetId = 7;

StatSnapshot at(DateTime date, Map<String, int> counters) => StatSnapshot(
  timeSpan: TimeSpan.allTime,
  agentName: 'AgentDemo',
  faction: 'Enlightened',
  recordedAt: date,
  level: 9,
  counters: counters,
);

void main() {
  testWidgets('the home screen widget is written on launch and kept in step', (
    tester,
  ) async {
    final db = FieldTallyDatabase(NativeDatabase.memory());
    final gateway = FakeHomeWidgetGateway()..ids = [widgetId];
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(
          FakeNotificationService(),
        ),
        counterRegistryProvider.overrideWith(fixedRegistry),
        homeWidgetGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);

    await container.read(widgetInstanceCounterRepositoryProvider).setPinnedFor(
      widgetId,
      const ['Hacks'],
    );
    await container
        .read(snapshotRepositoryProvider)
        .save(at(DateTime(2026, 1, 1), const {'Hacks': 100}));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FieldTallyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Proves the call site: AppLocalizations.of(context) did not throw and
    // get swallowed. If it had, nothing below would ever have been written.
    expect(gateway.written['widget_state_$widgetId'], 'data');
    expect(gateway.written['widget_label_0_$widgetId'], 'Hacks');
    expect(gateway.written['widget_value_0_$widgetId'], '100');
    expect(gateway.refreshes, greaterThanOrEqualTo(1));

    final refreshesAfterLaunch = gateway.refreshes;

    // A later change, not just the first frame: the reactive half of #154.
    await container
        .read(snapshotRepositoryProvider)
        .save(at(DateTime(2026, 1, 2), const {'Hacks': 140}));
    await tester.pumpAndSettle();

    expect(gateway.written['widget_value_0_$widgetId'], '140');
    expect(gateway.written['widget_line_0_$widgetId'], contains('+40'));
    expect(gateway.refreshes, greaterThan(refreshesAfterLaunch));
  });

  testWidgets(
    'the startup reminder re-arm actually runs, not just the widget sync',
    (tester) async {
      // A regression test for a bug this branch fixes as a side effect, not
      // one it introduces: StartupTasks used to wrap MaterialApp.router
      // rather than sit inside its `builder`, one layer too high for
      // AppLocalizations.of(context) to resolve. `_armReminder` already
      // wrapped that call in a try/catch "silent by design", so the failure
      // threw and vanished on every single launch — nothing ever scheduled
      // the "nothing recorded lately" reminder at startup. Proven by the
      // fix, not assumed: reverting main.dart's `builder` placement while
      // leaving this test in place turns it red.
      final db = FieldTallyDatabase(NativeDatabase.memory());
      final notifications = FakeNotificationService();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notifications),
          counterRegistryProvider.overrideWith(fixedRegistry),
          homeWidgetGatewayProvider.overrideWithValue(FakeHomeWidgetGateway()),
        ],
      );
      addTearDown(db.close);
      addTearDown(container.dispose);

      await container
          .read(settingsRepositoryProvider)
          .write(SettingKeys.notifications, 'true');
      await container
          .read(snapshotRepositoryProvider)
          .save(at(DateTime(2026, 1, 1), const {'Hacks': 100}));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FieldTallyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(notifications.scheduled, isNotEmpty);
    },
  );

  testWidgets(
    'an unconfigured instance asks to be pinned, rather than borrowing the '
    'dashboard pins (#181)',
    (tester) async {
      // Before #181 an empty widget selection silently followed the
      // dashboard's own pins. That fallback is gone on purpose: once
      // instances are independently configurable, an unconfigured one has
      // nothing sensible to borrow from, so it asks to be set up instead.
      final db = FieldTallyDatabase(NativeDatabase.memory());
      final gateway = FakeHomeWidgetGateway()..ids = [widgetId];
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
          counterRegistryProvider.overrideWith(fixedRegistry),
          homeWidgetGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(db.close);
      addTearDown(container.dispose);

      // Dashboard pins deliberately set to something the widget must not
      // show, so its presence below would prove the fallback still exists.
      await container.read(pinnedCounterRepositoryProvider).setPinned(const [
        'Hacks',
      ]);
      await container
          .read(snapshotRepositoryProvider)
          .save(at(DateTime(2026, 1, 1), const {'Hacks': 100}));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FieldTallyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(gateway.written['widget_state_$widgetId'], 'unpinned');
      expect(gateway.written['widget_label_0_$widgetId'], isNull);
    },
  );

  group('migrating the old single selection (#181)', () {
    testWidgets(
      'copies it into an instance with nothing of its own, and writes at once',
      (tester) async {
        final db = FieldTallyDatabase(NativeDatabase.memory());
        final gateway = FakeHomeWidgetGateway()..ids = [widgetId];
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(
              FakeNotificationService(),
            ),
            counterRegistryProvider.overrideWith(fixedRegistry),
            homeWidgetGatewayProvider.overrideWithValue(gateway),
          ],
        );
        addTearDown(db.close);
        addTearDown(container.dispose);

        // Seeded directly: the legacy table has no repository of its own any
        // more, since nothing should write to it going forward.
        await db
            .into(db.widgetPinnedCounters)
            .insert(
              const WidgetPinnedCountersCompanion(
                exportHeader: Value('Hacks'),
                position: Value(0),
              ),
            );
        await container
            .read(snapshotRepositoryProvider)
            .save(at(DateTime(2026, 1, 1), const {'Hacks': 100}));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const FieldTallyApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          await container
              .read(widgetInstanceCounterRepositoryProvider)
              .pinnedFor(widgetId),
          ['Hacks'],
        );
        expect(await db.select(db.widgetPinnedCounters).get(), isEmpty);
        // Not left for the next history change to happen to trigger: the
        // migration writes the widget itself once it has copied the
        // selection across.
        expect(gateway.written['widget_state_$widgetId'], 'data');
        expect(gateway.written['widget_label_0_$widgetId'], 'Hacks');
      },
    );

    testWidgets('never overwrites an instance already configured on its own', (
      tester,
    ) async {
      final db = FieldTallyDatabase(NativeDatabase.memory());
      final gateway = FakeHomeWidgetGateway()..ids = [widgetId];
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
          counterRegistryProvider.overrideWith(fixedRegistry),
          homeWidgetGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(db.close);
      addTearDown(container.dispose);

      await db
          .into(db.widgetPinnedCounters)
          .insert(
            const WidgetPinnedCountersCompanion(
              exportHeader: Value('Hacks'),
              position: Value(0),
            ),
          );
      await container
          .read(widgetInstanceCounterRepositoryProvider)
          .setPinnedFor(widgetId, const ['Links Created']);
      await container
          .read(snapshotRepositoryProvider)
          .save(
            at(DateTime(2026, 1, 1), const {'Hacks': 100, 'Links Created': 3}),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FieldTallyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        await container
            .read(widgetInstanceCounterRepositoryProvider)
            .pinnedFor(widgetId),
        ['Links Created'],
      );
    });
  });

  group('cleaning up a removed instance (#181)', () {
    testWidgets('drops a configuration whose instance is no longer placed', (
      tester,
    ) async {
      final db = FieldTallyDatabase(NativeDatabase.memory());
      // Only widgetId is reported as still placed -- 99 stands in for one
      // removed from the home screen before this launch.
      final gateway = FakeHomeWidgetGateway()..ids = [widgetId];
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
          counterRegistryProvider.overrideWith(fixedRegistry),
          homeWidgetGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(db.close);
      addTearDown(container.dispose);

      const removedId = 99;
      await container
          .read(widgetInstanceCounterRepositoryProvider)
          .setPinnedFor(widgetId, const ['Hacks']);
      await container
          .read(widgetInstanceCounterRepositoryProvider)
          .setPinnedFor(removedId, const ['Recursions']);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FieldTallyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        await container
            .read(widgetInstanceCounterRepositoryProvider)
            .pinnedFor(widgetId),
        ['Hacks'],
      );
      expect(
        await container
            .read(widgetInstanceCounterRepositoryProvider)
            .pinnedFor(removedId),
        isEmpty,
      );
    });

    testWidgets('never touches an instance still on the home screen', (
      tester,
    ) async {
      final db = FieldTallyDatabase(NativeDatabase.memory());
      final gateway = FakeHomeWidgetGateway()..ids = [widgetId];
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
          counterRegistryProvider.overrideWith(fixedRegistry),
          homeWidgetGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(db.close);
      addTearDown(container.dispose);

      await container
          .read(widgetInstanceCounterRepositoryProvider)
          .setPinnedFor(widgetId, const ['Hacks']);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FieldTallyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        await container
            .read(widgetInstanceCounterRepositoryProvider)
            .pinnedFor(widgetId),
        ['Hacks'],
      );
    });
  });
}
