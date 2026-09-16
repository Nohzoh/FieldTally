import 'package:fieldtally/domain/models/changelog_release.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/widgets/changelog_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

ChangelogRelease release({
  required int versionCode,
  required String version,
  Map<String, List<String>> features = const {},
  Map<String, List<String>> fixes = const {},
  Map<String, String> titles = const {},
}) => ChangelogRelease(
  versionCode: versionCode,
  version: version,
  featureNotes: features,
  fixNotes: fixes,
  titles: titles,
);

Future<void> pumpDialog(
  WidgetTester tester,
  List<ChangelogRelease> releases, {
  String languageCode = 'en',
  ChangelogDetail detail = ChangelogDetail.full,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showChangelogDialog(
            context,
            releases: releases,
            languageCode: languageCode,
            detail: detail,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('what changed after an update (§9)', () {
    testWidgets('separates what is new from what was fixed', (tester) async {
      await pumpDialog(tester, [
        release(
          versionCode: 2,
          version: '1.1.0',
          features: {
            'en': ['Pick your language'],
          },
          fixes: {
            'en': ['Dashboard labels fit again'],
          },
        ),
      ]);

      expect(find.text('✨ New'), findsOneWidget);
      expect(find.text('🐛 Fixed'), findsOneWidget);
      expect(find.text('Pick your language'), findsOneWidget);
      expect(find.text('Dashboard labels fit again'), findsOneWidget);
    });

    testWidgets('names the newest version it is showing', (tester) async {
      await pumpDialog(tester, [
        release(
          versionCode: 2,
          version: '1.1.0',
          features: {
            'en': ['Older'],
          },
        ),
        release(
          versionCode: 3,
          version: '1.2.0',
          features: {
            'en': ['Newer'],
          },
        ),
      ]);

      expect(find.textContaining('1.2.0'), findsOneWidget);
    });

    testWidgets('skipped versions read as one list, not one block each', (
      tester,
    ) async {
      // Someone who jumped two releases wants what changed, not a lesson in
      // release history.
      await pumpDialog(tester, [
        release(
          versionCode: 2,
          version: '1.1.0',
          features: {
            'en': ['Older feature'],
          },
        ),
        release(
          versionCode: 3,
          version: '1.2.0',
          features: {
            'en': ['Newer feature'],
          },
        ),
      ]);

      expect(find.text('Older feature'), findsOneWidget);
      expect(find.text('Newer feature'), findsOneWidget);
      // One heading for both releases, not one block per version.
      expect(find.text('✨ New'), findsOneWidget);
    });

    testWidgets('a release with no fixes shows no fixes heading', (
      tester,
    ) async {
      await pumpDialog(tester, [
        release(
          versionCode: 2,
          version: '1.1.0',
          features: {
            'en': ['Only a feature'],
          },
        ),
      ]);

      expect(find.text('🐛 Fixed'), findsNothing);
    });

    testWidgets('follows the locale', (tester) async {
      await pumpDialog(tester, [
        release(
          versionCode: 2,
          version: '1.1.0',
          features: {
            'en': ['Pick your language'],
            'fr': ['Choisis ta langue'],
          },
        ),
      ], languageCode: 'fr');

      expect(find.text('Choisis ta langue'), findsOneWidget);
      expect(find.text('Pick your language'), findsNothing);
      expect(find.text('Fermer'), findsOneWidget);
    });

    testWidgets('is dismissible', (tester) async {
      await pumpDialog(tester, [
        release(
          versionCode: 2,
          version: '1.1.0',
          features: {
            'en': ['Only a feature'],
          },
        ),
      ]);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Only a feature'), findsNothing);
    });

    testWidgets('a release carrying nothing shows no dialog at all', (
      tester,
    ) async {
      await pumpDialog(tester, [release(versionCode: 2, version: '1.1.0')]);

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('the dialog that interrupts (#112)', () {
    // It arrives uninvited, the moment an agent reopened the app to use it.
    // A headline is what gets read there; the rest is one tap away, and stays
    // bundled for Settings either way.

    testWidgets('says the headline, not the notes', (tester) async {
      await pumpDialog(tester, [
        release(
          versionCode: 7,
          version: '1.5.0',
          titles: {'en': 'Levels and seasonal medals'},
          features: {
            'en': ['Reaching a new level is announced'],
          },
        ),
      ], detail: ChangelogDetail.headlines);

      expect(find.text('1.5.0 — Levels and seasonal medals'), findsOneWidget);
      expect(find.text('Reaching a new level is announced'), findsNothing);
      expect(find.text('✨ New'), findsNothing);
      expect(find.text('Read the full notes'), findsOneWidget);
    });

    testWidgets('one headline and one link per skipped release', (
      tester,
    ) async {
      await pumpDialog(tester, [
        release(
          versionCode: 6,
          version: '1.4.0',
          titles: {'en': 'Counting past onyx'},
        ),
        release(
          versionCode: 7,
          version: '1.5.0',
          titles: {'en': 'Levels and seasonal medals'},
        ),
      ], detail: ChangelogDetail.headlines);

      expect(find.text('1.4.0 — Counting past onyx'), findsOneWidget);
      expect(find.text('1.5.0 — Levels and seasonal medals'), findsOneWidget);
      expect(find.text('Read the full notes'), findsNWidgets(2));
    });

    testWidgets('a release with no headline still shows its version', (
      tester,
    ) async {
      // The case that matters most, because it is the one this cannot be
      // tested into existence on a device: the notes come from the file the
      // *installed* app was built with, so a device on an older build has a
      // changelog.json written before `title` existed.
      await pumpDialog(tester, [
        release(versionCode: 2, version: '1.1.0'),
      ], detail: ChangelogDetail.headlines);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('1.1.0'), findsWidgets);
      expect(find.text('Read the full notes'), findsOneWidget);
    });

    testWidgets('follows the locale, headline and link alike', (tester) async {
      await pumpDialog(
        tester,
        [
          release(
            versionCode: 7,
            version: '1.5.0',
            titles: {'en': 'Levels', 'fr': 'Les niveaux'},
          ),
        ],
        languageCode: 'fr',
        detail: ChangelogDetail.headlines,
      );

      expect(find.text('1.5.0 — Les niveaux'), findsOneWidget);
      expect(find.text('Lire les notes complètes'), findsOneWidget);
    });

    test('the link points at the tag the release workflow creates', () {
      expect(
        releaseUrl('1.5.0').toString(),
        'https://github.com/Nohzoh/FieldTally/releases/tag/v1.5.0',
      );
    });
  });
}
