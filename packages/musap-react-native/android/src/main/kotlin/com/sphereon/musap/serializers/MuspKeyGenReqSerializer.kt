package com.sphereon.musap.serializers


import android.app.Activity
import android.view.View
import com.facebook.react.bridge.ReadableMap
import fi.methics.musap.sdk.internal.datatype.KeyAlgorithm
import fi.methics.musap.sdk.internal.datatype.KeyAttribute
import fi.methics.musap.sdk.internal.datatype.StepUpPolicy
import fi.methics.musap.sdk.internal.keygeneration.KeyGenReq


fun ReadableMap.toKeyGenReq(activity: Activity?, view: View? = null): KeyGenReq {
    val builder = KeyGenReq.Builder()

    if (hasKey("keyAlias")) {
        builder.setKeyAlias(getString("keyAlias"))
    }

    if (hasKey("did")) {
        builder.setDid(getString("did"))
    }

    if (hasKey("role")) {
        builder.setRole(getString("role"))
    }

    if (hasKey("keyUsage")) {
        builder.setKeyUsage(getString("keyUsage"))
    }

    if (hasKey("stepUpPolicy")) {
        builder.setStepUpPolicy(StepUpPolicy())
    }
    if (hasKey("userAuthenticationRequired")) {
        builder.setUserAuthenticationRequired(getBoolean("userAuthenticationRequired"))
    }

    if (hasKey("attributes")) {
        getArray("attributes")?.let { attributesArray ->
            for (i in 0 until attributesArray.size()) {
                val attributeMap = attributesArray.getMap(i)
                val keyAttribute = KeyAttribute(attributeMap?.getString("name"), attributeMap?.getString("value"))
                builder.addAttribute(keyAttribute)
            }
        }
    }

    if (hasKey("keyAlgorithm")) {
        getString("keyAlgorithm")?.let { keyAlgorithm ->
            builder.setKeyAlgorithm(KeyAlgorithm.fromString(keyAlgorithm))
        }
    }

    builder.setView(view)
    builder.setActivity(activity)

    return builder.createKeyGenReq()
}
