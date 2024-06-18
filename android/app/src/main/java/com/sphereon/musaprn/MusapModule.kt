package com.sphereon.musaprn;

import com.facebook.react.bridge.*
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import fi.methics.musap.sdk.api.MusapCallback
import fi.methics.musap.sdk.api.MusapClient
import fi.methics.musap.sdk.extension.MusapSscdInterface
import fi.methics.musap.sdk.internal.datatype.MusapKey
import fi.methics.musap.sdk.internal.keygeneration.KeyGenReq
import fi.methics.musap.sdk.internal.util.MusapSscd
import org.json.JSONArray
import org.json.JSONObject

fun convertToWritableArray(jsonArray: JSONArray): WritableArray {
    val writableArray = Arguments.createArray()
    for (index in 0..<jsonArray.length()) {
        when(val value = jsonArray.get(index)) {
            null -> writableArray.pushNull()
            is JSONObject -> writableArray.pushMap(convertToWritabaleMap(value))
            is JSONArray -> writableArray.pushArray(convertToWritableArray(value))
            is Boolean -> writableArray.pushBoolean(value)
            is Int -> writableArray.pushInt(value)
            is Double -> writableArray.pushDouble(value)
            is String -> writableArray.pushString(value)
            else -> writableArray.pushString(value.toString())
        }
    }
    return writableArray
}

fun convertToWritabaleMap(jsonObject: JSONObject): WritableMap {
    val writableMap = Arguments.createMap()
    val keys = jsonObject.keys()
    for (key in keys) {
        when(val value = jsonObject.get(key)) {
            null -> writableMap.putNull(key)
            is JSONObject -> writableMap.putMap(key, convertToWritabaleMap(value))
            is JSONArray -> writableMap.putArray(key, convertToWritableArray(value))
            is Boolean -> writableMap.putBoolean(key, value)
            is Int -> writableMap.putInt(key, value)
            is Double -> writableMap.putDouble(key, value)
            is String -> writableMap.putString(key, value)
            else -> writableMap.putString(key, value.toString())
        }
    }
    return writableMap
}

fun convertToJSONObject(readableMap: ReadableMap): JSONObject {
    val json = JSONObject()
    val iterator = readableMap.keySetIterator()
    while (iterator.hasNextKey()) {
        val key = iterator.nextKey()
        when(readableMap.getType(key)) {
            ReadableType.Null -> json.put(key, JSONObject.NULL)
            ReadableType.Boolean -> json.put(key, readableMap.getBoolean(key))
            ReadableType.Number -> json.put(key, readableMap.getDouble(key))
            ReadableType.String -> json.put(key, readableMap.getString(key))
            ReadableType.Map -> json.put(key, readableMap.getMap(key)?.let { convertToJSONObject(it) })
            ReadableType.Array -> json.put(key, readableMap.getArray(key)?.let { convertToJSONArray(it) })
        }
    }
    return json
}

fun convertToJSONArray(readableArray: ReadableArray): JSONArray {
    val jsonArray = JSONArray()
    for (index:Int in 0..<readableArray.size()) {
        when(readableArray.getType(index)) {
            ReadableType.Null -> break
            ReadableType.Boolean -> jsonArray.put(readableArray.getBoolean(index))
            ReadableType.Number -> jsonArray.put(readableArray.getDouble(index))
            ReadableType.String -> jsonArray.put(readableArray.getString(index))
            ReadableType.Map -> jsonArray.put(convertToJSONObject(readableArray.getMap(index)))
            ReadableType.Array -> jsonArray.put(convertToJSONArray(readableArray.getArray(index)))
        }
    }
    return jsonArray
}

class MusapModule(val context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {

    private val objectMapper = jacksonObjectMapper()
    override fun getName(): String = "MusapModule"

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun enableSscd(sscd: ReadableMap, sscdId: String) {
        val sscdObj = jacksonObjectMapper().readValue(convertToJSONObject(sscd).toString(), MusapSscdInterface::class.java)
        MusapClient.enableSscd(sscdObj, sscdId)
    }

    @ReactMethod
    fun generateKey (sscd: ReadableMap, req: ReadableMap, callBack: ReadableMap) {
        val sscdObj = jacksonObjectMapper().readValue(convertToJSONObject(sscd).toString(), MusapSscd::class.java)
        val reqObj = jacksonObjectMapper().readValue(convertToJSONObject(req).toString(), KeyGenReq::class.java)
        val callbackObj = jacksonObjectMapper().readValue(convertToJSONObject(callBack).toString(), MusapCallback::class.java)

        @Suppress("UNCHECKED_CAST")
        MusapClient.generateKey(sscdObj, reqObj, callbackObj as MusapCallback<MusapKey>)
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun listEnabledSscds(): WritableArray {
        val sscds = MusapClient.listEnabledSscds()
        val writableArray = Arguments.createArray()
        for (sscd in sscds) {
            val sscdMap = convertToWritabaleMap(JSONObject(objectMapper.writeValueAsString(sscd)))
            writableArray.pushMap(sscdMap)
        }
        return writableArray
    }
}
