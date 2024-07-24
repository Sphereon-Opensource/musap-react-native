package com.sphereon.musap


@Throws(Exception::class)
fun convertDERtoRS(derSignature: ByteArray): ByteArray {

    if (derSignature.size <= 8 || derSignature[0] != 0x30.toByte()) {
        throw Exception("Invalid DER signature")
    }

    var index = 2

    // Skip extra length bytes if present
    if (derSignature[1].toInt() and 0xFF > 0x80) {
        index += (derSignature[1].toInt() and 0xFF) - 0x80
    }

    fun extractInteger(): ByteArray {
        if (index >= derSignature.size || derSignature[index] != 0x02.toByte()) {
            throw Exception("Invalid integer marker")
        }
        index++
        val length = derSignature[index].toInt() and 0xFF
        index++
        val valueStartIndex = index
        index += length
        return derSignature.slice(valueStartIndex until index).toByteArray()
    }

    val r = extractInteger()
    val s = extractInteger()

    fun normalize(integer: ByteArray): ByteArray {
        val targetLength = 32
        return when {
            integer.size > targetLength -> integer.takeLast(targetLength).toByteArray()
            integer.size < targetLength -> ByteArray(targetLength - integer.size) + integer
            else -> integer
        }
    }

    val normalizedR = normalize(r)
    val normalizedS = normalize(s)

    val result = normalizedR + normalizedS

    return result
}
