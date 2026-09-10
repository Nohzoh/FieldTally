import 'package:fieldtally/presentation/widgets/activity_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpCalendar(
  WidgetTester tester, {
  required Map<DateTime, int> activity,
  required DateTime from,
  required DateTime to,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: ActivityCalendar(activityByDay: activity, from: from, to: to),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('activity calendar', () {
    testWidgets('spans the whole history, not only the active days',
        (tester) async {
      // The quiet stretches are exactly what this view is for; a calendar
      // covering only the days with progress would hide them.
      await pumpCalendar(
        tester,
        activity: {DateTime(2026, 3, 1): 5000},
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 3, 1),
      );

      // Nine weeks of January to March, seven squares each, plus the legend.
      expect(find.byType(Container).evaluate().length, greaterThan(7 * 8));
    });

    testWidgets('labels weekdays and months in the interface language',
        (tester) async {
      // The reason this widget exists rather than the package suggested in
      // §5.1, which hard-codes English weekday labels.
      await pumpCalendar(
        tester,
        activity: {DateTime(2026, 2, 1): 10},
        from: DateTime(2026, 1, 15),
        to: DateTime(2026, 2, 1),
        locale: const Locale('fr'),
      );

      expect(find.text('lun.'), findsOneWidget);
      expect(find.textContaining('janv.'), findsOneWidget);
      expect(find.text('Mon'), findsNothing);
    });

    testWidgets('survives having no activity at all', (tester) async {
      // Reachable when every snapshot lacks the AP column.
      await pumpCalendar(
        tester,
        activity: const {},
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 20),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a single day renders without collapsing', (tester) async {
      await pumpCalendar(
        tester,
        activity: {DateTime(2026, 1, 5): 100},
        from: DateTime(2026, 1, 5),
        to: DateTime(2026, 1, 5),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Tooltip), findsWidgets);
    });
  });
}
