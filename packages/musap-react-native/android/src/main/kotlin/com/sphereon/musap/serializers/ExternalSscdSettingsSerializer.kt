package com.sphereon.musap.serializers

import com.facebook.react.bridge.ReadableMap
import fi.methics.musap.sdk.sscd.external.ExternalSscdSettings
import java.time.Duration

fun ReadableMap.toExternalSscdSettings(): ExternalSscdSettings {
    if (!hasKey("clientId")) {
        throw IllegalArgumentException("clientId is required for ExternalSscdSettings")
    }

    val settings = ExternalSscdSettings(getString("clientId")!!)

    if (hasKey("sscdName")) {
        settings.sscdName = getString("sscdName")
    }

    if (hasKey("provider")) {
        settings.provider = getString("provider")
    }

    if (hasKey("timeout")) {
        getDouble("timeout").let { timeoutMinutes ->
            settings.settings[ExternalSscdSettings.SETTINGS_TIMEOUT] =
                Duration.ofMinutes(timeoutMinutes.toLong()).toMillis().toString()
        }
    }

    return settings
}
