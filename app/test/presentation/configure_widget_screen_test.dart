// The APPWIDGET_CONFIGURE screen (#181): what one widget instance saves, and
// what it tells Android and the widget itself once it does.

import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:fieldtally/presentation/screens/configure_widget_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_home_widget_gateway.dart';
import '../support/fixed_registry.dart';

const widgetId = 3;

Future<void> pumpScreen(
  WidgetTester tester,
  ProviderContainer container, {
  String? preselectedCounter,
}) async {
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
        home: ConfigureWidgetScreen(
          appWidgetId: widgetId,
          preselectedCounter: preselectedCounter,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FieldTallyDatabase db;
  late FakeHomeWidgetGateway gateway;
  late ProviderContainer container;

  setUp(() async {
    db = FieldTallyDatabase(NativeDatabase.memory());
    gateway = FakeHomeWidgetGateway();
    container = ProviderContainer(
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
            counters: const {'Hacks': 100, 'Recursions': 3},
          ),
        );
  });

  testWidgets('starts from this instance own selection, not from any other', (
    tester,
  ) async {
    await container.read(widgetInstanceCounterRepositoryProvider).setPinnedFor(
      widgetId,
      const ['Hacks'],
    );

    await pumpScreen(tester, container);

    final hacksTile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Hacks'),
    );
    final recursionsTile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Recursions'),
    );
    expect(hacksTile.value, isTrue);
    expect(recursionsTile.value, isFalse);
  });

  testWidgets('an empty selection cannot be saved', (tester) async {
    await pumpScreen(tester, container);

    final saveButton = tester.widget<TextButton>(find.byType(TextButton));
    expect(saveButton.onPressed, isNull);
  });

  testWidgets(
    'saving stores the selection, writes the widget at once, and tells '
    'Android configuring is done',
    (tester) async {
      await pumpScreen(tester, container);

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Hacks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        await container
            .read(widgetInstanceCounterRepositoryProvider)
            .pinnedFor(widgetId),
        ['Hacks'],
      );
      expect(gateway.written['widget_state_$widgetId'], 'data');
      expect(gateway.written['widget_label_0_$widgetId'], 'Hacks');
      expect(gateway.finishedConfiguring, [widgetId]);
    },
  );

  group('pinned from a counter\'s own screen (#181, path B)', () {
    testWidgets('a fresh instance starts pre-selected to that counter', (
      tester,
    ) async {
      await pumpScreen(tester, container, preselectedCounter: 'Recursions');

      final recursionsTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Recursions'),
      );
      expect(recursionsTile.value, isTrue);
    });

    testWidgets(
      'an instance already configured on its own ignores the preselection',
      (tester) async {
        await container
            .read(widgetInstanceCounterRepositoryProvider)
            .setPinnedFor(widgetId, const ['Hacks']);

        await pumpScreen(tester, container, preselectedCounter: 'Recursions');

        final hacksTile = tester.widget<CheckboxListTile>(
          find.widgetWithText(CheckboxListTile, 'Hacks'),
        );
        final recursionsTile = tester.widget<CheckboxListTile>(
          find.widgetWithText(CheckboxListTile, 'Recursions'),
        );
        expect(hacksTile.value, isTrue);
        expect(recursionsTile.value, isFalse);
      },
    );
  });
}
