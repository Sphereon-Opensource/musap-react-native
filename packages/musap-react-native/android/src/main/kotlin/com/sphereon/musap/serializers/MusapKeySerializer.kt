package com.sphereon.musap.serializers

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import fi.methics.musap.sdk.internal.datatype.*
import java.security.Principal
import java.security.cert.X509Certificate
import java.time.Instant
import javax.security.auth.x500.X500Principal

fun KeyAttribute.toWritableMap(): WritableMap {

    return Arguments.createMap().apply {
        putString("name", name)
        putString("value", value)
    }
}

fun PublicKey.toWritableMap(): WritableMap {

    val der = Arguments.createArray()
    this.der.forEach {
        der.pushInt(it.toInt())
    }

    return Arguments.createMap().apply {
        putString("pem", pem)
        putArray("der", der)
    }
}

fun java.security.PublicKey.toWritableMap(): WritableMap {

    val encoded = Arguments.createArray()
    this.encoded.forEach {
        encoded.pushInt(it.toInt())
    }

    return Arguments.createMap().apply {
        putString("algorithm", algorithm)
        putString("format", format)
        putArray("encoded", encoded)
    }
}

fun Principal.toWritableMap(): WritableMap {

    return Arguments.createMap().apply {
        putString("name", name)
    }
}

fun X500Principal.toWritableMap(): WritableMap {

    val encoded = Arguments.createArray()
    this.encoded.forEach {
        encoded.pushInt(it.toInt())
    }

    return Arguments.createMap().apply {
        putString("name", name)
        putArray("encoded", encoded)
    }
}


fun X509Certificate.toWritableMap(): WritableMap {

    val extendedKeyUsage = Arguments.createArray()
    this.extendedKeyUsage.forEach {
        extendedKeyUsage.pushString(it)
    }

    val issuerAlternativeNames = Arguments.createArray()
    this.issuerAlternativeNames.forEach {
        issuerAlternativeNames.pushString(it.toString())
    }

    val issuerUniqueID = Arguments.createArray()
    this.issuerUniqueID.forEach {
        issuerUniqueID.pushBoolean(it)
    }

    val keyUsage = Arguments.createArray()
    this.keyUsage.forEach {
        keyUsage.pushBoolean(it)
    }

    return Arguments.createMap().apply {
        putString("type", type)
        putString("sigAlgOID", sigAlgOID)
        putString("sigAlgName", sigAlgName)
        putString("serialNumber", serialNumber.toString())
        putInt("basicConstraints", basicConstraints)
        putArray("extendedKeyUsage", extendedKeyUsage)
        putArray("issuerAlternativeNames", issuerAlternativeNames)
        putMap("issuerDN", issuerDN.toWritableMap())
        putArray("issuerUniqueID", issuerUniqueID)
        putMap("issuerX500Principal", issuerX500Principal.toWritableMap())
        putArray("keyUsage", keyUsage)
        putString("notAfter", notAfter.toString())
        putString("notBefore", notBefore.toString())
        putMap("publicKey", publicKey.toWritableMap())
    }
}


fun MusapCertificate.toWritableMap(): WritableMap {
    val certificate = Arguments.createArray()
    this.certificate.forEach {
        certificate.pushInt(it.toInt())
    }

    return Arguments.createMap().apply {
        putString("email", email)
        putString("subject", subject)
        putString("surname", surname)
        putString("givenName", givenName)
        putString("serialNumber", serialNumber)
        putArray("certificate", certificate)
        putMap("publicKey", publicKey.toWritableMap())
        putMap("", x509Certificate.toWritableMap())
    }
}

fun SignatureAlgorithm.toWritableMap(): WritableMap {
    return Arguments.createMap().apply {
        putBoolean("isEc", isEc)
        putBoolean("isRsa", isRsa)
        putString("jwsAlgorithm", jwsAlgorithm)
        putString("hashAlgorithm", hashAlgorithm)
        putString("javaAlgorithm", jwsAlgorithm)
        putString("scheme", scheme)
    }
}

fun KeyURI.toWritableMap(): WritableMap {
    return Arguments.createMap().apply {
        putString("uri", uri)
        putString("country", country)
        putString("name", name)
    }
}

fun Instant.toWritableMap(): WritableMap {
    return Arguments.createMap().apply {
        putInt("nano", nano)
        putString("epochSecond", epochSecond.toString())
    }
}

fun MusapKey.toWritableMap(): WritableMap {
    val keyAttributes = Arguments.createArray()
    this.attributes.forEach {
        keyAttributes.pushMap(it.toWritableMap())
    }

    val certificateChain = Arguments.createArray()
    this.certificateChain.forEach {
        certificateChain.pushMap(it.toWritableMap())
    }

    val keyUsages = Arguments.createArray()
    this.keyUsages.forEach {
        keyUsages.pushString(it)
    }

    val loa = Arguments.createArray()
    this.loa.forEach {
        loa.pushString(it.loa)
    }

    return Arguments.createMap().apply {
        putString("sscdId", sscdId)
        putString("sscdType", sscdType)
        putString("keyId", keyId)
        putString("keyType", keyType)
        putString("keyAlias", keyAlias)
        putMap("sscd", sscd.toWritableMap())
        putString("algorithm", algorithm.toEnumString())
        putArray("attributes", keyAttributes)
        certificate?.let {
            putMap("certificate", certificate.toWritableMap())
        }
        certificateChain?.let {
            putArray("certificateChain", certificateChain)
        }
        putMap("createdDate", createdDate.toWritableMap())
        putMap("defaultsignatureAlgorithm", defaultsignatureAlgorithm.toWritableMap())
        putMap("keyUri", keyUri.toWritableMap())
        putArray("keyUsages", keyUsages)
        putArray("loa", loa)
        putMap("publicKey", publicKey.toWritableMap())
    }
}
