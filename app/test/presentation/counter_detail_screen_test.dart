// Pinning a widget straight from a counter's own screen (#181, path B).
//
// requestPinAppWidget places the widget asynchronously, with no platform
// callback for when -- or whether -- that finishes (#185: every native
// callback tried here ran into some flavour of Android's
// background-activity-start restrictions on a real device). So this screen
// polls for the newly-appeared instance instead and configures it directly,
// entirely in Dart -- these tests drive that poll loop through the fake
// clock rather than waiting on anything real.

import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:fieldtally/presentation/screens/counter_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_home_widget_gateway.dart';
import '../support/fixed_registry.dart';

const newWidgetId = 42;

Future<ProviderContainer> pumpScreen(
  WidgetTester tester,
  FakeHomeWidgetGateway gateway,
) async {
  final db = FieldTallyDatabase(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      counterRegistryProvider.overrideWith(fixedRegistry),
      homeWidgetGatewayProvider.overrideWithValue(gateway),
    ],
  );
  addTearDown(db.close);
  addTearDown(container.dispose);

  await container
      .read(snapshotRepositoryProvider)
      .save(
        StatSnapshot(
          timeSpan: TimeSpan.allTime,
          agentName: 'AgentDemo',
          faction: 'Enlightened',
          recordedAt: DateTime(2026, 1, 1),
          level: 9,
          counters: const {'Hacks': 100},
        ),
      );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const CounterDetailScreen(exportHeader: 'Hacks'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('asks the gateway to pin a widget', (tester) async {
    final gateway = FakeHomeWidgetGateway();
    await pumpScreen(tester, gateway);

    await tester.tap(find.byIcon(Icons.add_to_home_screen));
    await tester.pump();

    expect(gateway.pinRequests, 1);
    expect(find.byType(SnackBar), findsNothing);

    // Nothing new ever appears in this test -- let the poll loop exhaust
    // itself so no timer is left pending when the test ends.
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('tells the user when their launcher does not support this', (
    tester,
  ) async {
    final gateway = FakeHomeWidgetGateway()..pinWidgetSupported = false;
    await pumpScreen(tester, gateway);

    await tester.tap(find.byIcon(Icons.add_to_home_screen));
    await tester.pumpAndSettle();

    expect(gateway.pinRequests, 1);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets(
    'configures the newly placed instance to this counter, once it appears',
    (tester) async {
      final gateway = FakeHomeWidgetGateway();
      final container = await pumpScreen(tester, gateway);

      await tester.tap(find.byIcon(Icons.add_to_home_screen));
      await tester.pump();

      // Stands in for the launcher finishing its own placement dialog,
      // asynchronously, sometime after the request was accepted.
      gateway.ids = [newWidgetId];
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        await container
            .read(widgetInstanceCounterRepositoryProvider)
            .pinnedFor(newWidgetId),
        ['Hacks'],
      );
      expect(gateway.written['widget_state_$newWidgetId'], 'data');
      expect(gateway.written['widget_label_0_$newWidgetId'], 'Hacks');
    },
  );

  testWidgets(
    'gives up quietly if no new instance appears within the poll window',
    (tester) async {
      final gateway = FakeHomeWidgetGateway();
      final container = await pumpScreen(tester, gateway);

      await tester.tap(find.byIcon(Icons.add_to_home_screen));
      await tester.pump();

      // No new id is ever reported -- the poll loop should exhaust itself
      // rather than hang or crash.
      await tester.pump(const Duration(seconds: 11));

      expect(gateway.written, isEmpty);
      expect(
        await container
            .read(widgetInstanceCounterRepositoryProvider)
            .pinnedFor(newWidgetId),
        isEmpty,
      );
    },
  );
}
