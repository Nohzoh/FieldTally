import 'package:home_widget/home_widget.dart' as plugin;

/// The Android home screen widget, at arm's length from the app (#154).
///
/// Behind an interface for the same reason [NotificationService] is: every
/// method below is a platform channel, and no widget test can reach a real
/// `AppWidgetProvider`. What decides *what* the widget says lives in
/// [HomeWidgetSummaryBuilder], which is pure and tested without this at all.
abstract interface class HomeWidgetGateway {
  /// Writes one string field. `null` clears it — a widget that reads a
  /// missing key and one that reads an explicitly empty string must not be
  /// allowed to disagree about what that means, so this is the only way in.
  Future<void> write(String key, String? value);

  /// Asks Android to redraw every instance of the widget from what has just
  /// been written. Writing without calling this leaves a stale widget on the
  /// home screen until the next scheduled update, hours away.
  Future<void> refresh();
}

/// Backed by the `home_widget` plugin.
class PluginHomeWidgetGateway implements HomeWidgetGateway {
  const PluginHomeWidgetGateway();

  /// Must match the Kotlin `AppWidgetProvider` class name exactly —
  /// `android/app/src/main/kotlin/.../FieldTallyWidgetProvider.kt`. Nothing
  /// checks the two stay in step; a rename on either side breaks the widget
  /// silently, which is why it is a single named constant rather than a
  /// string typed out at each call site.
  static const androidProviderName = 'FieldTallyWidgetProvider';

  @override
  Future<void> write(String key, String? value) =>
      plugin.HomeWidget.saveWidgetData<String>(key, value);

  @override
  Future<void> refresh() =>
      plugin.HomeWidget.updateWidget(androidName: androidProviderName);
}
