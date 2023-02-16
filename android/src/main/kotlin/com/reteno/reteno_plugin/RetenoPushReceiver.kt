package com.reteno.reteno_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class RetenoPushReceiver() : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if(intent == null || intent.extras == null){
            return
        }
        val map = HashMap<String, Any?>()
        for (key in intent.extras!!.keySet()) {
            val value = intent.extras!!.get(key)
            map[key] = value
        }
        RetenoPlugin.methodChannel.invokeMethod("onRetenoNotificationReceived", map)
    }
}