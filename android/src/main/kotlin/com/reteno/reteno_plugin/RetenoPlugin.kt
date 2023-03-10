package com.reteno.reteno_plugin

import androidx.annotation.NonNull
import com.reteno.core.Reteno
import com.reteno.core.RetenoApplication

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/** RetenoPlugin */
class RetenoPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        lateinit var methodChannel: MethodChannel
    }

    private lateinit var reteno: Reteno
    private lateinit var receiver: RetenoPushReceiver
    private var initialNotification: HashMap<String, Any?>? = null


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "reteno_plugin")
        methodChannel.setMethodCallHandler(this)
        reteno = (flutterPluginBinding.applicationContext as RetenoApplication).getRetenoInstance()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
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
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        binding.applicationContext.unregisterReceiver(receiver)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        val extras = binding.activity.intent.extras
        if (extras != null) {
            initialNotification = HashMap()
            for (key in extras.keySet()) {
                val value = extras.get(key)
                initialNotification!![key] = value
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivity() {
        initialNotification = null
    }
}

