package com.sphereon.musap;

import android.content.Context
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.util.RNLog
import com.nimbusds.jose.JWSAlgorithm
import com.nimbusds.jose.JWSHeader
import com.nimbusds.jose.JWSObject
import com.nimbusds.jose.crypto.impl.ECDSA
import com.nimbusds.jose.util.Base64URL
import com.nimbusds.jwt.JWTClaimsSet
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
import fi.methics.musap.sdk.internal.datatype.SignatureAlgorithm
import fi.methics.musap.sdk.sscd.android.AndroidKeystoreSscd
import fi.methics.musap.sdk.sscd.yubikey.YubiKeySscd


class MusapModuleAndroid(private val context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {

    override fun getName(): String = "MusapModule"

    @ReactMethod
    fun generateKey(sscdType: String, req: ReadableMap, callback: Callback) {
        Log.i("MUSAP", "generateKey for ${sscdType}")
        val sscd = MusapClient.listEnabledSscds().first { it.sscdId == sscdType }
        val musapCallback = object : MusapCallback<MusapKey> {
            override fun onSuccess(musapKey: MusapKey?) {
                if (musapKey != null) {
                    callback.invoke(null, musapKey.keyUri.uri)
                }
            }

            override fun onException(e: MusapException?) {
                Log.e("MUSAP", "generateKey failed", e)
                callback.invoke(e?.message, null)
            }
        }
        val reqObj = req.toKeyGenReq(reactApplicationContext.currentActivity)
        MusapClient.generateKey(sscd, reqObj, musapCallback)
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
    fun sign(req: ReadableMap, callback: Callback) {
        Log.i("MUSAP", "sign called")
        try {
            Log.i(
                "MUSAP",
                "entry ${req}"
            )
            val signatureReq = req.toSignatureReq(this.currentActivity)
            val key = signatureReq.key
            val keyAlgo = key.algorithm
            val signatureAlgorithm =
                if (keyAlgo.isEc) SignatureAlgorithm.EDDSA else SignatureAlgorithm.SHA256_WITH_ECDSA
            Log.i(
                "MUSAP",
                "data transform ${signatureReq},\n ${key},\n ${keyAlgo},\n ${signatureAlgorithm}"
            )
            val header = JWSHeader.Builder(JWSAlgorithm.parse(signatureAlgorithm.jwsAlgorithm))
                .keyID(key.keyId)
                .build()
            Log.i(
                "MUSAP",
                "header transform ${header}",
            )
            val claims = JWTClaimsSet.parse(signatureReq.data.decodeToString())
            Log.i(
                "MUSAP",
                "claims transform ${claims}",
            )
            val callbackTmp = object : MusapCallback<MusapSignature> {
                override fun onSuccess(p0: MusapSignature) {
                    Log.i(
                        "MUSAP",
                        "before attachSignature"
                    )
                    val signed = attachSignature(JWSObject(header, claims.toPayload()), p0)
                    Log.i(
                        "MUSAP",
                        "after attachSignature ${signed}",
                    )
                    callback.invoke(null, signed.serialize())
                }

                override fun onException(p0: MusapException?) {
                    Log.i(
                        "MUSAP",
                        "onException",
                        p0
                    )
                    callback.invoke(p0?.message, null)
                }
            }
            MusapClient.sign(signatureReq, callbackTmp)
        } catch (e: Exception) {
            Log.e(
                "MUSAP",
                "sign failed",
                e
            )  // This will log a nice Java style exception to logcat with full stack trace
            throw e
        }
    }

    private fun attachSignature(orig: JWSObject, sig: MusapSignature): JWSObject {
        try {
            Log.i(
                "MUSAP",
                "entry ${orig} ${sig}"
            )
            val header = orig.header.toBase64URL()
            val payload = orig.payload.toBase64URL()
            val signature = Base64URL.encode(transcodeSignature(sig.rawSignature))
            Log.i(
                "MUSAP",
                "data transform: after encoding the signature ${signature}"
            )
            return JWSObject(header, payload, signature)
        } catch (e: Exception) {
            Log.e("MUSAP", "data transform: after encoding the signature ", e)
            return orig
        }
    }

    private fun transcodeSignature(rawSignature: ByteArray): ByteArray {
        val length = 64
        return ECDSA.transcodeSignatureToConcat(rawSignature, length)
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
        MusapClient.enableSscd(getSscdInstance(SscdType.valueOf(sscdType)), sscdType)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getKeyByUri(keyUri: String): WritableMap {
        val keyByUri = MusapClient.getKeyByUri(keyUri) ?: throw Exception("Key not found for $keyUri")
        return keyByUri.toWritableMap()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getKeyById(keyId: String): WritableMap {
        val keyByUri = MusapClient.getKeyByKeyID(keyId) ?: throw Exception("Key not found for $keyId")
        return keyByUri.toWritableMap()
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
