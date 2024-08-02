package com.sphereon.musap;

import android.content.Context
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.nimbusds.jose.JWSObject
import com.nimbusds.jose.crypto.impl.ECDSA
import com.nimbusds.jose.util.Base64URL
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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.Base64
import kotlin.coroutines.resumeWithException

@kotlinx.coroutines.ExperimentalCoroutinesApi
class MusapModuleAndroid(private val context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {

    override fun getName(): String = "MusapModule"

    @ReactMethod
    fun generateKey(sscdType: String, req: ReadableMap, promise: Promise) {
        Log.i("MUSAP", "generateKey for $sscdType")
        try {
            val sscd = MusapClient.listEnabledSscds().first { it.sscdId == sscdType }
            val reqObj = req.toKeyGenReq(reactApplicationContext.currentActivity)

            CoroutineScope(Dispatchers.Default).launch {
                try {
                    val result = suspendCancellableCoroutine<MusapKey> { continuation ->
                        val musapCallback = object : MusapCallback<MusapKey> {
                            override fun onSuccess(musapKey: MusapKey?) {
                                if (musapKey != null) {
                                    continuation.resume(musapKey) {
                                        Log.w("MUSAP", "Key generation cancelled")
                                    }
                                } else {
                                    continuation.resumeWithException(Exception("MusapKey is null"))
                                }
                            }

                            override fun onException(e: MusapException?) {
                                continuation.resumeWithException(e ?: Exception("Key generation failed"))
                            }
                        }
                        MusapClient.generateKey(sscd, reqObj, musapCallback)

                        continuation.invokeOnCancellation {
                            // Handle cancellation here
                            Log.i("MUSAP", "Key generation cancelled")
                            // Add any necessary cleanup code here, e.g., cancelling the ongoing operation if possible
                        }
                    }
                    promise.resolve(result.keyUri.uri)
                } catch (e: Exception) {
                    Log.e("MUSAP", "generateKey failed", e)
                    promise.reject("GENERATE_KEY_ERROR", e.message, e)
                }
            }
        } catch (e: Exception) {
            Log.e("MUSAP", "generateKey failed", e)
            promise.reject("GENERATE_KEY_ERROR", "Error setting up key generation: ${e.message}", e)
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
            Log.e("MUSAP", "removeKey failed", e)
            promise.reject(e)
        }
    }


    @ReactMethod
    fun sign(req: ReadableMap, promise: Promise) {
        try {
            val signatureReq = req.toSignatureReq(this.currentActivity)

            val key = signatureReq.key
            CoroutineScope(Dispatchers.Default).launch {
                try {
                    val result = suspendCancellableCoroutine<MusapSignature> { continuation ->
                        val musapCallback = object : MusapCallback<MusapSignature> {
                            override fun onSuccess(signature: MusapSignature?) {
                                if (signature != null) {
                                    continuation.resume(signature) {
                                        Log.w("MUSAP", "Signing cancelled")
                                    }
                                } else {
                                    continuation.resumeWithException(Exception("MusapSignature is null"))
                                }
                            }

                            override fun onException(e: MusapException?) {
                                continuation.resumeWithException(e ?: Exception("sign error"))
                            }
                        }
                        MusapClient.sign(signatureReq, musapCallback)

                        continuation.invokeOnCancellation {
                            Log.w("MUSAP", "Signing cancelled")
                        }
                    }
                    val convertToRS = true // FIXME to req

                    if (convertToRS) {
                        val rsSignature = convertDERtoRS(result.rawSignature)
                        val rsSignatureBase64 = Base64.getUrlEncoder().withoutPadding().encodeToString(rsSignature)
                        promise.resolve(rsSignatureBase64)
                    } else {
                        promise.resolve(result.b64Signature)
                    }
                } catch (e: Exception) {
                    Log.e("MUSAP", "Error signing the data", e)
                    promise.reject("SIGN_ERROR", "Error signing the data: ${e.message}", e)
                }
            }
        } catch (e: Exception) {
            Log.e("MUSAP", "sign failed", e)
            promise.reject("SIGN_ERROR", "Error preparing signature request: ${e.message}", e)
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
    fun enableSscd(sscdType: String) {
        try {
            val sscdInstance = getSscdInstance(SscdType.valueOf(sscdType))
            if(MusapClient.listEnabledSscds().count { musapSscd -> musapSscd.sscdId == sscdInstance.sscdInfo.sscdId } == 0) {
                MusapClient.enableSscd(sscdInstance, sscdType)
            }
        } catch (e: Exception) {
            Log.e("MUSAP", "enableSscd failed", e)
            throw e
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getKeyByUri(keyUri: String): WritableMap {
        Log.i("MUSAP", "keyUri called with keyUri ${keyUri}")
        val keyByUri = MusapClient.getKeyByUri(keyUri) ?: throw Exception("Key not found by keyUri for $keyUri")
        return keyByUri.toWritableMap()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getKeyById(keyId: String): WritableMap {
        Log.i("MUSAP", "getKeyById called with id ${keyId}")
        val key = MusapClient.getKeyByKeyID(keyId) ?: throw Exception("Key not found by id for $keyId")
        Log.i("MUSAP", "found key ${key.keyUri}")
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
        return Arguments.createArray().apply {
            MusapClient.listKeys().forEach {
                pushMap(it.toWritableMap())
            }
        }
    }

    fun getSscdInstance(type: SscdType): MusapSscdInterface<*> {
        return when (type) {
            SscdType.TEE -> AndroidKeystoreSscd(initialContext)
            SscdType.YUBI_KEY -> YubiKeySscd(initialContext)
        }
    }

    // For Android Native use, won't work otherwise because of the context
    companion object {
        var initialContext: Context? = null

        fun init(context: Context) {
            Log.i("MUSAP", "MusapClient.init(context)")
            MusapClient.init(context)
            Log.i("MUSAP", "MusapClient.init(context) done")
            initialContext = context
        }
    }
}
