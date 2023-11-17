package com.reteno.reteno_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
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
            if (Utils.isApplicationForeground(context)) {
                RetenoPlugin.methodChannel.invokeMethod("onRetenoNotificationReceived", map)
            }

        } catch (e: java.lang.Exception) {
            e.message?.let { Log.e("RetenoPushReceiver", it) };
        }
    }



}