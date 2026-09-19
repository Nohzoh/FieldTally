// Noticing that a counter started or stopped moving (#149).
//
// The issue asked for "your pace has doubled". These tests are what is left
// after taking that apart: a ratio needs a threshold, a threshold is a number
// nobody can defend, and below it the remark is noise. Stopping and starting
// are facts, so they are what the app says.

import 'package:fieldtally/domain/counter_pace.dart';
import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/pace_change.dart';
import 'package:flutter_test/flutter_test.dart';

StatSnapshot at(DateTime date, Map<String, int> counters) => StatSnapshot(
  timeSpan: TimeSpan.allTime,
  agentName: 'AgentDemo',
  faction: 'Enlightened',
  recordedAt: date,
  level: 9,
  counters: counters,
);

/// Three snapshots a month apart: the start of the earlier window, the border
/// between the two, and the end of the recent one.
///
/// Each counter is given its value at those three moments, which is what makes
/// "was moving, is not" and its opposite expressible in one line.
List<StatSnapshot> twoWindows(Map<String, (int, int, int)> counters) {
  final end = DateTime(2026, 6, 30);
  final middle = end.subtract(const Duration(days: 30));
  final start = end.subtract(const Duration(days: 60));

  return [
    at(start, {for (final e in counters.entries) e.key: e.value.$1}),
    at(middle, {for (final e in counters.entries) e.key: e.value.$2}),
    at(end, {for (final e in counters.entries) e.key: e.value.$3}),
  ];
}

List<String> headersOf(List<CounterShift> shifts) => [
  for (final s in shifts) s.exportHeader,
];

void main() {
  const finder = PaceChangeFinder();

  group('what is worth saying', () {
    test('a counter that was moving and has stopped', () {
      final shifts = finder.find(
        snapshots: twoWindows(const {'Hacks': (0, 300, 300)}),
        pinned: const ['Hacks'],
      );

      expect(shifts.single.shift, PaceShift.stopped);
      expect(shifts.single.was.gain, 300);
      expect(shifts.single.now.gain, 0);
    });

    test('a counter that was still and has started', () {
      final shifts = finder.find(
        snapshots: twoWindows(const {'Hacks': (300, 300, 600)}),
        pinned: const ['Hacks'],
      );

      expect(shifts.single.shift, PaceShift.resumed);
      expect(shifts.single.was.gain, 0);
      expect(shifts.single.now.gain, 300);
    });
  });

  group('what is deliberately not said', () {
    test('a counter that merely sped up', () {
      // The case the issue asked for, and the one left out on purpose: saying
      // it needs a threshold, and every threshold is arbitrary.
      final shifts = finder.find(
        snapshots: twoWindows(const {'Hacks': (0, 100, 1000)}),
        pinned: const ['Hacks'],
      );

      expect(shifts, isEmpty);
    });

    test('a counter that merely slowed down', () {
      final shifts = finder.find(
        snapshots: twoWindows(const {'Hacks': (0, 1000, 1010)}),
        pinned: const ['Hacks'],
      );

      expect(shifts, isEmpty);
    });

    test('a counter that has not moved in either window', () {
      // It stopped some time ago and has already been mentioned. Saying it
      // again every month is how a remark becomes noise.
      final shifts = finder.find(
        snapshots: twoWindows(const {'Hacks': (300, 300, 300)}),
        pinned: const ['Hacks'],
      );

      expect(shifts, isEmpty);
    });

    test('a counter that is not pinned', () {
      final shifts = finder.find(
        snapshots: twoWindows(const {'Hacks': (0, 300, 300)}),
        pinned: const ['Links Created'],
      );

      expect(shifts, isEmpty);
    });

    test('a recursion, which is not a stop', () {
      // Current AP genuinely falls (§3.1.3). No guard implements this: a
      // negative gain is neither `> 0` nor `== 0`, so it matches neither
      // branch. Kept as a test of the behaviour rather than of a line — the
      // guard that did exist for it was removed once it failed to fail.
      final shifts = finder.find(
        snapshots: twoWindows(const {'Current AP': (1000, 5000, 0)}),
        pinned: const ['Current AP'],
      );

      expect(shifts, isEmpty);
    });

    test('a history too short to have an earlier window', () {
      // Nothing is known about how this counter used to behave, which is not
      // the same as it having been still.
      final shifts = finder.find(
        snapshots: [
          at(DateTime(2026, 6, 20), const {'Hacks': 100}),
          at(DateTime(2026, 6, 30), const {'Hacks': 100}),
        ],
        pinned: const ['Hacks'],
      );

      expect(shifts, isEmpty);
    });

    test('nothing pinned at all', () {
      expect(
        finder.find(
          snapshots: twoWindows(const {'Hacks': (0, 300, 300)}),
          pinned: const [],
        ),
        isEmpty,
      );
    });
  });

  group('the order and the size of the remark', () {
    test('stops come before restarts', () {
      final shifts = finder.find(
        snapshots: twoWindows(const {
          'Links Created': (100, 100, 200),
          'Hacks': (0, 300, 300),
        }),
        // Pinned the other way round, so only the rule can produce this order.
        pinned: const ['Links Created', 'Hacks'],
      );

      expect(headersOf(shifts), ['Hacks', 'Links Created']);
    });

    test('within a kind, the pinned order is the agent\'s', () {
      final shifts = finder.find(
        snapshots: twoWindows(const {
          'Hacks': (0, 300, 300),
          'Links Created': (0, 50, 50),
          'Resonators Deployed': (0, 9000, 9000),
        }),
        pinned: const ['Links Created', 'Resonators Deployed', 'Hacks'],
      );

      // Not by how much was being gained: across counters five orders of
      // magnitude apart, a raw difference is not a comparison.
      expect(headersOf(shifts), [
        'Links Created',
        'Resonators Deployed',
        'Hacks',
      ]);
    });

    test('never more than asked for', () {
      final shifts = const PaceChangeFinder(limit: 2).find(
        snapshots: twoWindows(const {
          'Hacks': (0, 300, 300),
          'Links Created': (0, 50, 50),
          'Resonators Deployed': (0, 9000, 9000),
        }),
        pinned: const ['Hacks', 'Links Created', 'Resonators Deployed'],
      );

      expect(shifts.length, 2);
    });
  });

  group('the windows themselves', () {
    test('are measured from the last snapshot, not from today', () {
      // An agent who stopped importing two months ago has not stopped playing
      // — the app stopped hearing about it, and must not say otherwise.
      final shifts = finder.find(
        snapshots: [
          at(DateTime(2020, 1, 1), const {'Hacks': 0}),
          at(DateTime(2020, 1, 31), const {'Hacks': 300}),
          at(DateTime(2020, 3, 1), const {'Hacks': 300}),
        ],
        pinned: const ['Hacks'],
      );

      expect(shifts.single.shift, PaceShift.stopped);
    });

    test('the window is the one asked for', () {
      // A week's worth of stillness inside a month that was busy is not a
      // stop over the month.
      final end = DateTime(2026, 6, 30);
      final snapshots = [
        at(end.subtract(const Duration(days: 14)), const {'Hacks': 0}),
        at(end.subtract(const Duration(days: 7)), const {'Hacks': 300}),
        at(end, const {'Hacks': 300}),
      ];

      expect(
        const PaceChangeFinder(
          window: ProgressWindow.week,
        ).find(snapshots: snapshots, pinned: const ['Hacks']).single.shift,
        PaceShift.stopped,
      );
      expect(
        const PaceChangeFinder().find(
          snapshots: snapshots,
          pinned: const ['Hacks'],
        ),
        isEmpty,
        reason: 'over a month, that counter did move',
      );
    });
  });
}
