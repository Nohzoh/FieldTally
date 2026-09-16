// The counter tile's subtitle (#63, #87).

import 'package:fieldtally/domain/models/tracked_counter.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/widgets/counter_tile.dart';
import 'package:fieldtally/presentation/widgets/medal_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

TrackedCounter counterOf({required int value, int? previous}) => TrackedCounter(
  exportHeader: 'Unique Portals Visited',
  firstSeen: DateTime(2026, 1, 1),
  lastSeen: DateTime(2026, 6, 1),
  lastValue: value,
  previousValue: previous,
  status: CounterStatus.active,
);

Future<void> pumpTile(
  WidgetTester tester, {
  required TrackedCounter counter,
  String? medalKey = 'explorer',
  String? tierName,
  int? tierMultiple,
  double width = 360,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: CounterTile(
            counter: counter,
            label: 'Unique Portals Visited',
            medalKey: medalKey,
            tierName: tierName,
            tierMultiple: tierMultiple,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the subtitle names the tier', () {
    testWidgets('with no multiplier while a tier is still ahead', (
      tester,
    ) async {
      await pumpTile(
        tester,
        counter: counterOf(value: 9756, previous: 9000),
        tierName: 'gold',
      );

      expect(find.textContaining('Gold medal ·'), findsOneWidget);
    });

    testWidgets('and carries the multiplier past the top tier (#87)', (
      tester,
    ) async {
      await pumpTile(
        tester,
        counter: counterOf(value: 210000, previous: 209000),
        tierName: 'onyx',
        tierMultiple: 7,
      );

      expect(find.textContaining('Onyx medal ×7 ·'), findsOneWidget);
    });

    testWidgets('but not a bare ×1, which says nothing the medal does not', (
      tester,
    ) async {
      await pumpTile(
        tester,
        counter: counterOf(value: 41000, previous: 40000),
        tierName: 'onyx',
        tierMultiple: 1,
      );

      expect(find.textContaining('Onyx medal ·'), findsOneWidget);
      expect(find.textContaining('×'), findsNothing);
    });
  });

  group('the subtitle fits the row it is given', () {
    // The multiplier lengthens a line that was already the longest thing on
    // the tile. A subtitle that does not fit is not a cosmetic problem: it
    // throws during layout, which fails any test that happens to pump it.
    for (final width in [360.0, 320.0, 280.0]) {
      testWidgets('at ${width.toInt()} logical pixels', (tester) async {
        await pumpTile(
          tester,
          counter: counterOf(value: 210000, previous: 9756),
          tierName: 'onyx',
          tierMultiple: 7,
          width: width,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('a counter this release cannot draw an emblem for (#98)', () {
    // The ordinary case for a seasonal medal, not a contrived one: a ladder
    // reaches an installed app through the registry (§3.1.4), an emblem only
    // in a release. They cannot arrive together.
    const undrawn = 'not_an_emblem_this_release_knows';

    testWidgets('still names the tier', (tester) async {
      expect(
        MedalIcon.existsFor(undrawn),
        isFalse,
        reason: 'the premise of this test',
      );

      await pumpTile(
        tester,
        counter: counterOf(value: 900, previous: 400),
        medalKey: undrawn,
        tierName: 'silver',
      );

      expect(find.textContaining('Silver medal ·'), findsOneWidget);
    });

    testWidgets('and still says so before the first threshold', (tester) async {
      await pumpTile(
        tester,
        counter: counterOf(value: 10, previous: 5),
        medalKey: undrawn,
      );

      expect(find.textContaining('No medal yet ·'), findsOneWidget);
    });

    testWidgets('a counter with no medal at all is untouched', (tester) async {
      await pumpTile(
        tester,
        counter: counterOf(value: 10, previous: 5),
        medalKey: null,
      );

      expect(find.textContaining('medal'), findsNothing);
    });
  });
}
