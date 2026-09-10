import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:fieldtally/presentation/widgets/activity_heatmap.dart';
import 'package:fieldtally/presentation/widgets/counter_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixed_registry.dart';

const seedPath = 'assets/counters_registry_seed.json';

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

  Future<void> pumpAt(
    WidgetTester tester,
    String route, {
    required List<StatSnapshot> history,
  }) async {
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

    router.go(route);
    await tester.pumpAndSettle();
  }

  final twoMonths = [
    for (var day = 0; day < 45; day += 3)
      at(DateTime(2026, 1, 1).add(Duration(days: day)), {
        'Hacks': 70000 + day * 120,
        'Lifetime AP': 90000000 + day * 250000,
      }),
  ];

  group('counter chart (§3.5)', () {
    testWidgets('draws a chart once there are two snapshots', (tester) async {
      await pumpAt(tester, Routes.counterDetail('Hacks'), history: twoMonths);

      expect(find.byType(CounterChart), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('a single snapshot says a chart cannot be drawn',
        (tester) async {
      await pumpAt(
        tester,
        Routes.counterDetail('Hacks'),
        history: [at(DateTime(2026, 1, 1), const {'Hacks': 10})],
      );

      expect(find.textContaining('At least two snapshots'), findsOneWidget);
    });

    testWidgets('switching the range changes what is plotted', (tester) async {
      await pumpAt(tester, Routes.counterDetail('Hacks'), history: twoMonths);

      final all = tester
          .widget<CounterChart>(find.byType(CounterChart))
          .series
          .points
          .length;

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      final week = tester
          .widget<CounterChart>(find.byType(CounterChart))
          .series
          .points
          .length;

      expect(week, lessThan(all));
      expect(week, greaterThan(1), reason: 'a range must stay plottable');
    });

    testWidgets('the progress over the range is stated in words too',
        (tester) async {
      // §3.9: the chart is never the only carrier of information.
      await pumpAt(tester, Routes.counterDetail('Hacks'), history: twoMonths);

      expect(find.textContaining('over this period'), findsOneWidget);
    });

    testWidgets('the values stay listed under the chart', (tester) async {
      await pumpAt(
        tester,
        Routes.counterDetail('Hacks'),
        history: [
          at(DateTime(2026, 1, 1), const {'Hacks': 70000}),
          at(DateTime(2026, 1, 10), const {'Hacks': 78735}),
        ],
      );

      expect(find.text('History'), findsOneWidget);
      expect(find.text('78,735'), findsWidgets);
    });
  });

  group('activity calendar (§3.5)', () {
    testWidgets('appears above the snapshot list', (tester) async {
      await pumpAt(tester, Routes.snapshots, history: twoMonths);

      expect(find.byType(ActivityHeatmap), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
    });

    testWidgets('states in words what the squares mean', (tester) async {
      // The squares are AP measured on the day of the snapshot, not per-day
      // activity — worth saying rather than letting the calendar imply it.
      await pumpAt(tester, Routes.snapshots, history: twoMonths);

      expect(find.textContaining('on the day each snapshot was taken'),
          findsOneWidget);
      expect(find.textContaining('days with progress'), findsOneWidget);
    });

    testWidgets('a single snapshot says why there is nothing to show',
        (tester) async {
      await pumpAt(
        tester,
        Routes.snapshots,
        history: [at(DateTime(2026, 1, 1), const {'Lifetime AP': 100})],
      );

      expect(find.textContaining('Two snapshots are needed'), findsOneWidget);
    });
  });
}
