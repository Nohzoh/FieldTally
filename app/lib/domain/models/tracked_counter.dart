import 'stat_snapshot.dart';

/// Status of a counter, decided **only** by its presence in recent imports
/// (§3.1.2).
///
/// There is deliberately no upfront notion of an "ephemeral" counter: when a
/// counter first appears, nothing tells whether it will be temporary (like
/// Orion/Apollo) or permanent. A single rule therefore applies to all of them
/// — an anomaly counter that ends, a base game counter retired by Niantic, or
/// an unknown novelty.
enum CounterStatus { active, inactive }

/// What the app knows about a counter, on top of its value history.
class TrackedCounter {
  const TrackedCounter({
    required this.exportHeader,
    required this.firstSeen,
    required this.lastSeen,
    required this.lastValue,
    required this.status,
    this.previousValue,
    this.isMonotonic = true,
  });

  /// Stable identity of the counter: its export column name.
  final String exportHeader;

  final DateTime firstSeen;
  final DateTime lastSeen;

  /// Last known value. Stays displayed, frozen, once the counter goes
  /// inactive — never read as a reset to zero.
  final int lastValue;

  /// Value at the previous snapshot that carried this counter, or null when
  /// there is only one.
  ///
  /// "Previous snapshot that carried it" rather than "previous snapshot": a
  /// counter absent from one import has not moved, it was simply not reported
  /// (§3.1.2). Comparing against a snapshot where it does not exist would
  /// invent a delta.
  final int? previousValue;

  final CounterStatus status;

  /// Feeds the behavioural guard. True by default: nearly every Ingress
  /// counter can only grow or stay flat.
  final bool isMonotonic;

  bool get isActive => status == CounterStatus.active;

  /// Progress since the previous snapshot, or null when there is nothing to
  /// compare against. Null and zero mean different things: "not known yet"
  /// versus "no progress".
  int? get delta =>
      previousValue == null ? null : lastValue - previousValue!;

  @override
  String toString() =>
      'TrackedCounter($exportHeader, $lastValue, ${status.name}, seen $lastSeen)';
}

/// Derives counter state from the snapshot history.
///
/// Nothing is stored: like every view in §3.2, this recomputes from the
/// snapshots so it stays consistent if one of them is edited or deleted.
class CounterTracker {
  const CounterTracker({this.inactivityThreshold = const Duration(days: 45)});

  /// How long a counter may be absent before it flips to inactive.
  final Duration inactivityThreshold;

  /// [snapshots] does not need to be sorted.
  ///
  /// Age is measured against the **most recent snapshot**, not against today.
  /// Otherwise an agent who stops importing for two months would see every
  /// counter flip to inactive at once, even though nothing happened in the
  /// game: the rule measures absence *from the imports*, not the passage of
  /// time.
  List<TrackedCounter> track(List<StatSnapshot> snapshots) {
    if (snapshots.isEmpty) return const [];

    final sorted = [...snapshots]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final reference = sorted.last.recordedAt;

    final firstSeen = <String, DateTime>{};
    final lastSeen = <String, DateTime>{};
    final lastValue = <String, int>{};
    final previousValue = <String, int>{};

    for (final snapshot in sorted) {
      for (final entry in snapshot.counters.entries) {
        firstSeen.putIfAbsent(entry.key, () => snapshot.recordedAt);
        // The value being replaced becomes the previous one, so the delta
        // always spans two snapshots that actually carried the counter.
        if (lastValue.containsKey(entry.key)) {
          previousValue[entry.key] = lastValue[entry.key]!;
        }
        lastSeen[entry.key] = snapshot.recordedAt;
        lastValue[entry.key] = entry.value;
      }
    }

    return [
      for (final header in lastSeen.keys)
        TrackedCounter(
          exportHeader: header,
          firstSeen: firstSeen[header]!,
          lastSeen: lastSeen[header]!,
          lastValue: lastValue[header]!,
          previousValue: previousValue[header],
          status: reference.difference(lastSeen[header]!) > inactivityThreshold
              ? CounterStatus.inactive
              : CounterStatus.active,
        ),
    ];
  }
}
