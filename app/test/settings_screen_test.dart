import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fieldtally/core/build_info.dart';
import 'package:fieldtally/core/router.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/domain/repositories/settings_repository.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fieldtally/data/registry/counter_registry_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_notification_service.dart';

/// The screen carries two switches; these name them rather than repeating the
/// positional lookup. Getters, not fields: a finder caches what it matched,
/// and one shared across tests would hand back a stale element.
Finder get _onlineUpdates => find.byType(SwitchListTile).first;
Finder get _notifications => find.byType(SwitchListTile).last;

/// The screen is taller than a phone: anything below the About divider has to
/// be scrolled to before it is even built.
Future<void> scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  late FieldTallyDatabase db;
  late ProviderContainer container;
  late FakeNotificationService notifications;

  /// Stands in for the platform: PackageInfo reads a channel no widget test
  /// has, so the provider is overridden rather than the plugin mocked.
  ///
  /// The build number is deliberately one the changelog will never carry.
  /// It used to be 7, which held only until the seventh release shipped an
  /// entry keyed 7 — and then "this build has no notes bundled" quietly
  /// became false and the test failed on a release commit.
  const runningBuild = BuildInfo(
    version: '1.2.3',
    build: '9999',
    commit: 'abc1234',
  );

  Future<void> pumpSettings(
    WidgetTester tester, {
    double textScale = 1.0,
    BuildInfo? build = runningBuild,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = FieldTallyDatabase(NativeDatabase.memory());
    notifications = FakeNotificationService();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        // No test asks Android for anything.
        notificationServiceProvider.overrideWithValue(notifications),
        if (build != null) buildInfoProvider.overrideWith((ref) async => build),
        // No test touches the real network. This one always fails, which is also
        // the case that must leave the app fully usable.
        counterRegistryServiceProvider.overrideWith(
          (ref) => CounterRegistryService(
            settings: ref.watch(settingsRepositoryProvider),
            client: MockClient((_) async => http.Response('nope', 503)),
          ),
        ),
      ],
    );
    // Dispose the container before closing the database: closing Drift while a
    // stream query is still subscribed hangs.
    addTearDown(db.close);
    addTearDown(container.dispose);

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
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.go(Routes.settings);
    await tester.pumpAndSettle();

    // No startup refresh here: the registry now resolves locally and the fetch
    // is an explicit startup task, so a test only touches the network when it
    // means to.
    await tester.pumpAndSettle();
  }

  group('settings (§3.1.4)', () {
    testWidgets('online updates are on by default', (tester) async {
      await pumpSettings(tester);

      final toggle = tester.widget<SwitchListTile>(_onlineUpdates);
      expect(toggle.value, isTrue);
    });

    testWidgets('says what is downloaded and that nothing is sent', (
      tester,
    ) async {
      // This is the only network request in the whole of v1, so the wording
      // has to be plain rather than reassuring.
      await pumpSettings(tester);

      expect(find.textContaining('Nothing about you'), findsOneWidget);
      expect(find.textContaining('entirely offline'), findsOneWidget);
    });

    testWidgets('turning it off is persisted', (tester) async {
      await pumpSettings(tester);

      await tester.tap(_onlineUpdates);
      await tester.pumpAndSettle();

      expect(
        await container
            .read(settingsRepositoryProvider)
            .read(SettingKeys.onlineRegistryUpdates),
        'false',
      );
      final toggle = tester.widget<SwitchListTile>(_onlineUpdates);
      expect(toggle.value, isFalse);
    });

    testWidgets('carries the non-affiliation notice', (tester) async {
      await pumpSettings(tester);
      await scrollTo(
        tester,
        find.textContaining('not affiliated with Niantic'),
      );

      expect(
        find.textContaining('not affiliated with Niantic'),
        findsOneWidget,
      );
    });
  });

  group('reminders (§3.7)', () {
    testWidgets('notifications are off until switched on', (tester) async {
      // Opt-in, because Android 13 grants the permission to nobody by
      // default: a switch that started on would promise nothing.
      await pumpSettings(tester);

      expect(tester.widget<SwitchListTile>(_notifications).value, isFalse);
      expect(find.textContaining('after 7 days'), findsOneWidget);
    });

    testWidgets('switching them on asks Android first', (tester) async {
      await pumpSettings(tester);

      await tester.tap(_notifications);
      await tester.pumpAndSettle();

      expect(notifications.permissionRequests, 1);
      expect(tester.widget<SwitchListTile>(_notifications).value, isTrue);
      expect(
        await container
            .read(settingsRepositoryProvider)
            .read(SettingKeys.notifications),
        'true',
      );
    });

    testWidgets('a refused permission leaves the switch off', (tester) async {
      // A switch that says "on" while Android posts nothing would be a lie.
      await pumpSettings(tester);
      notifications.permissionGranted = false;

      await tester.tap(_notifications);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(_notifications).value, isFalse);
      expect(find.textContaining('refused'), findsOneWidget);
    });

    testWidgets('switching them off cancels the pending reminder', (
      tester,
    ) async {
      await pumpSettings(tester);

      await tester.tap(_notifications);
      await tester.pumpAndSettle();
      await tester.tap(_notifications);
      await tester.pumpAndSettle();

      expect(
        await container
            .read(settingsRepositoryProvider)
            .read(SettingKeys.notifications),
        'false',
      );
      expect(notifications.cancels, greaterThan(0));
    });

    testWidgets('choosing another delay is persisted', (tester) async {
      await pumpSettings(tester);
      // The delay is only reachable once reminders are on.
      await tester.tap(_notifications);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byType(DropdownButton<int>));
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('14').last);
      await tester.pumpAndSettle();

      expect(
        await container
            .read(settingsRepositoryProvider)
            .read(SettingKeys.reminderDays),
        '14',
      );
      expect(find.textContaining('after 14 days'), findsOneWidget);
    });

    testWidgets('a daily reminder can be chosen (#69)', (tester) async {
      // The shortest delay, for an agent who plays every evening: three days
      // is already long enough to lose the habit the reminder protects.
      await pumpSettings(tester);
      await tester.tap(_notifications);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byType(DropdownButton<int>));
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1').last);
      await tester.pumpAndSettle();

      expect(
        await container
            .read(settingsRepositoryProvider)
            .read(SettingKeys.reminderDays),
        '1',
      );
      // And it reads as a sentence rather than "after 1 days".
      expect(
        find.text('Remind me after a day without a snapshot'),
        findsOneWidget,
      );
    });
  });

  group('language (§3.10)', () {
    testWidgets('follows the system until a language is picked', (
      tester,
    ) async {
      await pumpSettings(tester);
      await scrollTo(tester, find.byType(DropdownButton<String?>));

      expect(
        tester
            .widget<DropdownButton<String?>>(
              find.byType(DropdownButton<String?>),
            )
            .value,
        isNull,
      );
    });

    testWidgets('lists each language in its own language', (tester) async {
      // Someone who lands in a language they cannot read has to be able to
      // recognise their own in the list.
      await pumpSettings(tester);
      await scrollTo(tester, find.byType(DropdownButton<String?>));

      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      expect(find.text('Français'), findsWidgets);
      expect(find.text('English'), findsWidgets);
    });

    testWidgets('choosing one is persisted', (tester) async {
      await pumpSettings(tester);
      await scrollTo(tester, find.byType(DropdownButton<String?>));

      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Français').last);
      await tester.pumpAndSettle();

      expect(
        await container
            .read(settingsRepositoryProvider)
            .read(SettingKeys.locale),
        'fr',
      );
    });
  });

  group('appearance (§3.9)', () {
    testWidgets('the theme follows the system until changed', (tester) async {
      await pumpSettings(tester);
      await scrollTo(tester, find.byType(DropdownButton<ThemeMode>));

      expect(
        tester
            .widget<DropdownButton<ThemeMode>>(
              find.byType(DropdownButton<ThemeMode>),
            )
            .value,
        ThemeMode.system,
      );

      await tester.tap(find.byType(DropdownButton<ThemeMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();

      expect(
        await container
            .read(settingsRepositoryProvider)
            .read(SettingKeys.themeMode),
        'dark',
      );
    });

    testWidgets('faction colours are off, and say there is no faction yet', (
      tester,
    ) async {
      // Without a snapshot the switch has nothing to follow, and saying so
      // beats a control that looks broken.
      await pumpSettings(tester);
      await scrollTo(tester, find.textContaining('no faction to follow'));

      expect(find.textContaining('no faction to follow'), findsOneWidget);
    });

    testWidgets('turning faction colours on is persisted', (tester) async {
      await pumpSettings(tester);
      await scrollTo(tester, find.text('Faction colours'));

      await tester.tap(find.text('Faction colours'));
      await tester.pumpAndSettle();

      expect(
        await container
            .read(settingsRepositoryProvider)
            .read(SettingKeys.factionColours),
        'true',
      );
    });
  });

  group('text size (§3.9)', () {
    // Three switches, two dropdowns and long explanatory subtitles: this is
    // the screen most likely to overflow when someone scales their fonts up.
    for (final scale in [1.0, 1.6, 2.0]) {
      testWidgets('survives a text scale of $scale', (tester) async {
        await pumpSettings(tester, textScale: scale);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('about (§9)', () {
    testWidgets('names the running build and copies it on tap', (tester) async {
      // The first question on any bug report is "which version?".
      //
      // The clipboard is a platform channel, so it is mocked rather than read
      // back: Clipboard.getData never completes under the widget-test clock.
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpSettings(tester);
      await scrollTo(tester, find.textContaining('Version'));

      await tester.tap(find.textContaining('Version'));
      await tester.pumpAndSettle();

      expect(copied.single, 'FieldTally 1.2.3 (9999) · abc1234');
      expect(find.text('Version copied.'), findsOneWidget);
    });

    testWidgets('a build with no commit says so rather than naming one', (
      tester,
    ) async {
      // A working copy must not claim a commit that may not hold what runs.
      await pumpSettings(
        tester,
        build: const BuildInfo(version: '1.2.3', build: '9999', commit: null),
      );
      await scrollTo(tester, find.textContaining('working copy'));

      expect(find.textContaining('working copy'), findsOneWidget);
      expect(find.text('Version 1.2.3 (9999)'), findsOneWidget);
    });

    testWidgets('shows the commit when the build carries one', (tester) async {
      await pumpSettings(tester);
      await scrollTo(tester, find.text('Version 1.2.3 (9999)'));

      expect(find.text('abc1234'), findsOneWidget);
    });

    testWidgets('offers the source and a way to support the project', (
      tester,
    ) async {
      await pumpSettings(tester);
      await scrollTo(tester, find.text('Source code'));

      expect(find.text('Support the project'), findsOneWidget);
      expect(find.text('Source code'), findsOneWidget);
    });

    testWidgets('credits the author', (tester) async {
      await pumpSettings(tester);
      await scrollTo(tester, find.text('Author'));

      expect(find.text('Author'), findsOneWidget);
      expect(find.text('Nohzoh, on GitHub.'), findsOneWidget);
    });

    testWidgets('offers the release notes again (§9)', (tester) async {
      // The build under test carries no bundled notes, so the tile says so
      // rather than opening an empty dialog — the same thing a development
      // build does.
      await pumpSettings(tester);
      await scrollTo(tester, find.text("What's new"));

      await tester.tap(find.text("What's new"));
      await tester.pumpAndSettle();

      expect(find.textContaining('No notes bundled'), findsOneWidget);
    });
  });

  group('reaching settings', () {
    testWidgets('from the dashboard overflow menu', (tester) async {
      await pumpSettings(tester);
      // Land back on the dashboard first.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });
  });

  group('a newer release, for an app no store watches (#34)', () {
    /// What the project site publishes, seeded straight into the cache: the
    /// screen reads that, never the network, so it answers instantly and
    /// answers the same offline.
    Future<void> siteSays({required int build}) async {
      await container
          .read(settingsRepositoryProvider)
          .write(
            SettingKeys.latestRelease,
            jsonEncode({
              'version': '9.9.9',
              'build': build,
              'url': 'https://github.com/Nohzoh/FieldTally/releases/tag/v9.9.9',
            }),
          );
    }

    testWidgets('is offered when the site knows a higher build', (
      tester,
    ) async {
      await pumpSettings(tester);
      // runningBuild is 9999.
      await siteSays(build: 10000);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.textContaining('is available'));

      expect(find.text('Version 9.9.9 is available'), findsOneWidget);
      expect(
        find.textContaining('never installs anything on its own'),
        findsOneWidget,
      );
    });

    testWidgets('is absent when the running build is the newest', (
      tester,
    ) async {
      await pumpSettings(tester);
      await siteSays(build: 9999);
      await tester.pumpAndSettle();

      // Scrolled to where the line would be before asserting it is not there.
      // Settings is a lazy list, so an assertion made from the top of it would
      // pass whether or not the line exists.
      await scrollTo(tester, find.textContaining('Version 1.2.3'));

      expect(find.textContaining('is available'), findsNothing);
    });

    testWidgets('is absent on a device that has heard nothing', (tester) async {
      // The ordinary state: a fresh install, or a phone that has never had
      // network since installing. Saying nothing is the correct answer, and
      // it must not look like a failure.
      await pumpSettings(tester);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.textContaining('Version 1.2.3'));

      expect(find.textContaining('is available'), findsNothing);
    });
  });
}
