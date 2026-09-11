import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:fieldtally/presentation/widgets/badge_projection_card.dart';
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

  Future<void> pumpDetail(
    WidgetTester tester,
    String header, {
    required List<StatSnapshot> history,
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

    for (final snapshot in history) {
      await container.read(snapshotRepositoryProvider).save(snapshot);
    }

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

    router.go(Routes.counterDetail(header));
    await tester.pumpAndSettle();
  }

  /// Ten portals a day for a fortnight, sitting between silver and gold.
  List<StatSnapshot> steadyExplorer() => [
        for (var day = 0; day < 14; day++)
          at(DateTime(2026, 1, 1).add(Duration(days: day)),
              {'Unique Portals Visited': 1400 + day * 10}),
      ];

  group('badge projection (§3.6)', () {
    testWidgets('shows the next tier and what is left', (tester) async {
      await pumpDetail(tester, 'Unique Portals Visited',
          history: steadyExplorer());

      expect(find.byType(BadgeProjectionCard), findsOneWidget);
      expect(find.text('Next badge'), findsOneWidget);
      expect(find.textContaining('to go for Gold'), findsOneWidget);
    });

    testWidgets('states the projected date and the pace in words',
        (tester) async {
      // §3.9: the progress bar is never the only carrier of information.
      await pumpDetail(tester, 'Unique Portals Visited',
          history: steadyExplorer());

      expect(find.textContaining('at your recent pace'), findsOneWidget);
      expect(find.textContaining('per day'), findsOneWidget);
    });

    testWidgets('a stalled counter gets no date rather than a wrong one',
        (tester) async {
      await pumpDetail(tester, 'Unique Portals Visited', history: [
        for (var day = 0; day < 5; day++)
          at(DateTime(2026, 1, 1).add(Duration(days: day)),
              const {'Unique Portals Visited': 1400}),
      ]);

      expect(find.textContaining('has not moved lately'), findsOneWidget);
      expect(find.textContaining('at your recent pace'), findsNothing);
    });

    testWidgets('onyx reached leaves nothing to chase', (tester) async {
      await pumpDetail(tester, 'Unique Portals Visited', history: [
        at(DateTime(2026, 1, 1), const {'Unique Portals Visited': 40000}),
        at(DateTime(2026, 1, 2), const {'Unique Portals Visited': 40100}),
      ]);

      expect(find.textContaining('Onyx reached'), findsOneWidget);
    });

    testWidgets('a counter without thresholds shows no card', (tester) async {
      await pumpDetail(tester, 'Orion Tokens', history: [
        at(DateTime(2026, 1, 1), const {'Orion Tokens': 100}),
        at(DateTime(2026, 1, 2), const {'Orion Tokens': 200}),
      ]);

      expect(find.byType(BadgeProjectionCard), findsNothing);
      expect(find.textContaining('No badge threshold'), findsOneWidget);
    });

    testWidgets('the pace window is labelled apart from the chart range',
        (tester) async {
      // Two segmented controls sit on this screen; sharing "Week / Month"
      // between them read as the same control twice.
      await pumpDetail(tester, 'Unique Portals Visited',
          history: steadyExplorer());

      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget, reason: 'the chart range');
    });

    testWidgets('switching the window changes the pace used', (tester) async {
      // Slow for a month, then a burst: the two windows must disagree.
      await pumpDetail(tester, 'Unique Portals Visited', history: [
        for (var day = 0; day < 28; day++)
          at(DateTime(2026, 1, 1).add(Duration(days: day)),
              {'Unique Portals Visited': 1400 + day}),
        for (var day = 0; day < 3; day++)
          at(DateTime(2026, 1, 29).add(Duration(days: day)),
              {'Unique Portals Visited': 1500 + day * 100}),
      ]);

      String paceLine() => tester
          .widgetList<Text>(find.textContaining('per day'))
          .first
          .data!;

      final monthly = paceLine();
      // The card sits below the chart, so the segment has to be brought into
      // view before it can be tapped.
      await tester.ensureVisible(find.text('Last 7 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();

      expect(paceLine(), isNot(monthly));
    });
  });
}
