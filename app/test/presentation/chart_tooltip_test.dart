// The tooltip on a counter's chart (#82).
//
// Three defects shipped together in 1.3.0, all invisible to the suite that
// was green at the time: the timestamp broke across two lines after its
// comma, the value underneath read as the tail of that timestamp, and both
// were painted in near-black on a dark box. None of them throws, none of them
// overflows, and none of them can be caught by pumping and asserting text.
// They are caught by measuring and by computing contrast.

import 'package:fieldtally/domain/counter_series.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/widgets/counter_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// A day with two snapshots, so the timestamp carries its longest form.
final _points = [
  DateTime(2026, 9, 13, 9, 15),
  DateTime(2026, 9, 13, 21, 20),
  DateTime(2026, 9, 14, 21, 20),
];

Future<LineChartData> pumpChart(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  String languageCode = 'en',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness, useMaterial3: true),
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
          child: CounterChart(
            series: CounterSeries(
              points: [
                for (var i = 0; i < _points.length; i++)
                  (at: _points[i], value: 28897 + i * 1000),
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

LineTooltipItem _itemFor(LineChartData data, DateTime at) {
  final bar = data.lineBarsData.first;
  final spot = bar.spots.firstWhere(
    (s) => s.x == at.millisecondsSinceEpoch.toDouble(),
  );
  return data.lineTouchData.touchTooltipData.getTooltipItems([
    LineBarSpot(bar, 0, spot),
  ]).first!;
}

/// WCAG relative luminance.
double _luminance(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final l1 = _luminance(a), l2 = _luminance(b);
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('the timestamp holds one line', () {
    testWidgets('the box is wide enough for the longest form it can show', (
      tester,
    ) async {
      // Measured against the very style the widget paints with, rather than
      // trusting a number. fl_chart lays the text out with maxContentWidth as
      // its maxWidth, so anything wider wraps — which is precisely what broke
      // "13 Sep 2026, 21:20" after the comma.
      final data = await pumpChart(tester);
      final item = _itemFor(data, _points[1]);

      final painter = TextPainter(
        text: TextSpan(text: item.text, style: item.textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      expect(
        data.lineTouchData.touchTooltipData.maxContentWidth,
        greaterThanOrEqualTo(painter.width),
        reason:
            'the timestamp "${item.text}" needs ${painter.width} and the '
            'tooltip caps at ${data.lineTouchData.touchTooltipData.maxContentWidth}',
      );
    });

    testWidgets('and in French, where the month abbreviations differ', (
      tester,
    ) async {
      final data = await pumpChart(tester, languageCode: 'fr');
      final item = _itemFor(data, _points[1]);

      final painter = TextPainter(
        text: TextSpan(text: item.text, style: item.textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      expect(
        data.lineTouchData.touchTooltipData.maxContentWidth,
        greaterThanOrEqualTo(painter.width),
      );
    });
  });

  group('the value is not the tail of the timestamp', () {
    testWidgets('it is carried by its own span, weighted apart', (
      tester,
    ) async {
      // "29,897" under "21:20", in the same style, reads as seconds and
      // milliseconds — and the thousands separator cannot carry the
      // distinction, being a comma in English and a space in French.
      final data = await pumpChart(tester);
      final item = _itemFor(data, _points[1]);

      expect(item.text, isNot(contains('29')), reason: 'the value is a child');
      expect(item.children, hasLength(1));

      final value = item.children!.single;
      expect(value.text, contains('29,897'));
      expect(
        value.style!.fontWeight!.value,
        greaterThan(item.textStyle.fontWeight?.value ?? 0),
        reason: 'the value must be heavier than the timestamp above it',
      );
      expect(value.style!.fontSize, greaterThan(item.textStyle.fontSize!));
    });

    testWidgets('and reads with the separator of its own language', (
      tester,
    ) async {
      final data = await pumpChart(tester, languageCode: 'fr');
      final value = _itemFor(data, _points[1]).children!.single;

      expect(value.text, isNot(contains('29,897')));
      expect(value.text!.replaceAll(RegExp(r'[\s  ]'), ''), contains('29897'));
    });
  });

  group('both lines are legible on the box they are painted on', () {
    for (final brightness in Brightness.values) {
      testWidgets('contrast holds on $brightness', (tester) async {
        // The defect this replaces: the package paints its tooltip in a dark
        // blueGrey in both themes, while the style carried onSurface — near
        // black in a light theme. Dark on dark, and nothing in the suite
        // noticed (§3.9).
        final data = await pumpChart(tester, brightness: brightness);
        final tooltip = data.lineTouchData.touchTooltipData;
        final item = _itemFor(data, _points[1]);

        final bar = data.lineBarsData.first;
        final background = tooltip.getTooltipColor(
          LineBarSpot(bar, 0, bar.spots.first),
        );

        for (final style in [item.textStyle, item.children!.single.style!]) {
          expect(
            _contrast(style.color!, background),
            greaterThanOrEqualTo(4.5),
            reason: 'text ${style.color} on $background under $brightness',
          );
        }
      });
    }
  });
}
