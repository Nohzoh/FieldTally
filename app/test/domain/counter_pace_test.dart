// Recent progress, measured over a window (#89).
//
// The list used to rank on `lastValue - previousValue`: an absolute difference
// across "the previous snapshot that carried this counter", which is a rank
// rather than a duration. Two snapshots an hour apart and two six weeks apart
// produced numbers the sort then compared as equals.

import 'package:fieldtally/domain/counter_pace.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:flutter_test/flutter_test.dart';

StatSnapshot at(DateTime date, Map<String, int> counters) => StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: date,
      level: 9,
      counters: counters,
    );

final day = DateTime(2026, 3, 1);
DateTime on(int offset) => day.add(Duration(days: offset));

void main() {
  group('the window decides the ranking, not the snapshot spacing', () {
    // Hacks burst early and has crawled since; Links Created has been steady
    // and just spiked. Over thirty days Hacks is far ahead; since the last
    // snapshot Links Created is. Both readings are true, and the agent picks
    // which question they are asking — which is the whole point of #89.
    final history = [
      at(on(0), const {'Hacks': 0, 'Links Created': 0}),
      at(on(1), const {'Hacks': 3000, 'Links Created': 10}),
      for (var d = 2; d <= 29; d++)
        at(on(d), {'Hacks': 3000 + d, 'Links Created': 10 * d}),
      at(on(30), const {'Hacks': 3030, 'Links Created': 2000}),
    ];

    test('since the last snapshot, the recent spike wins', () {
      final paces = paceByCounter(history, ProgressWindow.sinceLastSnapshot);

      expect(paces['Links Created']!.perDay,
          greaterThan(paces['Hacks']!.perDay));
    });

    test('over a month, the early burst wins', () {
      final paces = paceByCounter(history, ProgressWindow.month);

      expect(paces['Hacks']!.perDay, greaterThan(paces['Links Created']!.perDay));
    });

    test('over a week, neither the burst nor the whole history', () {
      final paces = paceByCounter(history, ProgressWindow.week);

      // The burst is 30 days behind, outside the window entirely.
      expect(paces['Hacks']!.perDay, lessThan(10));
    });
  });

  group('the span measured is the real one', () {
    test('an agent who imports monthly gets a rate, not a seven-day total', () {
      // Nothing sits seven days back, so the anchor is the snapshot forty days
      // before the last one. Dividing by seven would claim a pace four times
      // what the agent actually managed.
      final paces = paceByCounter([
        at(on(0), const {'Hacks': 1000}),
        at(on(40), const {'Hacks': 1400}),
      ], ProgressWindow.week);

      expect(paces['Hacks']!.days, closeTo(40, 0.001));
      expect(paces['Hacks']!.perDay, closeTo(10, 0.001));
      expect(paces['Hacks']!.gain, 400);
    });

    test('measured back from the last snapshot, not from today', () {
      // §3.5 and §3.6: an agent who stopped importing has not slowed down,
      // the app stopped hearing about it. These snapshots are years old and
      // the pace is still a pace.
      final paces = paceByCounter([
        at(DateTime(2020, 1, 1), const {'Hacks': 0}),
        at(DateTime(2020, 1, 11), const {'Hacks': 100}),
      ], ProgressWindow.week);

      expect(paces['Hacks']!.perDay, closeTo(10, 0.001));
    });
  });

  group('what cannot be measured is absent, not zero', () {
    test('a counter seen once has no pace', () {
      final paces = paceByCounter([
        at(on(0), const {'Hacks': 10}),
        at(on(1), const {'Links Created': 5}),
      ], ProgressWindow.month);

      expect(paces, isEmpty);
    });

    test('a single snapshot yields nothing at all', () {
      expect(paceByCounter([at(on(0), const {'Hacks': 10})],
          ProgressWindow.month), isEmpty);
    });

    test('two snapshots at the same instant give no span to divide by', () {
      final paces = paceByCounter([
        at(on(0), const {'Hacks': 10}),
        at(on(0), const {'Hacks': 20}),
      ], ProgressWindow.month);

      expect(paces, isEmpty);
    });
  });

  group('a counter absent from a snapshot has not moved', () {
    test('it is never anchored on one that did not carry it', () {
      // §3.1.2: absence is silence, not a zero. Anchoring Links Created on the
      // middle snapshot would invent a value it never had.
      final paces = paceByCounter([
        at(on(0), const {'Hacks': 0, 'Links Created': 100}),
        at(on(5), const {'Hacks': 50}),
        at(on(10), const {'Hacks': 100, 'Links Created': 200}),
      ], ProgressWindow.month);

      expect(paces['Links Created']!.days, closeTo(10, 0.001));
      expect(paces['Links Created']!.gain, 100);
    });
  });

  group('a counter that went backwards', () {
    test('reports a negative pace rather than being hidden', () {
      // A recursion drops AP and Level (§3.1.2). It is real movement, and the
      // sort should put it where it belongs — last — rather than treat it as
      // unmeasurable.
      final paces = paceByCounter([
        at(on(0), const {'AP': 40000000}),
        at(on(10), const {'AP': 1000}),
      ], ProgressWindow.month);

      expect(paces['AP']!.perDay, lessThan(0));
    });
  });
}
