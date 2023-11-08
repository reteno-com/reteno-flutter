package com.reteno.reteno_plugin
import android.app.Activity
import android.content.Intent
import android.util.Log
import com.reteno.core.Reteno
import com.reteno.core.RetenoApplication

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.NewIntentListener

class RetenoPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, NewIntentListener {
    companion object {
        lateinit var methodChannel: MethodChannel
        private var initialized: Boolean = false
    }
    private val ES_INTERACTION_ID_KEY: String = "es_interaction_id"
    private lateinit var reteno: Reteno
    private var initialNotification: HashMap<String, Any?>? = null
    private var mainActivity: Activity? = null


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        if (initialized) {
            return
        }
        initialized = true
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "reteno_plugin")
        methodChannel.setMethodCallHandler(this)
        reteno = (flutterPluginBinding.applicationContext as RetenoApplication).getRetenoInstance()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getInitialNotification" -> {
                if (initialNotification != null) {
                    result.success(initialNotification)
                    initialNotification = null
                } else {
                    result.success(null)
                }
            }
            "setUserAttributes" -> {
                val userMap = call.arguments as HashMap<*, *>
                val userId = userMap["externalUserId"] as String
                val user = UserUtils.parseUser(userMap)
                reteno.setUserAttributes(userId, user)
                result.success(true)
            }
            "setAnonymousUserAttributes" -> {
                val arguments = call.arguments as HashMap<*, *>
                val userMap = arguments["anonymousUserAttributes"] as HashMap<*, *>
                val anonymousAttributes = UserUtils.parseAnonymousAttributes(userMap)
                reteno.setAnonymousUserAttributes(anonymousAttributes)
                result.success(true)
            }
            "logEvent" -> {
                val arguments = call.arguments as HashMap<*, *>
                val eventMap = arguments["event"] as? Map<String, Any>

                if (eventMap == null) {
                    result.success(false)
                    return
                } else {
                    val event = RetenoEvent.buildEventFromPayload(eventMap)
                    reteno.logEvent(event)
                    result.success(true)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
        mainActivity = binding.activity
        val extras = binding.activity.intent.extras
        if (extras != null && extras.containsKey(ES_INTERACTION_ID_KEY)) {
            initialNotification = HashMap()
            for (key in extras.keySet()) {
                val value = extras.get(key)
                initialNotification!![key] = value
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        mainActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
        mainActivity = binding.activity
    }

    override fun onDetachedFromActivity() {
        mainActivity = null
        initialNotification = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        if(intent.extras == null){
            return false
        }

        if(intent.extras?.getString(ES_INTERACTION_ID_KEY) == null){
            return false
        }
        val retenoNotificationMap = HashMap<String, Any?>()
        for (key in intent.extras!!.keySet()) {
            val value = intent.extras!!.get(key)
            retenoNotificationMap[key] = value
        }
        methodChannel.invokeMethod("onRetenoNotificationClicked", retenoNotificationMap)
        mainActivity?.intent = intent
        return true
    }
}

