package io.nohzoh.fieldtally

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the one thing about the home screen widget (#154) that
 * `home_widget` does not expose: which `appWidgetId`s currently exist (#181).
 * Everything else about the widget goes through that plugin's own channel.
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
        else -> result.notImplemented()
      }
    }
  }
}
