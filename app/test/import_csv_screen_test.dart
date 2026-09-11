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

/// Three years of history, the way an agent migrating would have it.
const goodCsv = 'Date ap lifetime_ap explorer hacker\n'
    '2024-01-01 1000 500000 1200 9000\n'
    '2025-01-01 2000 900000 4500 40000\n'
    '2026-01-01 3281218 101542335 9756 78735';

/// The same file with one row that goes backwards, in the middle.
const badCsv = 'Date ap lifetime_ap explorer hacker\n'
    '2024-01-01 1000 500000 1200 9000\n'
    '2025-01-01 2000 900000 400 40000\n'
    '2026-01-01 3281218 101542335 9756 78735';

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;

  Future<SnapshotRepository> pumpImport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      counterRegistryProvider.overrideWith(fixedRegistry),
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

    router.go(Routes.importCsv);
    await tester.pumpAndSettle();

    return container.read(snapshotRepositoryProvider);
  }

  Future<void> analyze(WidgetTester tester, String csv) async {
    await tester.enterText(find.byType(TextField), csv);
    await tester.tap(find.widgetWithText(FilledButton, 'Analyze'));
    await tester.pumpAndSettle();
  }

  group('migration import (Appendix B)', () {
    testWidgets('summarises what would land', (tester) async {
      await pumpImport(tester);
      await analyze(tester, goodCsv);

      expect(find.textContaining('3 snapshots, 4 counters'), findsOneWidget);
      expect(find.textContaining('From'), findsOneWidget);
      expect(find.text('Import 3 snapshots'), findsOneWidget);
    });

    testWidgets('nothing is written before confirming', (tester) async {
      final repository = await pumpImport(tester);
      await analyze(tester, goodCsv);

      expect(await repository.all(), isEmpty);
    });

    testWidgets('confirming imports the whole history', (tester) async {
      final repository = await pumpImport(tester);
      await analyze(tester, goodCsv);

      await tester.tap(find.text('Import 3 snapshots'));
      await tester.pumpAndSettle();

      final all = await repository.all();
      expect(all, hasLength(3));
      // Newest first, and the Agent Stats keys became export headers.
      expect(all.first.snapshot.counters['Lifetime AP'], 101542335);
      expect(all.first.snapshot.counters['Unique Portals Visited'], 9756);
    });

    testWidgets('says out loud that this format has no period column',
        (tester) async {
      // On this path the declarative guard simply does not exist, which is
      // worth stating rather than leaving implicit.
      await pumpImport(tester);
      await analyze(tester, goodCsv);

      expect(find.textContaining('no period column'), findsOneWidget);
    });
  });

  group('a bad row anywhere in the file', () {
    testWidgets('is caught and blocks the import', (tester) async {
      await pumpImport(tester);
      await analyze(tester, badCsv);

      expect(find.text('Inconsistent rows in this file'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Do not save'), findsOneWidget);
      expect(find.text('Import 3 snapshots'), findsNothing);
    });

    testWidgets('names the date and the counter', (tester) async {
      await pumpImport(tester);
      await analyze(tester, badCsv);

      // 1200 in 2024, 400 in 2025: the bad row is the middle one.
      expect(find.textContaining('Unique Portals Visited: 1200 → 400'),
          findsOneWidget);
    });

    testWidgets('overriding takes a separate action and a confirmation',
        (tester) async {
      final repository = await pumpImport(tester);
      await analyze(tester, badCsv);

      await tester.tap(find.text('Save anyway…'));
      await tester.pumpAndSettle();
      expect(find.text('Save despite the anomaly?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await repository.all(), isEmpty);
    });
  });

  testWidgets('an imported snapshot shows no level rather than "null"',
      (tester) async {
    // The Agent Stats format has no level column, so the field is genuinely
    // absent — printing the absence would be worse than saying so.
    await pumpImport(tester);
    await analyze(tester, goodCsv);
    await tester.tap(find.text('Import 3 snapshots'));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsWidgets);
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('an unreadable file shows the parser error', (tester) async {
    await pumpImport(tester);
    await analyze(tester, 'this is not a CSV');

    expect(find.text('Could not read this text'), findsOneWidget);
  });
}
