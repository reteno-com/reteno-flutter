package com.reteno.reteno_plugin

import com.google.firebase.messaging.RemoteMessage
import com.reteno.fcm.RetenoFirebaseMessagingService

class RetenoFirebaseMessagingServiceBridge : RetenoFirebaseMessagingService() {
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        notifyFlutterFirebaseAboutNewToken(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
    }

    private fun notifyFlutterFirebaseAboutNewToken(token: String) {
        try {
            val liveDataClass =
                Class.forName("io.flutter.plugins.firebase.messaging.FlutterFirebaseTokenLiveData")
            val getInstanceMethod = liveDataClass.getMethod("getInstance")
            val liveDataInstance = getInstanceMethod.invoke(null)
            val postTokenMethod = liveDataClass.getMethod("postToken", String::class.java)
            postTokenMethod.invoke(liveDataInstance, token)
        } catch (_: Throwable) {
            // firebase_messaging may be absent or internal API may change.
        }
    }
}
