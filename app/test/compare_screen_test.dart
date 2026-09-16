import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/parsing/ingress_tsv_parser.dart';
import 'package:fieldtally/data/sharing/incoming_share.dart';
import 'package:fieldtally/domain/comparison_payload.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/repositories/snapshot_repository.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/incoming_share_listener.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_notification_service.dart';
import 'support/fixed_registry.dart';

const allTimePath = 'test/fixtures/sample_export_all_time.tsv';

String fixture(String path) => File(path).readAsStringSync();

/// Stands in for the Android share sheet, which no widget test can trigger.
class FakeShareSource implements IncomingShareSource {
  final _controller = StreamController<String>.broadcast();

  void share(String text) => _controller.add(text);

  @override
  Future<String?> initialText() async => null;

  @override
  Stream<String> textStream() => _controller.stream;

  @override
  void reset() {}

  Future<void> dispose() => _controller.close();
}

/// What another agent's phone would send.
String payloadFrom({
  String agent = 'Rival',
  String faction = 'Resistance',
  int? level = 12,
  TimeSpan span = TimeSpan.allTime,
  Map<String, int> counters = const {
    'Unique Portals Visited': 7412,
    'Hacks': 40000,
  },
}) => const ComparisonPayload().encode(
  StatSnapshot(
    timeSpan: span,
    agentName: agent,
    faction: faction,
    recordedAt: DateTime(2026, 9, 1, 8),
    level: level,
    counters: counters,
  ),
);

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;
  late FakeShareSource share;
  late GoRouter router;

  Future<SnapshotRepository> pumpApp(
    WidgetTester tester, {
    bool withSnapshot = true,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    share = FakeShareSource();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(
          FakeNotificationService(),
        ),
        counterRegistryProvider.overrideWith(fixedRegistry),
        incomingShareProvider.overrideWithValue(share),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    addTearDown(share.dispose);

    final repository = container.read(snapshotRepositoryProvider);
    if (withSnapshot) {
      await repository.save(
        const IngressTsvParser().parseSingle(fixture(allTimePath)),
      );
    }

    router = createRouter();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: IncomingShareListener(
          router: router,
          child: MaterialApp.router(
            routerConfig: router,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return repository;
  }

  group('sending my own totals (#64)', () {
    testWidgets('the screen shows what will leave before it leaves', (
      tester,
    ) async {
      await pumpApp(tester);
      router.go(Routes.compare);
      await tester.pumpAndSettle();

      expect(find.text('What will be sent'), findsOneWidget);
      // Every value, not a summary: reading it beforehand only means
      // something if all of it is on screen.
      expect(
        find.text(
          '59 counters, plus your codename, faction, level and '
          'the date of this snapshot.',
        ),
        findsOneWidget,
      );
      expect(find.text('9,756'), findsOneWidget);
      // My own codename, not announced as an opponent: this screen is not
      // where I am my own rival.
      expect(find.text('AgentDemo'), findsOneWidget);
      expect(find.text('Against AgentDemo'), findsNothing);
    });

    testWidgets('says so plainly when there is nothing to send', (
      tester,
    ) async {
      await pumpApp(tester, withSnapshot: false);
      router.go(Routes.compare);
      await tester.pumpAndSettle();

      expect(find.text('Nothing to send yet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send my stats'), findsNothing);
    });
  });

  group("receiving another agent's totals", () {
    testWidgets('a shared comparison opens the side by side, not the import', (
      tester,
    ) async {
      await pumpApp(tester);

      share.share(payloadFrom());
      await tester.pumpAndSettle();

      expect(find.text('Against Rival'), findsOneWidget);
      // The import preview is what an Ingress export gets, and offering to
      // save a stranger's numbers is exactly what must not happen.
      expect(find.text('Preview'), findsNothing);
      expect(find.text('Save this snapshot'), findsNothing);
    });

    testWidgets('their numbers sit next to mine, with the gap spelled out', (
      tester,
    ) async {
      await pumpApp(tester);

      share.share(payloadFrom());
      await tester.pumpAndSettle();

      expect(find.text('9,756'), findsOneWidget);
      expect(find.text('7,412'), findsOneWidget);
      // A signed number rather than a colour or an arrow (§3.9).
      expect(find.text('+2,344'), findsOneWidget);
    });

    testWidgets('nothing received is written to the history', (tester) async {
      // The whole point: another agent's snapshot never reaches the
      // repository, where it would corrupt every derived view.
      final repository = await pumpApp(tester);

      share.share(payloadFrom());
      await tester.pumpAndSettle();

      final stored = await repository.all();
      expect(stored, hasLength(1));
      expect(stored.single.snapshot.agentName, 'AgentDemo');
    });

    testWidgets('the screen says the numbers are not kept', (tester) async {
      await pumpApp(tester);

      share.share(payloadFrom());
      await tester.pumpAndSettle();

      expect(find.textContaining('not saved'), findsOneWidget);
    });

    testWidgets('a counter only one of them has shows, with no gap', (
      tester,
    ) async {
      await pumpApp(tester);

      share.share(payloadFrom(counters: const {'Vesuvius Tokens': 5}));
      await tester.pumpAndSettle();

      // Right at the end: a counter the registry does not know falls into the
      // fallback category, below all sixty of the ones it does (§3.1.2).
      await tester.scrollUntilVisible(
        find.text('Vesuvius Tokens'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Vesuvius Tokens'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('their level and faction are named', (tester) async {
      await pumpApp(tester);

      share.share(payloadFrom());
      await tester.pumpAndSettle();

      expect(find.textContaining('Level 12'), findsOneWidget);
      expect(find.textContaining('Resistance'), findsOneWidget);
    });
  });

  group('what the screen refuses', () {
    testWidgets('totals covering a shorter period', (tester) async {
      await pumpApp(tester);

      share.share(payloadFrom(span: TimeSpan.week));
      await tester.pumpAndSettle();

      expect(find.text('This could not be read'), findsOneWidget);
      expect(find.textContaining('shorter period'), findsOneWidget);
      expect(find.text('Against Rival'), findsNothing);
    });

    testWidgets('a payload from a newer FieldTally', (tester) async {
      await pumpApp(tester);

      share.share('FieldTally/9 comparison\nagent\tRival\n--\nHacks\t1\n');
      await tester.pumpAndSettle();

      expect(find.textContaining('newer FieldTally'), findsOneWidget);
    });

    testWidgets('a broken payload, without losing the way to send mine', (
      tester,
    ) async {
      // A dead end would be worse than the error: the agent came here to
      // exchange stats, and sending theirs still works.
      await pumpApp(tester);

      share.share('FieldTally/1 comparison\nnonsense\n');
      await tester.pumpAndSettle();

      expect(find.text('This could not be read'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Send my stats'),
        findsOneWidget,
      );
    });
  });

  group('an ordinary Ingress export is untouched by all this', () {
    testWidgets('still lands on the import preview', (tester) async {
      // The regression that matters: every share goes past the comparison
      // check now, and a real export must carry on exactly as before (§3.1).
      await pumpApp(tester, withSnapshot: false);

      share.share(fixture(allTimePath));
      await tester.pumpAndSettle();

      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Against AgentDemo'), findsNothing);
    });
  });

  group('localisation', () {
    testWidgets('the comparison reads in French too', (tester) async {
      await pumpApp(tester, locale: const Locale('fr'));

      share.share(payloadFrom());
      await tester.pumpAndSettle();

      expect(find.text('Face à Rival'), findsOneWidget);
      expect(find.text('Écart'), findsWidgets);
    });
  });
}
