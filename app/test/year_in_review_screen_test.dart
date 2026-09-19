import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
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

  Future<void> pump(
    WidgetTester tester, {
    required List<StatSnapshot> history,
  }) async {
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

    router.go(Routes.yearInReview);
    await tester.pumpAndSettle();
  }

  group('a year read back (#153)', () {
    testWidgets('opens on the most recent year with history in it', (
      tester,
    ) async {
      // Not the calendar year: on 2 January there is nothing in it yet, and an
      // empty screen is a poor way to open a recap.
      await pump(
        tester,
        history: [
          at(DateTime(2025, 12, 28), const {'Hacks': 500}),
          at(DateTime(2026, 12, 20), const {'Hacks': 12000}),
        ],
      );

      expect(find.text('2026 in review'), findsOneWidget);
    });

    testWidgets('names what moved and by how much', (tester) async {
      await pump(
        tester,
        history: [
          at(DateTime(2025, 12, 28), const {'Hacks': 500}),
          at(DateTime(2026, 12, 20), const {'Hacks': 12000}),
        ],
      );

      expect(find.text('What moved'), findsOneWidget);
      expect(find.text('Hacks'), findsOneWidget);
      expect(find.text('+11,500'), findsOneWidget);
    });

    testWidgets('names the medals crossed during it', (tester) async {
      // Hacks: bronze at 2 000, silver at 10 000 in the real registry.
      await pump(
        tester,
        history: [
          at(DateTime(2025, 12, 28), const {'Hacks': 500}),
          at(DateTime(2026, 12, 20), const {'Hacks': 12000}),
        ],
      );

      expect(find.text('Medals crossed'), findsOneWidget);
      expect(find.text('Hacks · Bronze'), findsOneWidget);
      expect(find.text('Hacks · Silver'), findsOneWidget);
    });

    testWidgets(
      'says when it covers only part of the year, before the totals',
      (tester) async {
        await pump(
          tester,
          history: [
            at(DateTime(2026, 9, 1), const {'Hacks': 1000}),
            at(DateTime(2026, 12, 20), const {'Hacks': 4000}),
          ],
        );

        expect(find.textContaining('covers part of the year'), findsOneWidget);
      },
    );

    testWidgets('carries the caveat about what was recorded', (tester) async {
      await pump(
        tester,
        history: [
          at(DateTime(2026, 1, 1), const {'Hacks': 0}),
          at(DateTime(2026, 5, 1), const {'Hacks': 1000}),
        ],
      );

      expect(
        find.textContaining('describes what you recorded'),
        findsOneWidget,
      );
    });

    testWidgets('a year too thin to read back says so', (tester) async {
      await pump(
        tester,
        history: [
          at(DateTime(2026, 6, 1), const {'Hacks': 1000}),
        ],
      );

      expect(find.textContaining('not enough history'), findsOneWidget);
      expect(find.text('What moved'), findsNothing);
    });
  });
}
