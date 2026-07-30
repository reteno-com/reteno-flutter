package com.reteno.reteno_plugin

import android.content.Context
import com.reteno.push.RetenoNotifications

internal object RetenoNotificationGroupingRuleStore {
    private const val PREFERENCES_NAME = "com.reteno.flutter.notification-grouping"
    private const val PAYLOAD_KEY = "payload_key"
    private const val FALLBACK_GROUP_ID = "fallback_group_id"

    fun update(context: Context, rule: NativeNotificationGroupingRule?) {
        val payloadKey = rule?.payloadKey.normalize()
        val fallbackGroupId = rule?.fallbackGroupId.normalize()

        require(rule == null || payloadKey != null || fallbackGroupId != null) {
            "A notification grouping rule requires a non-empty group ID or payload key."
        }

        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply {
                payloadKey?.let { putString(PAYLOAD_KEY, it) }
                fallbackGroupId?.let { putString(FALLBACK_GROUP_ID, it) }
            }
            .apply()

        applyRule(payloadKey, fallbackGroupId)
    }

    fun applyStoredRule(context: Context) {
        val preferences =
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
        applyRule(
            preferences.getString(PAYLOAD_KEY, null).normalize(),
            preferences.getString(FALLBACK_GROUP_ID, null).normalize(),
        )
    }

    private fun applyRule(payloadKey: String?, fallbackGroupId: String?) {
        if (payloadKey == null && fallbackGroupId == null) {
            RetenoNotifications.setGroupingRule(null)
            return
        }

        RetenoNotifications.setGroupingRule { payload ->
            payloadKey
                ?.let(payload::get)
                .normalize()
                ?: fallbackGroupId
        }
    }

    private fun String?.normalize(): String? =
        this?.trim()?.takeIf(String::isNotEmpty)
}
