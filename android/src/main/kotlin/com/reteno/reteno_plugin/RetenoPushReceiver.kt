package com.reteno.reteno_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log


class RetenoPushReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Log.i("RetenoPushReceiver", "onReceive")
        if (intent?.extras == null) {
            return
        }

        val extras = intent.extras!!
        val map = HashMap<String, Any?>()

        for (key in extras.keySet()) {
            when (val value = extras.get(key)) {
                is String -> map[key] = value
                is Int -> map[key] = value
                is Long -> map[key] = value
                is Double -> map[key] = value
                is Boolean -> map[key] = value
                is Array<*> -> map[key] = value.joinToString(",")
                is Bundle -> map[key] = bundleToMap(value)
                else -> map[key] = value?.toString()
            }
        }

        Log.d("RetenoPushReceiver", "Extras: $map")

        for (key in extras?.keySet() ?: emptySet()) {
            val value = intent.extras?.getString(key)
            map[key] = value
        }
        println(map)
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

    private fun bundleToMap(bundle: Bundle): Map<String, Any?> {
        return bundle.keySet().associateWith { key ->
            when (val value = bundle.get(key)) {
                is Bundle -> bundleToMap(value)
                is Array<*> -> value.joinToString(",")
                else -> value
            }
        }
    }
}