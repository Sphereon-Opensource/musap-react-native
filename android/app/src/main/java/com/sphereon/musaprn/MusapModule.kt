package com.sphereon.musaprn;

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import fi.methics.musap.sdk.api.MusapClient
import fi.methics.musap.sdk.internal.util.MusapSscd

class MusapModule(val context: ReactApplicationContext): ReactContextBaseJavaModule(context) {

    override fun getName(): String = "MusapModule"

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun listEnabledSscds():MutableList<MusapSscd>? = MusapClient.listEnabledSscds()
}
