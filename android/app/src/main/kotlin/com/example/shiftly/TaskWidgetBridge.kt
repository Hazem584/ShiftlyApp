package com.example.shiftly

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class TaskWidgetBridge(private val context: Context) {
    private var ready = false
    private var channel: MethodChannel? = null
    private var pending: Map<String, String>? = null

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, "shiftly/task_widget").also { bridge ->
            bridge.setMethodCallHandler { call, result ->
                when (call.method) {
                    "publish" -> {
                        val value = call.arguments as? String
                        try {
                            require(value != null && value.length <= 16000)
                            val parsed = JSONObject(value)
                            require(parsed.getString("ownerId").isNotEmpty())
                            require(parsed.getJSONArray("tasks").length() <= 3)
                            context.getSharedPreferences(TaskWidgetProvider.STORE, Context.MODE_PRIVATE)
                                .edit().putString(TaskWidgetProvider.SNAPSHOT, value).commit()
                            TaskWidgetProvider.refresh(context)
                            result.success(null)
                        } catch (_: Exception) { result.error("WIDGET_DATA", "Invalid task snapshot", null) }
                    }
                    "clear" -> {
                        context.getSharedPreferences(TaskWidgetProvider.STORE, Context.MODE_PRIVATE).edit().clear().commit()
                        TaskWidgetProvider.refresh(context)
                        result.success(null)
                    }
                    "initialTap" -> {
                        ready = true
                        result.success(pending)
                        pending = null
                    }
                    "pin" -> {
                        val manager = AppWidgetManager.getInstance(context)
                        val supported = Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported
                        if (supported) {
                            result.success(manager.requestPinAppWidget(
                                ComponentName(context, TaskWidgetProvider::class.java), null, null))
                        } else result.success(false)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    fun accept(intent: Intent?) {
        if (intent?.action != TaskWidgetProvider.OPEN) return
        val tap = mapOf("ownerId" to (intent.getStringExtra("ownerId") ?: ""),
            "taskId" to (intent.getStringExtra("taskId") ?: ""))
        if (ready) channel?.invokeMethod("opened", tap) else pending = tap
        intent.action = null
    }
}
