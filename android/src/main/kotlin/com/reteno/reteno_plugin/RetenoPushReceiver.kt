package com.reteno.reteno_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.ActivityManager
import android.app.KeyguardManager
import android.util.Log

class RetenoPushReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null || intent.extras == null) {
            return
        }
        val map = HashMap<String, Any?>()
        for (key in intent.extras!!.keySet()) {
            val value = intent.extras!!.get(key)
            map[key] = value
        }
        try {
            if (isApplicationForeground(context)) {
                RetenoPlugin.methodChannel.invokeMethod("onRetenoNotificationReceived", map)
            }

        } catch (e: java.lang.Exception) {
            e.message?.let { Log.e("RetenoPushReceiver", it) };
        }
    }

    private fun isApplicationForeground(context: Context): Boolean {
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager

        if (keyguardManager.isKeyguardLocked) {
            return false
        }

        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager?
            ?: return false

        val appProcesses = activityManager.runningAppProcesses ?: return false

        val packageName = context.packageName
        for (appProcess in appProcesses) {
            if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                appProcess.processName == packageName
            ) {
                return true
            }
        }

        return false
    }

}