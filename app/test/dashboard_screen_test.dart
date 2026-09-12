import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/repositories/pinned_counter_repository.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:fieldtally/presentation/widgets/sparkline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixed_registry.dart';
import 'support/fake_notification_service.dart';

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

  Future<void> pumpDashboard(
    WidgetTester tester, {
    List<StatSnapshot> history = const [],
    List<String>? pinned,
    double textScale = 1.0,
    Size size = const Size(1080, 2400),
    double pixelRatio = 3.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      // No test asks Android to post anything (§3.7).
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: createRouter(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('dashboard (§3.3)', () {
    testWidgets('without any snapshot it says there is nothing to show',
        (tester) async {
      await pumpDashboard(tester);

      expect(find.text('Nothing to show yet'), findsOneWidget);
    });

    testWidgets('falls back to default pins on a fresh install',
        (tester) async {
      // An empty dashboard would be a poor first impression, so a few sensible
      // counters are shown until the agent picks their own.
      await pumpDashboard(
        tester,
        history: [
          at(DateTime(2026, 1, 1), const {
            'Lifetime AP': 101542335,
            'Unique Portals Visited': 9756,
            'Hacks': 78735,
            'Distance Walked': 4379,
          }),
        ],
      );

      for (final label in PinnedCounterRepository.defaults) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('shows the value and the progress on each card',
        (tester) async {
      await pumpDashboard(
        tester,
        pinned: const ['Hacks'],
        history: [
          at(DateTime(2026, 1, 1), const {'Hacks': 78000}),
          at(DateTime(2026, 1, 10), const {'Hacks': 78735}),
        ],
      );

      expect(find.text('78,735'), findsOneWidget);
      expect(find.text('+735'), findsOneWidget);
      expect(find.byType(Sparkline), findsOneWidget);
    });

    testWidgets('a single snapshot shows no sparkline and says why',
        (tester) async {
      await pumpDashboard(
        tester,
        pinned: const ['Hacks'],
        history: [at(DateTime(2026, 1, 1), const {'Hacks': 10})],
      );

      expect(find.byType(Sparkline), findsNothing);
      expect(find.text('1 snapshot'), findsOneWidget);
      // An em dash, not a sentence: see the card, which explains why just
      // below. Two wordy lines truncated each other on a narrow card.
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('cards keep the order the agent pinned them in',
        (tester) async {
      await pumpDashboard(
        tester,
        pinned: const ['Recursions', 'Hacks'],
        history: [
          at(DateTime(2026, 1, 1), const {'Hacks': 10, 'Recursions': 2}),
        ],
      );

      final recursions = tester.getTopLeft(find.text('Recursions'));
      final hacks = tester.getTopLeft(find.text('Hacks'));
      expect(recursions.dx <= hacks.dx || recursions.dy < hacks.dy, isTrue);
    });
  });

  /// Fails when a paragraph is painted into a box shorter than the text it
  /// laid out — the silent vertical clip that no exception reports.
  void expectNothingClipped(WidgetTester tester, Finder texts) {
    for (final element in texts.evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      final needed = paragraph.getMinIntrinsicHeight(paragraph.size.width);
      expect(
        paragraph.size.height,
        greaterThanOrEqualTo(needed),
        reason: 'clipped: "${(paragraph.text as TextSpan).toPlainText()}" '
            'got ${paragraph.size.height}, needs $needed',
      );
    }
  }

  group('card layout', () {
    // §3.9 requires honouring the system text size. A rigid card would overflow
    // for anyone who scales their fonts up, and an overflow is a test failure.
    // Reported from a phone at a larger system font: a two-line label was
    // sliced in half, losing the bottom of its second line. Nothing throws —
    // shrinking a Flexible is legal and the clip is silent — so asserting the
    // absence of an exception proved only that the app does not crash.
    for (final scale in [1.0, 1.3, 1.6, 2.0]) {
      testWidgets('no label is clipped at a text scale of $scale',
          (tester) async {
        await pumpDashboard(
          tester,
          textScale: scale,
          // Two columns, and a label long enough to wrap.
          size: const Size(1080, 2400),
          pixelRatio: 2.625,
          pinned: const ['Unique Portals Visited', 'Distance Walked'],
          history: [
            at(DateTime(2026, 1, 1),
                const {'Unique Portals Visited': 9000, 'Distance Walked': 4000}),
          ],
        );

        expectNothingClipped(tester, find.byType(Text));
      });
    }

    for (final scale in [1.0, 1.6, 2.0]) {
      testWidgets('survives a text scale of $scale', (tester) async {
        await pumpDashboard(
          tester,
          textScale: scale,
          pinned: const ['Unique Portals Visited', 'Hacks'],
          history: [
            at(DateTime(2026, 1, 1),
                const {'Unique Portals Visited': 9000, 'Hacks': 78000}),
            at(DateTime(2026, 1, 10),
                const {'Unique Portals Visited': 9756, 'Hacks': 78735}),
          ],
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no card text is truncated on a small screen', (tester) async {
      // Caught on the emulator: the placeholder for a missing diff was a full
      // sentence, ellipsised, and said the same thing as the line below it.
      //
      // Asks the render objects whether they actually clipped, rather than
      // re-measuring by hand: that is the same decision the painter made.
      await pumpDashboard(
        tester,
        size: const Size(320, 640),
        pixelRatio: 1.0,
        pinned: const ['Lifetime AP', 'Unique Portals Visited'],
        history: [
          at(DateTime(2026, 1, 1),
              const {'Lifetime AP': 101542335, 'Unique Portals Visited': 9756}),
        ],
      );

      final clipped = <String>[];
      void visit(RenderObject node) {
        if (node is RenderParagraph && node.didExceedMaxLines) {
          clipped.add(node.text.toPlainText());
        }
        node.visitChildren(visit);
      }

      // Scoped to the cards: the app bar title ellipsising next to its
      // actions is standard Material behaviour, and a separate concern.
      visit(tester.renderObject(find.byType(GridView)));
      expect(clipped, isEmpty, reason: 'clipped text: $clipped');
    });

    testWidgets('survives a small screen', (tester) async {
      await pumpDashboard(
        tester,
        size: const Size(320, 640),
        pixelRatio: 1.0,
        pinned: const ['Unique Portals Visited', 'Hacks'],
        history: [
          at(DateTime(2026, 1, 1),
              const {'Unique Portals Visited': 9000, 'Hacks': 78000}),
        ],
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('customising the pins (§3.3)', () {
    Future<void> openCustomise(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
    }

    testWidgets('lets the agent choose which counters to show', (tester) async {
      await pumpDashboard(
        tester,
        pinned: const ['Hacks', 'Recursions', 'Links Created', 'Level'],
        history: [
          at(DateTime(2026, 1, 1), const {
            'Hacks': 10,
            'Recursions': 2,
            'Links Created': 5,
            'Level': 9,
            'Unique Portals Visited': 100,
          }),
        ],
      );

      await openCustomise(tester);
      expect(find.text('Pinned counters'), findsOneWidget);

      await tester.tap(find.text('Unique Portals Visited'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        await container.read(pinnedCounterRepositoryProvider).pinned(),
        contains('Unique Portals Visited'),
      );
      expect(find.text('Unique Portals Visited'), findsOneWidget);
    });

    testWidgets('refuses to save fewer than the minimum', (tester) async {
      await pumpDashboard(
        tester,
        pinned: const ['Hacks', 'Recursions', 'Links Created', 'Level'],
        history: [
          at(DateTime(2026, 1, 1), const {
            'Hacks': 10,
            'Recursions': 2,
            'Links Created': 5,
            'Level': 9,
          }),
        ],
      );

      await openCustomise(tester);
      await tester.tap(find.text('Hacks'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pick at least'), findsOneWidget);
      final save = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Save'),
      );
      expect(save.onPressed, isNull, reason: 'saving must be blocked');
    });

    testWidgets('backing out leaves the dashboard untouched', (tester) async {
      await pumpDashboard(
        tester,
        pinned: const ['Hacks', 'Recursions', 'Links Created', 'Level'],
        history: [
          at(DateTime(2026, 1, 1), const {
            'Hacks': 10,
            'Recursions': 2,
            'Links Created': 5,
            'Level': 9,
            'Unique Portals Visited': 100,
          }),
        ],
      );

      await openCustomise(tester);
      await tester.tap(find.text('Unique Portals Visited'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(
        await container.read(pinnedCounterRepositoryProvider).pinned(),
        isNot(contains('Unique Portals Visited')),
      );
    });
  });
}
