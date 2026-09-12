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
}) =>
    ChangelogRelease(
      versionCode: versionCode,
      version: version,
      featureNotes: features,
      fixNotes: fixes,
    );

Future<void> pumpDialog(
  WidgetTester tester,
  List<ChangelogRelease> releases, {
  String languageCode = 'en',
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
        release(versionCode: 2, version: '1.1.0', features: {
          'en': ['Older'],
        }),
        release(versionCode: 3, version: '1.2.0', features: {
          'en': ['Newer'],
        }),
      ]);

      expect(find.textContaining('1.2.0'), findsOneWidget);
    });

    testWidgets('skipped versions read as one list, not one block each',
        (tester) async {
      // Someone who jumped two releases wants what changed, not a lesson in
      // release history.
      await pumpDialog(tester, [
        release(versionCode: 2, version: '1.1.0', features: {
          'en': ['Older feature'],
        }),
        release(versionCode: 3, version: '1.2.0', features: {
          'en': ['Newer feature'],
        }),
      ]);

      expect(find.text('Older feature'), findsOneWidget);
      expect(find.text('Newer feature'), findsOneWidget);
      // One heading for both releases, not one block per version.
      expect(find.text('✨ New'), findsOneWidget);
    });

    testWidgets('a release with no fixes shows no fixes heading',
        (tester) async {
      await pumpDialog(tester, [
        release(versionCode: 2, version: '1.1.0', features: {
          'en': ['Only a feature'],
        }),
      ]);

      expect(find.text('🐛 Fixed'), findsNothing);
    });

    testWidgets('follows the locale', (tester) async {
      await pumpDialog(
        tester,
        [
          release(
            versionCode: 2,
            version: '1.1.0',
            features: {
              'en': ['Pick your language'],
              'fr': ['Choisis ta langue'],
            },
          ),
        ],
        languageCode: 'fr',
      );

      expect(find.text('Choisis ta langue'), findsOneWidget);
      expect(find.text('Pick your language'), findsNothing);
      expect(find.text('Fermer'), findsOneWidget);
    });

    testWidgets('is dismissible', (tester) async {
      await pumpDialog(tester, [
        release(versionCode: 2, version: '1.1.0', features: {
          'en': ['Only a feature'],
        }),
      ]);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Only a feature'), findsNothing);
    });

    testWidgets('a release carrying nothing shows no dialog at all',
        (tester) async {
      await pumpDialog(tester, [release(versionCode: 2, version: '1.1.0')]);

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
