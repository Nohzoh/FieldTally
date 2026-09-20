package io.nohzoh.fieldtally

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.net.Uri
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

    /** Key `MainActivity`'s `requestPinWidget` puts the tapped counter under,
     * inside the extras `AppWidgetManager.requestPinAppWidget` forwards into
     * this activity's own launch intent (#181, path B). Its own constant
     * rather than a literal at each end, since nothing else checks the two
     * stay in step.
     */
    const val EXTRA_PRESELECTED_COUNTER = "io.nohzoh.fieldtally.PRESELECTED_COUNTER"
  }

  private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
  private var preselectedCounter: String? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    // Android convention: back-pressed without saving must cancel the
    // placement, not silently succeed. Set before the Flutter engine (and
    // its `finishConfiguring` channel) exists at all, so it holds even if
    // that engine never starts.
    setResult(RESULT_CANCELED)

    // Read before super.onCreate(): that call is what creates the Flutter
    // engine and asks getInitialRoute() for its route, so both have to be
    // known before it runs, not after.
    appWidgetId =
        intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            ?: AppWidgetManager.INVALID_APPWIDGET_ID
    preselectedCounter =
        intent
            ?.extras
            ?.getBundle(AppWidgetManager.EXTRA_APPWIDGET_PROVIDER_EXTRAS)
            ?.getString(EXTRA_PRESELECTED_COUNTER)

    if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
      finish()
      return
    }

    super.onCreate(savedInstanceState)
  }

  override fun getDartEntrypointFunctionName() = "configureWidgetMain"

  override fun getInitialRoute(): String {
    val counter = preselectedCounter
    return if (counter == null) {
      "/configure-widget/$appWidgetId"
    } else {
      "/configure-widget/$appWidgetId?preselect=${Uri.encode(counter)}"
    }
  }

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
