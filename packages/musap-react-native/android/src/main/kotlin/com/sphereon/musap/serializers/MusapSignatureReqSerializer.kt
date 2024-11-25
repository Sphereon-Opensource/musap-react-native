package com.sphereon.musap.serializers

import android.app.Activity
import android.util.Log
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import fi.methics.musap.sdk.api.MusapClient
import fi.methics.musap.sdk.internal.datatype.MusapLoA
import fi.methics.musap.sdk.internal.datatype.SignatureAlgorithm
import fi.methics.musap.sdk.internal.datatype.SignatureAttribute
import fi.methics.musap.sdk.internal.datatype.SignatureFormat
import fi.methics.musap.sdk.internal.sign.SignatureReq

fun ReadableMap.toSignatureReq(activity: Activity?): SignatureReq {
    val algorithmString = getString("algorithm")
    val algorithm = SignatureAlgorithm(algorithmString ?: "SHA256withECDSA")
    val builder = SignatureReq.Builder(algorithm)

    if (hasKey("keyUri")) {
        getString("keyUri")?.let { keyUri ->
            Log.i("MUSAP_BRIDGE", "SignatureReq found keyUri ${keyUri}")
            val keyByUri = MusapClient.getKeyByUri(keyUri) ?: throw Exception("Key not found for $keyUri")
            Log.i("MUSAP_BRIDGE", "SignatureReq key ${keyByUri.keyAlias}")
            builder.setKey(keyByUri)
        }
    }

    if (hasKey("data")) {
        getString("data")?.let { dataString ->
            builder.setData(dataString.toByteArray())
        }
    }

    if (hasKey("displayText")) {
        builder.setDisplayText(getString("displayText"))
    } else if (hasKey("display")) {
        builder.setDisplayText(getString("display"))
    }

    if (hasKey("format")) {
        builder.setFormat(SignatureFormat.fromString(getString("format")))
    }

    if (hasKey("attributes")) {
        getArray("attributes")?.let { attributesArray ->
            for (i in 0 until attributesArray.size()) {
                val attributeMap = attributesArray.getMap(i)
                val signatureAttribute =
                    SignatureAttribute(attributeMap.getString("name"), attributeMap.getString("value"))
                builder.addAttribute(signatureAttribute)
            }
        }
    }

    val createSignatureReq = builder.createSignatureReq()
    createSignatureReq.activity = activity
    return createSignatureReq
}

fun ReadableArray.toByteArray(): ByteArray {
    return ByteArray(size()).also { byteArray ->
        for (i in 0 until size()) {
            byteArray[i] = getInt(i).toByte()
        }
    }
}

fun ReadableArray.toStringList(): List<String> {
    return (0 until size()).map { getString(it) }
}


fun String.toMusapLoA(): MusapLoA {
    return when (this.lowercase()) {
        "low" -> MusapLoA.EIDAS_LOW
        "substantial" -> MusapLoA.EIDAS_SUBSTANTIAL
        "high" -> MusapLoA.EIDAS_HIGH
        "loa1" -> MusapLoA.ISO_LOA1
        "loa2" -> MusapLoA.ISO_LOA2
        "loa3" -> MusapLoA.ISO_LOA3
        "loa4" -> MusapLoA.ISO_LOA4
        "ial1" -> MusapLoA.NIST_IAL1
        "ial2" -> MusapLoA.NIST_IAL2
        "ial3" -> MusapLoA.NIST_IAL3
        "aal1" -> MusapLoA.NIST_AAL1
        "aal2" -> MusapLoA.NIST_AAL2
        "aal3" -> MusapLoA.NIST_AAL3
        else -> throw IllegalArgumentException("Unknown LoA: $this")
    }
}
