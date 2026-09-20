/// Which counters one particular home screen widget instance shows (#181).
///
/// Every method is scoped to an `appWidgetId` — Android's own identifier for
/// a placed widget — rather than assuming a single shared selection, since
/// more than one instance can exist at once, each configured on its own.
abstract interface class WidgetInstanceCounterRepository {
  /// Export headers, in the order chosen for this instance. Empty for an
  /// instance that has not been configured yet.
  Future<List<String>> pinnedFor(int appWidgetId);

  Stream<List<String>> watchPinnedFor(int appWidgetId);

  /// Replaces this instance's whole selection at once — see
  /// `PinnedCounterRepository.setPinned` for why whole-list rather than
  /// add/remove.
  Future<void> setPinnedFor(int appWidgetId, List<String> exportHeaders);

  /// Drops everything stored for this instance. Called when Android reports
  /// the instance removed from the home screen — without this, a removed
  /// widget's configuration lingers in the table forever.
  Future<void> deleteFor(int appWidgetId);

  /// Bounds from #177: the widget's own native layout shows at most four
  /// rows, and an instance with nothing pinned would have nothing to draw.
  static const minPinned = 1;
  static const maxPinned = 4;
}
