package io.nohzoh.fieldtally

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Runs the `APPWIDGET_CONFIGURE` flow (#181): the screen the launcher shows
 * when a widget instance is first placed, and again from that instance's own
 * long-press → Configure. A separate `FlutterActivity`/engine from
 * `MainActivity`'s, started at the `configureWidgetMain` Dart entry point
 * rather than `main()`, so an ordinary app launch never touches this code.
 */
class WidgetConfigureActivity : FlutterActivity() {
  companion object {
    private const val CHANNEL = "io.nohzoh.fieldtally/widget"
  }

  private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

  override fun onCreate(savedInstanceState: Bundle?) {
    // Android convention: back-pressed without saving must cancel the
    // placement, not silently succeed. Set before the Flutter engine (and
    // its `finishConfiguring` channel) exists at all, so it holds even if
    // that engine never starts.
    setResult(RESULT_CANCELED)

    // Read before super.onCreate(): that call is what creates the Flutter
    // engine and asks getInitialRoute() for its route, so it has to be
    // known before it runs, not after.
    appWidgetId =
        intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            ?: AppWidgetManager.INVALID_APPWIDGET_ID

    if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
      finish()
      return
    }

    super.onCreate(savedInstanceState)
  }

  override fun getDartEntrypointFunctionName() = "configureWidgetMain"

  override fun getInitialRoute() = "/configure-widget/$appWidgetId"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        call,
        result ->
      when (call.method) {
        "finishConfiguring" -> {
          val resultValue = Intent()
          resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
          setResult(RESULT_OK, resultValue)
          finish()
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }
  }
}
