import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/repositories/settings_repository.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fieldtally/data/registry/counter_registry_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      // No test touches the real network. This one always fails, which is also
      // the case that must leave the app fully usable.
      counterRegistryServiceProvider.overrideWith(
        (ref) => CounterRegistryService(
          settings: ref.watch(settingsRepositoryProvider),
          client: MockClient((_) async => http.Response('nope', 503)),
        ),
      ),
    ]);
    // Dispose the container before closing the database: closing Drift while a
    // stream query is still subscribed hangs.
    addTearDown(db.close);
    addTearDown(container.dispose);

    final router = createRouter();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.go(Routes.settings);
    await tester.pumpAndSettle();

    // No startup refresh here: the registry now resolves locally and the fetch
    // is an explicit startup task, so a test only touches the network when it
    // means to.
    await tester.pumpAndSettle();
  }

  group('settings (§3.1.4)', () {
    testWidgets('online updates are on by default', (tester) async {
      await pumpSettings(tester);

      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.value, isTrue);
    });

    testWidgets('says what is downloaded and that nothing is sent',
        (tester) async {
      // This is the only network request in the whole of v1, so the wording
      // has to be plain rather than reassuring.
      await pumpSettings(tester);

      expect(find.textContaining('Nothing about you'), findsOneWidget);
      expect(find.textContaining('entirely offline'), findsOneWidget);
    });

    testWidgets('turning it off is persisted', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(
        await container
            .read(settingsRepositoryProvider)
            .read(SettingKeys.onlineRegistryUpdates),
        'false',
      );
      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.value, isFalse);
    });

    testWidgets('carries the non-affiliation notice', (tester) async {
      await pumpSettings(tester);

      expect(find.textContaining('not affiliated with Niantic'), findsOneWidget);
    });
  });

  group('reaching settings', () {
    testWidgets('from the dashboard overflow menu', (tester) async {
      await pumpSettings(tester);
      // Land back on the dashboard first.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsOneWidget);
    });
  });
}
