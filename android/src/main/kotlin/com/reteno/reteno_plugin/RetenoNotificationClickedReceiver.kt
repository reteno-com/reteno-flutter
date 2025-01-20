package com.reteno.reteno_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

class RetenoNotificationClickedReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
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

        val esButtons = map["es_buttons"] as? String
        val esBtnActionLabel = map["es_btn_action_label"] as? String

        // If there's a button scenario:
        if (esButtons != null && esBtnActionLabel != null) {
            val action = findButtonAction(esButtons, esBtnActionLabel)
            if (action != null) {
                RetenoPlugin.handleNotificationAction(action)
            } else {
                Log.d("ClickedReceiver", "No matching button found")
            }
        } else {
            // Handle basic notification click using the new handler
            RetenoPlugin.handleNotificationClick(map)
            Log.d("ClickedReceiver", "Basic notification click queued")
        }
    }

    private fun findButtonAction(
        buttonsJson: String,
        actionLabel: String
    ): NativeUserNotificationAction? {
        try {
            val buttonsArray = JSONArray(buttonsJson)
            for (i in 0 until buttonsArray.length()) {
                val button = buttonsArray.getJSONObject(i)
                if (button.getString("label") == actionLabel) {
                    return NativeUserNotificationAction(
                        actionId = button.optString("action_id"),
                        customData = parseCustomData(button.optJSONObject("custom_data")),
                        link = button.optString("link")
                    )
                }
            }
        } catch (e: Exception) {
            Log.e("ClickedReceiver", "Error parsing buttons JSON", e)
        }
        return null
    }

    private fun parseCustomData(customData: JSONObject?): Map<String?, Any?>? {
        if (customData == null) return null
        return customData.keys().asSequence().associateWith { key ->
            when (val value = key?.let { customData.get(it) }) {
                is JSONObject -> parseCustomData(value)
                is JSONArray -> value.toString()
                else -> value
            }
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
