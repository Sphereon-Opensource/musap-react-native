package com.sphereon.musap.shared;

import android.content.Context
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableArray
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import fi.methics.musap.sdk.api.MusapCallback
import fi.methics.musap.sdk.api.MusapClient
import fi.methics.musap.sdk.extension.MusapSscdInterface
import fi.methics.musap.sdk.internal.datatype.MusapKey
import fi.methics.musap.sdk.internal.keygeneration.KeyGenReq
import fi.methics.musap.sdk.internal.util.MusapSscd
import fi.methics.musap.sdk.sscd.android.AndroidKeystoreSscd
import org.json.JSONObject

class MusapModuleAndroid(context: ReactApplicationContext) : ReactContextBaseJavaModule(context), MusapModule {

    override fun getName(): String = "MusapModule"

    private val objectMapper = jacksonObjectMapper()

    @ReactMethod
    override fun generateKey(sscd: ReadableMap, req: ReadableMap, callBack: ReadableMap) {
        val sscdObj = jacksonObjectMapper().readValue(
            convertToJSONObject(sscd).toString(),
            MusapSscd::class.java
        )
        val reqObj = jacksonObjectMapper().readValue(
            convertToJSONObject(req).toString(),
            KeyGenReq::class.java
        )
        val callbackObj = jacksonObjectMapper().readValue(
            convertToJSONObject(callBack).toString(),
            MusapCallback::class.java
        )

        @Suppress("UNCHECKED_CAST")
        MusapClient.generateKey(sscdObj, reqObj, callbackObj as MusapCallback<MusapKey>)
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    override fun listEnabledSscds(): WritableArray {
        val sscds = MusapClient.listEnabledSscds()
        val writableArray = Arguments.createArray()
        for (sscd in sscds) {
            val sscdMap =
                convertToWritabaleMap(JSONObject(objectMapper.writeValueAsString(sscd)))
            writableArray.pushMap(sscdMap)
        }
        return writableArray
    }

    // For Android Native use, wont work otherwise because of the context
    companion object {
        fun init(context: Context) {
            MusapClient.init(context)
        }

        fun enableSscd(type: SscdType, sscdId: String, context: Context) {
            MusapClient.enableSscd(getSscdInstance(type, context), sscdId)
        }

        fun getSscdInstance(type: SscdType, context: Context): MusapSscdInterface<*> {
            return when(type) {
                SscdType.AKS -> AndroidKeystoreSscd(context)
                else -> throw IllegalArgumentException("$type is not a valid SSCD")
            }
        }
    }
}
