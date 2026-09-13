import 'package:fieldtally/domain/chart_target.dart';
import 'package:fieldtally/domain/counter_series.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/widgets/counter_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// A modest curve: 100 to 200 over four days.
CounterSeries series() => CounterSeries(
      points: [
        for (var i = 0; i < 4; i++)
          (at: DateTime(2026, 1, 1).add(Duration(days: i)), value: 100 + i * 33),
      ],
      range: ChartRange.all,
    );

Future<LineChartData> pumpChart(
  WidgetTester tester, {
  ChartTarget? target,
  String languageCode = 'en',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SizedBox(
          height: 200,
          child: CounterChart(series: series(), target: target),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return tester.widget<LineChart>(find.byType(LineChart)).data;
}

void main() {
  group('the target line (§3.5)', () {
    testWidgets('no target leaves the axis fitted to the data', (tester) async {
      final data = await pumpChart(tester);

      expect(data.maxY, lessThan(250));
      expect(data.extraLinesData.horizontalLines, isEmpty);
    });

    testWidgets('the axis stretches to hold the target', (tester) async {
      final data = await pumpChart(
        tester,
        target: const ChartTarget(value: 2000, kind: ChartTargetKind.goal),
      );

      expect(data.maxY, greaterThanOrEqualTo(2000));
      expect(data.extraLinesData.horizontalLines.single.y, 2000);
    });

    testWidgets('a distant target squashes the curve, deliberately',
        (tester) async {
      // The decision of #61, and the one most likely to be undone by accident
      // later: an agent who set themselves something out of reach should learn
      // it by looking. The curve keeping a comfortable share of the height
      // would mean the axis had stopped following the target.
      final data = await pumpChart(
        tester,
        target: const ChartTarget(value: 20000, kind: ChartTargetKind.goal),
      );

      final axisSpan = data.maxY - data.minY;
      const dataSpan = 99.0; // 100 to 199

      expect(dataSpan / axisSpan, lessThan(0.02));
    });

    testWidgets('a goal is named as one, with its value', (tester) async {
      await pumpChart(
        tester,
        target: const ChartTarget(value: 2000, kind: ChartTargetKind.goal),
      );

      final line =
          tester.widget<LineChart>(find.byType(LineChart)).data.extraLinesData
              .horizontalLines
              .single;

      expect(line.label.labelResolver(line), 'Goal · 2K');
      // Dashed, so colour is not the only thing telling it from the data line.
      expect(line.dashArray, isNotNull);
    });

    testWidgets('a badge is named by its tier', (tester) async {
      final data = await pumpChart(
        tester,
        target: const ChartTarget(
          value: 2000,
          kind: ChartTargetKind.badge,
          tierName: 'gold',
        ),
      );

      final line = data.extraLinesData.horizontalLines.single;
      expect(line.label.labelResolver(line), 'Gold · 2K');
    });

    testWidgets('it follows the locale', (tester) async {
      final data = await pumpChart(
        tester,
        target: const ChartTarget(value: 2000, kind: ChartTargetKind.goal),
        languageCode: 'fr',
      );

      final line = data.extraLinesData.horizontalLines.single;
      expect(line.label.labelResolver(line), startsWith('Objectif'));
    });

    testWidgets('a screen reader is told about the line', (tester) async {
      // §3.9: the chart is never the only carrier. The line is the one mark
      // that would otherwise be invisible to anyone not looking at it.
      await pumpChart(
        tester,
        target: const ChartTarget(value: 2000, kind: ChartTargetKind.goal),
      );

      final semantics = tester.getSemantics(find.byType(CounterChart));
      expect(semantics.label, contains('Goal · 2K'));
    });
  });
}
