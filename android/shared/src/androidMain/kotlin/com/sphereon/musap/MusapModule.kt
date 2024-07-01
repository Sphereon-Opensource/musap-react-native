package com.sphereon.musap;

import android.content.Context
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.util.RNLog
import com.google.gson.GsonBuilder
import com.nimbusds.jose.JWSAlgorithm
import com.nimbusds.jose.JWSHeader
import com.nimbusds.jose.JWSObject
import com.nimbusds.jose.crypto.impl.ECDSA
import com.nimbusds.jose.util.Base64URL
import com.nimbusds.jwt.JWTClaimsSet
import com.sphereon.musap.models.SscdType
import com.sphereon.musap.serializers.ByteArrayDeserializer
import com.sphereon.musap.serializers.ByteArraySerializer
import com.sphereon.musap.serializers.InstantDeserializer
import com.sphereon.musap.serializers.InstantSerializer
import com.sphereon.musap.serializers.toKeyGenReq
import com.sphereon.musap.serializers.toWritableMap
import fi.methics.musap.sdk.api.MusapCallback
import fi.methics.musap.sdk.api.MusapClient
import fi.methics.musap.sdk.api.MusapException
import fi.methics.musap.sdk.extension.MusapSscdInterface
import fi.methics.musap.sdk.internal.datatype.MusapKey
import fi.methics.musap.sdk.internal.datatype.MusapSignature
import fi.methics.musap.sdk.internal.datatype.SignatureAlgorithm
import fi.methics.musap.sdk.internal.sign.SignatureReq
import fi.methics.musap.sdk.sscd.android.AndroidKeystoreSscd
import fi.methics.musap.sdk.sscd.yubikey.YubiKeySscd
import java.time.Instant


class MusapModuleAndroid(private val context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {

    override fun getName(): String = "MusapModule"

    private val gson = GsonBuilder()
        .registerTypeAdapter(Instant::class.java, InstantSerializer())
        .registerTypeAdapter(Instant::class.java, InstantDeserializer())
        .registerTypeAdapter(ByteArray::class.java, ByteArraySerializer())
        .registerTypeAdapter(ByteArray::class.java, ByteArrayDeserializer())
        .create()

    @ReactMethod
    fun generateKey(sscdType: String, req: ReadableMap, callback: Callback) {
        val sscd = MusapClient.listEnabledSscds().first { it.sscdId == sscdType }
        val musapCallback = object : MusapCallback<MusapKey> {
            override fun onSuccess(p0: MusapKey?) {
                if (p0 != null) {
                    callback.invoke(null, p0.keyUri.uri)
                }
            }

            override fun onException(p0: MusapException?) {
                callback.invoke(p0?.message, null)
            }
        }
        val reqObj = req.toKeyGenReq(reactApplicationContext.currentActivity)
        MusapClient.generateKey(sscd, reqObj, musapCallback)
    }

    @ReactMethod
    fun sign(req: String, callback: Callback) {
        // FIXME find a better solution using the RN Bridge or use Turbo Modules to completely avoid using JSON: https://sphereon.atlassian.net/browse/SPRIND-24
        val reqObj = gson.fromJson(req, SignatureReq::class.java)

        val key = reqObj.key
        val keyAlgo = key.algorithm
        val signatureAlgorithm = if (keyAlgo.isEc) SignatureAlgorithm.EDDSA else SignatureAlgorithm.SHA256_WITH_ECDSA

        val header = JWSHeader.Builder(JWSAlgorithm.parse(signatureAlgorithm.jwsAlgorithm))
            .keyID(key.keyId)
            .build()

        val claims = JWTClaimsSet.parse(reqObj.data.decodeToString())

        val callbackTmp = object : MusapCallback<MusapSignature> {
            override fun onSuccess(p0: MusapSignature) {
                val signed = attachSignature(JWSObject(header, claims.toPayload()), p0)
                callback.invoke(null, signed.serialize())
            }

            override fun onException(p0: MusapException?) {
                callback.invoke(p0?.message, null)
            }
        }
        MusapClient.sign(reqObj, callbackTmp)
    }

    private fun attachSignature(orig: JWSObject, sig: MusapSignature): JWSObject {
        try {
            val header = orig.header.toBase64URL()
            val payload = orig.payload.toBase64URL()
            val signature = Base64URL.encode(transcodeSignature(sig.rawSignature))
            return JWSObject(header, payload, signature)
        } catch (e: Exception) {
            RNLog.e(reactApplicationContext, "Error attaching signature ${e.message}")
            return orig
        }
    }

    private fun transcodeSignature(rawSignature: ByteArray): ByteArray {
        val length = 64
        return ECDSA.transcodeSignatureToConcat(rawSignature, length)
    }

    // enabled = supported by MUSAP
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
    fun enableSscd(sscdType: String)  {
        MusapClient.enableSscd(getSscdInstance(SscdType.valueOf(sscdType)), sscdType)
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getKeyByUri(keyUri: String): String {
        /** Fails because a deserialization of java.time.Instant - I cannot override the Gson configurations
         * [Error: Exception in HostFunction: com.google.gson.JsonSyntaxException: java.lang.IllegalStateException: Expected a string but was BEGIN_OBJECT at line 1 column 95 path $.createdDate
         * See https://github.com/google/gson/blob/main/Troubleshooting.md#unexpected-json-structure]
         * LOG  Exception in HostFunction: com.google.gson.JsonSyntaxException: java.lang.IllegalStateException: Expected a string but was BEGIN_OBJECT at line 1 column 95 path $.createdDate
         * See https://github.com/google/gson/blob/main/Troubleshooting.md#unexpected-json-structure
         */

        // FIXME find a better solution using the RN Bridge or use Turbo Modules to completely avoid using JSON: https://sphereon.atlassian.net/browse/SPRIND-24
        return gson.toJson(MusapClient.getKeyByUri(keyUri))
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
    fun listKeys(): String {
        /** Fails because a deserialization of java.time.Instant - I cannot override the Gson configurations
         * [Error: Exception in HostFunction: com.google.gson.JsonSyntaxException: java.lang.IllegalStateException: Expected a string but was BEGIN_OBJECT at line 1 column 95 path $.createdDate
         * See https://github.com/google/gson/blob/main/Troubleshooting.md#unexpected-json-structure]
         * LOG  Exception in HostFunction: com.google.gson.JsonSyntaxException: java.lang.IllegalStateException: Expected a string but was BEGIN_OBJECT at line 1 column 95 path $.createdDate
         * See https://github.com/google/gson/blob/main/Troubleshooting.md#unexpected-json-structure
         */

        // FIXME find a better solution using the RN Bridge or use Turbo Modules to completely or avoid using JSON: https://sphereon.atlassian.net/browse/SPRIND-24
        return gson.toJson(MusapClient.listKeys())
    }

    fun getSscdInstance(type: SscdType): MusapSscdInterface<*> {
        return when (type) {
            SscdType.TEE -> AndroidKeystoreSscd(initialContext)
            SscdType.YUBI_KEY -> YubiKeySscd(initialContext)
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
