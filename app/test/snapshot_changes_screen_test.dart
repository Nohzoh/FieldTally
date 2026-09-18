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
import 'package:go_router/go_router.dart';

import 'support/fake_notification_service.dart';
import 'support/fixed_registry.dart';

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
  late GoRouter router;

  Future<List<StoredSnapshot>> pump(
    WidgetTester tester, {
    required List<StatSnapshot> history,
  }) async {
    // Ahem lays every glyph out as a filled em square, so text is far wider
    // here than on a phone. A tall viewport keeps the list from overflowing
    // for reasons that have nothing to do with the screen.
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(
          FakeNotificationService(),
        ),
        counterRegistryProvider.overrideWith(fixedRegistry),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);

    final repository = container.read(snapshotRepositoryProvider);
    for (final snapshot in history) {
      await repository.save(snapshot);
    }
    final stored = await repository.all();

    router = createRouter();
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

    return stored;
  }

  /// Sorted the way the screen sorts them, so an index means "the nth
  /// recorded" rather than "the nth row the database returned".
  List<StoredSnapshot> byDate(List<StoredSnapshot> stored) => [...stored]
    ..sort((a, b) => a.snapshot.recordedAt.compareTo(b.snapshot.recordedAt));

  group('what changed between two snapshots (#147)', () {
    testWidgets('lists the counters that moved, with both of their ends', (
      tester,
    ) async {
      final stored = await pump(
        tester,
        history: [
          at(DateTime(2026, 6, 13, 9, 12), const {
            'Hacks': 38,
            'Links Created': 7,
          }),
          at(DateTime(2026, 6, 13, 18, 40), const {
            'Hacks': 52,
            'Links Created': 7,
          }),
        ],
      );

      router.go(Routes.snapshotChanges(byDate(stored)[1].id));
      await tester.pumpAndSettle();

      expect(find.text('What changed'), findsOneWidget);
      expect(find.text('Hacks'), findsOneWidget);
      expect(find.text('38 → 52'), findsOneWidget);
      expect(find.text('+14'), findsOneWidget);

      // Unmoved counters are absent rather than shown as "+0".
      expect(find.text('Links Created'), findsNothing);

      // The span and the tally share one line, the way a counter tile joins
      // its tier and its delta — so this matches on the part, not the whole.
      expect(find.textContaining('1 counter moved'), findsOneWidget);
      expect(find.textContaining('less than a day'), findsOneWidget);
    });

    testWidgets('a counter that went down reads as a fall, not an error', (
      tester,
    ) async {
      // Current AP genuinely drops on a recursion.
      final stored = await pump(
        tester,
        history: [
          at(DateTime(2026, 6, 1), const {'Current AP': 24800000}),
          at(DateTime(2026, 6, 13), const {'Current AP': 0}),
        ],
      );

      router.go(Routes.snapshotChanges(byDate(stored)[1].id));
      await tester.pumpAndSettle();

      expect(find.text('−24,800,000'), findsOneWidget);
    });

    testWidgets('the earliest snapshot says it has nothing to compare to', (
      tester,
    ) async {
      final stored = await pump(
        tester,
        history: [
          at(DateTime(2026, 6, 13), const {'Hacks': 38}),
        ],
      );

      router.go(Routes.snapshotChanges(stored.single.id));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('nothing before it to compare against'),
        findsOneWidget,
      );
    });

    testWidgets('two identical snapshots say so rather than showing zeros', (
      tester,
    ) async {
      final stored = await pump(
        tester,
        history: [
          at(DateTime(2026, 6, 1), const {'Hacks': 38}),
          at(DateTime(2026, 6, 13), const {'Hacks': 38}),
        ],
      );

      router.go(Routes.snapshotChanges(byDate(stored)[1].id));
      await tester.pumpAndSettle();

      expect(find.text('Nothing moved between these two snapshots.'), findsOne);
    });
  });

  group('getting there', () {
    testWidgets('tapping a row in the snapshot list opens it', (tester) async {
      await pump(
        tester,
        history: [
          at(DateTime(2026, 6, 1), const {'Hacks': 38}),
          at(DateTime(2026, 6, 13), const {'Hacks': 52}),
        ],
      );

      router.go(Routes.snapshots);
      await tester.pumpAndSettle();

      // The most recent snapshot sits first in the list (§3.2).
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(find.text('What changed'), findsOneWidget);
      expect(find.text('+14'), findsOneWidget);
    });
  });
}
