package com.reteno.reteno_plugin

import UserUtils
import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.reteno.core.Reteno
import com.reteno.core.RetenoApplication
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
import com.reteno.core.identification.DeviceIdProvider
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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeParseException
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import android.util.Pair as AndroidPair
private const val TAG = "RetenoPlugin"
private const val ES_INTERACTION_ID_KEY: String = "es_interaction_id"

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
    }

    private lateinit var reteno: Reteno
    private var initialNotification: HashMap<String, Any>? = null
    private var mainActivity: Activity? = null
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())
    private lateinit var applicationContext: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onAttachedToEngine")
        pluginBinding = flutterPluginBinding
        initializeFlutterApi(flutterPluginBinding.binaryMessenger)

        reteno = (flutterPluginBinding.applicationContext as RetenoApplication).getRetenoInstance()
        applicationContext = flutterPluginBinding.applicationContext
        createInAppLifecycleListener()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onDetachedFromEngine")
        // Don't clean up flutterApi here anymore
        pluginBinding = null
    }

    private fun initPlugin(binaryMessenger: BinaryMessenger) {
        RetenoHostApi.setUp(binaryMessenger, this)
        // Initialize flutterApi if it hasn't been initialized yet
        initializeFlutterApi(binaryMessenger)
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

    override fun initWith(
        accessKey: String,
        lifecycleTrackingOptions: NativeLifecycleTrackingOptions?,
        isPausedInAppMessages: Boolean,
        useCustomDeviceIdProvider: Boolean
    ) {
        val config = RetenoConfig(
            isPausedInAppMessages,
            userIdProvider = if (useCustomDeviceIdProvider) CustomDeviceIdProvider() else null,
            lifecycleTrackingOptions.toLifecycleTrackingOptions(),
            accessKey
        )
        reteno.initWith(config)
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

    override fun getAppInboxMessages(
        page: Long?,
        pageSize: Long?,
        callback: (Result<NativeAppInboxMessages>) -> Unit
    ) {
        reteno.appInbox.getAppInboxMessages(
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
        reteno.appInbox.getAppInboxMessagesCount(object : RetenoResultCallback<Int> {
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
        reteno.appInbox.markAsOpened(messageId)
    }

    override fun markAllMessagesAsOpened(callback: (Result<Unit>) -> Unit) {
        reteno.appInbox.markAllMessagesAsOpened(object : RetenoResultCallback<Unit> {
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
        reteno.appInbox.subscribeOnMessagesCountChanged(object : RetenoResultCallback<Int> {
            override fun onSuccess(result: Int) {
                flutterApi?.onMessagesCountChanged(result.toLong()){}
            }
            override fun onFailure(statusCode: Int?, response: String?, throwable: Throwable?) {}
        })
    }

    override fun unsubscribeAllMessagesCountChanged() {
        reteno.appInbox.unsubscribeAllMessagesCountChanged()
    }

    override fun logEcommerceProductViewed(product: NativeEcommerceProduct, currency: String?) {
        val productView = ProductView(
            product.productId,
            product.price,
            product.inStock,
            product.attributes.toAttributesList()
        )
        val ecomEvent: EcomEvent = EcomEvent.ProductViewed(productView, currency)
        reteno.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceProductCategoryViewed(category: NativeEcommerceCategory) {
        val productCategoryView = ProductCategoryView(
            category.productCategoryId,
            category.attributes.toAttributesList()
        )
        val ecomEvent: EcomEvent = EcomEvent.ProductCategoryViewed(productCategoryView)
        reteno.logEcommerceEvent(ecomEvent)
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
        reteno.logEcommerceEvent(ecomEvent)
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
        reteno.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceOrderCreated(order: NativeEcommerceOrder, currency: String?) {
        val ecomEvent: EcomEvent = EcomEvent.OrderCreated(order.toOrder(), currency)
        reteno.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceOrderUpdated(order: NativeEcommerceOrder, currency: String?) {
        val ecomEvent: EcomEvent = EcomEvent.OrderUpdated(order.toOrder(), currency)
        reteno.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceOrderDelivered(externalOrderId: String) {
        val ecomEvent: EcomEvent = EcomEvent.OrderDelivered(externalOrderId)
        reteno.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceOrderCancelled(externalOrderId: String) {
        val ecomEvent: EcomEvent = EcomEvent.OrderCancelled(externalOrderId)
        reteno.logEcommerceEvent(ecomEvent)
    }

    override fun logEcommerceSearchRequest(query: String, isFound: Boolean?) {
        val ecomEvent: EcomEvent = EcomEvent.SearchRequest(query, isFound == true)
        reteno.logEcommerceEvent(ecomEvent)
    }

    override fun pauseInAppMessages(isPaused: Boolean) {
        reteno.pauseInAppMessages(isPaused)
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
