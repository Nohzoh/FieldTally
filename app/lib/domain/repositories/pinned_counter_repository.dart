/// Which counters the dashboard shows (§3.3).
///
/// A preference rather than something derived from the snapshots, so it is
/// stored. Kept behind an interface for the same reason as the snapshots
/// (§5.2): screens should not know where it lives.
abstract interface class PinnedCounterRepository {
  /// Export headers, in the order the user arranged them.
  Future<List<String>> pinned();

  Stream<List<String>> watchPinned();

  /// Replaces the whole selection at once.
  ///
  /// Whole-list rather than add/remove: the customise screen edits a set and
  /// commits it, and replacing avoids leaving holes in the ordering.
  Future<void> setPinned(List<String> exportHeaders);

  /// The dashboard is useless empty, so a fresh install shows these until the
  /// agent picks their own.
  static const defaults = <String>[
    'Lifetime AP',
    'Unique Portals Visited',
    'Hacks',
    'Distance Walked',
  ];

  /// Bounds from §3.3: enough to be a dashboard, few enough to stay readable.
  static const minPinned = 4;
  static const maxPinned = 8;
}
