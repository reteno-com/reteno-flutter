package com.reteno.reteno_plugin

import UserUtils
import android.app.Activity
import android.content.Intent
import android.util.Log
import com.reteno.core.Reteno
import com.reteno.core.RetenoApplication
import com.reteno.reteno_plugin.RetenoEvent.buildEventFromCustomEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.PluginRegistry.NewIntentListener

private const val TAG = "RetenoPlugin"
private const val ES_INTERACTION_ID_KEY: String = "es_interaction_id"

class RetenoPlugin : FlutterPlugin, RetenoHostApi, ActivityAware, NewIntentListener {
    companion object {
        private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
        var flutterApi: RetenoFlutterApi? = null
    }

    private lateinit var reteno: Reteno
    private var initialNotification: HashMap<String, Any>? = null
    private var mainActivity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onAttachedToEngine")
        pluginBinding = flutterPluginBinding
        if (flutterApi == null) {
            initPlugin(flutterPluginBinding.binaryMessenger)
        }
        reteno = (flutterPluginBinding.applicationContext as RetenoApplication).getRetenoInstance()
    }

    private fun initPlugin(binaryMessenger: BinaryMessenger) {
        RetenoHostApi.setUp(binaryMessenger, this)
        flutterApi = RetenoFlutterApi(binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onDetachedFromEngine")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.i(TAG, "onAttachedToActivity")
        binding.addOnNewIntentListener(this)
        pluginBinding?.binaryMessenger?.let {
            // Reinitialize MethodChannel Forcefully from MainIsolate
            initPlugin(it)
        }
        mainActivity = binding.activity
        val extras = mainActivity?.intent?.extras
        if (extras != null && extras.containsKey(ES_INTERACTION_ID_KEY)) {
            initialNotification = HashMap()
            for (key in extras.keySet()) {
                val value = extras.get(key)
                initialNotification!![key] = value!!
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.i(TAG, "onDetachedFromActivityForConfigChanges")
        mainActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.i(TAG, "onReattachedToActivityForConfigChanges")
        binding.addOnNewIntentListener(this)
        mainActivity = binding.activity
    }

    override fun onDetachedFromActivity() {
        Log.i(TAG, "onDetachedFromActivity")
        mainActivity = null
        initialNotification = null
        flutterApi = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        Log.i(TAG, "onNewIntent")

        if (intent.extras == null) {
            return false
        }

        if (intent.extras?.getString(ES_INTERACTION_ID_KEY) == null) {
            return false
        }

        val retenoNotificationMap = HashMap<String, Any?>()
        for (key in intent.extras!!.keySet()) {
            val value = intent.extras!!.get(key)
            retenoNotificationMap[key] = value
        }

        flutterApi?.onNotificationClicked(retenoNotificationMap.toMap()) {}

        mainActivity?.intent = intent

        return true
    }

    override fun setUserAttributes(externalUserId: String, user: NativeRetenoUser?) {
        Log.i(TAG, "setUserAttributes")
        return reteno.setUserAttributes(externalUserId, UserUtils.fromRetenoUser(user))
    }

    override fun setAnonymousUserAttributes(anonymousUserAttributes: NativeAnonymousUserAttributes) {
        Log.i(TAG, "setAnonymousUserAttributes")
        return reteno.setAnonymousUserAttributes(UserUtils.parseAnonymousAttributes(anonymousUserAttributes))
    }

    override fun logEvent(event: NativeCustomEvent) {
        Log.i(TAG, "logEvent")
        return reteno.logEvent(buildEventFromCustomEvent(event))
    }

    override fun updatePushPermissionStatus() {
        Log.i(TAG, "updatePushPermissionStatus")
        return reteno.updatePushPermissionStatus()
    }

    override fun getInitialNotification(): Map<String, Any>? {
        Log.i(TAG, "getInitialNotification")
        if (initialNotification != null) {
            var map = initialNotification!!.toMap()
            initialNotification = null
            return map
        }
        return null
    }
}
