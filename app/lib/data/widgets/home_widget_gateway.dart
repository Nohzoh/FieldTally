import 'package:flutter/services.dart';
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

  /// The `appWidgetId`s of every instance currently placed on a home screen
  /// (#181) — each has its own counter selection, so anything that syncs the
  /// widget's content needs to know how many there are and which they are.
  /// `home_widget` has no equivalent of its own; this is a small channel of
  /// FieldTally's own, registered in `MainActivity`.
  Future<List<int>> instanceIds();

  /// Tells Android the `APPWIDGET_CONFIGURE` flow for [appWidgetId] is done
  /// (#181), so the widget host finishes placing it. Only meaningful from
  /// `WidgetConfigureActivity`'s own engine — calling it from the main app
  /// has nothing to report this to.
  Future<void> finishConfiguring(int appWidgetId);

  /// Asks the launcher to place a new widget instance on the home screen,
  /// pre-selected to [exportHeader] once its configuration activity opens
  /// (#181, from `CounterDetailScreen`). Returns `false` when the current
  /// launcher does not support this — a widget can still be placed the
  /// ordinary way, by long-pressing the home screen.
  ///
  /// Bypasses `home_widget`'s own `requestPinWidget()`: that call passes no
  /// extras, and carrying the counter through to `WidgetConfigureActivity`
  /// needs Android's own `EXTRA_APPWIDGET_PROVIDER_EXTRAS`, which the plugin
  /// has no equivalent for.
  Future<bool> requestPinWidget(String exportHeader);
}

/// Backed by the `home_widget` plugin, plus FieldTally's own small channel
/// for [instanceIds].
class PluginHomeWidgetGateway implements HomeWidgetGateway {
  const PluginHomeWidgetGateway();

  /// Must match the Kotlin `AppWidgetProvider` class name exactly —
  /// `android/app/src/main/kotlin/.../FieldTallyWidgetProvider.kt`. Nothing
  /// checks the two stay in step; a rename on either side breaks the widget
  /// silently, which is why it is a single named constant rather than a
  /// string typed out at each call site.
  static const androidProviderName = 'FieldTallyWidgetProvider';

  /// Must match the channel name registered in `MainActivity.kt`.
  static const _channel = MethodChannel('io.nohzoh.fieldtally/widget');

  @override
  Future<void> write(String key, String? value) =>
      plugin.HomeWidget.saveWidgetData<String>(key, value);

  @override
  Future<void> refresh() =>
      plugin.HomeWidget.updateWidget(androidName: androidProviderName);

  @override
  Future<List<int>> instanceIds() async {
    final ids = await _channel.invokeMethod<List<Object?>>('getWidgetIds');
    return [for (final id in ids ?? const []) id as int];
  }

  @override
  Future<void> finishConfiguring(int appWidgetId) =>
      _channel.invokeMethod('finishConfiguring', {'appWidgetId': appWidgetId});

  @override
  Future<bool> requestPinWidget(String exportHeader) async {
    final supported = await _channel.invokeMethod<bool>('requestPinWidget', {
      'exportHeader': exportHeader,
    });
    return supported ?? false;
  }
}
