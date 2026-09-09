import 'package:fieldtally/data/parsing/parse_exception.dart';
import 'package:fieldtally/domain/guards/import_guards.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/l10n/app_localizations.dart';
import 'package:fieldtally/presentation/messages.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

ImportCheck checkWith({
  TimeSpan timeSpan = TimeSpan.allTime,
  List<CounterRegression> regressions = const [],
}) =>
    ImportCheck(
      declaredTimeSpan: timeSpan,
      regressions: regressions,
      comparedAgainstPrevious: true,
    );

CounterRegression drop(String header, int from, int to) =>
    CounterRegression(exportHeader: header, previous: from, current: to);

void main() {
  late AppLocalizations en;
  late AppLocalizations fr;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    fr = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  group('import check messages', () {
    test('a clean import has nothing to say', () {
      expect(checkWith().message(en), isNull);
    });

    test('a partial period names the period it found', () {
      final message = checkWith(timeSpan: TimeSpan.week).message(en)!;

      expect(message, contains('WEEK'));
      expect(message, contains('All Time'));
    });

    test('the regression wording agrees with the number of counters', () {
      expect(
        checkWith(regressions: [drop('Hacks', 100, 80)]).message(en),
        contains('1 counter has gone down'),
      );
      expect(
        checkWith(regressions: [
          drop('Hacks', 100, 80),
          drop('Links Created', 9, 1),
        ]).message(en),
        contains('2 counters have gone down'),
      );
    });

    test('a declared partial period takes precedence over the drops', () {
      // The period already explains every regression: showing the cause beats
      // listing its consequences.
      final check = checkWith(
        timeSpan: TimeSpan.week,
        regressions: [drop('Hacks', 100, 80)],
      );

      expect(check.isPartialPeriod, isTrue);
      expect(check.hasRegressions, isTrue);
      expect(check.message(en), contains('WEEK'));
      expect(check.title(en), en.anomalyPartialPeriodTitle);
    });

    test('the same check reads in French without touching the domain', () {
      final check = checkWith(timeSpan: TimeSpan.week);

      expect(check.message(fr), contains('période'));
      expect(check.message(fr), isNot(check.message(en)));
    });
  });

  group('parse error messages', () {
    test('every failure kind has a translated message', () {
      // Guards against adding a kind and forgetting to word it.
      for (final kind in ParseErrorKind.values) {
        final error = ExportParseException(
          kind,
          column: 'Hacks',
          rawValue: 'lots',
          position: 3,
          expected: 64,
          actual: 63,
        );

        expect(error.message(en), isNotEmpty, reason: kind.name);
        expect(error.message(fr), isNotEmpty, reason: kind.name);
      }
    });

    test('a column failure names the column', () {
      const error =
          ExportParseException(ParseErrorKind.missingColumn, column: 'Agent Name');

      expect(error.message(en), contains('Agent Name'));
    });

    test('the raw value is offered only where it helps to fix the input', () {
      const notAnInteger = ExportParseException(
        ParseErrorKind.notAnInteger,
        column: 'Hacks',
        rawValue: 'lots',
      );
      const emptyText = ExportParseException(ParseErrorKind.emptyText);

      expect(notAnInteger.rawValueHint(en), contains('lots'));
      expect(emptyText.rawValueHint(en), isNull);
    });
  });

  group('time span labels', () {
    test('each period has a label', () {
      for (final span in TimeSpan.values) {
        expect(span.label(en), isNotEmpty, reason: span.name);
      }
    });

    test('the export values are shown verbatim, as Ingress spells them', () {
      // These strings mirror what the game displays, so they stay identical in
      // every language — the agent has to recognise them on their screen.
      expect(TimeSpan.allTime.label(en), 'ALL TIME');
      expect(TimeSpan.allTime.label(fr), 'ALL TIME');
      expect(TimeSpan.week.label(fr), 'WEEK');
    });
  });
}
