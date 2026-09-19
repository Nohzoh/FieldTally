// What the home screen widget's storage ends up holding (#154).

import 'dart:io';

import 'package:fieldtally/data/registry/counter_registry_loader.dart';
import 'package:fieldtally/domain/home_widget_summary.dart';
import 'package:fieldtally/domain/models/counter_registry.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/home_widget_coordinator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_home_widget_gateway.dart';

const seedPath = 'assets/counters_registry_seed.json';

HomeWidgetSummary summaryOf(List<HomeWidgetLine> lines, {bool pinned = true}) =>
    HomeWidgetSummary(lines: lines, hasAnyPinned: pinned);

void main() {
  late AppLocalizations en;
  late AppLocalizations fr;
  late CounterRegistry registry;
  late FakeHomeWidgetGateway gateway;
  late HomeWidgetCoordinator coordinator;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    fr = await AppLocalizations.delegate.load(const Locale('fr'));
    registry = const CounterRegistryLoader().parse(
      File(seedPath).readAsStringSync(),
    );
  });

  setUp(() {
    gateway = FakeHomeWidgetGateway();
    coordinator = HomeWidgetCoordinator(gateway: gateway);
  });

  group('the two message states', () {
    test('nothing pinned says so, and clears any old lines', () async {
      // Seeded, not left absent — see the same note on the "stale second
      // line" test below: an unwritten key and an explicitly cleared one
      // look identical to a bare map lookup.
      gateway.written['widget_label_0'] = 'Hacks';
      gateway.written['widget_line_0'] = '+320';

      await coordinator.sync(
        summary: summaryOf(const [], pinned: false),
        l10n: en,
        languageCode: 'en',
      );

      expect(gateway.written['widget_state'], 'unpinned');
      expect(gateway.written['widget_title'], 'Pin a counter');
      expect(gateway.written['widget_label_0'], isNull);
      expect(gateway.written['widget_line_0'], isNull);
    });

    test('pinned but nothing recorded yet reads differently', () async {
      await coordinator.sync(
        summary: summaryOf(const []),
        l10n: en,
        languageCode: 'en',
      );

      expect(gateway.written['widget_state'], 'empty');
      // Shares the dashboard's own empty-state copy, not a new sentence.
      expect(gateway.written['widget_title'], 'No snapshot yet');
    });

    test('refreshes the widget on every sync, message or data', () async {
      await coordinator.sync(
        summary: summaryOf(const [], pinned: false),
        l10n: en,
        languageCode: 'en',
      );
      expect(gateway.refreshes, 1);
    });
  });

  group('a line of data', () {
    test(
      'joins the value, the delta and the distance to the next tier',
      () async {
        await coordinator.sync(
          summary: summaryOf(const [
            (
              exportHeader: 'Hacks',
              value: 12450,
              delta: 320,
              nextTier: 'silver',
              remainingToNextTier: 1200,
            ),
          ]),
          l10n: en,
          languageCode: 'en',
          registry: registry,
        );

        expect(gateway.written['widget_state'], 'data');
        expect(gateway.written['widget_label_0'], 'Hacks');
        expect(gateway.written['widget_value_0'], '12,450');
        expect(gateway.written['widget_line_0'], '+320 · 1,200 to Silver');
      },
    );

    test('a fall is signed, not silently made positive', () async {
      await coordinator.sync(
        summary: summaryOf(const [
          (
            exportHeader: 'Current AP',
            value: 0,
            delta: -24800000,
            nextTier: null,
            remainingToNextTier: null,
          ),
        ]),
        l10n: en,
        languageCode: 'en',
      );

      expect(gateway.written['widget_line_0'], '−24,800,000');
    });

    test('no delta and no tier is a value with nothing else said', () async {
      await coordinator.sync(
        summary: summaryOf(const [
          (
            exportHeader: 'Hacks',
            value: 500,
            delta: null,
            nextTier: null,
            remainingToNextTier: null,
          ),
        ]),
        l10n: en,
        languageCode: 'en',
      );

      expect(gateway.written['widget_line_0'], '');
    });

    test(
      'without a registry the raw export header stands in for the label',
      () async {
        await coordinator.sync(
          summary: summaryOf(const [
            (
              exportHeader: 'Hacks',
              value: 500,
              delta: null,
              nextTier: null,
              remainingToNextTier: null,
            ),
          ]),
          l10n: en,
          languageCode: 'en',
        );

        expect(gateway.written['widget_label_0'], 'Hacks');
      },
    );

    test('a stale second line from before an unpin is cleared', () async {
      // Seeded rather than left absent: an unwritten key and an explicitly
      // cleared one are indistinguishable to this fake's map lookup, and a
      // test that never tells the two apart cannot catch the guard going
      // missing — it did, on the first draft of this test.
      gateway.written['widget_label_1'] = 'Links Created';
      gateway.written['widget_value_1'] = '7';

      await coordinator.sync(
        summary: summaryOf(const [
          (
            exportHeader: 'Hacks',
            value: 500,
            delta: null,
            nextTier: null,
            remainingToNextTier: null,
          ),
        ]),
        l10n: en,
        languageCode: 'en',
        registry: registry,
      );

      expect(gateway.written['widget_label_1'], isNull);
      expect(gateway.written['widget_value_1'], isNull);
    });

    test('numbers and the tier name follow the language asked for', () async {
      await coordinator.sync(
        summary: summaryOf(const [
          (
            exportHeader: 'Hacks',
            value: 12450,
            delta: null,
            nextTier: 'silver',
            remainingToNextTier: 1200,
          ),
        ]),
        l10n: fr,
        languageCode: 'fr',
        registry: registry,
      );

      // French groups thousands with U+202F, narrow no-break space, not an
      // ordinary one — NumberFormat's own choice (confirmed against its
      // actual output, not assumed), reproduced here rather than typed by
      // eye so the test does not silently compare two characters that merely
      // look alike.
      const nnbsp = '\u202F';
      expect(gateway.written['widget_value_0'], '12${nnbsp}450');
      expect(gateway.written['widget_line_0'], '1${nnbsp}200 avant Argent');
    });
  });
}
