package com.reteno.sample.reteno_plugin_example

import com.reteno.core.Reteno
import com.reteno.core.RetenoApplication
import com.reteno.core.RetenoImpl
import io.flutter.app.FlutterApplication

class CustomApplication : FlutterApplication(), RetenoApplication {
    override fun onCreate() {
        super.onCreate()
        retenoInstance = RetenoImpl(this)
    }

    private lateinit var retenoInstance: Reteno
    override fun getRetenoInstance(): Reteno {
        return retenoInstance
    }
}
