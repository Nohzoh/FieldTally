import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/files/export_file_picker.dart';
import 'package:fieldtally/domain/repositories/snapshot_repository.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_export_file_picker.dart';
import 'support/fake_notification_service.dart';
import 'support/fixed_registry.dart';

/// What the app writes: a header naming its columns, and three snapshots.
const exportCsv =
    'date,time,agent,faction,time_span,level,Hacks,Unique Portals Visited\n'
    '2024-01-01,08:00:00,AgentDemo,Enlightened,allTime,9,9000,1200\n'
    '2025-01-01,08:00:00,AgentDemo,Enlightened,allTime,12,40000,4500\n'
    '2026-01-01,08:00:00,AgentDemo,Enlightened,allTime,14,78735,9756\n';

/// The same file after someone edited one row downwards.
const backwardsCsv =
    'date,time,agent,faction,time_span,level,Hacks\n'
    '2024-01-01,08:00:00,AgentDemo,Enlightened,allTime,9,9000\n'
    '2025-01-01,08:00:00,AgentDemo,Enlightened,allTime,12,400\n'
    '2026-01-01,08:00:00,AgentDemo,Enlightened,allTime,14,78735\n';

/// A row claiming a week rather than the all-time total.
const weekCsv =
    'date,time,agent,faction,time_span,level,Hacks\n'
    '2026-01-01,08:00:00,AgentDemo,Enlightened,week,14,78735\n';

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;
  late FakeExportFilePicker picker;

  Future<SnapshotRepository> pumpImport(
    WidgetTester tester, {
    String? csv,
    String name = 'fieldtally-2026-09-23.csv',
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    picker = FakeExportFilePicker(
      file: csv == null ? null : PickedFile(name: name, content: csv),
    );
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(
          FakeNotificationService(),
        ),
        counterRegistryProvider.overrideWith(fixedRegistry),
        exportFilePickerProvider.overrideWithValue(picker),
      ],
    );
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

    router.go(Routes.importFieldTally);
    await tester.pumpAndSettle();

    return container.read(snapshotRepositoryProvider);
  }

  Future<void> choose(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Choose a file'));
    await tester.pumpAndSettle();
  }

  group('restoring a FieldTally export (#191)', () {
    testWidgets('summarises what would land, and names the file', (
      tester,
    ) async {
      await pumpImport(tester, csv: exportCsv);
      await choose(tester);

      expect(find.text('fieldtally-2026-09-23.csv'), findsOneWidget);
      expect(find.textContaining('3 snapshots, 2 counters'), findsOneWidget);
      expect(find.text('Import 3 snapshots'), findsOneWidget);
    });

    testWidgets('nothing is written before confirming', (tester) async {
      final repository = await pumpImport(tester, csv: exportCsv);
      await choose(tester);

      expect(await repository.all(), isEmpty);
    });

    testWidgets('confirming brings the whole history back', (tester) async {
      final repository = await pumpImport(tester, csv: exportCsv);
      await choose(tester);

      await tester.tap(find.text('Import 3 snapshots'));
      await tester.pumpAndSettle();

      final all = await repository.all();
      expect(all, hasLength(3));
      // Newest first. The three things Agent Stats could never carry are the
      // point of this path, so they are what is checked.
      expect(all.first.snapshot.counters['Hacks'], 78735);
      expect(all.first.snapshot.agentName, 'AgentDemo');
      expect(all.first.snapshot.faction, 'Enlightened');
      expect(all.first.snapshot.level, 14);
    });

    testWidgets('says the export carries the snapshots and nothing else', (
      tester,
    ) async {
      await pumpImport(tester, csv: exportCsv);
      await choose(tester);

      expect(find.textContaining('Goals, pinned counters'), findsOneWidget);
    });

    testWidgets('backing out of the picker changes nothing on screen', (
      tester,
    ) async {
      await pumpImport(tester);
      await choose(tester);

      expect(picker.calls, 1);
      expect(find.textContaining('snapshots,'), findsNothing);
      expect(find.byType(Card), findsNothing);
    });
  });

  group('getting to the screen at all', () {
    testWidgets('the history screen offers both imports, each named', (
      tester,
    ) async {
      // The only way in. A screen nothing reaches is a screen that does not
      // exist, and the two formats are told apart by their names here rather
      // than by either importer guessing.
      await pumpImport(tester, csv: exportCsv);
      container.read(snapshotRepositoryProvider);

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
      router.go(Routes.snapshots);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Import'));
      await tester.pumpAndSettle();

      expect(find.text('Import from Agent Stats'), findsOneWidget);
      await tester.tap(find.text('Restore a FieldTally export'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Choose a file'),
        findsOneWidget,
      );
    });
  });

  group('what the file has to get past', () {
    testWidgets('a row that goes backwards blocks the import', (tester) async {
      await pumpImport(tester, csv: backwardsCsv);
      await choose(tester);

      expect(find.text('Inconsistent rows in this file'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Do not save'), findsOneWidget);
      expect(find.text('Import 3 snapshots'), findsNothing);
    });

    testWidgets('a row declaring a partial period blocks it too', (
      tester,
    ) async {
      // The guard Appendix B cannot run, because it declares no period. This
      // file does, so being blind to it here would be a choice rather than a
      // limitation.
      await pumpImport(tester, csv: weekCsv);
      await choose(tester);

      expect(
        find.textContaining('declares a period other than all time'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Do not save'), findsOneWidget);
      expect(find.text('Import 1 snapshots'), findsNothing);
    });

    testWidgets('a file that is not an export says so instead of failing', (
      tester,
    ) async {
      final repository = await pumpImport(
        tester,
        csv: 'Date ap lifetime_ap\n2024-01-01 1000 500000\n',
        name: 'agent-stats.csv',
      );
      await choose(tester);

      expect(find.text('Could not read this text'), findsOneWidget);
      expect(await repository.all(), isEmpty);
    });
  });
}
