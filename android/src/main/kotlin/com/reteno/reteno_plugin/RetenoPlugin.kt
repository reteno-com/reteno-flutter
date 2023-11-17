package com.reteno.reteno_plugin

import UserUtils
import android.app.Activity
import android.content.Intent
import android.util.Log
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.TaskCompletionSource
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
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class RetenoPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, NewIntentListener {
    companion object {
        lateinit var methodChannel: MethodChannel
        private var initialized: Boolean = false
        private val cachedThreadPool: ExecutorService = Executors.newCachedThreadPool()
    }

    private val ES_INTERACTION_ID_KEY: String = "es_interaction_id"
    private lateinit var reteno: Reteno
    private var initialNotification: HashMap<String, Any>? = null
    private var mainActivity: Activity? = null


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        if (!Utils.isApplicationForeground(flutterPluginBinding.applicationContext) || initialized) {
            return
        }
        initialized = true
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "reteno_plugin")
        methodChannel.setMethodCallHandler(this)
        reteno = (flutterPluginBinding.applicationContext as RetenoApplication).getRetenoInstance()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val methodCallTask: Task<*>
        when (call.method) {
            "getInitialNotification" -> {
                methodCallTask = getInitialNotification()
            }
            "setUserAttributes" -> {
                methodCallTask = setUserAttributes(call.arguments as HashMap<*, *>)
            }
            "setAnonymousUserAttributes" -> {
                methodCallTask = setAnonymousUserAttributes(call.arguments as HashMap<*, *>)
            }
            "logEvent" -> {
                methodCallTask = logEvent(call.arguments as HashMap<*, *>)
            }
            else -> {
                result.notImplemented()
                return
            }
        }
        methodCallTask.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                result.success(task.result)
            } else {
                val exception = task.exception
                result.error("reteno_plugin", exception?.message, exception?.stackTrace)
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
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
        methodChannel.invokeMethod(
            "onRetenoNotificationClicked",
            retenoNotificationMap,
            object : Result {
                override fun success(result: Any?) {
                    Log.i("reteno_plugin", "Success")
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.i("reteno_plugin", "Error")
                }

                override fun notImplemented() {
                    Log.i("reteno_plugin", "Not Implemented")
                }
            })
        mainActivity?.intent = intent
        return true
    }

    private fun setAnonymousUserAttributes(arguments: HashMap<*, *>): Task<Boolean> {
        val taskCompletionSource = TaskCompletionSource<Boolean>()

        cachedThreadPool.execute {
            try {
                val anonymousAttributes = UserUtils.parseAnonymousAttributes(arguments)
                reteno.setAnonymousUserAttributes(anonymousAttributes)
                taskCompletionSource.setResult(true)
            } catch (e: Exception) {
                taskCompletionSource.setException(e)
            }
        }

        return taskCompletionSource.task
    }

    private fun setUserAttributes(arguments: HashMap<*, *>): Task<Boolean> {
        val taskCompletionSource = TaskCompletionSource<Boolean>()

        cachedThreadPool.execute {
            try {
                val userId = arguments["externalUserId"] as String
                val user = UserUtils.parseUser(arguments)
                reteno.setUserAttributes(userId, user)
                taskCompletionSource.setResult(true)
            } catch (e: Exception) {
                taskCompletionSource.setException(e)
            }
        }

        return taskCompletionSource.task
    }

    private fun logEvent(arguments: HashMap<*, *>): Task<Boolean> {
        val taskCompletionSource = TaskCompletionSource<Boolean>()
        cachedThreadPool.execute {
            try {
                val eventMap = arguments["event"] as? Map<String, Any>

                if (eventMap == null) {
                    taskCompletionSource.setResult(false)
                } else {
                    val event = RetenoEvent.buildEventFromPayload(eventMap)
                    reteno.logEvent(event)
                    taskCompletionSource.setResult(true)
                }
            } catch (e: Exception) {
                taskCompletionSource.setException(e)
            }
        }


        return taskCompletionSource.task
    }

    private fun getInitialNotification(): Task<HashMap<String, Any>> {
        val taskCompletionSource = TaskCompletionSource<HashMap<String, Any>>()

        cachedThreadPool.execute {
            try {
                if (initialNotification != null) {
                    taskCompletionSource.setResult(initialNotification!!)
                    initialNotification = null
                    return@execute
                }
                if (mainActivity == null) {
                    taskCompletionSource.setResult(null)
                    return@execute
                }

                val intent = mainActivity!!.intent
                if (intent == null || intent.extras == null) {
                    taskCompletionSource.setResult(null)
                    return@execute
                }


            } catch (e: Exception) {
                taskCompletionSource.setException(e)
            }
        }

        return taskCompletionSource.task
    }
}

