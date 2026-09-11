import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
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
import 'support/fake_notification_service.dart';

StatSnapshot at(DateTime date, Map<String, int> counters) => StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: date,
      level: 9,
      counters: counters,
    );

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;

  Future<List<StoredSnapshot>> pumpEdit(
    WidgetTester tester, {
    required List<StatSnapshot> history,
    int editIndex = 0,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      // No test asks Android to post anything (§3.7).
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
      counterRegistryProvider.overrideWith(fixedRegistry),
    ]);
    // Dispose the container before closing the database: closing Drift while a
    // stream query is still subscribed hangs.
    addTearDown(db.close);
    addTearDown(container.dispose);

    final repository = container.read(snapshotRepositoryProvider);
    for (final snapshot in history) {
      await repository.save(snapshot);
    }
    final stored = await repository.all();

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

    router.go(Routes.editSnapshot(stored[editIndex].id));
    await tester.pumpAndSettle();

    return stored;
  }

  Future<void> setCounter(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    final field = find.widgetWithText(TextField, label);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  group('correcting a snapshot (§3.2)', () {
    testWidgets('opens with the stored values', (tester) async {
      await pumpEdit(tester, history: [
        at(DateTime(2026, 1, 15), const {'Hacks': 78735}),
      ]);

      expect(find.text('Correct this snapshot'), findsOneWidget);
      expect(find.text('78735'), findsOneWidget);
    });

    testWidgets('saves a corrected value', (tester) async {
      final stored = await pumpEdit(tester, history: [
        at(DateTime(2026, 1, 15), const {'Hacks': 78735}),
      ]);

      await setCounter(tester, 'Hacks', '78000');
      await tester.tap(find.text('Save the correction'));
      await tester.pumpAndSettle();

      final repository = container.read(snapshotRepositoryProvider);
      final all = await repository.all();
      expect(all.single.id, stored.single.id, reason: 'same snapshot, edited');
      expect(all.single.snapshot.counters['Hacks'], 78000);
    });

    testWidgets('an unreadable value blocks saving rather than reverting',
        (tester) async {
      await pumpEdit(tester, history: [
        at(DateTime(2026, 1, 15), const {'Hacks': 78735}),
      ]);

      await setCounter(tester, 'Hacks', '-');
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save the correction'),
      );

      expect(button.onPressed, isNull);
      expect(find.text('Whole numbers only'), findsOneWidget);
    });

    testWidgets('correcting keeps the snapshot rather than adding one',
        (tester) async {
      await pumpEdit(tester, history: [
        at(DateTime(2026, 1, 1), const {'Hacks': 100}),
        at(DateTime(2026, 1, 15), const {'Hacks': 200}),
      ], editIndex: 0);

      await setCounter(tester, 'Hacks', '250');
      await tester.tap(find.text('Save the correction'));
      await tester.pumpAndSettle();

      expect(await container.read(snapshotRepositoryProvider).all(),
          hasLength(2));
    });
  });

  group('the consistency check follows the correction (§3.1.3)', () {
    testWidgets('warns when the correction would break the sequence',
        (tester) async {
      // Editing the middle of a series is another way to put a wrong number in
      // the history; guarding the import and not this would be odd.
      await pumpEdit(tester, history: [
        at(DateTime(2026, 1, 1), const {'Hacks': 100}),
        at(DateTime(2026, 1, 15), const {'Hacks': 200}),
      ], editIndex: 0);

      expect(find.text('This correction breaks the sequence'), findsNothing);

      await setCounter(tester, 'Hacks', '50');
      expect(find.text('This correction breaks the sequence'), findsOneWidget);
    });

    testWidgets('warns without blocking, unlike an import', (tester) async {
      // A correction is a deliberate act on a snapshot the agent is already
      // looking at, and the sequence being mended may look odd mid-edit.
      await pumpEdit(tester, history: [
        at(DateTime(2026, 1, 1), const {'Hacks': 100}),
        at(DateTime(2026, 1, 15), const {'Hacks': 200}),
      ], editIndex: 0);

      await setCounter(tester, 'Hacks', '50');
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save the correction'),
      );

      expect(button.onPressed, isNotNull);
    });
  });
}
