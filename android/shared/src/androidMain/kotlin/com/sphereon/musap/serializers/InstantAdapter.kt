package com.sphereon.musap.serializers

import com.google.gson.*
import java.lang.reflect.Type
import java.time.Instant

class InstantDeserializer: JsonDeserializer<Instant> {
    override fun deserialize(json: JsonElement?, typeOfT: Type?, context: JsonDeserializationContext?): Instant? {
        val epochMilli = json?.asLong ?: return null
        return Instant.ofEpochMilli(epochMilli)
    }
}

class InstantSerializer : JsonSerializer<Instant> {
    override fun serialize(src: Instant?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        return JsonPrimitive(src?.epochSecond)
    }
}
