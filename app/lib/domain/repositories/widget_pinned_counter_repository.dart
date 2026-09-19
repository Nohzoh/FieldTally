/// Which counters the home screen widget shows (#174), independently of the
/// dashboard's own pins.
///
/// A preference rather than something derived from the snapshots, so it is
/// stored — the same reasoning as [PinnedCounterRepository]. Deliberately its
/// own table rather than a second column on `PinnedCounters`: the two
/// selections are allowed to diverge, and squeezing "is this for the
/// dashboard, the widget, or both" into one row would make every read decide
/// which one it means.
abstract interface class WidgetPinnedCounterRepository {
  /// Export headers, in the order the user arranged them.
  Future<List<String>> pinned();

  Stream<List<String>> watchPinned();

  /// Replaces the whole selection at once — see
  /// [PinnedCounterRepository.setPinned] for why whole-list rather than
  /// add/remove.
  Future<void> setPinned(List<String> exportHeaders);

  /// Bounds from #177: the widget's own native layout shows at most four
  /// rows, and a widget with nothing pinned would have nothing to draw.
  static const minPinned = 1;
  static const maxPinned = 4;
}
