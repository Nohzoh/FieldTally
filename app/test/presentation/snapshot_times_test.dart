// Times on snapshot dates (#75).
//
// Some agents record several snapshots a day. The app has always kept the
// time — it is rebuilt from the export's Date and Time columns, and the series
// plots every snapshot as its own point — but the two surfaces that read a
// moment back printed the day alone, so a morning and an evening snapshot
// looked like the same one twice.


import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/counter_series.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:fieldtally/presentation/widgets/counter_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notification_service.dart';
import '../support/fixed_registry.dart';

const _localisations = <LocalizationsDelegate<Object>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Two snapshots on the same day, morning and evening.
final _sameDay = [
  DateTime(2026, 3, 4, 9, 15),
  DateTime(2026, 3, 4, 20, 40),
];

StatSnapshot _snapshot(DateTime at, int hacks) => StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: at,
      level: 9,
      counters: {'Hacks': hacks},
    );

/// The tooltip labels the chart would draw for [points].
List<String> _tooltipLabels(LineChartData data, List<DateTime> points) {
  final bar = data.lineBarsData.first;
  final items = data.lineTouchData.touchTooltipData.getTooltipItems([
    for (final at in points)
      LineBarSpot(
        bar,
        0,
        bar.spots.firstWhere(
          (s) => s.x == at.millisecondsSinceEpoch.toDouble(),
        ),
      ),
  ]);
  return [for (final item in items) item?.text ?? ''];
}

Future<LineChartData> _pumpChart(
  WidgetTester tester, {
  required List<DateTime> at,
  String languageCode = 'en',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: _localisations,
      home: Scaffold(
        body: SizedBox(
          height: 200,
          child: CounterChart(
            series: CounterSeries(
              points: [
                for (var i = 0; i < at.length; i++)
                  (at: at[i], value: 100 + i * 50),
              ],
              range: ChartRange.all,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return tester.widget<LineChart>(find.byType(LineChart)).data;
}

void main() {
  group("the chart's tooltip", () {
    testWidgets('names the time, not only the day', (tester) async {
      final data = await _pumpChart(tester, at: _sameDay);

      expect(_tooltipLabels(data, _sameDay).first, contains('09:15'));
    });

    testWidgets('tells two snapshots of the same day apart', (tester) async {
      // The whole point: side by side on the curve, with nothing but the
      // label to say which one is being touched.
      final data = await _pumpChart(tester, at: _sameDay);
      final labels = _tooltipLabels(data, _sameDay);

      expect(labels.first, isNot(labels.last));
      expect(labels.last, contains('20:40'));
    });

    testWidgets('does so in French too', (tester) async {
      final data =
          await _pumpChart(tester, at: _sameDay, languageCode: 'fr');

      expect(_tooltipLabels(data, _sameDay).first, contains('09:15'));
    });
  });

  group('the history list under a counter', () {
    late FieldTallyDatabase db;
    late ProviderContainer container;

    Future<void> pumpDetail(
      WidgetTester tester, {
      required List<DateTime> at,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      db = FieldTallyDatabase(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        counterRegistryProvider.overrideWith(fixedRegistry),
        changelogCheckProvider.overrideWith((ref) async => const []),
      ]);
      addTearDown(db.close);
      addTearDown(container.dispose);

      final repository = container.read(snapshotRepositoryProvider);
      for (var i = 0; i < at.length; i++) {
        await repository.save(_snapshot(at[i], 1000 + i * 250));
      }

      final router = createRouter();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: _localisations,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(Routes.counterDetail('Hacks'));
      await tester.pumpAndSettle();
    }

    testWidgets('gives each snapshot of a day its own moment', (tester) async {
      // Two rows reading "4 Mar 2026" with different values and a delta
      // between them read as a bug rather than as two moments.
      await pumpDetail(tester, at: _sameDay);
      await tester.scrollUntilVisible(find.text('History'), 200);
      await tester.pumpAndSettle();

      expect(find.text('4 Mar 2026, 09:15'), findsOneWidget);
      expect(find.text('4 Mar 2026, 20:40'), findsOneWidget);
      expect(find.text('4 Mar 2026'), findsNothing);
    });

    testWidgets('shows the time even when nothing shares the day',
        (tester) async {
      // Always, rather than only when it disambiguates: a row whose label
      // depended on its neighbours would be rewritten by a later import.
      await pumpDetail(tester, at: [DateTime(2026, 3, 4, 9, 15)]);
      await tester.scrollUntilVisible(find.text('History'), 200);
      await tester.pumpAndSettle();

      expect(find.text('4 Mar 2026, 09:15'), findsOneWidget);
    });
  });

  group('the dates that are about a day, not a moment', () {
    test('keep the format that carries no time', () async {
      // shortDateFormat is shared by goal deadlines, projected badge dates,
      // "inactive since" and the shareable card. A time there would be a
      // meaningless 00:00 stamped on a day the agent typed themselves.
      for (final locale in [const Locale('en'), const Locale('fr')]) {
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(l10n.shortDateFormat, isNot(contains('HH')));
        expect(l10n.shortDateFormat, isNot(contains('mm')));
        expect(l10n.shortDateTimeFormat, contains('HH:mm'));
      }
    });
  });
}
