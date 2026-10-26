package com.example.shiftly

import android.app.Activity
import android.app.Application
import android.content.ComponentName
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class LauncherIcons(private val activity: MainActivity) : Application.ActivityLifecycleCallbacks {
    private val pm = activity.packageManager
    private val prefs = activity.getSharedPreferences("shiftly_launcher_icons", 0)
    private fun aliases(): Map<String, ActivityInfo> {
        @Suppress("DEPRECATION")
        val info = pm.getPackageInfo(activity.packageName, PackageManager.GET_ACTIVITIES or PackageManager.GET_META_DATA or PackageManager.MATCH_DISABLED_COMPONENTS)
        return (info.activities ?: emptyArray()).filter { it.targetActivity == MainActivity::class.java.name && it.metaData?.getString("shiftly.iconKey") != null }
            .associateBy { it.metaData.getString("shiftly.iconKey")!! }
    }
    private fun enabled(info: ActivityInfo): Boolean = when (pm.getComponentEnabledSetting(ComponentName(activity.packageName, info.name))) {
        PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
        PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> info.enabled
        else -> false
    }
    fun register(messenger: BinaryMessenger) {
        activity.application.registerActivityLifecycleCallbacks(this)
        MethodChannel(messenger, "shiftly/app_icons").setMethodCallHandler { call, result ->
            try {
                val entries = aliases()
                when (call.method) {
                    "capabilities" -> result.success(mapOf("supported" to true, "icons" to entries.mapValues { it.value.metaData.getString("shiftly.iconSha256") }, "current" to (prefs.getString("pending", null) ?: entries.entries.firstOrNull { enabled(it.value) }?.key ?: "default")))
                    "select" -> {
                        val key = call.argument<String>("key")
                        if (key == null || !entries.containsKey(key)) result.error("ICON_NOT_BUNDLED", "Icon is not in this build", null)
                        else { prefs.edit().putString("pending", key).apply(); result.success(true) }
                    }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) { result.error("ICON_CHANGE_FAILED", "Could not inspect launcher icons", null) }
        }
    }
    override fun onActivityStopped(stopped: Activity) {
        if (stopped !== activity || activity.isChangingConfigurations) return
        val key = prefs.getString("pending", null) ?: return
        try {
            val entries = aliases()
            val selected = entries[key] ?: return
            if (Build.VERSION.SDK_INT >= 33) {
                pm.setComponentEnabledSettings(entries.values.map { info -> PackageManager.ComponentEnabledSetting(ComponentName(activity.packageName, info.name), if (info.name == selected.name) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP) })
            } else {
                // Enable the replacement first: never leave the app without a launcher.
                pm.setComponentEnabledSetting(ComponentName(activity.packageName, selected.name), PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
                entries.values.filter { it.name != selected.name }.forEach { pm.setComponentEnabledSetting(ComponentName(activity.packageName, it.name), PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP) }
            }
            prefs.edit().remove("pending").apply()
        } catch (_: Exception) { /* Retain the request and existing launcher for a later retry. */ }
    }
    override fun onActivityDestroyed(destroyed: Activity) { if (destroyed === activity) activity.application.unregisterActivityLifecycleCallbacks(this) }
    override fun onActivityCreated(a: Activity, b: Bundle?) {}
    override fun onActivityStarted(a: Activity) {}
    override fun onActivityResumed(a: Activity) {}
    override fun onActivityPaused(a: Activity) {}
    override fun onActivitySaveInstanceState(a: Activity, b: Bundle) {}
}
