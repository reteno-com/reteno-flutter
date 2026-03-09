package com.reteno.reteno_plugin

import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.google.firebase.messaging.RemoteMessage
import com.reteno.fcm.RetenoFirebaseMessagingService

private const val BRIDGE_TAG = "RetenoFcmBridge"
private const val FLUTTER_FIREBASE_RECEIVER =
    "io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver"
private const val C2DM_RECEIVE_ACTION = "com.google.android.c2dm.intent.RECEIVE"
private const val GOOGLE_MESSAGE_ID = "google.message_id"
private const val MESSAGE_ID = "message_id"
private const val MESSAGE_TYPE = "message_type"
private const val COLLAPSE_KEY = "collapse_key"
private const val TTL = "google.ttl"
private const val SENT_TIME = "google.sent_time"
private const val FROM = "from"
private const val TO = "to"
private const val TITLE = "gcm.notification.title"
private const val BODY = "gcm.notification.body"

class RetenoFirebaseMessagingServiceBridge : RetenoFirebaseMessagingService() {
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        notifyFlutterFirebaseAboutNewToken(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        if (!isRetenoMessage(message)) {
            forwardNonRetenoMessageToFlutter(message)
        }
    }

    private fun notifyFlutterFirebaseAboutNewToken(token: String) {
        try {
            val liveDataClass =
                Class.forName("io.flutter.plugins.firebase.messaging.FlutterFirebaseTokenLiveData")
            val getInstanceMethod = liveDataClass.getMethod("getInstance")
            val liveDataInstance = getInstanceMethod.invoke(null)
            val postTokenMethod = liveDataClass.getMethod("postToken", String::class.java)
            postTokenMethod.invoke(liveDataInstance, token)
        } catch (t: Throwable) {
            Log.d(BRIDGE_TAG, "Failed to forward token to firebase_messaging", t)
        }
    }

    private fun forwardNonRetenoMessageToFlutter(message: RemoteMessage) {
        try {
            val intent = Intent(C2DM_RECEIVE_ACTION).apply {
                setClassName(applicationContext, FLUTTER_FIREBASE_RECEIVER)
                putExtras(remoteMessageToBundle(message))
            }
            applicationContext.sendBroadcast(intent)
        } catch (t: Throwable) {
            Log.d(BRIDGE_TAG, "Failed to forward non-Reteno message to firebase_messaging", t)
        }
    }

    private fun remoteMessageToBundle(message: RemoteMessage): Bundle {
        val bundle = Bundle()
        message.data.forEach { (key, value) ->
            bundle.putString(key, value)
        }

        message.messageId?.let {
            bundle.putString(GOOGLE_MESSAGE_ID, it)
            bundle.putString(MESSAGE_ID, it)
        }
        message.messageType?.let { bundle.putString(MESSAGE_TYPE, it) }
        message.collapseKey?.let { bundle.putString(COLLAPSE_KEY, it) }
        message.from?.let { bundle.putString(FROM, it) }
        message.to?.let { bundle.putString(TO, it) }

        if (message.ttl > 0) {
            bundle.putString(TTL, message.ttl.toString())
        }
        if (message.sentTime > 0L) {
            bundle.putLong(SENT_TIME, message.sentTime)
        }

        message.notification?.let { notification ->
            notification.title?.let { bundle.putString(TITLE, it) }
            notification.body?.let { bundle.putString(BODY, it) }
        }

        return bundle
    }
}
