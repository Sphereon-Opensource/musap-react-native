package com.sphereon.musap.serializer

import com.google.gson.JsonArray
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import fi.methics.musap.sdk.internal.util.MusapSscd
import java.lang.reflect.Type

class MusapSscdSerializer: JsonSerializer<MusapSscd> {

    override fun serialize(
        src: MusapSscd?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        val json = JsonObject()

        val supportedAlgorithms = JsonArray()

        src?.sscdInfo?.supportedAlgorithms?.forEach{
            val algorithm = JsonObject()
            algorithm.addProperty("curve", it.curve)
            algorithm.addProperty("primitive", it.primitive)
            algorithm.addProperty("bits", it.bits)
            algorithm.addProperty("isRsa", it.isRsa)
            algorithm.addProperty("isEc", it.isEc)
            supportedAlgorithms.add(algorithm)
        }

        val sscdInfo = JsonObject()
        sscdInfo.addProperty("sscdId", src?.sscdInfo?.sscdId)
        sscdInfo.addProperty("sscdType", src?.sscdInfo?.sscdType)
        sscdInfo.addProperty("sscdName", src?.sscdInfo?.sscdName)
        sscdInfo.addProperty("country", src?.sscdInfo?.country)
        sscdInfo.addProperty("provider", src?.sscdInfo?.provider)
        sscdInfo.addProperty("isKeyGenSupported", src?.sscdInfo?.isKeygenSupported)
        sscdInfo.add("supportedAlgorithms", supportedAlgorithms)

        val settings = JsonObject()
        src?.settings?.settings?.entries?.forEach{
            settings.addProperty(it.key, it.value)
        }

        json.addProperty("sscdId", src?.sscdId)
        json.add("sscdInfo", sscdInfo)
        json.add("settings", settings)

        return json
    }
}