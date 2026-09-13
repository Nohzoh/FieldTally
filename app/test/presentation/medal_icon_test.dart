import 'dart:convert';
import 'dart:io';

import 'package:fieldtally/domain/models/tracked_counter.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/widgets/counter_tile.dart';
import 'package:fieldtally/presentation/widgets/medal_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const seedPath = 'assets/counters_registry_seed.json';
const tiers = ['bronze', 'silver', 'gold', 'platinum', 'onyx'];

void main() {
  // Read from the seed rather than through the loader: what has to be covered
  // is the file a contributor edits, key by key.
  final seed = jsonDecode(File(seedPath).readAsStringSync())
      as Map<String, dynamic>;
  final tiered = [
    for (final entry in (seed['counters'] as Map<String, dynamic>).entries)
      if ((entry.value as Map<String, dynamic>)['tiers'] != null) entry.key,
  ]..sort();

  group('coverage of the registry', () {
    test('is not vacuous', () {
      // Guards the test below: an empty list would make it pass for the wrong
      // reason if the seed ever stopped carrying thresholds.
      expect(tiered.length, greaterThan(10));
    });

    test('every counter with thresholds has an emblem', () {
      // The one test worth having: adding a badge counter to the registry
      // without drawing its emblem leaves a gap in the list, and the registry
      // is edited far more often than this widget.
      final missing = [
        for (final key in tiered)
          if (!MedalIcon.existsFor(key)) key,
      ];
      expect(missing, isEmpty,
          reason: 'no emblem drawn for: ${missing.join(', ')}');
    });

    test('no emblem is drawn for a counter that has no thresholds', () {
      // The other direction: an emblem nothing can ever show is dead weight,
      // and usually a typo in the key.
      final orphans = [
        for (final key in MedalIcon.emblemKeys)
          if (!tiered.contains(key)) key,
      ];
      expect(orphans, isEmpty,
          reason: 'emblem drawn for untiered counters: ${orphans.join(', ')}');
    });
  });

  group('the metals', () {
    test('are all named by the registry, and all distinct', () {
      for (final brightness in Brightness.values) {
        final rims = [
          for (final tier in tiers) MedalMetal.of(tier, brightness)!.rim,
        ];
        expect(rims.toSet(), hasLength(tiers.length),
            reason: 'two tiers share a colour on $brightness');
      }
    });

    test('leave a tier this release does not know without one', () {
      // The registry is refreshed from the network (§3.1.4): it can name a
      // tier this build has never heard of, and guessing a colour for it
      // would be a lie about which medal was earned.
      expect(MedalMetal.of('mythic', Brightness.light), isNull);
      expect(MedalMetal.of(null, Brightness.light), isNull);
    });

    test('fill onyx solid, and only onyx', () {
      for (final brightness in Brightness.values) {
        for (final tier in tiers) {
          expect(MedalMetal.of(tier, brightness)!.solid, tier == 'onyx',
              reason: '$tier on $brightness');
        }
      }
    });
  });

  group('drawing', () {
    testWidgets('every emblem paints at every tier, and unearned', (
      tester,
    ) async {
      // A CustomPainter that throws only does so when it is painted, so the
      // seventeen shapes are worth walking rather than trusting.
      for (final key in tiered) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: Wrap(
              children: [
                  for (final tier in [null, ...tiers])
                    MedalIcon(counterKey: key, tierName: tier),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: key);
      }
    });

    testWidgets('an unknown counter takes its space but draws nothing', (
      tester,
    ) async {
      // Rendering a bare ring for a counter this release cannot draw would
      // read as a medal nobody can explain.
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: MedalIcon(counterKey: 'no_such_counter', tierName: 'gold'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(MedalIcon),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      expect(tester.getSize(find.byType(MedalIcon)), const Size(28, 28));
    });
  });

  group('the tier beside a counter', () {
    Future<void> pumpTile(WidgetTester tester, {String? tierName}) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CounterTile(
              counter: TrackedCounter(
                exportHeader: 'Unique Portals Visited',
                firstSeen: DateTime(2026, 1, 1),
                lastSeen: DateTime(2026, 1, 2),
                lastValue: 42,
                status: CounterStatus.active,
              ),
              label: 'Unique Portals Visited',
              medalKey: 'explorer',
              tierName: tierName,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('is named in words when one is reached', (tester) async {
      await pumpTile(tester, tierName: 'platinum');
      expect(find.textContaining('Platinum medal'), findsOneWidget);
    });

    testWidgets('says so plainly below the first threshold', (tester) async {
      // The emblem still shows, drawn unearned: "this counter has a medal and
      // you are on your way" is worth saying, and the greyed rim alone would
      // not say it (§3.9).
      await pumpTile(tester);
      expect(find.textContaining('No medal yet'), findsOneWidget);
      expect(find.byType(MedalIcon), findsOneWidget);
    });

    testWidgets('does not swallow the progress since the last import',
        (tester) async {
      await pumpTile(tester, tierName: 'gold');
      expect(find.textContaining('no comparison yet'), findsOneWidget);
    });
  });
}
