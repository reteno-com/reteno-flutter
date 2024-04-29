package com.reteno.reteno_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class RetenoPushReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Log.i("RetenoPushReceiver", "onReceive")
        if (intent == null || intent.extras == null) {
            return
        }
        val map = HashMap<String, Any?>()
        for (key in intent.extras?.keySet() ?: emptySet()) {
            val value = intent.extras?.getString(key)
            map[key] = value
        }
        try {
            if (Utils.isApplicationForeground(context)) {
                var pushMap = map!!.toMap()
                RetenoPlugin.flutterApi?.onNotificationReceived(pushMap) {
                    Log.i("RetenoPushReceiver", "onNotificationReceived sent")
                }
                Log.i("RetenoPushReceiver", "onRetenoNotificationReceived")
            }

        } catch (e: java.lang.Exception) {
            e.message?.let { Log.e("RetenoPushReceiver", it) };
        }
    }
}