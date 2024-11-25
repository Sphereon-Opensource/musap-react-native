package com.sphereon.musap.models

enum class ResultSignatureFormat {
    DER,
    RS,
    BASE64;

    companion object {
        fun fromString(value: String?): ResultSignatureFormat {
            return when (value?.uppercase()) {
                "RS" -> RS
                "BASE64" -> BASE64
                "DER" -> DER
                else -> BASE64  // Default value
            }
        }
    }
}
