import 'dart:convert';
import 'dart:io';

import 'package:fieldtally/data/changelog/changelog_loader.dart';
import 'package:fieldtally/domain/changelog.dart';
import 'package:fieldtally/domain/models/changelog_release.dart';
import 'package:flutter_test/flutter_test.dart';

ChangelogRelease release(int versionCode) => ChangelogRelease(
  versionCode: versionCode,
  version: '1.$versionCode.0',
  featureNotes: {
    'en': ['feature $versionCode'],
    'fr': ['nouveauté $versionCode'],
  },
  fixNotes: {
    'en': ['fix $versionCode'],
    'fr': ['correction $versionCode'],
  },
);

void main() {
  final all = [release(2), release(3), release(4)];

  group('what a device has not seen yet (§9)', () {
    test('a fresh install sees nothing at all', () {
      // No stored value means first install, not "everything shipped is new":
      // a changelog would be the first thing the app ever showed them.
      expect(
        unseenReleases(
          all: all,
          installedVersionCode: 4,
          lastSeenVersionCode: null,
        ),
        isEmpty,
      );
    });

    test('skipping versions shows everything missed, oldest first', () {
      final unseen = unseenReleases(
        all: [release(4), release(2), release(3)],
        installedVersionCode: 4,
        lastSeenVersionCode: 2,
      );

      expect(unseen.map((r) => r.versionCode), [3, 4]);
    });

    test('nothing new since the last launch shows nothing', () {
      expect(
        unseenReleases(
          all: all,
          installedVersionCode: 4,
          lastSeenVersionCode: 4,
        ),
        isEmpty,
      );
    });

    test('notes for a release not installed yet are not shown early', () {
      // The bundled file can only ever describe the build it shipped in, but
      // a downgrade — or a hand-edited file — must not leak future notes.
      final unseen = unseenReleases(
        all: all,
        installedVersionCode: 3,
        lastSeenVersionCode: 2,
      );

      expect(unseen.map((r) => r.versionCode), [3]);
    });
  });

  group('the file this build actually ships', () {
    // Read from the asset rather than a fixture: what has to hold is the file
    // the release is cut from, and it is edited once per release by hand.
    final shipped = const ChangelogLoader().parse(
      File('assets/changelog.json').readAsStringSync(),
    );

    test('is not vacuous', () {
      expect(shipped.length, greaterThan(3));
    });

    test('every release has a headline, in both languages (#112)', () {
      // The dialog after an update shows this and nothing else, so a release
      // that forgets one shows a bare version number to every agent who
      // updates. Cheaper to fail here.
      final missing = [
        for (final release in shipped)
          if (release.titles['en'] == null || release.titles['fr'] == null)
            release.version,
      ];
      expect(
        missing,
        isEmpty,
        reason: 'no headline for: ${missing.join(', ')}',
      );
    });

    test('and still carries its notes, for Settings and for offline', () {
      // The other half of #112: the dialog got shorter, the file did not. The
      // notes are bundled because the app promises to work with no network.
      for (final release in shipped) {
        expect(
          release.features('en').isNotEmpty || release.fixes('en').isNotEmpty,
          isTrue,
          reason: '${release.version} has a headline but nothing behind it',
        );
      }
    });
  });

  group('reading the bundled file', () {
    const loader = ChangelogLoader();

    test('parses releases keyed by version code, in both languages', () {
      final releases = loader.parse(
        jsonEncode({
          '2': {
            'version': '1.1.0',
            'features': {
              'en': ['Pick your language'],
              'fr': ['Choisis ta langue'],
            },
            'fixes': {
              'en': ['Dashboard labels fit again'],
              'fr': ['Les libellés du tableau de bord tiennent à nouveau'],
            },
          },
        }),
      );

      expect(releases.single.versionCode, 2);
      expect(releases.single.version, '1.1.0');
      expect(releases.single.features('fr'), ['Choisis ta langue']);
      expect(releases.single.fixes('en'), ['Dashboard labels fit again']);
    });

    test('an unknown language falls back to English', () {
      final releases = loader.parse(
        jsonEncode({
          '2': {
            'version': '1.1.0',
            'features': {
              'en': ['Pick your language'],
            },
            'fixes': <String, dynamic>{},
          },
        }),
      );

      expect(releases.single.features('de'), ['Pick your language']);
      expect(releases.single.fixes('en'), isEmpty);
    });

    test('a release with only fixes parses', () {
      final releases = loader.parse(
        jsonEncode({
          '3': {
            'version': '1.1.1',
            'fixes': {
              'en': ['One fix'],
            },
          },
        }),
      );

      expect(releases.single.features('en'), isEmpty);
      expect(releases.single.fixes('en'), ['One fix']);
    });
  });
}
