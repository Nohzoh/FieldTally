import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/goal.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

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

/// Ten days ending today, ten portals a day.
List<StatSnapshot> recentHistory() {
  final today = DateTime.now();
  return [
    for (var day = 9; day >= 0; day--)
      at(today.subtract(Duration(days: day)), {
        'Unique Portals Visited': 1400 + (9 - day) * 10,
      }),
  ];
}

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;

  Future<void> pumpDetail(
    WidgetTester tester, {
    List<StatSnapshot>? history,
    Goal? goal,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        // No test asks Android to post anything (§3.7).
        notificationServiceProvider.overrideWithValue(
          FakeNotificationService(),
        ),
        counterRegistryProvider.overrideWith(fixedRegistry),
      ],
    );
    // Dispose the container before closing the database: closing Drift while a
    // stream query is still subscribed hangs.
    addTearDown(db.close);
    addTearDown(container.dispose);

    // Anchored on today rather than a fixed date: the card asks the real clock
    // whether a deadline has passed, so a hard-coded year would quietly rot.
    for (final snapshot in history ?? recentHistory()) {
      await container.read(snapshotRepositoryProvider).save(snapshot);
    }
    if (goal != null) await container.read(goalRepositoryProvider).set(goal);

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

    router.go(Routes.counterDetail('Unique Portals Visited'));
    await tester.pumpAndSettle();
  }

  Future<void> scrollToGoal(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Personal goal'), 200);
    await tester.pumpAndSettle();
  }

  group('personal goals (§3.7)', () {
    testWidgets('offers to set one when there is none', (tester) async {
      await pumpDetail(tester);
      await scrollToGoal(tester);

      expect(find.text('No goal on this counter yet.'), findsOneWidget);
      expect(find.text('Set a goal'), findsOneWidget);
    });

    testWidgets('setting one stores it and shows what is left', (tester) async {
      await pumpDetail(tester);
      await scrollToGoal(tester);

      await tester.tap(find.text('Set a goal'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '2000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save the goal'));
      await tester.pumpAndSettle();

      final stored = await container.read(goalRepositoryProvider).all();
      expect(stored.single.target, 2000);
      expect(stored.single.exportHeader, 'Unique Portals Visited');

      await scrollToGoal(tester);
      // 1490 now, so 510 to go out of 2000.
      expect(find.textContaining('510 to go'), findsOneWidget);
    });

    testWidgets('a target at or below the current value is refused', (
      tester,
    ) async {
      // That is not a goal, it is a statement of the present.
      await pumpDetail(tester);
      await scrollToGoal(tester);

      await tester.tap(find.text('Set a goal'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '1000');
      await tester.pumpAndSettle();

      expect(find.text('Must be above the current value'), findsOneWidget);
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save the goal'),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('a reached goal says so', (tester) async {
      await pumpDetail(
        tester,
        goal: Goal(
          exportHeader: 'Unique Portals Visited',
          target: 1000,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await scrollToGoal(tester);

      expect(find.text('Reached.'), findsWidgets);
    });

    testWidgets('removing it clears the goal', (tester) async {
      await pumpDetail(
        tester,
        goal: Goal(
          exportHeader: 'Unique Portals Visited',
          target: 2000,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await scrollToGoal(tester);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(await container.read(goalRepositoryProvider).all(), isEmpty);
    });
  });

  group('the deadline picker (#80)', () {
    /// Opens the goal sheet and taps through to the calendar.
    Future<void> openPicker(
      WidgetTester tester, {
      required bool editing,
    }) async {
      await scrollToGoal(tester);
      await tester.tap(find.text(editing ? 'Change' : 'Set a goal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
    }

    /// The month the calendar is showing, as its own header spells it.
    String monthShown() =>
        DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase();

    testWidgets('opens on the current month, with nothing chosen', (
      tester,
    ) async {
      // It suggested a date thirty days out, which nothing motivated: the app
      // has no basis for an opinion about the agent's own ambition, and the
      // specification only ever gave an absolute date as its example.
      await pumpDetail(tester);
      await openPicker(tester, editing: false);

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.initialDate, isNull);

      // Today is on screen, in its own month, rather than a month ahead.
      expect(
        find.textContaining(RegExp(monthShown(), caseSensitive: false)),
        findsWidgets,
      );
    });

    testWidgets('confirming without choosing sets no deadline', (tester) async {
      // The other half of opening on nothing: the picker returns null, and
      // the agent has not been handed a date they never picked.
      await pumpDetail(tester);
      await openPicker(tester, editing: false);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('No deadline'), findsOneWidget);
    });

    testWidgets('an existing deadline still opens on itself', (tester) async {
      final deadline = DateTime.now().add(const Duration(days: 120));
      await pumpDetail(
        tester,
        goal: Goal(
          exportHeader: 'Unique Portals Visited',
          target: 2000,
          deadline: deadline,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await openPicker(tester, editing: true);

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.initialDate, DateUtils.dateOnly(deadline));
    });

    testWidgets('a deadline already missed does not take the picker down', (
      tester,
    ) async {
      // showDatePicker asserts initialDate is not before firstDate. Re-dating
      // a goal whose deadline has passed handed it exactly that: a debug-mode
      // crash, and in release a selection outside the picker's own range.
      await pumpDetail(
        tester,
        goal: Goal(
          exportHeader: 'Unique Portals Visited',
          target: 2000,
          deadline: DateTime.now().subtract(const Duration(days: 3)),
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await openPicker(tester, editing: true);

      expect(tester.takeException(), isNull);
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      // Nothing to offer: a past date cannot be chosen anyway, so the agent
      // lands on the current month like anyone re-dating from scratch.
      expect(picker.initialDate, isNull);
    });
  });

  group('against a deadline', () {
    testWidgets('says when the pace gets there in time', (tester) async {
      // 10 a day, 510 to go: about 51 days, so June is ample.
      await pumpDetail(
        tester,
        goal: Goal(
          exportHeader: 'Unique Portals Visited',
          target: 2000,
          // 10 a day, 510 to go: about 51 days, so four months is ample.
          deadline: DateTime.now().add(const Duration(days: 120)),
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await scrollToGoal(tester);

      expect(find.textContaining('On track'), findsOneWidget);
    });

    testWidgets('says when it does not', (tester) async {
      await pumpDetail(
        tester,
        goal: Goal(
          exportHeader: 'Unique Portals Visited',
          target: 2000,
          // Ten days is far short of the fifty the pace needs.
          deadline: DateTime.now().add(const Duration(days: 10)),
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await scrollToGoal(tester);

      expect(find.textContaining('Behind'), findsOneWidget);
    });

    testWidgets('a stalled counter gets no opinion rather than "behind"', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        history: [
          for (var day = 4; day >= 0; day--)
            at(DateTime.now().subtract(Duration(days: day)), const {
              'Unique Portals Visited': 1400,
            }),
        ],
        goal: Goal(
          exportHeader: 'Unique Portals Visited',
          target: 2000,
          deadline: DateTime.now().add(const Duration(days: 120)),
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await scrollToGoal(tester);

      // Exact text: the badge card above says "No estimate" too, for the same
      // reason — the counter has not moved.
      expect(find.text('No estimate at your recent pace.'), findsOneWidget);
      expect(find.textContaining('Behind'), findsNothing);
    });
  });
}
