import 'package:drift/native.dart';
import 'package:fieldtally/data/changelog/changelog_loader.dart';
import 'package:fieldtally/data/changelog/changelog_service.dart';
import 'package:fieldtally/data/db/database.dart';
import 'package:fieldtally/data/repositories/drift_settings_repository.dart';
import 'package:fieldtally/domain/models/changelog_release.dart';
import 'package:fieldtally/domain/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the asset bundle, which a plain unit test has no access to.
class _FixedLoader implements ChangelogLoader {
  const _FixedLoader(this.releases);

  final List<ChangelogRelease> releases;

  @override
  Future<List<ChangelogRelease>> loadAll() async => releases;

  @override
  List<ChangelogRelease> parse(String rawJson) =>
      const ChangelogLoader().parse(rawJson);
}

ChangelogRelease release(int versionCode) => ChangelogRelease(
      versionCode: versionCode,
      version: '1.$versionCode.0',
      featureNotes: {
        'en': ['feature $versionCode'],
      },
      fixNotes: const {},
    );

void main() {
  late FieldTallyDatabase db;
  late SettingsRepository settings;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = FieldTallyDatabase(NativeDatabase.memory());
    settings = DriftSettingsRepository(db);
  });

  tearDown(() => db.close());

  ChangelogService service() => ChangelogService(
        settings: settings,
        loader: _FixedLoader([release(2), release(3)]),
      );

  Future<String?> lastSeen() =>
      settings.read(SettingKeys.changelogLastSeenBuild);

  group('checking for an update (§9)', () {
    test('a fresh install shows nothing and records the build', () async {
      expect(await service().checkForUpdate(3), isEmpty);
      expect(await lastSeen(), '3');
    });

    test('the launch after an update shows the new notes', () async {
      // First launch on 2 records it; the device then updates to 3.
      await service().checkForUpdate(2);

      final unseen = await service().checkForUpdate(3);

      expect(unseen.map((r) => r.versionCode), [3]);
      expect(await lastSeen(), '3');
    });

    test('skipping a version shows both sets of notes', () async {
      await settings.write(SettingKeys.changelogLastSeenBuild, '1');

      final unseen = await service().checkForUpdate(3);

      expect(unseen.map((r) => r.versionCode), [2, 3]);
    });

    test('a second launch on the same build shows nothing again', () async {
      await settings.write(SettingKeys.changelogLastSeenBuild, '2');
      expect(await service().checkForUpdate(3), isNotEmpty);

      expect(await service().checkForUpdate(3), isEmpty);
    });

    test('an unreadable stored value is treated as a fresh install', () async {
      // Recoverable by construction: the build is recorded on the way out, so
      // the next update behaves normally rather than repeating this.
      await settings.write(SettingKeys.changelogLastSeenBuild, 'not a number');

      expect(await service().checkForUpdate(3), isEmpty);
      expect(await lastSeen(), '3');
    });
  });

  group('reading the notes again from Settings', () {
    test('returns the running build notes whatever has been seen', () async {
      await service().checkForUpdate(3);

      final notes = await service().currentReleaseNotes(3);

      expect(notes.map((r) => r.versionCode), [3]);
    });

    test('a build with no bundled notes returns nothing', () async {
      expect(await service().currentReleaseNotes(99), isEmpty);
    });
  });
}
