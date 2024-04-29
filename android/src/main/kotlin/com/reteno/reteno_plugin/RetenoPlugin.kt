package com.reteno.reteno_plugin

import UserUtils
import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.reteno.core.Reteno
import com.reteno.core.RetenoApplication
import com.reteno.core.data.remote.model.recommendation.get.Recoms
import com.reteno.core.domain.model.recommendation.get.RecomFilter
import com.reteno.core.domain.model.recommendation.get.RecomRequest
import com.reteno.core.domain.model.recommendation.post.RecomEvents
import com.reteno.core.features.recommendation.GetRecommendationResponseCallback
import com.reteno.core.view.iam.callback.InAppCloseAction
import com.reteno.core.view.iam.callback.InAppCloseData
import com.reteno.core.view.iam.callback.InAppData
import com.reteno.core.view.iam.callback.InAppErrorData
import com.reteno.core.view.iam.callback.InAppLifecycleCallback
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
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onAttachedToEngine")
        pluginBinding = flutterPluginBinding
        if (flutterApi == null) {
            initPlugin(flutterPluginBinding.binaryMessenger)
        }
        reteno = (flutterPluginBinding.applicationContext as RetenoApplication).getRetenoInstance()
        createInAppLifecycleListener()
    }

    private fun initPlugin(binaryMessenger: BinaryMessenger) {
        RetenoHostApi.setUp(binaryMessenger, this)
        flutterApi = RetenoFlutterApi(binaryMessenger)
    }

    private fun createInAppLifecycleListener() {
        reteno.setInAppLifecycleCallback(object : InAppLifecycleCallback {
            override fun afterClose(closeData: InAppCloseData) {
                uiThreadHandler.post {
                    flutterApi?.onInAppMessageStatusChanged(
                        NativeInAppMessageStatus.IN_APP_IS_CLOSED,
                        inAppCloseActionToNativeInAppMessageAction(closeData.closeAction),
                        null,
                    ) {}
                }
            }

            override fun beforeClose(closeData: InAppCloseData) {
                uiThreadHandler.post {
                    flutterApi?.onInAppMessageStatusChanged(
                        NativeInAppMessageStatus.IN_APP_SHOULD_BE_CLOSED,
                        inAppCloseActionToNativeInAppMessageAction(closeData.closeAction),
                        null,
                    ) {}
                }
            }

            override fun beforeDisplay(inAppData: InAppData) {
                uiThreadHandler.post {
                    flutterApi?.onInAppMessageStatusChanged(
                        NativeInAppMessageStatus.IN_APP_SHOULD_BE_DISPLAYED,
                        null,
                        null,
                    ) {}
                }
            }

            override fun onDisplay(inAppData: InAppData) {
                uiThreadHandler.post {
                    flutterApi?.onInAppMessageStatusChanged(
                        NativeInAppMessageStatus.IN_APP_IS_DISPLAYED,
                        null,
                        null,
                    ) {}
                }

            }

            override fun onError(errorData: InAppErrorData) {
                uiThreadHandler.post {
                    flutterApi?.onInAppMessageStatusChanged(
                        NativeInAppMessageStatus.IN_APP_RECEIVED_ERROR,
                        null,
                        errorData.errorMessage,
                    ) {}
                }
            }
        })
    }

    private fun inAppCloseActionToNativeInAppMessageAction(closeAction: InAppCloseAction): NativeInAppMessageAction {
        return when(closeAction) {
            InAppCloseAction.CLOSE_BUTTON -> NativeInAppMessageAction(
                isCloseButtonClicked = true,
                isButtonClicked = false,
                isOpenUrlClicked = false,
            )
            InAppCloseAction.OPEN_URL -> NativeInAppMessageAction(
                isCloseButtonClicked = true,
                isButtonClicked = false,
                isOpenUrlClicked = false,
            )
            InAppCloseAction.BUTTON -> NativeInAppMessageAction(
                isCloseButtonClicked = true,
                isButtonClicked = false,
                isOpenUrlClicked = false,
            )
        }
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
        return reteno.setAnonymousUserAttributes(
            UserUtils.parseAnonymousAttributes(
                anonymousUserAttributes
            )
        )
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
            val map = initialNotification!!.toMap()
            initialNotification = null
            return map
        }
        return null
    }

    override fun getRecommendations(
        recomVariantId: String,
        productIds: List<String>,
        categoryId: String,
        filters: List<NativeRecomFilter>?,
        fields: List<String>?,
        callback: (Result<List<NativeRecommendation>>) -> Unit
    ) {
        val request = RecomRequest(
            products = productIds,
            category = categoryId,
            fields = fields,
            filters = convertToRecomFilterList(filters)
        )
        reteno.recommendation.fetchRecommendation<RecommendationResponse>(
            recomVariantId,
            request,
            RecommendationResponse::class.java,
            object : GetRecommendationResponseCallback<RecommendationResponse> {
                override fun onSuccess(response: Recoms<RecommendationResponse>) {
                    val recommendations = response.recoms.map { it.toNativeRecommendation() }
                    callback(Result.success(recommendations))
                }

                override fun onSuccessFallbackToJson(response: String) {
                    Log.i(TAG, response)
                    val result = Result.failure<List<NativeRecommendation>>(
                        Exception("Fallback JSON response received")
                    )
                    callback(result)
                }

                override fun onFailure(statusCode: Int?, response: String?, throwable: Throwable?) {
                    Log.i(TAG, "onFailure")
                    Log.i(TAG, statusCode.toString())
                    Log.i(TAG, throwable?.message.toString())

                    val result = Result.failure<List<NativeRecommendation>>(
                        throwable ?: Exception("Unknown error")
                    )
                    callback(result)
                }
            })
    }

    override fun logRecommendationsEvent(events: NativeRecomEvents) {
        reteno.recommendation.logRecommendations(
            RecomEvents(events.recomVariantId, convertToRecomEventList(events))
        )
    }

    override fun pauseInAppMessages(isPaused: Boolean) {
        reteno.pauseInAppMessages(isPaused)
    }
}
