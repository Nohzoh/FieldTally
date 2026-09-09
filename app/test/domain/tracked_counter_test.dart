import 'package:fieldtally/domain/models/stat_snapshot.dart';
import 'package:fieldtally/domain/models/time_span.dart';
import 'package:fieldtally/domain/models/tracked_counter.dart';
import 'package:flutter_test/flutter_test.dart';

StatSnapshot at(DateTime date, Map<String, int> counters) => StatSnapshot(
      timeSpan: TimeSpan.allTime,
      agentName: 'AgentDemo',
      faction: 'Enlightened',
      recordedAt: date,
      level: 9,
      counters: counters,
    );

TrackedCounter of(List<TrackedCounter> counters, String header) =>
    counters.firstWhere((c) => c.exportHeader == header);

void main() {
  const tracker = CounterTracker();

  test('with no snapshot there is nothing to track', () {
    expect(tracker.track(const []), isEmpty);
  });

  test('records first seen, last seen and last value', () {
    final counters = tracker.track([
      at(DateTime(2026, 1, 1), {'Hacks': 10}),
      at(DateTime(2026, 1, 20), {'Hacks': 30}),
    ]);

    final hacks = of(counters, 'Hacks');
    expect(hacks.firstSeen, DateTime(2026, 1, 1));
    expect(hacks.lastSeen, DateTime(2026, 1, 20));
    expect(hacks.lastValue, 30);
    expect(hacks.isActive, isTrue);
    expect(hacks.isMonotonic, isTrue);
  });

  test('the order snapshots are given in does not matter', () {
    final counters = tracker.track([
      at(DateTime(2026, 1, 20), {'Hacks': 30}),
      at(DateTime(2026, 1, 1), {'Hacks': 10}),
    ]);

    expect(of(counters, 'Hacks').lastValue, 30);
    expect(of(counters, 'Hacks').firstSeen, DateTime(2026, 1, 1));
  });

  group('progress since the previous snapshot', () {
    test('is null with a single snapshot, which is not the same as zero', () {
      final counters = tracker.track([
        at(DateTime(2026, 1, 1), {'Hacks': 10}),
      ]);

      expect(of(counters, 'Hacks').previousValue, isNull);
      expect(of(counters, 'Hacks').delta, isNull);
    });

    test('compares the two most recent values', () {
      final counters = tracker.track([
        at(DateTime(2026, 1, 1), {'Hacks': 10}),
        at(DateTime(2026, 1, 10), {'Hacks': 30}),
        at(DateTime(2026, 1, 20), {'Hacks': 75}),
      ]);

      expect(of(counters, 'Hacks').previousValue, 30);
      expect(of(counters, 'Hacks').delta, 45);
    });

    test('zero progress is reported as zero, not as unknown', () {
      final counters = tracker.track([
        at(DateTime(2026, 1, 1), {'Hacks': 10}),
        at(DateTime(2026, 1, 10), {'Hacks': 10}),
      ]);

      expect(of(counters, 'Hacks').delta, 0);
    });

    test('skips snapshots that did not carry the counter', () {
      // A counter absent from an import has not moved, it was simply not
      // reported (§3.1.2). Comparing against a snapshot where it does not
      // exist would invent a delta.
      final counters = tracker.track([
        at(DateTime(2026, 1, 1), {'Orion Tokens': 100}),
        at(DateTime(2026, 1, 10), {'Hacks': 5}),
        at(DateTime(2026, 1, 20), {'Orion Tokens': 160}),
      ]);

      expect(of(counters, 'Orion Tokens').previousValue, 100);
      expect(of(counters, 'Orion Tokens').delta, 60);
    });
  });

  group('active to inactive after 45 days of absence (§3.1.2)', () {
    test('a counter absent for less than 45 days stays active', () {
      final counters = tracker.track([
        at(DateTime(2026, 1, 1), {'Hacks': 10, 'Orion Tokens': 500}),
        at(DateTime(2026, 2, 10), {'Hacks': 30}), // 40 days later
      ]);

      expect(of(counters, 'Orion Tokens').isActive, isTrue);
    });

    test('beyond 45 days it goes inactive but keeps its last value', () {
      final counters = tracker.track([
        at(DateTime(2026, 1, 1), {'Hacks': 10, 'Orion Tokens': 500}),
        at(DateTime(2026, 3, 1), {'Hacks': 30}), // 59 days later
      ]);

      final orion = of(counters, 'Orion Tokens');
      expect(orion.isActive, isFalse);
      // Frozen, never reset to zero.
      expect(orion.lastValue, 500);
      expect(of(counters, 'Hacks').isActive, isTrue);
    });

    test('a counter coming back picks its history up where it left off', () {
      final counters = tracker.track([
        at(DateTime(2026, 1, 1), {'Orion Tokens': 500}),
        at(DateTime(2026, 3, 1), {}), // absent: season over
        at(DateTime(2026, 6, 1), {'Orion Tokens': 800}), // anomaly returns
      ]);

      final orion = of(counters, 'Orion Tokens');
      expect(orion.isActive, isTrue);
      expect(orion.firstSeen, DateTime(2026, 1, 1));
      expect(orion.lastValue, 800);
    });

    test('age is measured against the last snapshot, not against today', () {
      // An agent who stops importing for six months must not find every
      // counter inactive: the rule measures absence *from the imports*, not
      // the mere passage of time.
      final counters = tracker.track([
        at(DateTime(2020, 1, 1), {'Hacks': 10}),
        at(DateTime(2020, 1, 15), {'Hacks': 20}),
      ]);

      expect(of(counters, 'Hacks').isActive, isTrue);
    });

    test('the threshold is configurable', () {
      const strict = CounterTracker(inactivityThreshold: Duration(days: 7));
      final counters = strict.track([
        at(DateTime(2026, 1, 1), {'Hacks': 10, 'Orion Tokens': 500}),
        at(DateTime(2026, 1, 20), {'Hacks': 30}),
      ]);

      expect(of(counters, 'Orion Tokens').isActive, isFalse);
    });
  });
}
