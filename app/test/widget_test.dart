import 'dart:io';

import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
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

  /// Mounts the whole app — router included — on an in-memory database and the
  /// real registry read from disk, so nothing is mocked.
  ///
  /// Tests run in English: assertions then match the template ARB rather than
  /// a translation, which keeps test code readable and stops a reworded French
  /// string from breaking unrelated tests. One dedicated test below checks
  /// that the French locale actually renders French.
  Future<SnapshotRepository> pumpApp(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    // The flutter_test default surface (800x600 logical) matches no phone: it
    // is too short, and a ListView will not build children below the fold —
    // which would make widgets unfindable for the wrong reasons. Simulate an
    // ordinary screen (360x800 logical).
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: createRouter(),
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

    return container.read(snapshotRepositoryProvider);
  }

  /// Pastes text into the field and runs the analysis.
  Future<void> analyze(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.widgetWithText(FilledButton, 'Analyze'));
    await tester.pumpAndSettle();
  }

  Future<void> goToAddScreen(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add a snapshot'));
    await tester.pumpAndSettle();
  }

  /// The snapshot list is no longer the home screen: the dashboard took its
  /// place (§3.3), and the destinations moved into the overflow menu so the
  /// app bar title stops being ellipsised on a narrow phone.
  Future<void> goToSnapshots(WidgetTester tester) async {
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
  }

  group('home screen', () {
    testWidgets('the dashboard says there is nothing to show yet',
        (tester) async {
      await pumpApp(tester);

      expect(find.text('Nothing to show yet'), findsOneWidget);
    });

    testWidgets('the snapshot list is reachable and empty', (tester) async {
      await pumpApp(tester);
      await goToSnapshots(tester);

      expect(find.text('No snapshot yet'), findsOneWidget);
    });

    testWidgets('leads to the add screen', (tester) async {
      await pumpApp(tester);
      await goToAddScreen(tester);

      expect(find.text('Text exported from Ingress'), findsOneWidget);
    });
  });

  group('preview before saving (§3.1)', () {
    testWidgets('a valid export shows the detected values', (tester) async {
      await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(allTimePath));

      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('AgentDemo'), findsOneWidget);
      expect(find.text('ALL TIME'), findsOneWidget);
      // All 59 counters are announced before anything is saved.
      expect(find.text('59'), findsOneWidget);
      expect(find.textContaining('Nothing is saved'), findsOneWidget);
    });

    testWidgets('counters are grouped by the in-game categories',
        (tester) async {
      await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(allTimePath));

      // Categories taken from the Ingress stats screen (Appendix A).
      expect(find.text('Discovery'), findsOneWidget);
      expect(find.text('Combat'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
    });

    testWidgets('nothing is stored until the user confirms', (tester) async {
      final repository = await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(allTimePath));

      expect(await repository.all(), isEmpty);
    });

    testWidgets('unreadable text shows an explicit error and nothing else',
        (tester) async {
      await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, 'this is not an Ingress export');

      expect(find.text('Could not read this text'), findsOneWidget);
      expect(find.text('Preview'), findsNothing);
    });
  });

  group('saving', () {
    testWidgets('confirming stores the snapshot and returns home',
        (tester) async {
      final repository = await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(allTimePath));

      await tester.tap(find.text('Save this snapshot'));
      await tester.pumpAndSettle();

      final all = await repository.all();
      expect(all, hasLength(1));
      expect(all.single.snapshot.counters, hasLength(59));
      // Saving returns to the dashboard, which now has something to show.
      expect(find.text('Nothing to show yet'), findsNothing);
    });
  });

  group('guards on screen (§3.1.3)', () {
    testWidgets('a WEEK export is flagged and the primary action refuses',
        (tester) async {
      await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(weekPath));

      expect(find.text('Partial period detected'), findsOneWidget);
      expect(find.textContaining('WEEK'), findsWidgets);

      // The prominent action is the one that protects the history; the
      // override is not a button sitting next to the message.
      expect(find.widgetWithText(FilledButton, 'Do not save'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save this snapshot'),
          findsNothing);
      expect(find.text('Save anyway…'), findsOneWidget);
    });

    testWidgets('on a small screen the reason stays visible without scrolling',
        (tester) async {
      // Regression seen on the emulator (320x640): the instructions and the
      // paste field filled the screen, so the decision buttons showed without
      // the message that justifies them.
      await pumpApp(tester);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      await goToAddScreen(tester);
      await analyze(tester, fixture(weekPath));

      final card = find.text('Partial period detected');
      expect(card, findsOneWidget);

      final rect = tester.getRect(card);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(640),
          reason: 'the blocking message must fit on screen');
    });

    testWidgets('overriding requires an explicit confirmation', (tester) async {
      final repository = await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(weekPath));

      await tester.tap(find.text('Save anyway…'));
      await tester.pumpAndSettle();

      expect(find.text('Save despite the anomaly?'), findsOneWidget);

      // Cancelling must store nothing.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await repository.all(), isEmpty);
    });

    testWidgets('confirming the override does store the snapshot',
        (tester) async {
      final repository = await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(weekPath));

      await tester.tap(find.text('Save anyway…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save anyway'));
      await tester.pumpAndSettle();

      expect(await repository.all(), hasLength(1));
    });

    testWidgets('a WEEK imported after an ALL TIME trips the behavioural guard',
        (tester) async {
      await pumpApp(tester);

      // First snapshot, legitimate.
      await goToAddScreen(tester);
      await analyze(tester, fixture(allTimePath));
      await tester.tap(find.text('Save this snapshot'));
      await tester.pumpAndSettle();

      // Second snapshot, wrong period: both guards fire.
      await goToAddScreen(tester);
      await analyze(tester, fixture(weekPath));

      expect(find.text('Partial period detected'), findsOneWidget);

      // The named list of drops is shown so the user can judge — the ten
      // largest, biggest first, then a count rather than a wall of 55 lines.
      // Matched on the full line, not just the counter name: the pasted
      // export is still on screen and contains every header verbatim.
      expect(
        find.textContaining('XM Collected: 248830242 → 3652350'),
        findsOneWidget,
      );
      expect(find.textContaining('and 45 more'), findsOneWidget);
    });
  });

  group('deleting', () {
    testWidgets('deleting asks for confirmation then removes the snapshot',
        (tester) async {
      final repository = await pumpApp(tester);
      await goToAddScreen(tester);
      await analyze(tester, fixture(allTimePath));
      await tester.tap(find.text('Save this snapshot'));
      await tester.pumpAndSettle();

      await goToSnapshots(tester);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete this snapshot?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(await repository.all(), isEmpty);
      expect(find.text('No snapshot yet'), findsOneWidget);
    });
  });

  group('localisation (§3.10)', () {
    testWidgets('the French locale renders French, including counter labels',
        (tester) async {
      await pumpApp(tester, locale: const Locale('fr'));

      expect(find.text('Rien à afficher pour l\'instant'), findsOneWidget);

      await tester.tap(
          find.widgetWithText(FloatingActionButton, 'Ajouter un relevé'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), fixture(allTimePath));
      await tester.tap(find.widgetWithText(FilledButton, 'Analyser'));
      await tester.pumpAndSettle();

      // App strings come from the .arb files…
      expect(find.text('Aperçu'), findsOneWidget);
      // …and counter categories from the registry's own translations.
      expect(find.text('Découverte'), findsOneWidget);
    });
  });
}
