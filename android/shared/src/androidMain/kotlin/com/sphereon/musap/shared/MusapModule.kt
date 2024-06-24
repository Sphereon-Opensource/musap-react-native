package com.sphereon.musap.shared;

import android.content.Context
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.util.RNLog
import com.sphereon.musap.rnserializer.toKeyGenReq
import com.sphereon.musap.rnserializer.toSignatureReq
import com.sphereon.musap.rnserializer.toWritableMap
import fi.methics.musap.sdk.api.MusapCallback
import fi.methics.musap.sdk.api.MusapClient
import fi.methics.musap.sdk.api.MusapException
import fi.methics.musap.sdk.extension.MusapSscdInterface
import fi.methics.musap.sdk.internal.datatype.MusapKey
import fi.methics.musap.sdk.internal.datatype.MusapSignature
import fi.methics.musap.sdk.sscd.android.AndroidKeystoreSscd


class MusapModuleAndroid(context: ReactApplicationContext) : ReactContextBaseJavaModule(context), MusapModule {

    override fun getName(): String = "MusapModule"

    init {
        MusapClient.setDebugLog(true)
    }

    @ReactMethod
    override fun generateKey(sscdID: String, req: ReadableMap, callback: Callback) {

        val sscd = MusapClient.listEnabledSscds().first { it.sscdId == sscdID }
        val musapCallback = object : MusapCallback<MusapKey> {
            override fun onSuccess(p0: MusapKey?) {
                callback.invoke("Key successfully created: ${p0?.keyId}")
            }

            override fun onException(p0: MusapException?) {
                callback.invoke("Error creating key: ${p0?.message}")
            }
        }
        val reqObj = req.toKeyGenReq(null, reactApplicationContext.currentActivity)
        RNLog.w(reactApplicationContext, "MUSAP client: ${MusapClient.getMusapId()}")
        RNLog.w(reactApplicationContext, "${reqObj}")
        MusapClient.generateKey(sscd, reqObj, musapCallback)
    }

    @ReactMethod
    override fun sign(req: ReadableMap, callback: Callback) {
        val reqObj = req.toSignatureReq(reactApplicationContext.currentActivity)
        val callbackTmp = object : MusapCallback<MusapSignature> {
            override fun onSuccess(p0: MusapSignature?) {
                callback.invoke("Data successfully signed: ${p0?.b64Signature}")
            }

            override fun onException(p0: MusapException?) {
                callback.invoke("Error signing the data: ${p0?.message}")
            }

        }
        MusapClient.sign(reqObj, callbackTmp)
    }

    // enabled = supported by MUSAP
    @ReactMethod(isBlockingSynchronousMethod = true)
    override fun listEnabledSscds(): WritableArray {
        val sscds = MusapClient.listEnabledSscds()
        val writableArray = Arguments.createArray()
        for (sscd in sscds) {
            writableArray.pushMap(sscd.toWritableMap())
        }
        return writableArray
    }

    // active = that can generate or bind keys
    @ReactMethod(isBlockingSynchronousMethod = true)
    override fun listActiveSscds(): WritableArray {
        val sscds = MusapClient.listActiveSscds()
        val writableArray = Arguments.createArray()
        for (sscd in sscds) {
            writableArray.pushMap(sscd.toWritableMap())
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
            return when (type) {
                SscdType.AKS -> AndroidKeystoreSscd(context)
                else -> throw IllegalArgumentException("$type is not a valid SSCD")
            }
        }
    }
}
