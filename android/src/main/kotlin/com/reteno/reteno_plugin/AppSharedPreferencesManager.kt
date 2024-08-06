package com.reteno.reteno_plugin

import android.content.Context
import android.content.SharedPreferences



class AppSharedPreferencesManager {
    private val PREF_FILE_NAME: String = "sharedPrefs"
    private val PREF_KEY_DEVICE_ID = "KEY_DEVICE_ID"
    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREF_FILE_NAME, Context.MODE_PRIVATE)
    }

    fun saveDeviceId(context: Context?, externalId: String?) {
        getPrefs(context!!).edit().putString(PREF_KEY_DEVICE_ID, externalId).apply()
    }

    fun getDeviceId(context: Context?): String? {
        return getPrefs(context!!).getString(PREF_KEY_DEVICE_ID, "")
    }
}