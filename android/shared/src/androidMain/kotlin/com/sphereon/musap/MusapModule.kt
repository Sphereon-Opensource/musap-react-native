package com.sphereon.musap;

import android.content.Context
import com.facebook.react.bridge.*
import com.facebook.react.util.RNLog
import com.sphereon.musap.models.SscdType
import com.sphereon.musap.serializers.toKeyGenReq
import com.sphereon.musap.serializers.toSignatureReq
import com.sphereon.musap.serializers.toWritableMap
import fi.methics.musap.sdk.api.MusapCallback
import fi.methics.musap.sdk.api.MusapClient
import fi.methics.musap.sdk.api.MusapException
import fi.methics.musap.sdk.extension.MusapSscdInterface
import fi.methics.musap.sdk.internal.datatype.MusapKey
import fi.methics.musap.sdk.internal.datatype.MusapSignature
import fi.methics.musap.sdk.sscd.android.AndroidKeystoreSscd
import fi.methics.musap.sdk.sscd.yubikey.YubiKeySscd


class MusapModuleAndroid(private val context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {

    override fun getName(): String = "MusapModule"

    init {
        MusapClient.setDebugLog(true)
    }

    @ReactMethod
    fun generateKey(sscdType: String, req: ReadableMap, callback: Callback) {
        val sscd = MusapClient.listEnabledSscds().first { it.sscdId == sscdType }
        val musapCallback = object : MusapCallback<MusapKey> {
            override fun onSuccess(p0: MusapKey?) {
                callback.invoke("Key successfully created: ${p0?.keyId}")
            }

            override fun onException(p0: MusapException?) {
                callback.invoke("Error creating key: ${p0?.message}")
            }
        }
        val reqObj = req.toKeyGenReq(reactApplicationContext.currentActivity)
        RNLog.w(reactApplicationContext, "${reqObj}")
        MusapClient.generateKey(sscd, reqObj, musapCallback)
    }

    @ReactMethod
    fun sign(req: ReadableMap, callback: Callback) {
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
    fun listEnabledSscds(): WritableArray {
        val writableArray = Arguments.createArray()
         MusapClient.listEnabledSscds().forEach{ sscd->
            writableArray.pushMap(sscd.sscdInfo.toWritableMap())
        }
        return writableArray
    }

    // active = that can generate or bind keys
    @ReactMethod(isBlockingSynchronousMethod = true)
    fun listActiveSscds(): WritableArray {
        val writableArray = Arguments.createArray()
        MusapClient.listActiveSscds().forEach { sscd ->
            writableArray.pushMap(sscd.sscdInfo.toWritableMap())
        }
        return writableArray
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun enableSscd(sscdType: String)  {
        MusapClient.enableSscd(getSscdInstance(SscdType.valueOf(sscdType)), sscdType)
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getKeyByUri(keyURI: String): MusapKey {
        return MusapClient.getKeyByUri(keyURI)
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getSscdInfo(sscdId: String): WritableMap {
        return MusapClient.listEnabledSscds().first{ it.sscdId == sscdId}.sscdInfo.toWritableMap()
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getSettings(sscdId: String): WritableMap {
        return MusapClient.listEnabledSscds().first{ it.sscdId == sscdId }.settings.toWritableMap()
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun listKeys(): WritableArray {
        val writableArray = Arguments.createArray()
        MusapClient.listKeys().forEach{
            writableArray.pushMap(it.toWritableMap())
        }
        return writableArray
    }

    fun getSscdInstance(type: SscdType): MusapSscdInterface<*> {
        return when (type) {
            SscdType.TEE -> AndroidKeystoreSscd(initialContext)
            SscdType.YUBI_KEY -> YubiKeySscd(initialContext)
            else -> throw IllegalArgumentException("$type is not a supported SSCD")
        }
    }

    // For Android Native use, won't work otherwise because of the context
    companion object {
        var initialContext:Context? = null

        fun init(context: Context) {
            MusapClient.init(context)
            initialContext = context
        }
    }
}
