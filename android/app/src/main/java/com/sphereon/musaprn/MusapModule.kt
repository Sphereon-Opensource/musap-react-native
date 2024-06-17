package com.sphereon.musaprn;

import com.facebook.react.bridge.*
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import fi.methics.musap.sdk.api.MusapClient
import fi.methics.musap.sdk.internal.keygeneration.KeyGenReq

private val objectMapper = jacksonObjectMapper()

class MusapModule(val context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {


    override fun getName(): String = "MusapModule"

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun listEnabledSscdsInfos(): String {
        return objectMapper.writeValueAsString(MusapClient.listEnabledSscds().map { it.sscdInfo })
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun generateKey(sscdId:String, keyGenRequestPayload: String) : String {
        val keyGenReq: KeyGenReq = objectMapper.readValue(keyGenRequestPayload, KeyGenReq::class.java)
        val key = MusapClient.listEnabledSscds().first{it.sscdId == sscdId}.generateKey(keyGenReq)
        return objectMapper.writeValueAsString(key)
    }
}
