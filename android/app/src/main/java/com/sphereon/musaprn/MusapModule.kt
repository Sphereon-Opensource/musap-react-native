package com.sphereon.musaprn;

import com.facebook.react.bridge.*
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import fi.methics.musap.sdk.api.MusapClient
import org.json.JSONArray
import org.json.JSONObject

fun convertToJsonArray(jsonArray: JSONArray): WritableArray {
    val writableArray = Arguments.createArray()
    for (index in 0..<jsonArray.length()) {
        when(val value = jsonArray.get(index)) {
            null -> writableArray.pushNull()
            is JSONObject -> writableArray.pushMap(convertToJsonMap(value))
            is JSONArray -> writableArray.pushArray(convertToJsonArray(value))
            is Boolean -> writableArray.pushBoolean(value)
            is Int -> writableArray.pushInt(value)
            is Double -> writableArray.pushDouble(value)
            is String -> writableArray.pushString(value)
            else -> writableArray.pushString(value.toString())
        }
    }
    return writableArray
}

fun convertToJsonMap(jsonObject: JSONObject): WritableMap {
    val writableMap = Arguments.createMap()
    val keys = jsonObject.keys()
    for (key in keys) {
        when(val value = jsonObject.get(key)) {
            null -> writableMap.putNull(key)
            is JSONObject -> writableMap.putMap(key, convertToJsonMap(value))
            is JSONArray -> writableMap.putArray(key, convertToJsonArray(value))
            is Boolean -> writableMap.putBoolean(key, value)
            is Int -> writableMap.putInt(key, value)
            is Double -> writableMap.putDouble(key, value)
            is String -> writableMap.putString(key, value)
            else -> writableMap.putString(key, value.toString())
        }
    }
    return writableMap
}

class MusapModule(val context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {

    private val objectMapper = jacksonObjectMapper()
    override fun getName(): String = "MusapModule"

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun listEnabledSscds(): WritableArray {
        val sscds = MusapClient.listEnabledSscds()
        val writableArray = Arguments.createArray()
        for (sscd in sscds) {
            val sscdMap = convertToJsonMap(JSONObject(objectMapper.writeValueAsString(sscd)))
            writableArray.pushMap(sscdMap)
        }
        return writableArray
    }
}
