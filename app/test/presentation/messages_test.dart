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

  group('the reminder delay reads as a sentence at every choice (#69)', () {
    // One day is an offered delay, and both of these interpolate the number,
    // so without a plural the app says "after 1 days" and the lock screen
    // says "for 1 days".
    for (final choice in [1, 3, 7, 14, 30]) {
      test('the settings line at $choice day(s)', () {
        for (final l10n in [en, fr]) {
          final line = l10n.settingsReminderDelay(choice);
          expect(line, isNot(contains('1 days')));
          expect(line, isNot(contains('1 jours')));
          if (choice > 1) expect(line, contains('$choice'));
        }
      });

      test('the notification body at $choice day(s)', () {
        for (final l10n in [en, fr]) {
          final body = l10n.notificationReminderBody(choice);
          expect(body, isNot(contains('1 days')));
          expect(body, isNot(contains('1 jours')));
          if (choice > 1) expect(body, contains('$choice'));
        }
      });
    }

    test('a single day is worded, not numbered', () {
      expect(en.settingsReminderDelay(1), 'Remind me after a day without a snapshot');
      expect(fr.settingsReminderDelay(1), 'Me rappeler après un jour sans relevé');
      // "since yesterday" rather than "for 1 day": the reminder fires a day
      // after the last snapshot, and that is how a person would say it.
      expect(en.notificationReminderBody(1), startsWith('Nothing recorded since yesterday.'));
      expect(fr.notificationReminderBody(1), startsWith("Rien d'enregistré depuis hier."));
    });
  });
}
