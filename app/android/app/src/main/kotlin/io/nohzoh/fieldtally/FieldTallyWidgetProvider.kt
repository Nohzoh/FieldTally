package io.nohzoh.fieldtally

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home screen widget (#154). Reads the `widget_*` keys `HomeWidgetCoordinator`
 * (Dart side) writes into the same SharedPreferences file and renders one of
 * two mutually exclusive blocks declared in `field_tally_widget.xml`: a
 * one/two-line message, or up to two pinned-counter rows.
 *
 * Class name must stay `FieldTallyWidgetProvider` — it is referenced by
 * string from `PluginHomeWidgetGateway.androidProviderName` on the Dart side
 * and from the manifest's `<receiver>` entry.
 */
class FieldTallyWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.field_tally_widget)

      val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
      views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

      if (widgetData.getString("widget_state", null) == "data") {
        showData(context, views, widgetData)
      } else {
        showMessage(context, views, widgetData)
      }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  /** Before the first sync ever runs, both source keys are unset — the
   * layout's own `tools:text`-free defaults never show on a real device, so
   * this falls back to the strings bundled for that moment instead of
   * leaving the TextViews blank.
   */
  private fun showMessage(context: Context, views: RemoteViews, widgetData: SharedPreferences) {
    views.setViewVisibility(R.id.widget_message, View.VISIBLE)
    views.setViewVisibility(R.id.widget_data, View.GONE)

    val title = widgetData.getString("widget_title", null)
        ?: context.getString(R.string.widget_initial_title)
    val detail = widgetData.getString("widget_detail", null)
        ?: context.getString(R.string.widget_initial_detail)
    views.setTextViewText(R.id.widget_title, title)
    views.setTextViewText(R.id.widget_detail, detail)
  }

  private fun showData(context: Context, views: RemoteViews, widgetData: SharedPreferences) {
    views.setViewVisibility(R.id.widget_message, View.GONE)
    views.setViewVisibility(R.id.widget_data, View.VISIBLE)

    setRow(
        views = views,
        rowId = R.id.widget_row_0,
        labelId = R.id.widget_label_0,
        valueId = R.id.widget_value_0,
        lineId = R.id.widget_line_0,
        label = widgetData.getString("widget_label_0", null),
        value = widgetData.getString("widget_value_0", null),
        line = widgetData.getString("widget_line_0", null),
        // The first row is always shown once state is "data" — the
        // coordinator never writes "data" with zero lines.
        collapsible = false,
    )
    setRow(
        views = views,
        rowId = R.id.widget_row_1,
        labelId = R.id.widget_label_1,
        valueId = R.id.widget_value_1,
        lineId = R.id.widget_line_1,
        label = widgetData.getString("widget_label_1", null),
        value = widgetData.getString("widget_value_1", null),
        line = widgetData.getString("widget_line_1", null),
        // A second pinned counter is optional — hide the whole row rather
        // than showing an empty label/value pair when only one is pinned.
        collapsible = true,
    )
  }

  private fun setRow(
      views: RemoteViews,
      rowId: Int,
      labelId: Int,
      valueId: Int,
      lineId: Int,
      label: String?,
      value: String?,
      line: String?,
      collapsible: Boolean,
  ) {
    if (collapsible && (label == null || value == null)) {
      views.setViewVisibility(rowId, View.GONE)
      return
    }

    views.setViewVisibility(rowId, View.VISIBLE)
    views.setTextViewText(labelId, label ?: "")
    views.setTextViewText(valueId, value ?: "")
    if (line.isNullOrEmpty()) {
      views.setViewVisibility(lineId, View.GONE)
    } else {
      views.setViewVisibility(lineId, View.VISIBLE)
      views.setTextViewText(lineId, line)
    }
  }
}
