import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/registry/counter_registry_service.dart';
import 'package:fieldtally/data/repositories/drift_settings_repository.dart';
import 'package:fieldtally/domain/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const seedPath = 'assets/counters_registry_seed.json';

/// A registry that is valid but visibly different from the bundled seed.
String remoteRegistry({
  String updatedAt = '2099-01-01',
  String label = 'Remote Hacks',
}) =>
    jsonEncode({
      'schema_version': 1,
      'updated_at': updatedAt,
      'categories': [
        {
          'key': 'resource_gathering',
          'order': 1,
          'label': {'en': 'Resource Gathering', 'fr': 'Collecte'},
        },
      ],
      'counters': {
        'hacker': {
          'export_header': 'Hacks',
          'category': 'resource_gathering',
          'order': 0,
          'label': {'en': label, 'fr': label},
        },
      },
    });

void main() {
  late FieldTallyDatabase db;
  late SettingsRepository settings;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = FieldTallyDatabase(NativeDatabase.memory());
    settings = DriftSettingsRepository(db);
  });

  tearDown(() => db.close());

  CounterRegistryService service({
    http.Client? client,
    DateTime Function()? now,
    Duration interval = const Duration(hours: 24),
  }) =>
      CounterRegistryService(
        settings: settings,
        client: client,
        now: now,
        minimumInterval: interval,
      );

  MockClient responding(
    String body, {
    int status = 200,
    void Function()? onCall,
  }) =>
      MockClient((request) async {
        onCall?.call();
        return http.Response(body, status, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

  group('loading', () {
    test('falls back to the bundled copy when nothing is cached', () async {
      final registry = await service().load();

      // The seed carries the whole of Appendix A.
      expect(registry.length, 59);
    });

    test('prefers the cached copy once there is one', () async {
      await settings.write(SettingKeys.cachedRegistry, remoteRegistry());

      final registry = await service().load();

      expect(registry.forExportHeader('Hacks')!.label('en'), 'Remote Hacks');
    });

    test('a corrupt cache falls back rather than failing', () async {
      // The app must start even if the cache was truncated by a crash.
      await settings.write(SettingKeys.cachedRegistry, 'not json at all');

      final registry = await service().load();

      expect(registry.length, 59);
    });
  });

  group('refreshing (§3.1.4)', () {
    test('fetches on first run and adopts the result', () async {
      final registry =
          await service(client: responding(remoteRegistry())).refresh();

      expect(registry.forExportHeader('Hacks')!.label('en'), 'Remote Hacks');
      expect(await settings.read(SettingKeys.cachedRegistryUpdatedAt),
          '2099-01-01');
    });

    test('does not fetch again before the interval has passed', () async {
      var calls = 0;
      final client = responding(remoteRegistry(), onCall: () => calls++);
      final now = DateTime(2026, 1, 1, 12);

      await service(client: client, now: () => now).refresh();
      await service(client: client, now: () => now.add(const Duration(hours: 3)))
          .refresh();

      expect(calls, 1);
    });

    test('fetches again once the interval has passed', () async {
      var calls = 0;
      final client = responding(remoteRegistry(), onCall: () => calls++);
      final now = DateTime(2026, 1, 1, 12);

      await service(client: client, now: () => now).refresh();
      await service(client: client, now: () => now.add(const Duration(hours: 25)))
          .refresh();

      expect(calls, 2);
    });

    test('a failed attempt still counts towards the interval', () async {
      // Otherwise a device with no network retries on every single launch.
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        throw const SocketException('offline');
      });
      final now = DateTime(2026, 1, 1, 12);

      await service(client: client, now: () => now).refresh();
      await service(client: client, now: () => now.add(const Duration(hours: 2)))
          .refresh();

      expect(calls, 1);
    });

    test('leaves the cache alone when nothing changed', () async {
      await settings.write(SettingKeys.cachedRegistry, remoteRegistry());
      await settings.write(SettingKeys.cachedRegistryUpdatedAt, '2099-01-01');

      final registry = await service(
        client: responding(remoteRegistry(label: 'Should not be adopted')),
      ).refresh();

      // Same updated_at means same content: no reason to rewrite the cache.
      expect(registry.forExportHeader('Hacks')!.label('en'), 'Remote Hacks');
    });

    test('refuses an older version than the one already on the device', () async {
      // Between a release and a registry deploy, the copy bundled with the app
      // is the newer one — a plain "different, so take it" would quietly
      // downgrade the app to the older file on Pages.
      await settings.write(SettingKeys.cachedRegistry, remoteRegistry());
      await settings.write(SettingKeys.cachedRegistryUpdatedAt, '2099-06-01');

      final registry = await service(
        client: responding(
          remoteRegistry(updatedAt: '2099-01-01', label: 'Older Hacks'),
        ),
      ).refresh();

      expect(registry.forExportHeader('Hacks')!.label('en'), 'Remote Hacks');
      expect(await settings.read(SettingKeys.cachedRegistryUpdatedAt),
          '2099-06-01');
    });

    test('refuses a registry older than the bundled copy', () async {
      // Nothing cached yet, so the comparison is against the seed shipped with
      // the app — the case a fresh install actually hits.
      final seedStamp = (await service().load()).updatedAt;
      expect(seedStamp, isNotEmpty);

      final registry = await service(
        client: responding(
          remoteRegistry(updatedAt: '2000-01-01', label: 'Ancient Hacks'),
        ),
      ).refresh();

      expect(registry.length, 59, reason: 'the bundled copy is kept');
    });

    test('adopts a newer version', () async {
      await settings.write(SettingKeys.cachedRegistry, remoteRegistry());
      await settings.write(SettingKeys.cachedRegistryUpdatedAt, '2099-01-01');

      final registry = await service(
        client: responding(
          remoteRegistry(updatedAt: '2099-06-01', label: 'Newer Hacks'),
        ),
      ).refresh();

      expect(registry.forExportHeader('Hacks')!.label('en'), 'Newer Hacks');
    });
  });

  group('failure is silent and never destructive', () {
    Future<void> expectCacheSurvives(http.Client client) async {
      await settings.write(SettingKeys.cachedRegistry, remoteRegistry());
      await settings.write(SettingKeys.cachedRegistryUpdatedAt, '2099-01-01');

      final registry = await service(client: client).refresh();

      expect(registry.forExportHeader('Hacks')!.label('en'), 'Remote Hacks');
      expect(await settings.read(SettingKeys.cachedRegistry),
          remoteRegistry());
    }

    test('no network', () async {
      await expectCacheSurvives(
        MockClient((_) async => throw const SocketException('offline')),
      );
    });

    test('a 404 from the CDN', () async {
      await expectCacheSurvives(responding('nope', status: 404));
    });

    test('malformed JSON', () async {
      // The client-side half of the guarantee CI makes on the other end: a bad
      // file served by mistake must never replace a good cache.
      await expectCacheSurvives(responding('{ this is not json'));
    });

    test('valid JSON that is not a registry', () async {
      await expectCacheSurvives(responding('{"hello": "world"}'));
    });

    test('an empty registry', () async {
      await expectCacheSurvives(
        responding(jsonEncode({
          'schema_version': 1,
          'updated_at': '2099-09-09',
          'categories': [],
          'counters': <String, dynamic>{},
        })),
      );
    });

    test('without any cache, a failure still yields the bundled copy',
        () async {
      final registry = await service(
        client: MockClient((_) async => throw const SocketException('offline')),
      ).refresh();

      expect(registry.length, 59);
    });
  });

  group('the preference (§3.1.4)', () {
    test('online updates are on by default', () async {
      expect(await service().onlineUpdatesEnabled(), isTrue);
    });

    test('turning it off stops the app touching the network', () async {
      var calls = 0;
      final client = responding(remoteRegistry(), onCall: () => calls++);

      await service().setOnlineUpdatesEnabled(false);
      final registry = await service(client: client).refresh();

      expect(calls, 0);
      expect(registry.length, 59, reason: 'still fully usable offline');
    });

    test('turning it back on resumes fetching', () async {
      var calls = 0;
      final client = responding(remoteRegistry(), onCall: () => calls++);

      await service().setOnlineUpdatesEnabled(false);
      await service(client: client).refresh();
      await service().setOnlineUpdatesEnabled(true);
      await service(client: client).refresh();

      expect(calls, 1);
    });
  });

  test('the endpoint is the GitHub Pages URL of the registry', () {
    // Pages rather than raw.githubusercontent.com: a real CDN with standard
    // HTTP caching, and no aggressive rate limiting across many clients.
    expect(
      CounterRegistryService.defaultEndpoint,
      'https://nohzoh.github.io/FieldTally/registry/counters.json',
    );
  });
}
