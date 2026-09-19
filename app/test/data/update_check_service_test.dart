// Telling a sideloaded install that a newer release exists (#34).
//
// The app is installed by hand, so nothing else will say it: Android is
// silent and there is no store. These tests are mostly about the cases where
// the app must say nothing at all — an offline device, a malformed file, a
// build newer than the site knows about — because a version check is a
// courtesy and never a prerequisite.

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/repositories/drift_settings_repository.dart';
import 'package:fieldtally/data/updates/update_check_service.dart';
import 'package:fieldtally/domain/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String published({
  String version = '1.8.0',
  int build = 10,
  String url = 'https://github.com/Nohzoh/FieldTally/releases/tag/v1.8.0',
}) => jsonEncode({'version': version, 'build': build, 'url': url});

void main() {
  late FieldTallyDatabase db;
  late SettingsRepository settings;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = FieldTallyDatabase(NativeDatabase.memory());
    settings = DriftSettingsRepository(db);
  });

  tearDown(() => db.close());

  UpdateCheckService service({
    http.Client? client,
    DateTime Function()? now,
    Duration interval = const Duration(hours: 24),
  }) => UpdateCheckService(
    settings: settings,
    client: client,
    now: now,
    minimumInterval: interval,
  );

  MockClient responding(
    String body, {
    int status = 200,
    void Function()? onCall,
  }) => MockClient((request) async {
    onCall?.call();
    return http.Response.bytes(utf8.encode(body), status);
  });

  group('reading what the site publishes', () {
    test('a well-formed file is kept and answered from the cache', () async {
      await service(client: responding(published())).refresh();

      final known = await service().known();
      expect(known?.version, '1.8.0');
      expect(known?.build, 10);
      expect(known?.url, endsWith('/v1.8.0'));
    });

    test('a malformed file never replaces a good cache', () async {
      await service(client: responding(published())).refresh();

      await service(
        client: responding('{ not json at all'),
        now: () => DateTime(2099),
      ).refresh();

      expect((await service().known())?.version, '1.8.0');
    });

    test('a file missing a field is refused, not half-read', () async {
      await service(
        client: responding(jsonEncode({'version': '1.9.0'})),
      ).refresh();

      expect(await service().known(), isNull);
    });

    test('a url that is not https is refused', () async {
      // The file is the one thing the app reads and then hands to a browser.
      await service(
        client: responding(
          published(url: 'http://example.invalid/not-a-release'),
        ),
      ).refresh();

      expect(await service().known(), isNull);
    });

    test('a non-200 leaves the device with what it had', () async {
      await service(client: responding(published())).refresh();
      await service(
        client: responding('', status: 404),
        now: () => DateTime(2099),
      ).refresh();

      expect((await service().known())?.version, '1.8.0');
    });

    test('being offline is silent, and changes nothing', () async {
      await service(
        client: MockClient((_) async => throw const SocketException('offline')),
      ).refresh();

      expect(await service().known(), isNull);
    });
  });

  group('what counts as newer', () {
    setUp(() async {
      await service(client: responding(published(build: 10))).refresh();
    });

    test('a higher build code is offered', () async {
      expect((await service().newerThan(9))?.version, '1.8.0');
    });

    test('the same build code is not', () async {
      expect(await service().newerThan(10), isNull);
    });

    test(
      'a build newer than the site knows about is never a downgrade',
      () async {
        // A local build, or a release whose Pages deploy has not caught up yet.
        expect(await service().newerThan(11), isNull);
      },
    );

    test('a device that has never heard anything offers nothing', () async {
      await settings.write(SettingKeys.latestRelease, '');
      expect(await service().newerThan(1), isNull);
    });
  });

  group('how often it asks', () {
    test('not at all when online updates are switched off', () async {
      await settings.write(SettingKeys.onlineRegistryUpdates, 'false');

      var calls = 0;
      await service(
        client: responding(published(), onCall: () => calls++),
      ).refresh();

      expect(calls, 0);
      expect(await service().known(), isNull);
    });

    test('once inside the interval, however many launches', () async {
      var calls = 0;
      final client = responding(published(), onCall: () => calls++);
      final at = DateTime(2026, 6, 13, 9);

      await service(client: client, now: () => at).refresh();
      await service(
        client: client,
        now: () => at.add(const Duration(hours: 3)),
      ).refresh();

      expect(calls, 1);
    });

    test('again once the interval has passed', () async {
      var calls = 0;
      final client = responding(published(), onCall: () => calls++);
      final at = DateTime(2026, 6, 13, 9);

      await service(client: client, now: () => at).refresh();
      await service(
        client: client,
        now: () => at.add(const Duration(days: 2)),
      ).refresh();

      expect(calls, 2);
    });

    test('a failed attempt still counts against the interval', () async {
      // Otherwise a device with no network retries on every single launch.
      var calls = 0;
      final at = DateTime(2026, 6, 13, 9);

      await service(
        client: MockClient((_) async {
          calls++;
          throw const SocketException('offline');
        }),
        now: () => at,
      ).refresh();

      await service(
        client: responding(published(), onCall: () => calls++),
        now: () => at.add(const Duration(hours: 3)),
      ).refresh();

      expect(calls, 1);
    });
  });
}
