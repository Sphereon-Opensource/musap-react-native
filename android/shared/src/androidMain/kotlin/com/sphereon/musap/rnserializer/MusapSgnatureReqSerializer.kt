package com.sphereon.musap.rnserializer

import android.app.Activity
import com.facebook.react.bridge.ReadableMap
import fi.methics.musap.sdk.internal.datatype.KeyAlgorithm
import fi.methics.musap.sdk.internal.datatype.MusapKey
import fi.methics.musap.sdk.internal.datatype.SignatureAlgorithm
import fi.methics.musap.sdk.internal.datatype.SignatureAttribute
import fi.methics.musap.sdk.internal.datatype.SignatureFormat
import fi.methics.musap.sdk.internal.sign.SignatureReq

fun ReadableMap.toSignatureReq(activity: Activity?): SignatureReq {
    val algorithmString = getString("algorithm")
    val algorithm = SignatureAlgorithm(algorithmString ?: "SHA256withECDSA")
    val builder = SignatureReq.Builder(algorithm)

    if (hasKey("key")) {
        getMap("key")?.let { keyMap ->
            val key = MusapKey.Builder()
                .setKeyAlias(keyMap.getString("keyAlias"))
                .setKeyType(keyMap.getString("keyType"))
                .setKeyId(keyMap.getString("keyId"))
                .setSscdId(keyMap.getString("sscdId"))
                .setSscdType(keyMap.getString("sscdType"))
                .setAlgorithm(KeyAlgorithm.fromString(keyMap.getString("algorithm")))
                .build()
            builder.setKey(key)
        }
    }

    if (hasKey("data")) {
        getArray("data")?.let { dataArray ->
            val data = ByteArray(dataArray.size())
            for (i in 0 until dataArray.size()) {
                data[i] = dataArray.getInt(i).toByte()
            }
            builder.setData(data)
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
    createSignatureReq.setActivity(activity)
    return createSignatureReq
}
