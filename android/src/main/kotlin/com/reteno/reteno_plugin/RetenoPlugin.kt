package com.reteno.reteno_plugin

import UserUtils
import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessaging
import com.reteno.core.Reteno
import com.reteno.core.RetenoConfig
import com.reteno.core.data.remote.model.recommendation.get.Recoms
import com.reteno.core.domain.callback.appinbox.RetenoResultCallback
import com.reteno.core.domain.model.appinbox.AppInboxMessage
import com.reteno.core.domain.model.appinbox.AppInboxMessages
import com.reteno.core.domain.model.ecom.Attributes
import com.reteno.core.domain.model.ecom.EcomEvent
import com.reteno.core.domain.model.ecom.Order
import com.reteno.core.domain.model.ecom.OrderItem
import com.reteno.core.domain.model.ecom.OrderStatus
import com.reteno.core.domain.model.ecom.ProductCategoryView
import com.reteno.core.domain.model.ecom.ProductInCart
import com.reteno.core.domain.model.ecom.ProductView
import com.reteno.core.domain.model.event.LifecycleTrackingOptions
import com.reteno.core.domain.model.recommendation.get.RecomRequest
import com.reteno.core.domain.model.recommendation.post.RecomEvents
import com.reteno.core.features.recommendation.GetRecommendationResponseCallback
import com.reteno.core.features.recommendation.GetRecommendationResponseJsonCallback
import com.reteno.core.identification.DeviceIdProvider
import com.reteno.core.util.Procedure
import com.reteno.core.view.iam.callback.InAppCloseAction
import com.reteno.core.view.iam.callback.InAppCloseData
import com.reteno.core.view.iam.callback.InAppData
import com.reteno.core.view.iam.callback.InAppErrorData
import com.reteno.core.view.iam.callback.InAppLifecycleCallback
import com.reteno.push.RetenoNotificationService
import com.reteno.push.RetenoNotifications
import com.reteno.push.events.InAppCustomData
import com.reteno.reteno_plugin.RetenoEvent.buildEventFromCustomEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeParseException
import org.json.JSONArray
import org.json.JSONObject
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import android.util.Pair as AndroidPair

private const val TAG = "RetenoPlugin"
private const val ES_INTERACTION_ID_KEY: String = "es_interaction_id"
private const val FCM_MESSAGING_EVENT_ACTION: String = "com.google.firebase.MESSAGING_EVENT"
private const val FIREBASE_BASE_MESSAGING_SERVICE: String = "com.google.firebase.messaging.FirebaseMessagingService"
private const val RETENO_BRIDGE_MESSAGING_SERVICE: String = "com.reteno.reteno_plugin.RetenoFirebaseMessagingServiceBridge"
private const val ISSUE_FCM_TOKEN_MISSING: String = "FCM_TOKEN_MISSING"
private const val ISSUE_FCM_TOKEN_FETCH_FAILED: String = "FCM_TOKEN_FETCH_FAILED"
private const val MAX_FCM_SYNC_RETRIES: Int = 5
private const val FCM_SYNC_RETRY_DELAY_MS: Long = 2_000L

class RetenoPlugin : FlutterPlugin, RetenoHostApi, ActivityAware {
    companion object {
        private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null

        // Create a singleton instance of flutterApi
        @Volatile
        private var flutterApiInstance: RetenoFlutterApi? = null

        // Synchronized getter for flutterApi
        val flutterApi: RetenoFlutterApi?
            get() {
                return flutterApiInstance
            }

        @Synchronized
        private fun initializeFlutterApi(messenger: BinaryMessenger) {
            if (flutterApiInstance == null) {
                flutterApiInstance = RetenoFlutterApi(messenger)
            }
        }

        // Store both types of pending notifications
        private var pendingNotificationAction: NativeUserNotificationAction? = null
        private var pendingNotificationClick: Map<String, Any?>? = null
        private var pendingNotificationReceived: Map<String, Any?>? = null
        private var pendingNotificationDeleted: Map<String, Any?>? = null
        private var pendingNotificationCustom: Map<String, Any?>? = null
        private var pendingInAppCustomData: NativeInAppCustomData? = null
        private const val REQUEST_POST_NOTIFICATIONS = 9412

        fun handleNotificationAction(action: NativeUserNotificationAction) {
            if (flutterApiInstance != null) {
                flutterApiInstance?.onNotificationActionHandler(action) {}
            } else {
                pendingNotificationAction = action
            }
        }

        fun handleNotificationClick(payload: Map<String, Any?>) {
            if (flutterApiInstance != null) {
                flutterApiInstance?.onNotificationClicked(payload) {}
            } else {
                Log.i(TAG, "Plugin not attached yet. Queuing notification click.")
                pendingNotificationClick = payload
            }
        }

        fun handleNotificationReceived(payload: Map<String, Any?>) {
            if (flutterApiInstance != null) {
                flutterApiInstance?.onNotificationReceived(payload) {}
            } else {
                pendingNotificationReceived = payload
            }
        }

        fun handleNotificationDeleted(payload: Map<String, Any?>) {
            if (flutterApiInstance != null) {
                flutterApiInstance?.onNotificationDeleted(payload) {}
            } else {
                pendingNotificationDeleted = payload
            }
        }

        fun handleCustomNotificationReceived(payload: Map<String, Any?>) {
            if (flutterApiInstance != null) {
                flutterApiInstance?.onCustomNotificationReceived(payload) {}
            } else {
                pendingNotificationCustom = payload
            }
        }

        fun handleInAppCustomDataReceived(payload: NativeInAppCustomData) {
            if (flutterApiInstance != null) {
                flutterApiInstance?.onInAppCustomDataReceived(payload) {}
            } else {
                pendingInAppCustomData = payload
            }
        }
    }

    private var initialNotification: HashMap<String, Any>? = null
    private var mainActivity: Activity? = null
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())
    private lateinit var applicationContext: Context
    private var pendingPushPermissionResult: ((Result<Boolean>) -> Unit)? = null
    private var isPushListenersSubscribed = false
    private var isRetenoInitialized = false

    private val clickListener = Procedure<Bundle> { data ->
        uiThreadHandler.post {
            val payload = bundleToMap(data)
            val action = parseNotificationAction(payload)
            if (action != null) {
                handleNotificationAction(action)
            } else {
                handleNotificationClick(payload)
            }
        }
    }

    private val closeListener = Procedure<Bundle> { data ->
        uiThreadHandler.post {
            handleNotificationDeleted(bundleToMap(data))
        }
    }

    private val receivedListener = Procedure<Bundle> { data ->
        uiThreadHandler.post {
            handleNotificationReceived(bundleToMap(data))
        }
    }

    private val customListener = Procedure<Bundle> { data ->
        uiThreadHandler.post {
            handleCustomNotificationReceived(bundleToMap(data))
        }
    }

    private val inAppCustomDataListener = Procedure<InAppCustomData> { data ->
        uiThreadHandler.post {
            handleInAppCustomDataReceived(data.toNativeInAppCustomData())
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onAttachedToEngine")
        pluginBinding = flutterPluginBinding
        initializeFlutterApi(flutterPluginBinding.binaryMessenger)

        applicationContext = flutterPluginBinding.applicationContext
        createInAppLifecycleListener()
        subscribePushListeners()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onDetachedFromEngine")
        unsubscribePushListeners()
        // Don't clean up flutterApi here anymore
        pluginBinding = null
    }

    private fun initPlugin(binaryMessenger: BinaryMessenger) {
        RetenoHostApi.setUp(binaryMessenger, this)
        // Initialize flutterApi if it hasn't been initialized yet
        initializeFlutterApi(binaryMessenger)
    }

    private fun createInAppLifecycleListener() {
        Reteno.instance.setInAppLifecycleCallback(object : InAppLifecycleCallback {
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
                isCloseButtonClicked = false,
                isButtonClicked = false,
                isOpenUrlClicked = true,
            )
            InAppCloseAction.BUTTON -> NativeInAppMessageAction(
                isCloseButtonClicked = false,
                isButtonClicked = true,
                isOpenUrlClicked = false,
            )

            InAppCloseAction.DISMISSED -> NativeInAppMessageAction(
                isCloseButtonClicked = false,
                isButtonClicked = false,
                isOpenUrlClicked = false,
            )
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.i(TAG, "onAttachedToActivity")
        mainActivity = binding.activity

        // Reinitialize channels if necessary
        pluginBinding?.binaryMessenger?.let {
            initPlugin(it)
        }

        // Handle any pending notifications
        pendingNotificationAction?.let { action ->
            Log.i(TAG, "Delivering pending notification action")
            flutterApiInstance?.onNotificationActionHandler(action) {}
            pendingNotificationAction = null
        }

        pendingNotificationClick?.let { payload ->
            Log.i(TAG, "Delivering pending notification click")
            flutterApiInstance?.onNotificationClicked(payload) {}
            pendingNotificationClick = null
        }

        pendingNotificationReceived?.let { payload ->
            Log.i(TAG, "Delivering pending notification received")
            flutterApiInstance?.onNotificationReceived(payload) {}
            pendingNotificationReceived = null
        }

        pendingNotificationDeleted?.let { payload ->
            Log.i(TAG, "Delivering pending notification deleted")
            flutterApiInstance?.onNotificationDeleted(payload) {}
            pendingNotificationDeleted = null
        }

        pendingNotificationCustom?.let { payload ->
            Log.i(TAG, "Delivering pending custom notification")
            flutterApiInstance?.onCustomNotificationReceived(payload) {}
            pendingNotificationCustom = null
        }

        pendingInAppCustomData?.let { payload ->
            Log.i(TAG, "Delivering pending in-app custom data")
            flutterApiInstance?.onInAppCustomDataReceived(payload) {}
            pendingInAppCustomData = null
        }

        binding.addRequestPermissionsResultListener { requestCode, _, grantResults ->
            if (requestCode != REQUEST_POST_NOTIFICATIONS) return@addRequestPermissionsResultListener false
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            updatePushPermissionStatus()
            if (granted) {
                syncCurrentFcmToken()
            }
            pendingPushPermissionResult?.invoke(Result.success(granted))
            pendingPushPermissionResult = null
            true
        }

        // Handle initial notification
        val extras = mainActivity?.intent?.extras
        if (extras != null && extras.containsKey(ES_INTERACTION_ID_KEY)) {
            initialNotification = HashMap()
            for (key in extras.keySet()) {
                val value = extras.get(key)
                initialNotification!![key] = value!!
            }
        }
    }

    override fun onDetachedFromActivity() {
        Log.i(TAG, "onDetachedFromActivity")
        mainActivity = null
        initialNotification = null
        // Don't clean up flutterApi here anymore
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.i(TAG, "onDetachedFromActivityForConfigChanges")
        mainActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.i(TAG, "onReattachedToActivityForConfigChanges")
        mainActivity = binding.activity
    }

    private fun subscribePushListeners() {
        if (isPushListenersSubscribed) {
            return
        }
        RetenoNotifications.click.addListener(clickListener)
        RetenoNotifications.close.addListener(closeListener)
        RetenoNotifications.received.addListener(receivedListener)
        RetenoNotifications.custom.addListener(customListener)
        RetenoNotifications.inAppCustomDataReceived.addListener(inAppCustomDataListener)
        isPushListenersSubscribed = true
    }

    private fun unsubscribePushListeners() {
        if (!isPushListenersSubscribed) {
            return
        }
        RetenoNotifications.click.removeListener(clickListener)
        RetenoNotifications.close.removeListener(closeListener)
        RetenoNotifications.received.removeListener(receivedListener)
        RetenoNotifications.custom.removeListener(customListener)
        RetenoNotifications.inAppCustomDataReceived.removeListener(inAppCustomDataListener)
        isPushListenersSubscribed = false
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

    private fun parseNotificationAction(payload: Map<String, Any?>): NativeUserNotificationAction? {
        val buttonsJson = payload["es_buttons"] as? String ?: return null
        val actionLabel = payload["es_btn_action_label"] as? String ?: return null
        return try {
            val buttonsArray = JSONArray(buttonsJson)
            for (i in 0 until buttonsArray.length()) {
                val button = buttonsArray.getJSONObject(i)
                if (button.getString("label") == actionLabel) {
                    return NativeUserNotificationAction(
                        actionId = button.optString("action_id"),
                        customData = parseCustomData(button.optJSONObject("custom_data")),
                        link = button.optString("link"),
                    )
                }
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing notification action", e)
            null
        }
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

    override fun initWith(
        accessKey: String,
        lifecycleTrackingOptions: NativeLifecycleTrackingOptions?,
        isPausedInAppMessages: Boolean,
        useCustomDeviceIdProvider: Boolean,
        isDebug: Boolean,
        deviceTokenHandlingMode: NativeDeviceTokenHandlingMode,
        defaultNotificationChannelConfig: NativeDefaultNotificationChannelConfig?
    ) {

        val configBuilder = RetenoConfig.Builder()
            .pauseInAppMessages(isPausedInAppMessages)
            .lifecycleTrackingOptions(lifecycleTrackingOptions.toLifecycleTrackingOptions())
            .accessKey(accessKey)
            .setDebug(isDebug)

        if (useCustomDeviceIdProvider) {
            configBuilder.customDeviceIdProvider(CustomDeviceIdProvider())
        }

        defaultNotificationChannelConfig?.let { config ->
            configBuilder.defaultNotificationChannelConfig(
                Procedure<NotificationChannelCompat.Builder> { builder ->
                    config.name?.let { builder.setName(it) }
                    config.description?.let { builder.setDescription(it) }
                    config.showBadge?.let { builder.setShowBadge(it) }
                    config.lightsEnabled?.let { builder.setLightsEnabled(it) }
                    config.vibrationEnabled?.let { builder.setVibrationEnabled(it) }
                }
            )
        }

        Reteno.initWithConfig(configBuilder.build())
        isRetenoInitialized = true
        updatePushPermissionStatus()
        syncCurrentFcmToken()
    }

    override fun setUserAttributes(externalUserId: String, user: NativeRetenoUser?) {
        Log.i(TAG, "setUserAttributes")
        Reteno.instance.setUserAttributes(externalUserId, UserUtils.fromRetenoUser(user))
        syncCurrentFcmToken()
    }

    override fun setAnonymousUserAttributes(anonymousUserAttributes: NativeAnonymousUserAttributes) {
        Log.i(TAG, "setAnonymousUserAttributes")
        Reteno.instance.setAnonymousUserAttributes(
            UserUtils.parseAnonymousAttributes(
                anonymousUserAttributes
            )
        )
        syncCurrentFcmToken()
    }

    override fun logEvent(event: NativeCustomEvent) {
        Log.i(TAG, "logEvent")
        return Reteno.instance.logEvent(buildEventFromCustomEvent(event))
    }

    override fun updatePushPermissionStatus() {
        Log.i(TAG, "updatePushPermissionStatus")
        return Reteno.instance.updatePushPermissionStatus()
    }

    override fun diagnose(callback: (Result<List<String>>) -> Unit) {
        val issues = mutableListOf<String>()
        if (!isRetenoInitialized) {
            issues.add("SDK_NOT_INITIALIZED")
        }

        val notificationsEnabled = NotificationManagerCompat.from(applicationContext).areNotificationsEnabled()
        if (!notificationsEnabled) {
            issues.add("NOTIFICATIONS_DISABLED")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val permissionGranted = ContextCompat.checkSelfPermission(
                applicationContext,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED

            if (!permissionGranted) {
                issues.add("PUSH_PERMISSION_DENIED")
            }
        }

        val fcmServices = getMessagingEventHandlers().filter {
            it != FIREBASE_BASE_MESSAGING_SERVICE
        }
        val isRetenoBridgeDeclared = isServiceDeclared(RETENO_BRIDGE_MESSAGING_SERVICE)
        if (fcmServices.isEmpty()) {
            if (!isRetenoBridgeDeclared) {
                issues.add("FCM_MESSAGING_SERVICE_MISSING")
            }
        } else {
            val hasRetenoService = fcmServices.any { it.contains("reteno", ignoreCase = true) }
            if (!hasRetenoService) {
                issues.add("RETENO_MESSAGING_SERVICE_MISSING")
            }
            if (fcmServices.size > 1) {
                issues.add("FCM_MESSAGING_SERVICE_CONFLICT")
            }
        }

        finalizeDiagnoseWithTokenCheck(issues, callback)
    }

    private fun isServiceDeclared(serviceName: String): Boolean {
        val componentName = ComponentName(applicationContext.packageName, serviceName)
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                applicationContext.packageManager.getServiceInfo(
                    componentName,
                    PackageManager.ComponentInfoFlags.of(0L)
                )
            } else {
                @Suppress("DEPRECATION")
                applicationContext.packageManager.getServiceInfo(componentName, 0)
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun syncCurrentFcmToken(attempt: Int = 0) {
        FirebaseMessaging.getInstance().token
            .addOnSuccessListener { token ->
                if (token.isNullOrBlank()) {
                    Log.d(TAG, "syncCurrentFcmToken: FCM token is empty, attempt=$attempt")
                    scheduleFcmTokenSyncRetry(attempt)
                    return@addOnSuccessListener
                }
                try {
                    RetenoNotificationService(applicationContext).onNewToken(token)
                    Log.d(TAG, "syncCurrentFcmToken: token synced")
                } catch (t: Throwable) {
                    Log.d(TAG, "syncCurrentFcmToken: failed to sync token", t)
                    scheduleFcmTokenSyncRetry(attempt)
                }
            }
            .addOnFailureListener { error ->
                Log.d(TAG, "syncCurrentFcmToken: failed to fetch FCM token", error)
                scheduleFcmTokenSyncRetry(attempt)
            }
    }

    private fun scheduleFcmTokenSyncRetry(currentAttempt: Int) {
        if (currentAttempt >= MAX_FCM_SYNC_RETRIES) {
            return
        }
        val nextAttempt = currentAttempt + 1
        val delay = nextAttempt * FCM_SYNC_RETRY_DELAY_MS
        uiThreadHandler.postDelayed(
            { syncCurrentFcmToken(nextAttempt) },
            delay
        )
    }

    private fun finalizeDiagnoseWithTokenCheck(
        issues: MutableList<String>,
        callback: (Result<List<String>>) -> Unit
    ) {
        FirebaseMessaging.getInstance().token
            .addOnSuccessListener { token ->
                if (token.isNullOrBlank()) {
                    issues.add(ISSUE_FCM_TOKEN_MISSING)
                }
                callback(Result.success(issues.distinct()))
            }
            .addOnFailureListener { error ->
                Log.d(TAG, "diagnose: failed to fetch FCM token", error)
                issues.add(ISSUE_FCM_TOKEN_FETCH_FAILED)
                callback(Result.success(issues.distinct()))
            }
    }

    private fun getMessagingEventHandlers(): List<String> {
        val intent = Intent(FCM_MESSAGING_EVENT_ACTION).setPackage(applicationContext.packageName)
        val resolvedServices = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            applicationContext.packageManager.queryIntentServices(
                intent,
                PackageManager.ResolveInfoFlags.of(0L)
            )
        } else {
            @Suppress("DEPRECATION")
            applicationContext.packageManager.queryIntentServices(intent, 0)
        }
        return resolvedServices.mapNotNull { it.serviceInfo?.name }
    }

    override fun requestPushPermission(
        provisional: Boolean,
        callback: (Result<Boolean>) -> Unit
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            val enabled = NotificationManagerCompat.from(applicationContext).areNotificationsEnabled()
            callback(Result.success(enabled))
            return
        }

        val activity = mainActivity
        if (activity == null) {
            callback(Result.failure(IllegalStateException("No Activity attached")))
            return
        }

        val granted = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED

        if (granted) {
            updatePushPermissionStatus()
            syncCurrentFcmToken()
            callback(Result.success(true))
            return
        }

        if (pendingPushPermissionResult != null) {
            callback(Result.failure(IllegalStateException("Permission request already in progress")))
            return
        }

        pendingPushPermissionResult = callback
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_POST_NOTIFICATIONS
        )
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
        categoryId: String?,
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
        Reteno.instance.recommendation.fetchRecommendation(
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

    override fun getRecommendationsJson(
        recomVariantId: String,
        productIds: List<String>,
        categoryId: String?,
        filters: List<NativeRecomFilter>?,
        fields: List<String>?,
        callback: (Result<Map<String, Any>>) -> Unit
    ) {
        val request = RecomRequest(
            products = productIds,
            category = categoryId,
            fields = fields,
            filters = convertToRecomFilterList(filters)
        )

        Reteno.instance.recommendation.fetchRecommendationJson(
            recomVariantId,
            request,
            object : GetRecommendationResponseJsonCallback {
                override fun onSuccess(response: String) {
                    try {
                        val jsonMap = parseJsonToMap(response)
                        callback(Result.success(jsonMap))
                    } catch (e: Exception) {
                        val resultMap = mapOf("response" to response)
                        callback(Result.success(resultMap))
                    }
                }

                override fun onFailure(statusCode: Int?, response: String?, throwable: Throwable?) {
                    val errorMessage = buildString {
                        append("Recommendation request failed")
                        statusCode?.let { append(" with status code: $it") }
                        response?.let { append(", response: $it") }
                        throwable?.let { append(", error: ${it.message}") }
                    }

                    val exception = throwable ?: Exception(errorMessage)
                    callback(Result.failure(exception))
                }
            }
        )

    }

    override fun logRecommendationsEvent(events: NativeRecomEvents) {
        Reteno.instance.recommendation.logRecommendations(
            RecomEvents(events.recomVariantId, convertToRecomEventList(events))
        )
    }

    override fun getAppInboxMessages(
        page: Long?,
        pageSize: Long?,
        callback: (Result<NativeAppInboxMessages>) -> Unit
    ) {
        Reteno.instance.appInbox.getAppInboxMessages(
            page = page?.toInt(),
            pageSize = pageSize?.toInt(),
            callback = object : RetenoResultCallback<AppInboxMessages> {
                override fun onSuccess(result: AppInboxMessages) {
                    val nativeMessages = result.toNativeAppInboxMessages()
                    callback(Result.success(nativeMessages))
                }

                override fun onFailure(statusCode: Int?, response: String?, throwable: Throwable?) {
                    val error = throwable ?: Exception("Failed to get AppInbox messages. Status: $statusCode, Response: $response")
                    callback(Result.failure(error))
                }
            }
        )
    }

    override fun getAppInboxMessagesCount(callback: (Result<Long>) -> Unit) {
        Reteno.instance.appInbox.getAppInboxMessagesCount(object : RetenoResultCallback<Int> {
            override fun onSuccess(result: Int) {
                callback(Result.success(result.toLong()))
            }

            override fun onFailure(statusCode: Int?, response: String?, throwable: Throwable?) {
                val error = throwable ?: Exception("Failed to get AppInbox messages count. Status: $statusCode, Response: $response")
                callback(Result.failure(error))
            }
        })
    }

    override fun markAsOpened(messageId: String) {
        Reteno.instance.appInbox.markAsOpened(messageId)
    }

    override fun markAllMessagesAsOpened(callback: (Result<Unit>) -> Unit) {
        Reteno.instance.appInbox.markAllMessagesAsOpened(object : RetenoResultCallback<Unit> {
            override fun onSuccess(result: Unit) {
                callback(Result.success(Unit))
            }

            override fun onFailure(statusCode: Int?, response: String?, throwable: Throwable?) {
                val error = throwable ?: Exception("Failed to get AppInbox messages count. Status: $statusCode, Response: $response")
                callback(Result.failure(error))
            }
        })
    }

    override fun subscribeOnMessagesCountChanged() {
        Reteno.instance.appInbox.subscribeOnMessagesCountChanged(object : RetenoResultCallback<Int> {
            override fun onSuccess(result: Int) {
                flutterApi?.onMessagesCountChanged(result.toLong()){}
            }
            override fun onFailure(statusCode: Int?, response: String?, throwable: Throwable?) {}
        })
    }

    override fun unsubscribeAllMessagesCountChanged() {
        Reteno.instance.appInbox.unsubscribeAllMessagesCountChanged()
    }

    override fun logEcommerceProductViewed(product: NativeEcommerceProduct, currency: String?) {
        val productView = ProductView(
            product.productId,
            product.price,
            product.inStock,
            product.attributes.toAttributesList()
        )
        val ecomEvent: EcomEvent = EcomEvent.ProductViewed(productView, currency)
        Reteno.instance.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceProductCategoryViewed(category: NativeEcommerceCategory) {
        val productCategoryView = ProductCategoryView(
            category.productCategoryId,
            category.attributes.toAttributesList()
        )
        val ecomEvent: EcomEvent = EcomEvent.ProductCategoryViewed(productCategoryView)
        Reteno.instance.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceProductAddedToWishlist(
        product: NativeEcommerceProduct,
        currency: String?
    ) {
        val productView = ProductView(
            product.productId,
            product.price,
            product.inStock,
            product.attributes.toAttributesList()
        )
        val ecomEvent: EcomEvent = EcomEvent.ProductAddedToWishlist(productView, currency)
        Reteno.instance.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceCartUpdated(
        cartId: String,
        products: List<NativeEcommerceProductInCart>,
        currency: String?
    ) {
        val ecomEvent: EcomEvent = EcomEvent.CartUpdated(
            cartId,
            products.toProductInCartList(),
            currency
        )
        Reteno.instance.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceOrderCreated(order: NativeEcommerceOrder, currency: String?) {
        val ecomEvent: EcomEvent = EcomEvent.OrderCreated(order.toOrder(), currency)
        Reteno.instance.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceOrderUpdated(order: NativeEcommerceOrder, currency: String?) {
        val ecomEvent: EcomEvent = EcomEvent.OrderUpdated(order.toOrder(), currency)
        Reteno.instance.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceOrderDelivered(externalOrderId: String) {
        val ecomEvent: EcomEvent = EcomEvent.OrderDelivered(externalOrderId)
        Reteno.instance.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceOrderCancelled(externalOrderId: String) {
        val ecomEvent: EcomEvent = EcomEvent.OrderCancelled(externalOrderId)
        Reteno.instance.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceSearchRequest(query: String, isFound: Boolean?) {
        val ecomEvent: EcomEvent = EcomEvent.SearchRequest(query, isFound == true)
        Reteno.instance.logEcommerceEvent(ecomEvent)
    }

    override fun pauseInAppMessages(isPaused: Boolean) {
        Reteno.instance.pauseInAppMessages(isPaused)
    }
}

fun NativeLifecycleTrackingOptions?.toLifecycleTrackingOptions(): LifecycleTrackingOptions {
    return this?.let {
        LifecycleTrackingOptions(
            appLifecycleEnabled = it.appLifecycleEnabled,
            pushSubscriptionEnabled = it.pushSubscriptionEnabled,
            sessionEventsEnabled = it.sessionEventsEnabled
        )
    } ?: LifecycleTrackingOptions.ALL
}

class CustomDeviceIdProvider : DeviceIdProvider {
    override fun getDeviceId(): String? {
        return runBlocking {
            withContext(Dispatchers.Main) {
                suspendCoroutine { continuation ->
                    RetenoPlugin.flutterApi?.getDeviceId { result ->
                        val deviceId = result.getOrNull()
                        continuation.resume(deviceId)
                    }
                }
            }
        }
    }
}

fun AppInboxMessages.toNativeAppInboxMessages(): NativeAppInboxMessages {
    return NativeAppInboxMessages(
        messages = this.messages.map { it.toNativeAppInboxMessage() },
        totalPages = this.totalPages.toLong()
    )
}

fun AppInboxMessage.toNativeAppInboxMessage(): NativeAppInboxMessage {
    return NativeAppInboxMessage(
        id = this.id,
        title = this.title,
        content = this.content,
        createdDate = this.createdDate,
        imageUrl = this.imageUrl,
        isNewMessage = this.isNewMessage,
        linkUrl = this.linkUrl,
        category = this.category,
        customData = this.customData?.mapValues { it.value as Any? }
    )
}

fun Map<String?, List<String>?>?.toAttributesList(): List<Attributes>? =
    this?.mapNotNull { (key, list) ->
        key?.let { Attributes(it, list ?: emptyList()) }
    }?.takeUnless { it.isEmpty() }

fun NativeEcommerceProductInCart.toProductInCart(): ProductInCart =
    ProductInCart(
        productId  = productId,
        quantity   = quantity.coerceAtMost(Int.MAX_VALUE.toLong()).toInt(), // safe-cast
        price      = price,
        discount   = discount,
        name       = name,
        category   = category,
        attributes = attributes.toAttributesList()
    )

fun List<NativeEcommerceProductInCart>.toProductInCartList(): List<ProductInCart> =
    map { it.toProductInCart() }


fun String?.toOrderStatus(): OrderStatus =
    when (this?.uppercase()) {
        "DELIVERED"    -> OrderStatus.DELIVERED
        "IN_PROGRESS"  -> OrderStatus.IN_PROGRESS
        "CANCELLED"    -> OrderStatus.CANCELLED
        "INITIALIZED"  -> OrderStatus.INITIALIZED
        else           -> OrderStatus.INITIALIZED
    }

fun String.toZonedDateTime(): ZonedDateTime =
    try {
        ZonedDateTime.parse(this)
    } catch (ex: DateTimeParseException) {
        LocalDateTime.parse(this).atZone(ZoneId.systemDefault())
    }

fun Map<String?, List<String>?>.toPairsList(): List<AndroidPair<String, String>> {
    val list: MutableList<AndroidPair<String, String>> = ArrayList()
    this.forEach { (key, values) ->
        key?.let { k ->
            val joinedValues = values?.joinToString(",") ?: ""
            list.add(AndroidPair(k, joinedValues))
        }
    }

    return list
}

fun NativeEcommerceItem.toOrderItem(): OrderItem = OrderItem(
    externalItemId = externalItemId,
    name           = name,
    category       = category,
    quantity       = quantity,
    cost           = cost,
    url            = url,
    imageUrl       = imageUrl,
    description    = description
)

fun List<NativeEcommerceItem?>?.toOrderItems(): List<OrderItem>? =
    this?.mapNotNull { it?.toOrderItem() }?.takeUnless { it.isEmpty() }

fun NativeEcommerceOrder.toOrder(): Order = Order(
    externalOrderId     = externalOrderId,
    externalCustomerId  = null,
    totalCost           = totalCost,
    status              = status.toOrderStatus(),
    date                = date.toZonedDateTime(),
    cartId              = cartId,
    email               = email,
    phone               = phone,
    firstName           = firstName,
    lastName            = lastName,
    shipping            = shipping,
    discount            = discount,
    taxes               = taxes,
    restoreUrl          = restoreUrl,
    statusDescription   = statusDescription,
    storeId             = storeId,
    source              = source,
    deliveryMethod      = deliveryMethod,
    paymentMethod       = paymentMethod,
    deliveryAddress     = deliveryAddress,
    items               = items.toOrderItems(),
    attributes          = attributes?.toPairsList()
)

private fun InAppCustomData.toNativeInAppCustomData(): NativeInAppCustomData {
    val normalizedData: Map<String?, String?> = data.mapKeys { it.key }.mapValues { it.value }
    return NativeInAppCustomData(
        url = url,
        source = source,
        inAppId = inAppId,
        data = normalizedData,
    )
}

private fun parseJsonToMap(jsonString: String): Map<String, Any> {
    val jsonObject = org.json.JSONObject(jsonString)
    return jsonObjectToMap(jsonObject)
}

private fun jsonObjectToMap(jsonObject: org.json.JSONObject): Map<String, Any> {
    val map = mutableMapOf<String, Any>()
    val keys = jsonObject.keys()

    while (keys.hasNext()) {
        val key = keys.next()
        val value = jsonObject.get(key)

        map[key] = when (value) {
            is org.json.JSONObject -> jsonObjectToMap(value)
            is org.json.JSONArray -> jsonArrayToList(value)
            else -> value
        }
    }

    return map
}

private fun jsonArrayToList(jsonArray: org.json.JSONArray): List<Any> {
    val list = mutableListOf<Any>()

    for (i in 0 until jsonArray.length()) {
        val value = jsonArray.get(i)

        list.add(when (value) {
            is org.json.JSONObject -> jsonObjectToMap(value)
            is org.json.JSONArray -> jsonArrayToList(value)
            else -> value
        })
    }

    return list
}
