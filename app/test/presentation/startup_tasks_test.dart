// The startup-time wiring that has no other test: whether StartupTasks sits
// where AppLocalizations.of(context) actually resolves, and whether it keeps
// the home screen widget (#154) in step with later changes, not just the
// first frame.
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
    final gateway = FakeHomeWidgetGateway();
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

    // Proves the call site: AppLocalizations.of(context) did not throw and
    // get swallowed. If it had, nothing below would ever have been written.
    expect(gateway.written['widget_state'], 'data');
    expect(gateway.written['widget_label_0'], 'Hacks');
    expect(gateway.written['widget_value_0'], '100');
    expect(gateway.refreshes, greaterThanOrEqualTo(1));

    final refreshesAfterLaunch = gateway.refreshes;

    // A later change, not just the first frame: the reactive half of #154.
    await container
        .read(snapshotRepositoryProvider)
        .save(at(DateTime(2026, 1, 2), const {'Hacks': 140}));
    await tester.pumpAndSettle();

    expect(gateway.written['widget_value_0'], '140');
    expect(gateway.written['widget_line_0'], contains('+40'));
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

  testWidgets('unpinning falls back to the same defaults the dashboard uses', (
    tester,
  ) async {
    // Checked before writing this test, not assumed: PinnedCounterRepository
    // enforces a floor of 4 pins in the customise-pins UI, and
    // pinnedCountersProvider itself substitutes PinnedCounterRepository's
    // defaults for a genuinely empty repository result. So there is no route
    // by which this app ever shows an agent nothing pinned at all — the
    // widget's "unpinned" message exists as a contract HomeWidgetCoordinator
    // honours (tested directly in home_widget_coordinator_test.dart), not as
    // a state reachable through this screen. What this app actually does on
    // "unpin everything" is fall back to the four defaults, same as the
    // dashboard — which is what this test checks instead.
    final db = FieldTallyDatabase(NativeDatabase.memory());
    final gateway = FakeHomeWidgetGateway();
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

    // A counter that is not one of the four defaults, so its presence in
    // the widget afterwards would prove the fallback did not happen.
    await container.read(pinnedCounterRepositoryProvider).setPinned(const [
      'Links Created',
    ]);
    await container
        .read(snapshotRepositoryProvider)
        .save(
          at(DateTime(2026, 1, 1), const {'Links Created': 3, 'Hacks': 100}),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FieldTallyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(gateway.written['widget_label_0'], 'Links Created');

    await container.read(pinnedCounterRepositoryProvider).setPinned(const []);
    await tester.pumpAndSettle();

    // Still 'data', not 'unpinned': PinnedCounterRepository.defaults
    // includes Hacks, which does have a snapshot.
    expect(gateway.written['widget_state'], 'data');
    expect(gateway.written['widget_label_0'], isNot('Links Created'));
  });
}
