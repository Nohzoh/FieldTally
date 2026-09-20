package io.nohzoh.fieldtally

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Relays `requestPinAppWidget`'s success callback into an ordinary,
 * same-process activity start (#181, path B; #185).
 *
 * `MainActivity.requestPinWidget` first pointed this callback straight at
 * `WidgetConfigureActivity` via `PendingIntent.getActivity`, fired by the
 * *launcher's* process once the pin succeeds. On a real device that silently
 * placed the widget without ever opening the configuration screen -- the
 * launcher already commits the placement regardless of the callback's
 * outcome, since bypassing that gate is the whole point of
 * `requestPinAppWidget`, so a callback that never arrives (or never actually
 * starts anything) still leaves the widget on the home screen, just
 * unconfigured. A `BroadcastReceiver`, triggered the same way but calling
 * `startActivity` itself from live code in our own process, is the pattern
 * every reference implementation of this flow uses instead -- not yet
 * confirmed on a device either, but not resting on a cross-process activity
 * start this time.
 */
class WidgetPinSuccessReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    val appWidgetId =
        intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
    if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return

    val configureIntent =
        Intent(context, WidgetConfigureActivity::class.java).apply {
          putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
          putExtra(
              WidgetConfigureActivity.EXTRA_PRESELECTED_COUNTER,
              intent.getStringExtra(WidgetConfigureActivity.EXTRA_PRESELECTED_COUNTER))
          addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    context.startActivity(configureIntent)
  }
}
