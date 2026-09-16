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
import 'package:fieldtally/presentation/widgets/medal_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixed_registry.dart';
import 'support/fake_notification_service.dart';

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
    CounterRegistryNotifier Function() registry = fixedRegistry,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        // No test asks Android to post anything (§3.7).
        notificationServiceProvider.overrideWithValue(
          FakeNotificationService(),
        ),
        counterRegistryProvider.overrideWith(registry),
      ],
    );
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
      await repository.save(
        StatSnapshot(
          timeSpan: TimeSpan.allTime,
          agentName: 'AgentDemo',
          faction: 'Enlightened',
          recordedAt: DateTime(2026, 1, 1),
          level: 9,
          counters: const {'Unique Portals Visited': 9000, 'Hacks': 78000},
        ),
      );
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
    testWidgets('lists counters grouped by the in-game categories', (
      tester,
    ) async {
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

  group('badge emblems (#63)', () {
    testWidgets('a counter with a badge shows its emblem and names the tier', (
      tester,
    ) async {
      await pumpCounterList(tester);
      await search(tester, 'Unique Portals Visited');

      final tile = find.widgetWithText(ListTile, 'Unique Portals Visited');
      expect(
        find.descendant(of: tile, matching: find.byType(MedalIcon)),
        findsOneWidget,
      );
      // 9,756 portals: past gold at 2,000, short of platinum at 10,000. The
      // metal is a colour, so the tier is spelled out too (§3.9).
      expect(
        find.descendant(of: tile, matching: find.textContaining('Gold medal')),
        findsOneWidget,
      );
    });

    testWidgets('a counter with no badge is left exactly as it was', (
      tester,
    ) async {
      // Most counters have no thresholds; none of them should grow a medal
      // line, and none should show an emblem.
      await pumpCounterList(tester);
      await search(tester, 'Orion Tokens');

      final tile = find.widgetWithText(ListTile, 'Orion Tokens');
      expect(
        find.descendant(of: tile, matching: find.byType(MedalIcon)),
        findsNothing,
      );
      expect(
        find.descendant(of: tile, matching: find.textContaining('medal')),
        findsNothing,
      );
    });

    testWidgets('past onyx the tile carries the multiplier too (#87)', (
      tester,
    ) async {
      // The wiring, not the wording: the screen must hand the tile a
      // multiple, or the rule would live in the domain and never reach a row.
      final repository = await pumpCounterList(tester);

      // Narrowed before the new snapshot lands, so exactly one tile is laid
      // out. Pumping fifty rows of Ahem text into a 360-pixel window overflows
      // on subtitles this change does not touch: the test font makes every
      // glyph a full em square, which is not what a phone draws.
      await search(tester, 'Unique Portals Visited');

      // Carries every counter of the fixture, at its existing value, so only
      // Explorer has moved: a snapshot holding one counter would mark all the
      // others absent and the list would be answering a different question.
      final base = const IngressTsvParser().parseSingle(fixture(allTimePath));
      await repository.save(
        StatSnapshot(
          timeSpan: TimeSpan.allTime,
          agentName: 'AgentDemo',
          faction: 'Enlightened',
          recordedAt: DateTime(2026, 6, 1),
          // Explorer onyx is 30,000; 210,000 is seven whole times over.
          counters: {...base.counters, 'Unique Portals Visited': 210000},
          level: 9,
        ),
      );
      await tester.pumpAndSettle();

      final tile = find.widgetWithText(ListTile, 'Unique Portals Visited');
      expect(
        find.descendant(
          of: tile,
          matching: find.textContaining('Onyx medal \u00d77'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the detail screen shows the emblem of the tier reached', (
      tester,
    ) async {
      await pumpCounterList(tester);
      await search(tester, 'Unique Portals Visited');

      await tester.tap(find.widgetWithText(ListTile, 'Unique Portals Visited'));
      await tester.pumpAndSettle();

      expect(find.byType(MedalIcon), findsOneWidget);
      expect(find.textContaining('Gold medal'), findsOneWidget);
    });
  });

  group('search and ordering', () {
    testWidgets('search narrows the list down', (tester) async {
      await pumpCounterList(tester);
      await search(tester, 'portals');

      expect(find.text('Unique Portals Visited'), findsOneWidget);
      expect(find.text('Hacks'), findsNothing);
    });

    testWidgets('a search with no match says so instead of showing nothing', (
      tester,
    ) async {
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

    testWidgets('says plainly when no badge threshold is known', (
      tester,
    ) async {
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
    testWidgets('the French locale uses the registry translations', (
      tester,
    ) async {
      await pumpCounterList(tester, locale: const Locale('fr'));

      expect(find.text('Découverte'), findsOneWidget);
      expect(find.text('Portails uniques visités'), findsOneWidget);
    });
  });

  group('filtering and the controls row (#88, #89, #90)', () {
    testWidgets('the medal chip narrows the list to counters with a badge', (
      tester,
    ) async {
      // Two neighbours in the Discovery category, one with thresholds and one
      // without, so both are on screen before and the difference is the
      // filter rather than the scroll position.
      await pumpCounterList(tester);

      expect(find.text('Unique Portals Visited'), findsOneWidget);
      expect(find.text('Unique Portals Drone Visited'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Medals'));
      await tester.pumpAndSettle();

      expect(find.text('Unique Portals Visited'), findsOneWidget);
      expect(
        find.text('Unique Portals Drone Visited'),
        findsNothing,
        reason: 'the registry gives it no thresholds',
      );
    });

    testWidgets('the inactive filter is a named chip now, not a bare eye', (
      tester,
    ) async {
      // It was an IconButton with an eye and no word beside it. A second
      // unlabelled toggle next to it would have left the row unreadable.
      await pumpCounterList(tester);

      expect(find.widgetWithText(FilterChip, 'Inactive'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('the window appears only for the ordering that uses it', (
      tester,
    ) async {
      await pumpCounterList(tester);

      expect(find.text('Measured over'), findsNothing);

      await tester.tap(find.byType(DropdownButtonFormField<CounterSort>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recent progress').last);
      await tester.pumpAndSettle();

      expect(find.text('Measured over'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '7 days'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '30 days'), findsOneWidget);
    });

    testWidgets('ordering by proximity to the next tier is offered', (
      tester,
    ) async {
      await pumpCounterList(tester);

      await tester.tap(find.byType(DropdownButtonFormField<CounterSort>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Closest to next tier').last);
      await tester.pumpAndSettle();

      // No window for this one: it measures a position, not a rate.
      expect(find.text('Measured over'), findsNothing);
    });

    testWidgets('the filters compose with the search', (tester) async {
      await pumpCounterList(tester);
      await search(tester, 'Drone Visited');
      expect(find.text('Unique Portals Drone Visited'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Medals'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No counter matches'), findsOneWidget);
    });
  });

  group('the medal filter needs a registry (#88)', () {
    testWidgets('the chip is disabled until one has loaded', (tester) async {
      // Without thresholds nothing qualifies, so offering the filter would
      // empty the list and blame the agent's game for it.
      await pumpCounterList(tester, registry: pendingRegistry);

      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Medals'),
      );
      expect(chip.onSelected, isNull);
      expect(chip.isEnabled, isFalse);
    });
  });

  group('a ladder with no emblem to draw (#98)', () {
    // Apollo's Global Op medal is measured on a counter the registry already
    // knows. Its thresholds can reach an installed app through the registry
    // (§3.1.4); its emblem could only arrive in a release. The list has to
    // work in between, which is most of the time.

    testWidgets('the row names its tier like any other medal', (tester) async {
      await pumpCounterList(tester, registry: eventLadderRegistry);
      await search(tester, 'Apollo Mod Battle Points');

      final tile = find.widgetWithText(ListTile, 'Apollo Mod Battle Points');
      expect(
        find.descendant(of: tile, matching: find.textContaining('Gold medal')),
        findsOneWidget,
      );
    });

    testWidgets('and the filter no longer disagrees with the row', (
      tester,
    ) async {
      // The defect this closes: the Medals filter kept the counter, the
      // next-tier ordering ranked it, the detail screen named its tier — and
      // the row itself said nothing at all.
      await pumpCounterList(tester, registry: eventLadderRegistry);
      await tester.tap(find.widgetWithText(FilterChip, 'Medals'));
      await tester.pumpAndSettle();
      await search(tester, 'Apollo Mod Battle Points');

      final tile = find.widgetWithText(ListTile, 'Apollo Mod Battle Points');
      expect(tile, findsOneWidget, reason: 'the filter keeps it');
      expect(
        find.descendant(of: tile, matching: find.textContaining('medal')),
        findsOneWidget,
        reason: 'and the row now says so too',
      );
    });

    testWidgets('a counter with no ladder still says nothing', (tester) async {
      // Apollo Tokens carries no thresholds in this registry, so nothing about
      // it should change.
      await pumpCounterList(tester, registry: eventLadderRegistry);
      await search(tester, 'Apollo Tokens');

      final tile = find.widgetWithText(ListTile, 'Apollo Tokens');
      expect(
        find.descendant(of: tile, matching: find.textContaining('medal')),
        findsNothing,
      );
    });
  });
}
