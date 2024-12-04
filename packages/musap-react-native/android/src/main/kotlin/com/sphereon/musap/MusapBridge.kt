package com.sphereon.musap;

import android.content.Context
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.sphereon.musap.models.SscdType
import com.sphereon.musap.serializers.toDecryptionReq
import com.sphereon.musap.serializers.toEncryptionReq
import com.sphereon.musap.serializers.toExternalSscdSettings
import com.sphereon.musap.serializers.toKeyBindReq
import com.sphereon.musap.serializers.toKeyGenReq
import com.sphereon.musap.serializers.toSignatureReq
import com.sphereon.musap.serializers.toWritableMap
import fi.methics.musap.sdk.api.MusapCallback
import fi.methics.musap.sdk.api.MusapClient
import fi.methics.musap.sdk.api.MusapException
import fi.methics.musap.sdk.extension.MusapSscdInterface
import fi.methics.musap.sdk.internal.datatype.MusapKey
import fi.methics.musap.sdk.internal.datatype.MusapLink
import fi.methics.musap.sdk.internal.datatype.MusapSignature
import fi.methics.musap.sdk.internal.datatype.RelyingParty
import fi.methics.musap.sdk.sscd.android.AndroidKeystoreSscd
import fi.methics.musap.sdk.sscd.external.ExternalSscd
import fi.methics.musap.sdk.sscd.external.ExternalSscdSettings
import fi.methics.musap.sdk.sscd.yubikey.YubiKeySscd
import java.util.*

@OptIn(ExperimentalStdlibApi::class)
class MusapBridgeAndroid(private val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String = "MusapBridge"

    init {
        initializeMusap(reactContext)
    }

    @ReactMethod
    fun generateKey(sscdId: String, req: ReadableMap, promise: Promise) {
        try {
            val sscd = MusapClient.listEnabledSscds().first { it.sscdId == sscdId }
            val reqObj = req.toKeyGenReq(reactApplicationContext.currentActivity)

            val callback = object : MusapCallback<MusapKey> {
                override fun onSuccess(musapKey: MusapKey?) {
                    if (musapKey != null) {
                        promise.resolve(musapKey.keyUri.uri)
                    } else {
                        promise.reject("GENERATE_KEY_ERROR", "MusapKey is null")
                    }
                }

                override fun onException(e: MusapException?) {
                    promise.reject("GENERATE_KEY_ERROR", e?.message, e)
                }
            }

            MusapClient.generateKey(sscd, reqObj, callback)
        } catch (e: Exception) {
            Log.e("MUSAP_BRIDGE", "generateKey failed", e)
            promise.reject("GENERATE_KEY_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun bindKey(sscdId: String, req: ReadableMap, promise: Promise) {
        try {
            val sscd = MusapClient.listEnabledSscds().first { it.sscdId == sscdId }
            val reqObj = req.toKeyBindReq(reactApplicationContext.currentActivity)

            val callback = object : MusapCallback<MusapKey> {
                override fun onSuccess(musapKey: MusapKey?) {
                    if (musapKey != null) {
                        val result = Arguments.createMap().apply {
                            putString("keyUri", musapKey.keyUri.uri)
                        }
                        promise.resolve(result)
                    } else {
                        promise.reject("GENERATE_KEY_ERROR", "MusapKey is null")
                    }
                }

                override fun onException(e: MusapException?) {
                    Log.e("MUSAP_BRIDGE", "bindKey failed", e)
                    promise.reject("GENERATE_KEY_ERROR", e?.message, e)
                }
            }

            MusapClient.bindKey(sscd, reqObj, callback)
        } catch (e: Exception) {
            Log.e("MUSAP_BRIDGE", "generateKey failed", e)
            promise.reject("GENERATE_KEY_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun removeKey(keyIdOrUri: String, promise: Promise) {
        try {
            val musapKey = if (keyIdOrUri.startsWith("keyuri:")) {
                MusapClient.getKeyByUri(keyIdOrUri)
                    ?: throw IllegalArgumentException("No key found for URI $keyIdOrUri")
            } else {
                MusapClient.getKeyByKeyID(keyIdOrUri)
                    ?: throw IllegalArgumentException("No key found for ID $keyIdOrUri")
            }
            val removedKey = MusapClient.removeKey(musapKey)
            promise.resolve(removedKey)
        } catch (e: Exception) {
            Log.e("MUSAP_BRIDGE", "removeKey failed", e)
            promise.reject(e)
        }
    }


    @ReactMethod
    fun sign(req: ReadableMap, promise: Promise) {
        try {
            var signatureReq = req.toSignatureReq(this.currentActivity)

            val callback = object : MusapCallback<MusapSignature> {
                override fun onSuccess(signature: MusapSignature?) {
                    if (signature != null) {
                        val convertToRS = true // FIXME to req
                        if (convertToRS) {
                            val rsSignature = SignatureConverter.convertToRS(signature.rawSignature)
                            val rsSignatureBase64 = Base64.getUrlEncoder().withoutPadding().encodeToString(rsSignature)
                            promise.resolve(rsSignatureBase64)
                        } else {
                            promise.resolve(signature.b64Signature)
                        }
                    } else {
                        promise.reject("SIGN_ERROR", "MusapSignature is null")
                    }
                }

                override fun onException(e: MusapException?) {
                    promise.reject("SIGN_ERROR", e?.message, e)
                }
            }

            MusapClient.sign(signatureReq, callback)
        } catch (e: Throwable) {
            Log.e("MUSAP_BRIDGE", "sign failed", e)
            promise.reject("SIGN_ERROR", "Error preparing signature request: ${e.message}", e)
        }
    }

    @ReactMethod
    fun encryptData(req: ReadableMap, promise: Promise) {
        try {
            val encryptionReq = req.toEncryptionReq()

            val callback = object : MusapCallback<ByteArray?> {
                override fun onSuccess(encData: ByteArray?) {
                    if (encData != null) {
                        promise.resolve(Base64.getEncoder().encodeToString(encData))
                    } else {
                        promise.reject("ENCRYPTION_ERROR", "Encrypted data is null")
                    }
                }

                override fun onException(e: MusapException?) {
                    promise.reject("ENCRYPTION_ERROR", e?.message, e)
                }
            }

            MusapClient.encryptData(encryptionReq, callback)
        } catch (e: Exception) {
            Log.e("MUSAP_BRIDGE", "Encryption failed", e)
            promise.reject("ENCRYPTION_ERROR", "Error preparing encryption request: ${e.message}", e)
        }
    }


    @ReactMethod
    fun decryptData(req: ReadableMap, promise: Promise) {
        try {
            val decryptionReq = req.toDecryptionReq()

            val callback = object : MusapCallback<ByteArray?> {
                override fun onSuccess(decData: ByteArray?) {
                    if (decData != null) {
                        promise.resolve(Base64.getEncoder().encodeToString(decData))
                    } else {
                        promise.reject("DECRYPTION_ERROR", "Decrypted data is null")
                    }
                }

                override fun onException(e: MusapException?) {
                    promise.reject("DECRYPTION_ERROR", e?.message, e)
                }
            }

            MusapClient.decryptData(decryptionReq, callback)
        } catch (e: Exception) {
            Log.e("MUSAP_BRIDGE", "Decryption failed", e)
            promise.reject("DECRYPTION_ERROR", "Error preparing decryption request: ${e.message}", e)
        }
    }


    // enabled = supported by device running MUSAP
    @ReactMethod(isBlockingSynchronousMethod = true)
    fun listEnabledSscds(): WritableArray {
        return Arguments.createArray().apply {
            MusapClient.listEnabledSscds().forEach {
                pushMap(it.toWritableMap())
            }
        }
    }

    // active = that can generate or bind keys
    @ReactMethod(isBlockingSynchronousMethod = true)
    fun listActiveSscds(): WritableArray {
        return Arguments.createArray().apply {
            MusapClient.listActiveSscds().forEach {
                pushMap(it.toWritableMap())
            }
        }
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun enableSscd(sscdType: String, sscdId: String?, settings: ReadableMap?) {
        val selectedSscdId = sscdId ?: sscdType
        try {
            if(sscdType == "EXTERNAL") {
                MusapClient.listEnabledSscds()
                    .filter { sscd -> sscd.sscdId == sscdId }
                    .forEach { sscd -> MusapClient.removeSscd(sscd.sscdInfo) }
                val sscdInstance = createSscdInstance(SscdType.valueOf(sscdType), settings?.toExternalSscdSettings()) // FIXME ExternalSscdSettings is mandatory 
                MusapClient.enableSscd(sscdInstance, selectedSscdId)
            } else {
                if (MusapClient.listEnabledSscds()
                        .count { musapSscd -> musapSscd.sscdId == selectedSscdId } == 0
                ) {
                    val sscdInstance = createSscdInstance(SscdType.valueOf(sscdType), settings?.toExternalSscdSettings())
                    MusapClient.enableSscd(sscdInstance, selectedSscdId)
                }
            }
        } catch (e: Exception) {
            Log.e("MUSAP_BRIDGE", "enableSscd failed", e)
            throw e
        }
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getKeyByUri(keyUri: String): WritableMap {
        val keyByUri = MusapClient.getKeyByUri(keyUri) ?: throw Exception("Key not found by keyUri for $keyUri")
        return keyByUri.toWritableMap()
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getKeyById(keyId: String): WritableMap {
        val key = MusapClient.getKeyByKeyID(keyId) ?: throw Exception("Key not found by id for $keyId")
        return key.toWritableMap()
    }

    // TODO BEFORE PR check everything for possible NPs
    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getSscdInfo(sscdId: String): WritableMap {
        return MusapClient.listEnabledSscds().first { it.sscdId == sscdId }.sscdInfo.toWritableMap()
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getSettings(sscdId: String): WritableMap {
        return MusapClient.listEnabledSscds().first { it.sscdId == sscdId }.settings.toWritableMap()
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun listKeys(): WritableArray {
        try {
            return Arguments.createArray().apply {
                MusapClient.listKeys().forEach {
                    pushMap(it.toWritableMap())
                }
            }
        } catch (e: Exception) {
            Log.e("MUSAP_BRIDGE", "listKeys failed", e)
            throw e
        }
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getLink(): String? {
        val musapLink = MusapClient.getMusapLink()
        if (musapLink != null) {
            return musapLink.musapId
        }
        return null
    }
    
    @ReactMethod
    fun enableLink(url: String, fcmToken: String?, promise: Promise) {
        try {
            val callback = object : MusapCallback<MusapLink> {
                override fun onSuccess(musapLink: MusapLink?) {
                    if (musapLink != null) {
                        Log.d("MUSAP_BRIDGE", "enableLink.musapId=${MusapClient.getMusapLink().musapId}")
                        promise.resolve(musapLink.musapId)
                    } else {
                        promise.reject("ENABLE_LINK_ERROR", "MusapLink is null")
                    }
                }

                override fun onException(e: MusapException?) {
                    promise.reject("ENABLE_LINK_ERROR", e?.message, e)
                }
            }
            val musapLink = MusapClient.getMusapLink()
            if(musapLink == null) {
                Log.d("MUSAP_BRIDGE", "calling enableLink")
                MusapClient.enableLink(url, fcmToken, callback)
            } else {
                Log.d("MUSAP_BRIDGE", "link already enabled, musapId=${musapLink.musapId}")
                promise.resolve(musapLink.musapId)
            }
        } catch (e: Exception) {
            Log.e("MUSAP_BRIDGE", "enableLink failed", e)
            promise.reject("ENABLE_LINK_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun disconnectLink() {
        MusapClient.disableLink()
    }

    @ReactMethod
    fun coupleWithRelyingParty(couplingCode: String, promise: Promise) {
        try {
            val callback = object : MusapCallback<RelyingParty> {
                override fun onSuccess(rp: RelyingParty?) {
                    if (rp != null) {
                        promise.resolve(rp.linkID)
                    } else {
                        promise.reject("COUPLE_RP_ERROR", "RelyingParty is null")
                    }
                }

                override fun onException(e: MusapException?) {
                    promise.reject("COUPLE_RP_ERROR", e?.message, e)
                }
            }
            Log.d("MUSAP_BRIDGE", "coupleWithRelyingParty.musapId=${MusapClient.getMusapLink().musapId}")
            MusapClient.coupleWithRelyingParty(couplingCode, callback)
        } catch (e: Exception) {
            Log.e("MUSAP_BRIDGE", "Coupling failed", e)
            promise.reject("COUPLE_RP_ERROR", e.message, e)
        }
    }


    fun createSscdInstance(type: SscdType, settings: ExternalSscdSettings?): MusapSscdInterface<*> {
        return when (type) {
            SscdType.TEE -> AndroidKeystoreSscd(reactContext)
            SscdType.YUBI_KEY -> YubiKeySscd(reactContext)
            SscdType.EXTERNAL -> ExternalSscd(reactContext, settings)
        }
    }

    fun sendKeygenCallback(musapKey: MusapKey, transId: String, promise: Promise): Boolean {
        try {
            MusapClient.sendKeygenCallback(musapKey, transId)
        } catch (e: Exception) {
            Log.e("MUSAP_BRIDGE", "sendKeygenCallback failed", e)
            promise.reject("SEND_KEY_CALLBACK_ERROR", e.message, e)
            return false
        }
        return true
    }

    // For Android Native use, won't work otherwise because of the context
    companion object {
        @Volatile
        private var isInitialized = false
        private val initializationLock = Any()

        fun initializeMusap(context: Context) {
            if (!isInitialized) {
                synchronized(initializationLock) {
                    if (!isInitialized) {
                        Log.d("MUSAP_BRIDGE", "Initializing MusapClient")
                        MusapClient.init(context)
                        isInitialized = true
                        Log.d("MUSAP_BRIDGE", "MusapClient initialization complete")
                    }
                }
            }
        }
    }
}
