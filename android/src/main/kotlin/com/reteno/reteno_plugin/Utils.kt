package com.reteno.reteno_plugin

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context

class Utils {
    companion object{
        fun isApplicationForeground(context: Context): Boolean {
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
}