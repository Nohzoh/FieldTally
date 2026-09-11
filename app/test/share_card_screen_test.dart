import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/counter_series.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:fieldtally/presentation/widgets/share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_notification_service.dart';
import 'support/fixed_registry.dart';

StatSnapshot at(
  DateTime date,
  Map<String, int> counters, {
  int? level = 9,
  String faction = 'Enlightened',
}) =>
    StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: faction,
      recordedAt: date,
      level: level,
      counters: counters,
    );

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;

  Future<void> pumpShareCard(
    WidgetTester tester, {
    List<StatSnapshot> history = const [],
    List<String>? pinned,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
      counterRegistryProvider.overrideWith(fixedRegistry),
    ]);
    // Dispose the container before closing the database: Drift hangs on close
    // while a stream query is still subscribed.
    addTearDown(db.close);
    addTearDown(container.dispose);

    for (final snapshot in history) {
      await container.read(snapshotRepositoryProvider).save(snapshot);
    }
    if (pinned != null) {
      await container.read(pinnedCounterRepositoryProvider).setPinned(pinned);
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

    router.go(Routes.shareCard);
    await tester.pumpAndSettle();
  }

  final history = [
    at(DateTime(2026, 1, 1), const {'Hacks': 70000, 'Lifetime AP': 95000000}),
    at(DateTime(2026, 1, 20), const {'Hacks': 78735, 'Lifetime AP': 101542335}),
  ];

  group('share card (§3.8)', () {
    testWidgets('shows the agent, the values and the progress',
        (tester) async {
      await pumpShareCard(
        tester,
        history: history,
        pinned: const ['Hacks', 'Lifetime AP'],
      );

      expect(find.text('AgentDemo'), findsOneWidget);
      expect(find.textContaining('Enlightened'), findsOneWidget);
      expect(find.text('Level 9'), findsOneWidget);
      expect(find.text('78,735'), findsOneWidget);
      expect(find.text('+8,735'), findsOneWidget);
    });

    testWidgets('carries the non-affiliation notice into the image',
        (tester) async {
      // The card is the part that leaves the app, so it is the part that has
      // to carry the notice.
      await pumpShareCard(tester, history: history, pinned: const ['Hacks']);

      expect(
        find.textContaining('not affiliated with Niantic'),
        findsOneWidget,
      );
    });

    testWidgets('changing the period changes the gains', (tester) async {
      await pumpShareCard(
        tester,
        history: [
          at(DateTime(2026, 1, 1), const {'Hacks': 70000}),
          at(DateTime(2026, 1, 15), const {'Hacks': 76000}),
          at(DateTime(2026, 1, 20), const {'Hacks': 78735}),
        ],
        pinned: const ['Hacks'],
      );

      // A month back from the newest snapshot covers the whole history here.
      expect(find.text('+8,735'), findsOneWidget);

      container.read(shareCardRangeProvider.notifier).set(ChartRange.week);
      await tester.pumpAndSettle();

      // A week back from 20 January starts at the 15th, not at the 1st.
      expect(find.text('+2,735'), findsOneWidget);
      expect(find.text('+8,735'), findsNothing);
    });

    testWidgets('a single snapshot says there is no progress yet',
        (tester) async {
      await pumpShareCard(
        tester,
        history: [history.first],
        pinned: const ['Hacks'],
      );

      expect(find.textContaining('Only one snapshot'), findsOneWidget);
      expect(find.textContaining('Progress since'), findsNothing);
    });

    testWidgets('without any snapshot there is nothing to share',
        (tester) async {
      await pumpShareCard(tester);

      expect(find.text('Nothing to share yet'), findsOneWidget);
      expect(find.byType(ShareCard), findsNothing);
    });

    testWidgets('a level no import carried leaves no empty badge',
        (tester) async {
      // Appendix B has no level column; an empty badge would look like a bug
      // on a public image.
      await pumpShareCard(
        tester,
        history: [
          at(DateTime(2026, 1, 1), const {'Hacks': 1}, level: null),
          at(DateTime(2026, 1, 2), const {'Hacks': 2}, level: null),
        ],
        pinned: const ['Hacks'],
      );

      expect(find.textContaining('Level'), findsNothing);
    });

    testWidgets('the card renders to a PNG at the expected size',
        (tester) async {
      // The capture is the whole point of the screen, and it is the part that
      // silently produces nothing if the boundary is ever laid out at zero.
      await pumpShareCard(tester, history: history, pinned: const ['Hacks']);

      // The boundary wrapping the card, not whichever one the framework
      // happens to have inserted elsewhere in the list.
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find
            .ancestor(
              of: find.byType(ShareCard),
              matching: find.byType(RepaintBoundary),
            )
            .first,
      );
      // runAsync, because toImage waits on the real engine: inside the fake
      // clock of a widget test the future never completes and the suite hangs
      // with no output at all.
      final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 3));
      addTearDown(image!.dispose);

      // 360pt wide whatever the phone is: the card keeps its own layout and
      // only its display is scaled down, so the image is the same shape for
      // everyone.
      expect(image.width, (ShareCard.width * 3).round());
      expect(image.height, greaterThan(0));

      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      );
      expect(bytes, isNotNull);
      expect(bytes!.lengthInBytes, greaterThan(0));
    });
  });

  group('faction colours (§3.8)', () {
    test('each faction gets its own, and an unknown one gets neither', () {
      final enlightened = ShareCard.factionColour('Enlightened');
      final resistance = ShareCard.factionColour('Resistance');

      expect(enlightened, isNot(resistance));
      // Case and padding come from an export, not from a controlled list.
      expect(ShareCard.factionColour(' resistance '), resistance);
      // Fan-made tools have invented factions before.
      expect(ShareCard.factionColour('Machina'), isNot(enlightened));
      expect(ShareCard.factionColour('Machina'), isNot(resistance));
    });
  });
}
