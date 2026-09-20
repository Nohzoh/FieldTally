// Pinning a widget straight from a counter's own screen (#181, path B).

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
  testWidgets('asks the gateway to pin this counter', (tester) async {
    final gateway = FakeHomeWidgetGateway();
    await pumpScreen(tester, gateway);

    await tester.tap(find.byIcon(Icons.add_to_home_screen));
    await tester.pumpAndSettle();

    expect(gateway.pinRequests, ['Hacks']);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('tells the user when their launcher does not support this', (
    tester,
  ) async {
    final gateway = FakeHomeWidgetGateway()..pinWidgetSupported = false;
    await pumpScreen(tester, gateway);

    await tester.tap(find.byIcon(Icons.add_to_home_screen));
    await tester.pumpAndSettle();

    expect(gateway.pinRequests, ['Hacks']);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
