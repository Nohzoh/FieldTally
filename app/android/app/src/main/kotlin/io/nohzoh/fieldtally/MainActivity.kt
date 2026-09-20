package io.nohzoh.fieldtally

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges what the home screen widget (#154) needs that `home_widget` does
 * not expose: which `appWidgetId`s currently exist (#181), and pinning a new
 * one pre-selected to a given counter (#181, path B) — that plugin's own
 * `requestPinWidget()` passes no extras. Everything else about the widget
 * goes through that plugin's own channel.
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
          val exportHeader = call.argument<String>("exportHeader")
          val appWidgetManager = AppWidgetManager.getInstance(this)
          if (!appWidgetManager.isRequestPinAppWidgetSupported) {
            result.success(false)
          } else {
            val provider = ComponentName(this, FieldTallyWidgetProvider::class.java)
            // requestPinAppWidget's own `extras` param is for launcher-level
            // customisation only (e.g. EXTRA_APPWIDGET_PREVIEW) -- it does
            // NOT reach a configuration activity, and pinning this way skips
            // that activity entirely rather than launching it. The
            // documented way to still show one is `successCallback`: fired
            // once the pin succeeds, with the system's own
            // EXTRA_APPWIDGET_ID merged onto whatever intent it targets.
            // Pointed straight at WidgetConfigureActivity, carrying the
            // tapped counter as a plain extra of our own.
            val successIntent =
                Intent(this, WidgetConfigureActivity::class.java).apply {
                  putExtra(WidgetConfigureActivity.EXTRA_PRESELECTED_COUNTER, exportHeader)
                  // The launcher fires this from outside any Activity context.
                  addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            val successCallback =
                PendingIntent.getActivity(
                    this,
                    0,
                    successIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
            result.success(appWidgetManager.requestPinAppWidget(provider, null, successCallback))
          }
        }
        else -> result.notImplemented()
      }
    }
  }
}
