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

    router.go(Routes.withinReach);
    await tester.pumpAndSettle();
  }

  group('badges within reach (#148)', () {
    testWidgets('names the tier being chased and how long it would take', (
      tester,
    ) async {
      // Hacks: bronze at 2 000 in the real registry. 1 400 → 1 700 over ten
      // days is 30/day, so bronze is ten days out.
      await pump(
        tester,
        history: [
          at(DateTime(2026, 6, 1), const {'Hacks': 1400}),
          at(DateTime(2026, 6, 11), const {'Hacks': 1700}),
        ],
      );

      expect(find.text('Within reach'), findsOneWidget);
      expect(find.text('Hacks'), findsOneWidget);
      expect(find.textContaining('about 10 days'), findsOneWidget);

      // The window is stated rather than assumed: the ranking changes with it.
      expect(find.text('At your pace over the last 30 days'), findsOneWidget);
    });

    testWidgets('a stalled counter is absent, and the screen says why', (
      tester,
    ) async {
      await pump(
        tester,
        history: [
          at(DateTime(2026, 6, 1), const {'Hacks': 1400}),
          at(DateTime(2026, 6, 11), const {'Hacks': 1400}),
        ],
      );

      expect(
        find.text('No badge is within reach at your recent pace.'),
        findsOneWidget,
      );
      expect(find.textContaining('would be a guess'), findsOneWidget);
    });

    testWidgets('one snapshot says there is no pace yet, not no progress', (
      tester,
    ) async {
      // The distinction matters: "nothing is within reach" reads as a verdict
      // on the agent, and with a single snapshot there is simply nothing to
      // measure.
      await pump(
        tester,
        history: [
          at(DateTime(2026, 6, 1), const {'Hacks': 1400}),
        ],
      );

      expect(
        find.text('Two snapshots are needed before a pace can be measured.'),
        findsOneWidget,
      );
    });

    testWidgets('ranks by time, so it disagrees with the list\'s own sort', (
      tester,
    ) async {
      // Real thresholds. Hacks: bronze at 2 000, and 1 000 → 1 600 over ten
      // days is 60/day, so bronze is under seven days out at 80 % of the
      // stretch. Unique Portals Visited: bronze at 100, and 90 → 92 is
      // 0.2/day, so bronze is forty days out at 92 % of the stretch.
      //
      // The counter list, which sorts on that share, would put them the other
      // way round. This is the whole reason the screen exists, so it is
      // asserted where an agent would actually read it.
      await pump(
        tester,
        history: [
          at(DateTime(2026, 6, 1), const {
            'Hacks': 1000,
            'Unique Portals Visited': 90,
          }),
          at(DateTime(2026, 6, 11), const {
            'Hacks': 1600,
            'Unique Portals Visited': 92,
          }),
        ],
      );

      final titles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data)
          .toList();

      expect(titles, ['Hacks', 'Unique Portals Visited']);
      expect(find.textContaining('about 7 days'), findsOneWidget);
      expect(find.textContaining('about 40 days'), findsOneWidget);
    });

    testWidgets('tapping a row opens that counter', (tester) async {
      await pump(
        tester,
        history: [
          at(DateTime(2026, 6, 1), const {'Hacks': 1400}),
          at(DateTime(2026, 6, 11), const {'Hacks': 1700}),
        ],
      );

      await tester.tap(find.text('Hacks'));
      await tester.pumpAndSettle();

      // The counter detail screen, where the full projection card lives. Its
      // app bar carries the counter's own label, which is what says we landed
      // on the right one rather than merely leaving this screen.
      expect(find.widgetWithText(AppBar, 'Hacks'), findsOneWidget);
      expect(find.text('Within reach'), findsNothing);
    });
  });
}
