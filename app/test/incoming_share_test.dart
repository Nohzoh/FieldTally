import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/data/sharing/incoming_share.dart';
import 'package:fieldtally/domain/repositories/snapshot_repository.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/incoming_share_listener.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

const allTimePath = 'test/fixtures/sample_export_all_time.tsv';
const weekPath = 'test/fixtures/sample_export_week.tsv';
const seedPath = 'assets/counters_registry_seed.json';

String fixture(String path) => File(path).readAsStringSync();

/// Stands in for the Android share sheet, which no widget test can trigger.
class FakeShareSource implements IncomingShareSource {
  FakeShareSource({this.initial});

  final String? initial;
  final _controller = StreamController<String>.broadcast();

  int resetCount = 0;

  void share(String text) => _controller.add(text);

  @override
  Future<String?> initialText() async => initial;

  @override
  Stream<String> textStream() => _controller.stream;

  @override
  void reset() => resetCount++;

  Future<void> dispose() => _controller.close();
}

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;
  late FakeShareSource share;

  Future<SnapshotRepository> pumpApp(
    WidgetTester tester, {
    String? initialShare,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    share = FakeShareSource(initial: initialShare);
    final registry =
        const CounterRegistryLoader().parse(File(seedPath).readAsStringSync());

    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      counterRegistryProvider.overrideWith((ref) async => registry),
      incomingShareProvider.overrideWithValue(share),
    ]);
    // Order matters: tearDowns run last-registered-first, so the container is
    // disposed before the database is closed. Closing Drift while a stream
    // query is still subscribed hangs.
    addTearDown(db.close);
    addTearDown(container.dispose);
    addTearDown(share.dispose);

    final router = createRouter();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: IncomingShareListener(
          router: router,
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
      ),
    );
    await tester.pumpAndSettle();

    return container.read(snapshotRepositoryProvider);
  }

  group('incoming share (§3.1)', () {
    testWidgets('a share received while running lands on the preview',
        (tester) async {
      await pumpApp(tester);
      expect(find.text('Nothing to show yet'), findsOneWidget);

      share.share(fixture(allTimePath));
      await tester.pumpAndSettle();

      // Straight to the preview, already analysed: no manual paste, no extra
      // button to press.
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('AgentDemo'), findsOneWidget);
      expect(find.text('59'), findsOneWidget);
    });

    testWidgets('a share that launched the app is handled too', (tester) async {
      await pumpApp(tester, initialShare: fixture(allTimePath));

      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('ALL TIME'), findsOneWidget);
    });

    testWidgets('the initial share is marked consumed', (tester) async {
      // Otherwise coming back to the app replays it and offers to import a
      // snapshot that was already dealt with.
      await pumpApp(tester, initialShare: fixture(allTimePath));

      expect(share.resetCount, 1);
    });

    testWidgets('nothing is saved without confirmation', (tester) async {
      // A share is an intent to import, not an import. The preview and its
      // guards still stand between the text and the history.
      final repository = await pumpApp(tester, initialShare: fixture(allTimePath));

      expect(await repository.all(), isEmpty);
      expect(find.text('Save this snapshot'), findsOneWidget);
    });

    testWidgets('the guards apply to a shared snapshot as well', (tester) async {
      await pumpApp(tester, initialShare: fixture(weekPath));

      expect(find.text('Partial period detected'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Do not save'), findsOneWidget);
    });

    testWidgets('unreadable shared text shows the parser error', (tester) async {
      await pumpApp(tester, initialShare: 'shared from the wrong app');

      expect(find.text('Could not read this text'), findsOneWidget);
      expect(find.text('Preview'), findsNothing);
    });

    testWidgets('a second share replaces the first', (tester) async {
      await pumpApp(tester);

      share.share(fixture(weekPath));
      await tester.pumpAndSettle();
      expect(find.text('WEEK'), findsWidgets);

      share.share(fixture(allTimePath));
      await tester.pumpAndSettle();
      expect(find.text('ALL TIME'), findsWidgets);
      expect(find.text('59'), findsOneWidget);
    });

    testWidgets('opening the app normally does not jump anywhere',
        (tester) async {
      await pumpApp(tester);

      expect(find.text('Nothing to show yet'), findsOneWidget);
      expect(find.text('Preview'), findsNothing);
      expect(share.resetCount, 0);
    });
  });

  group('text extraction from a share', () {
    SharedMediaFile file(String path, SharedMediaType type) =>
        SharedMediaFile(path: path, type: type);

    test('picks the shared text', () {
      expect(
        PluginIncomingShareSource.extractText([
          file('Time Span\tAgent Name', SharedMediaType.text),
        ]),
        'Time Span\tAgent Name',
      );
    });

    test('ignores anything that is not plain text', () {
      // Ingress shares one block of text; an image dropped on the app is not
      // something the parser could do anything with, so it is skipped rather
      // than handed over to fail there.
      expect(
        PluginIncomingShareSource.extractText([
          file('/tmp/photo.jpg', SharedMediaType.image),
          file('https://example.org', SharedMediaType.url),
        ]),
        isNull,
      );
    });

    test('ignores blank text', () {
      expect(
        PluginIncomingShareSource.extractText([
          file('   ', SharedMediaType.text),
        ]),
        isNull,
      );
    });

    test('nothing shared yields nothing', () {
      expect(PluginIncomingShareSource.extractText(const []), isNull);
    });
  });
}
