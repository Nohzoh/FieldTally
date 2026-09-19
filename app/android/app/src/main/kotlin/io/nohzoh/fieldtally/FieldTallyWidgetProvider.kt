package io.nohzoh.fieldtally

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home screen widget (#154). Reads the `widget_*` keys `HomeWidgetCoordinator`
 * (Dart side) writes into the same SharedPreferences file and renders one of
 * two mutually exclusive blocks declared in `field_tally_widget.xml`: a
 * one/two-line message, or up to four pinned-counter rows (#177) — how many
 * of those four actually show depends on the widget's current on-screen
 * size, not on how many are pinned.
 *
 * Class name must stay `FieldTallyWidgetProvider` — it is referenced by
 * string from `PluginHomeWidgetGateway.androidProviderName` on the Dart side
 * and from the manifest's `<receiver>` entry.
 */
class FieldTallyWidgetProvider : HomeWidgetProvider() {

  /** One row's three `TextView` ids, plus its container. */
  private data class RowIds(
      val rowId: Int,
      val labelId: Int,
      val valueId: Int,
      val lineId: Int,
  )

  private val rows =
      listOf(
          RowIds(R.id.widget_row_0, R.id.widget_label_0, R.id.widget_value_0, R.id.widget_line_0),
          RowIds(R.id.widget_row_1, R.id.widget_label_1, R.id.widget_value_1, R.id.widget_line_1),
          RowIds(R.id.widget_row_2, R.id.widget_label_2, R.id.widget_value_2, R.id.widget_line_2),
          RowIds(R.id.widget_row_3, R.id.widget_label_3, R.id.widget_value_3, R.id.widget_line_3),
      )

  /** `field_tally_widget_info.xml`'s own `minHeight`, sized for exactly two
   * rows — the fixed cost (title/padding) that a rows-that-fit estimate has
   * to subtract before dividing by a single row's height.
   */
  private val baseHeightDp = 110

  /** A row beyond the second adds roughly this much height, from the same
   * two-rows-at-110dp calibration above. Unverified on a real device (no
   * Android SDK in the sandbox that wrote this) — worth confirming against
   * a few real launcher sizes before trusting it far from that calibration
   * point.
   */
  private val extraRowHeightDp = 60

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      render(context, appWidgetManager, widgetId, widgetData)
    }
  }

  /**
   * Fires whenever the launcher resizes this widget (or first places it).
   * `onUpdate` above only reruns on the scheduled refresh or a data change —
   * without this override, a resize would just change the box around
   * whatever was already drawn.
   */
  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: Bundle,
  ) {
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    render(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
  }

  private fun render(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetId: Int,
      widgetData: SharedPreferences,
  ) {
    val views = RemoteViews(context.packageName, R.layout.field_tally_widget)

    val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
    views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

    if (widgetData.getString("widget_state", null) == "data") {
      showData(views, widgetData, rowsThatFit(appWidgetManager, widgetId))
    } else {
      showMessage(context, views, widgetData)
    }

    appWidgetManager.updateAppWidget(widgetId, views)
  }

  /** How many of [rows] the widget's current on-screen size can show, from
   * its reported minimum height. Falls back to two — the size the widget
   * ships at and the layout's own declared minimum — when the launcher has
   * not reported a height yet.
   */
  private fun rowsThatFit(appWidgetManager: AppWidgetManager, widgetId: Int): Int {
    val heightDp =
        appWidgetManager
            .getAppWidgetOptions(widgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
    if (heightDp <= 0) return 2

    val extraRows = (heightDp - baseHeightDp) / extraRowHeightDp
    return (2 + extraRows).coerceIn(1, rows.size)
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

  private fun showData(views: RemoteViews, widgetData: SharedPreferences, maxRows: Int) {
    views.setViewVisibility(R.id.widget_message, View.GONE)
    views.setViewVisibility(R.id.widget_data, View.VISIBLE)

    rows.forEachIndexed { index, row ->
      if (index >= maxRows) {
        // Doesn't fit at the current size, whatever HomeWidgetCoordinator
        // wrote for it — distinct from `collapsible` below, which is about
        // there being no data at all.
        views.setViewVisibility(row.rowId, View.GONE)
        return@forEachIndexed
      }

      setRow(
          views = views,
          row = row,
          label = widgetData.getString("widget_label_$index", null),
          value = widgetData.getString("widget_value_$index", null),
          line = widgetData.getString("widget_line_$index", null),
          // The first row is always shown once state is "data" — the
          // coordinator never writes "data" with zero lines.
          collapsible = index != 0,
      )
    }
  }

  private fun setRow(
      views: RemoteViews,
      row: RowIds,
      label: String?,
      value: String?,
      line: String?,
      collapsible: Boolean,
  ) {
    if (collapsible && (label == null || value == null)) {
      views.setViewVisibility(row.rowId, View.GONE)
      return
    }

    views.setViewVisibility(row.rowId, View.VISIBLE)
    views.setTextViewText(row.labelId, label ?: "")
    views.setTextViewText(row.valueId, value ?: "")
    if (line.isNullOrEmpty()) {
      views.setViewVisibility(row.lineId, View.GONE)
    } else {
      views.setViewVisibility(row.lineId, View.VISIBLE)
      views.setTextViewText(row.lineId, line)
    }
  }
}
