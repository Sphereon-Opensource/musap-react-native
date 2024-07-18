package com.sphereon.musap.serializers

import android.app.Activity
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import fi.methics.musap.sdk.internal.datatype.MusapCertificate
import fi.methics.musap.sdk.internal.datatype.MusapKey
import fi.methics.musap.sdk.internal.datatype.MusapLoA
import fi.methics.musap.sdk.internal.datatype.PublicKey
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
            val keyBuilder = MusapKey.Builder()
                .setKeyAlias(keyMap.getString("keyAlias"))
                .setKeyType(keyMap.getString("keyType"))
                .setKeyId(keyMap.getString("keyId"))
                .setSscdId(keyMap.getString("sscdId"))
                .setSscdType(keyMap.getString("sscdType"))
                .setAlgorithm(keyMap.getString("algorithm")?.toKeyAlgorithm())
                .setLoa(keyMap.getArray("loa")?.toStringList()?.map { it.toMusapLoA() })

            keyMap.getMap("publicKey")?.let { publicKeyMap ->
                val publicKeyDer = publicKeyMap.getArray("publickeyDer")?.toByteArray()
                if (publicKeyDer != null) {
                    keyBuilder.setPublicKey(PublicKey(publicKeyDer))
                }
            }

            keyMap.getArray("loa")?.let { loaArray ->
                val loaList = mutableListOf<MusapLoA>()
                for (i in 0 until loaArray.size()) {
                    val loa = loaArray.getString(i)
                    loaList.add(loa.toMusapLoA())
                }
                keyBuilder.setLoa(loaList)
            }

            keyMap.getArray("keyUsages")?.toStringList()?.let { keyUsages ->
                keyBuilder.setKeyUsages(keyUsages)
            }

            keyMap.getMap("certificate")?.let { certMap ->
                val certDer = certMap.getArray("certificateDer")?.toByteArray()
                if (certDer != null) {
                    keyBuilder.setCertificate(MusapCertificate(certDer))
                }
            }
            keyMap.getArray("certificateChain")?.let { chainArray ->
                val certificateChain = mutableListOf<MusapCertificate>()
                for (i in 0 until chainArray.size()) {
                    val certDer = chainArray.getArray(i)?.toByteArray()
                    if (certDer != null) {
                        certificateChain.add(MusapCertificate(certDer))
                    }
                }
                keyBuilder.setCertificateChain(certificateChain)
            }

            builder.setKey(keyBuilder.build())
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
