package com.sphereon.musaprn;

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import fi.methics.musap.sdk.api.MusapClient

private val objectMapper = jacksonObjectMapper()


class MusapModule(val context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {

    override fun getName(): String = "MusapModule"

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun listEnabledSscdsAsJson(): String {
        val sscds = MusapClient.listEnabledSscds()
        return objectMapper.writeValueAsString(sscds)
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun listActiveSscdsAsJson(): String {
        val sscds = MusapClient.listActiveSscds()
        return objectMapper.writeValueAsString(sscds)
    }
}
