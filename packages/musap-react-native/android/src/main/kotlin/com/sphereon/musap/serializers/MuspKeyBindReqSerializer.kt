package com.sphereon.musap.serializers

import android.app.Activity
import android.view.View
import com.facebook.react.bridge.ReadableMap
import fi.methics.musap.sdk.internal.datatype.KeyAttribute
import fi.methics.musap.sdk.internal.datatype.StepUpPolicy
import fi.methics.musap.sdk.internal.discovery.KeyBindReq


fun ReadableMap.toKeyBindReq(activity: Activity?, view: View? = null): KeyBindReq {
    val builder = KeyBindReq.Builder()

    if (hasKey("keyAlias")) {
        builder.setKeyAlias(getString("keyAlias"))
    }

    if (hasKey("displayText")) {
        builder.setDisplayText(getString("displayText"))
    }

    if (hasKey("did")) {
        builder.setDid(getString("did"))
    }

    if (hasKey("role")) {
        builder.setRole(getString("role"))
    }

    if (hasKey("stepUpPolicy")) {
        builder.setStepUpPolicy(StepUpPolicy())
    }

    if (hasKey("attributes")) {
        getArray("attributes")?.let { attributesArray ->
            for (i in 0 until attributesArray.size()) {
                val attributeMap = attributesArray.getMap(i)
                val keyAttribute = KeyAttribute(
                    attributeMap?.getString("name"),
                    attributeMap?.getString("value")
                )
                builder.addAttribute(keyAttribute)
            }
        }
    }

    if (hasKey("keyUsages")) {
        getArray("keyUsages")?.let { usagesArray ->
            for (i in 0 until usagesArray.size()) {
                builder.addKeyUsage(usagesArray.getString(i))
            }
        }
    }

    builder.setActivity(activity)
    builder.setView(view)

    return builder.createKeyBindReq()
}
