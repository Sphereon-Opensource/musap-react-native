package com.sphereon.musap.shared;

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.ReadableType.Array
import com.facebook.react.bridge.ReadableType.Map
import com.facebook.react.bridge.ReadableType.Null
import com.facebook.react.bridge.ReadableType.Number
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import org.json.JSONArray
import org.json.JSONObject

interface MusapModule {
    fun generateKey (sscd: ReadableMap, req: ReadableMap, callBack: ReadableMap)
    fun sign(req: ReadableMap, callback: Callback)
    fun listEnabledSscds(): WritableArray
    fun listActiveSscds(): WritableArray
}

enum class SscdType {
    AKS, SE
}

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
            Null -> json.put(key, JSONObject.NULL)
            ReadableType.Boolean -> json.put(key, readableMap.getBoolean(key))
            Number -> json.put(key, readableMap.getDouble(key))
            ReadableType.String -> json.put(key, readableMap.getString(key))
            Map -> json.put(key, readableMap.getMap(key)?.let { convertToJSONObject(it) })
            Array -> json.put(key, readableMap.getArray(key)?.let { convertToJSONArray(it) })
        }
    }
    return json
}

fun convertToJSONArray(readableArray: ReadableArray): JSONArray {
    val jsonArray = JSONArray()
    for (index:Int in 0..<readableArray.size()) {
        when(readableArray.getType(index)) {
            Null -> break
            ReadableType.Boolean -> jsonArray.put(readableArray.getBoolean(index))
            Number -> jsonArray.put(readableArray.getDouble(index))
            ReadableType.String -> jsonArray.put(readableArray.getString(index))
            Map -> jsonArray.put(convertToJSONObject(readableArray.getMap(index)))
            Array -> jsonArray.put(convertToJSONArray(readableArray.getArray(index)))
        }
    }
    return jsonArray
}
