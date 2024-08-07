package com.sphereon.musap.serializers

import android.util.Log
import com.facebook.react.bridge.ReadableMap
import fi.methics.musap.sdk.api.MusapClient
import fi.methics.musap.sdk.internal.encryption.DecryptionReq
import okio.ByteString.Companion.decodeBase64

fun ReadableMap.toDecryptionReq(): DecryptionReq {
    val builder = DecryptionReq.Builder()

    if (hasKey("keyUri")) {
        getString("keyUri")?.let { keyUri ->
            Log.d("MUSAP", "SignatureReq found keyUri ${keyUri}")
            val keyByUri = MusapClient.getKeyByUri(keyUri) ?: throw Exception("Key not found for $keyUri")
            Log.d("MUSAP", "SignatureReq key ${keyByUri.keyAlias}")
            builder.setKey(keyByUri)
        }
    }

    if (hasKey("base64Data")) {
        getString("base64Data")?.let { dataString ->
            builder.setData(dataString.decodeBase64()?.toByteArray())
        }
    }

    if (hasKey("base64Salt")) {
        getString("base64Salt")?.let { dataString ->
            builder.setSalt(dataString.decodeBase64()?.toByteArray())
        }
    }
    
    return builder.build()
}
