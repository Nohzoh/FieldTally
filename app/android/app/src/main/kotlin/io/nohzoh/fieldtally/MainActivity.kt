package io.nohzoh.fieldtally

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges what the home screen widget (#154) needs that `home_widget` does
 * not expose: which `appWidgetId`s currently exist (#181), and pinning a new
 * one from a counter's own screen (#181, path B; #185) -- that plugin's own
 * `requestPinWidget()` passes no extras, though this needs none either: the
 * newly-placed instance's `appWidgetId` is not known synchronously here, so
 * configuring it to the tapped counter is the Dart side's job, once it
 * notices the new id appear in `getWidgetIds`. Everything else about the
 * widget goes through that plugin's own channel.
 */
class MainActivity : FlutterActivity() {
  companion object {
    private const val CHANNEL = "io.nohzoh.fieldtally/widget"
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        call,
        result ->
      when (call.method) {
        "getWidgetIds" -> {
          val appWidgetManager = AppWidgetManager.getInstance(this)
          val ids =
              appWidgetManager
                  .getAppWidgetIds(ComponentName(this, FieldTallyWidgetProvider::class.java))
                  .toList()
          result.success(ids)
        }
        "requestPinWidget" -> {
          val appWidgetManager = AppWidgetManager.getInstance(this)
          if (!appWidgetManager.isRequestPinAppWidgetSupported) {
            result.success(false)
          } else {
            val provider = ComponentName(this, FieldTallyWidgetProvider::class.java)
            result.success(appWidgetManager.requestPinAppWidget(provider, null, null))
          }
        }
        else -> result.notImplemented()
      }
    }
  }
}
