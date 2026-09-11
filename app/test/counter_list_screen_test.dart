import 'dart:io';

import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/parsing/ingress_tsv_parser.dart';
import 'package:fieldtally/domain/counter_list.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/repositories/snapshot_repository.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixed_registry.dart';

const allTimePath = 'test/fixtures/sample_export_all_time.tsv';
const weekPath = 'test/fixtures/sample_export_week.tsv';
const seedPath = 'assets/counters_registry_seed.json';

String fixture(String path) => File(path).readAsStringSync();

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;

  /// Mounts the app straight on the counter list, on an in-memory database
  /// seeded with real fixtures.
  Future<SnapshotRepository> pumpCounterList(
    WidgetTester tester, {
    bool withHistory = false,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      counterRegistryProvider.overrideWith(fixedRegistry),
    ]);
    // Order matters: tearDowns run last-registered-first, so the container is
    // disposed before the database is closed. Closing Drift while a stream
    // query is still subscribed hangs, and the dashboard adds a second one on
    // top of the snapshots stream.
    addTearDown(db.close);
    addTearDown(container.dispose);

    final repository = container.read(snapshotRepositoryProvider);
    const parser = IngressTsvParser();

    // A single snapshot leaves every delta unknown; two give the list
    // something to compare, which is what "recent progress" sorts on.
    //
    // The earlier point is synthetic rather than the WEEK fixture: both
    // fixtures are stamped the same day, and the WEEK one is actually ten
    // minutes *later*, so using it as history would build a timeline the
    // import guards exist to prevent.
    if (withHistory) {
      await repository.save(StatSnapshot(
        timeSpan: TimeSpan.allTime,
        agentName: 'AgentDemo',
        faction: 'Enlightened',
        recordedAt: DateTime(2026, 1, 1),
        level: 9,
        counters: const {'Unique Portals Visited': 9000, 'Hacks': 78000},
      ));
    }
    await repository.save(parser.parseSingle(fixture(allTimePath)));

    final router = createRouter();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
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

    router.go(Routes.counters);
    await tester.pumpAndSettle();

    return repository;
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pumpAndSettle();
  }

  group('counter list (§3.4)', () {
    testWidgets('lists counters grouped by the in-game categories',
        (tester) async {
      await pumpCounterList(tester);

      expect(find.text('Discovery'), findsOneWidget);
      expect(find.text('Unique Portals Visited'), findsOneWidget);
    });

    testWidgets('shows the current value of a counter', (tester) async {
      await pumpCounterList(tester);

      // 9,756 unique portals in the ALL TIME fixture.
      expect(find.text('9,756'), findsOneWidget);
    });

    testWidgets('a single snapshot leaves the delta unknown', (tester) async {
      await pumpCounterList(tester);

      expect(find.textContaining('no comparison yet'), findsWidgets);
    });

    testWidgets('with two snapshots it shows the progress', (tester) async {
      await pumpCounterList(tester, withHistory: true);
      await search(tester, 'Unique Portals Visited');

      // 9,756 - 9,000 since the earlier snapshot.
      expect(find.textContaining('+756'), findsOneWidget);
    });
  });

  group('search and ordering', () {
    testWidgets('search narrows the list down', (tester) async {
      await pumpCounterList(tester);
      await search(tester, 'portals');

      expect(find.text('Unique Portals Visited'), findsOneWidget);
      expect(find.text('Hacks'), findsNothing);
    });

    testWidgets('a search with no match says so instead of showing nothing',
        (tester) async {
      await pumpCounterList(tester);
      await search(tester, 'zzzz');

      expect(find.textContaining('No counter matches'), findsOneWidget);
    });

    testWidgets('sorting by name flattens the categories', (tester) async {
      await pumpCounterList(tester);

      await tester.tap(find.byType(DropdownButtonFormField<CounterSort>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name').last);
      await tester.pumpAndSettle();

      // Category headings disappear once the list is flat.
      expect(find.text('Discovery'), findsNothing);
    });
  });

  group('counter detail', () {
    testWidgets('tapping a counter opens its history', (tester) async {
      await pumpCounterList(tester, withHistory: true);
      await search(tester, 'Unique Portals Visited');

      // Tap the row, not the search field, which now holds the same text.
      await tester.tap(find.widgetWithText(ListTile, 'Unique Portals Visited'));
      await tester.pumpAndSettle();

      // Checked before scrolling: the summary sits at the top and is disposed
      // once the list moves past it.
      expect(find.text('Current value'), findsOneWidget);
      // The raw export header is surfaced: it is what a contributor needs in
      // order to declare the counter in the registry.
      expect(find.text('Export header'), findsOneWidget);

      // The projection and goal cards now sit between the summary and the
      // history, so the heading starts well below the fold.
      await tester.scrollUntilVisible(find.text('History'), 200);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('says plainly when no badge threshold is known', (tester) async {
      // Most counters have none — anomaly counters never will — and saying so
      // beats leaving an empty space.
      await pumpCounterList(tester);
      await search(tester, 'Orion Tokens');

      await tester.tap(find.widgetWithText(ListTile, 'Orion Tokens'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No badge threshold'), findsOneWidget);
    });
  });

  group('localisation', () {
    testWidgets('the French locale uses the registry translations',
        (tester) async {
      await pumpCounterList(tester, locale: const Locale('fr'));

      expect(find.text('Découverte'), findsOneWidget);
      expect(find.text('Portails uniques visités'), findsOneWidget);
    });
  });
}
