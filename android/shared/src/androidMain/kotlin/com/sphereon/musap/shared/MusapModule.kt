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
import com.google.gson.GsonBuilder
import com.sphereon.musap.serializer.MusapSscdSerializer
import fi.methics.musap.sdk.api.MusapCallback
import fi.methics.musap.sdk.api.MusapClient
import fi.methics.musap.sdk.api.MusapException
import fi.methics.musap.sdk.extension.MusapSscdInterface
import fi.methics.musap.sdk.internal.datatype.MusapKey
import fi.methics.musap.sdk.internal.datatype.MusapSignature
import fi.methics.musap.sdk.internal.keygeneration.KeyGenReq
import fi.methics.musap.sdk.internal.sign.SignatureReq
import fi.methics.musap.sdk.internal.util.MusapSscd
import fi.methics.musap.sdk.sscd.android.AndroidKeystoreSscd
import org.json.JSONObject

class MusapModuleAndroid(context: ReactApplicationContext) : ReactContextBaseJavaModule(context), MusapModule {

    override fun getName(): String = "MusapModule"

    private val gson = GsonBuilder().registerTypeAdapter(MusapSscd::class.java, MusapSscdSerializer()).create()
    init {
        MusapClient.setDebugLog(true)
    }

    @ReactMethod
    override fun generateKey(sscd: ReadableMap, req: ReadableMap, callback: Callback) {
        val sscdObj = gson.fromJson(sscd.toString(), MusapSscd::class.java)
        val reqObj = gson.fromJson(req.toString(), KeyGenReq::class.java)
        val musapCallback = object: MusapCallback<MusapKey> {
            override fun onSuccess(p0: MusapKey?) {
                callback.invoke("Key successfully created: ${p0?.keyId}")
            }
            override fun onException(p0: MusapException?) {
                callback.invoke("Error creating key: ${p0?.message}")
            }
        }
        reqObj.activity = reactApplicationContext.currentActivity
        RNLog.w(reactApplicationContext, "MUSAP client: ${MusapClient.getMusapId()}")
        RNLog.w(reactApplicationContext, "${reqObj}")
        MusapClient.generateKey(sscdObj, reqObj, musapCallback)
    }

    @ReactMethod
    override fun sign(req: ReadableMap, callback: Callback) {
        val reqObj = gson.fromJson(req.toString(), SignatureReq::class.java)
        val callbackTmp = object: MusapCallback<MusapSignature>{
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
            val sscdMap =
                convertToWritabaleMap(JSONObject(gson.toJson(sscd)))
            writableArray.pushMap(sscdMap)
        }
        return writableArray
    }

    // active = that can generate or bind keys
    @ReactMethod(isBlockingSynchronousMethod = true)
    override fun listActiveSscds(): WritableArray {
        val sscds = MusapClient.listActiveSscds()
        val writableArray = Arguments.createArray()
        for (sscd in sscds) {
            val sscdMap =
                convertToWritabaleMap(JSONObject(gson.toJson(sscd)))
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
