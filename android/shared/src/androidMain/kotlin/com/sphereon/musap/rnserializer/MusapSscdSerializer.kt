package com.sphereon.musap.rnserializer

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import fi.methics.musap.sdk.internal.util.MusapSscd


fun MusapSscd.toWritableMap(): WritableMap {
    val writableMap = Arguments.createMap()

    val supportedAlgorithms = Arguments.createArray()

    this.sscdInfo?.supportedAlgorithms?.forEach {
        val algorithm = Arguments.createMap()
        algorithm.putString("curve", it.curve)
        algorithm.putString("primitive", it.primitive)
        algorithm.putInt("bits", it.bits)
        algorithm.putBoolean("isRsa", it.isRsa)
        algorithm.putBoolean("isEc", it.isEc)
        supportedAlgorithms.pushMap(algorithm)
    }

    val sscdInfo = Arguments.createMap()
    sscdInfo.putString("sscdId", this.sscdInfo?.sscdId)
    sscdInfo.putString("sscdType", this.sscdInfo?.sscdType)
    sscdInfo.putString("sscdName", this.sscdInfo?.sscdName)
    sscdInfo.putString("country", this.sscdInfo?.country)
    sscdInfo.putString("provider", this.sscdInfo?.provider)
    sscdInfo.putBoolean("isKeyGenSupported", this.sscdInfo?.isKeygenSupported ?: false)
    sscdInfo.putArray("supportedAlgorithms", supportedAlgorithms)

    val settings = Arguments.createMap()
    this.settings?.settings?.entries?.forEach {
        settings.putString(it.key, it.value)
    }

    writableMap.putString("sscdId", this.sscdId)
    writableMap.putMap("sscdInfo", sscdInfo)
    writableMap.putMap("settings", settings)

    return writableMap
}
