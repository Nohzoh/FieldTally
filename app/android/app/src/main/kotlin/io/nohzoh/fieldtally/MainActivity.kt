package io.nohzoh.fieldtally

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Bundle
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
            // Forwarded verbatim into WidgetConfigureActivity's own launch
            // intent by the widget host, under the same
            // EXTRA_APPWIDGET_PROVIDER_EXTRAS key -- that is what lets the
            // configuration screen pre-select this counter rather than
            // opening empty.
            val providerExtras =
                Bundle().apply {
                  putString(WidgetConfigureActivity.EXTRA_PRESELECTED_COUNTER, exportHeader)
                }
            val extras =
                Bundle().apply {
                  putBundle(AppWidgetManager.EXTRA_APPWIDGET_PROVIDER_EXTRAS, providerExtras)
                }
            result.success(appWidgetManager.requestPinAppWidget(provider, extras, null))
          }
        }
        else -> result.notImplemented()
      }
    }
  }
}
