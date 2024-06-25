package com.sphereon.musap.serializers

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import fi.methics.musap.sdk.internal.datatype.SscdInfo
import fi.methics.musap.sdk.internal.util.MusapSscd


fun SscdInfo.toWritableMap(): WritableMap {

    val supportedAlgorithms = Arguments.createArray()
    this.supportedAlgorithms?.forEach {
        val algorithm = Arguments.createMap()
        algorithm.putString("curve", it.curve)
        algorithm.putString("primitive", it.primitive)
        algorithm.putInt("bits", it.bits)
        algorithm.putBoolean("isRsa", it.isRsa)
        algorithm.putBoolean("isEc", it.isEc)
        supportedAlgorithms.pushMap(algorithm)
    }

    val sscdInfo = Arguments.createMap()
    sscdInfo.putString("sscdId", this.sscdId)
    sscdInfo.putString("sscdType", this.sscdType)
    sscdInfo.putString("sscdName", this.sscdName)
    sscdInfo.putString("country", this.country)
    sscdInfo.putString("provider", this.provider)
    sscdInfo.putBoolean("isKeyGenSupported", this.isKeygenSupported ?: false)
    sscdInfo.putArray("supportedAlgorithms", supportedAlgorithms)

    return sscdInfo
}
