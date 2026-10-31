package com.example.shiftly

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.DateFormat
import java.util.Date

class TaskWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == TIME_UPDATE) refresh(context) else super.onReceive(context, intent)
    }

    override fun onDisabled(context: Context) {
        context.getSystemService(AlarmManager::class.java).cancel(timeIntent(context))
    }
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { manager.updateAppWidget(it, render(context, it)) }
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        manager.updateAppWidget(id, render(context, id))
    }

    companion object {
        private const val TIME_UPDATE = "com.example.shiftly.WIDGET_TIME"
        private fun timeIntent(context: Context): PendingIntent =
            PendingIntent.getBroadcast(context, 0,
                Intent(context, TaskWidgetProvider::class.java).setAction(TIME_UPDATE),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        const val STORE = "shiftly_task_widget"
        const val SNAPSHOT = "snapshot"
        const val OPEN = "com.example.shiftly.OPEN_TASK_WIDGET"

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TaskWidgetProvider::class.java))
            ids.forEach { manager.updateAppWidget(it, render(context, it)) }
        }

        private fun open(context: Context, owner: String, task: String): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = OPEN
                // Categories distinguish immutable PendingIntents without sending
                // a second deep-link event to Flutter's built-in router.
                addCategory("shiftly.task.$owner.$task")
                putExtra("ownerId", owner)
                putExtra("taskId", task)
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        private fun render(context: Context, widgetId: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.task_widget)
            val raw = context.getSharedPreferences(STORE, Context.MODE_PRIVATE).getString(SNAPSHOT, null)
            val data = try { raw?.let { JSONObject(it) } } catch (_: Exception) { null }
            val height = AppWidgetManager.getInstance(context)
                .getAppWidgetOptions(widgetId).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 250)
            val visibleRows = if (height < 235) 2 else 3
            val now = System.currentTimeMillis()
            val valid = data != null && data.optLong("expiresAt") > now
            val owner = if (valid) data!!.optString("ownerId") else ""
            views.setOnClickPendingIntent(R.id.widget_root, open(context, owner, ""))
            val title = if (valid) context.getString(R.string.widget_remaining, data!!.optInt("total"))
                else context.getString(R.string.widget_sign_in)
            views.setTextViewText(R.id.widget_summary, title)
            views.setTextViewText(R.id.widget_updated, if (valid) context.getString(R.string.widget_updated,
                DateFormat.getTimeInstance(DateFormat.SHORT).format(Date(data!!.optLong("updatedAt"))))
                else context.getString(R.string.widget_open))
            val tasks = if (valid) data!!.optJSONArray("tasks") else null
            val rows = arrayOf(R.id.task_row_0, R.id.task_row_1, R.id.task_row_2)
            val names = arrayOf(R.id.task_title_0, R.id.task_title_1, R.id.task_title_2)
            val times = arrayOf(R.id.task_time_0, R.id.task_time_1, R.id.task_time_2)
            val clocks = arrayOf(R.id.task_clock_0, R.id.task_clock_1, R.id.task_clock_2)
            var nextUpdate = if (valid) data!!.optLong("expiresAt") else Long.MAX_VALUE
            for (i in 0..2) {
                val task = if (i < visibleRows) tasks?.optJSONObject(i) else null
                views.setViewVisibility(rows[i], if (task != null) View.VISIBLE else View.GONE)
                if (task == null) continue
                val dates = task.optJSONArray("dueDates")
                val duration = task.optLong("durationMs")
                val occurrences = if (dates == null || dates.length() == 0) listOf(task.optLong("dueAt"))
                    else (0 until dates.length()).map { dates.optLong(it) }.sorted()
                val due = occurrences.firstOrNull { it + duration > now } ?: occurrences.last()
                val ends = due + duration
                for (boundary in occurrences.flatMap { listOf(it, it + duration) }) {
                    if (boundary > now) nextUpdate = minOf(nextUpdate, boundary)
                }
                val target = if (due <= now && ends > now) ends else due
                views.setTextViewText(names[i], task.optString("title"))
                views.setTextViewText(times[i], context.getString(
                    if (due > now) R.string.widget_due_in else if (ends > now) R.string.widget_ends_in else R.string.widget_overdue))
                // A system Chronometer keeps ticking without waking Dart or polling the server.
                views.setChronometer(clocks[i], SystemClock.elapsedRealtime() + target - now, null, true)
                views.setChronometerCountDown(clocks[i], target > now)
                views.setOnClickPendingIntent(rows[i], open(context, owner, task.optString("id")))
            }
            views.setViewVisibility(R.id.widget_empty, if (valid && (tasks == null || tasks.length() == 0)) View.VISIBLE else View.GONE)
            val alarms = context.getSystemService(AlarmManager::class.java)
            val alarm = timeIntent(context)
            if (nextUpdate != Long.MAX_VALUE) {
                // Inexact, non-wakeup alarm: no exact-alarm permission or background network.
                alarms.set(AlarmManager.RTC, nextUpdate, alarm)
            } else alarms.cancel(alarm)
            return views
        }
    }
}
