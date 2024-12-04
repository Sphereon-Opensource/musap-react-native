package com.sphereon.musap

import android.util.Log
import org.bouncycastle.asn1.ASN1InputStream
import org.bouncycastle.asn1.ASN1ObjectIdentifier
import org.bouncycastle.cms.CMSSignedData

@ExperimentalStdlibApi
object SignatureConverter {
    private const val TAG = "MUSAP_BRIDGE"
    private const val CMS_SIGNED_DATA_OID = "1.2.840.113549.1.7.2"
    private const val CONTENT_INFO_SEQUENCE = 0x30.toByte()
    private const val INTEGER = 0x02.toByte()

    @Throws(Exception::class)
    fun convertToRS(input: ByteArray): ByteArray {
        return when {
            isCMS(input) -> {
                Log.d(TAG, "Detected CMS signature")
                extractAndConvertCMSSignature(input)
            }

            isDERSignature(input) -> {
                Log.d(TAG, "Detected DER signature")
                convertDERtoRS(input)
            }

            else -> {
                Log.e(TAG, "Invalid signature format")
                throw Exception("Invalid signature format")
            }
        }
    }

    private fun isCMS(data: ByteArray): Boolean {
        return try {
            val oid = ASN1ObjectIdentifier("1.2.840.113549.1.7.2")
            val asn1 = ASN1InputStream(data).readObject()
            val result = asn1.toString().contains(oid.toString())
            result
        } catch (e: Exception) {
            Log.e(TAG, "CMS check failed", e)
            false
        }
    }

    private fun isDERSignature(data: ByteArray): Boolean {
        return try {
            val result = data.size > 8 && data[0] == CONTENT_INFO_SEQUENCE && data[2] == INTEGER
            result
        } catch (e: Exception) {
            Log.e(TAG, "DER check failed", e)
            false
        }
    }

    private fun extractAndConvertCMSSignature(cms: ByteArray): ByteArray {
        val signedData = CMSSignedData(cms)
        val signerInfos = signedData.signerInfos
        if (signerInfos.size() == 0) {
            Log.e(TAG, "No signatures in CMS")
            throw Exception("No signatures found in CMS structure")
        }

        val signerInfo = signerInfos.getSigners().first()
        val signature = signerInfo.signature

        return if (isDERSignature(signature)) {
            convertDERtoRS(signature)
        } else {
            Log.e(TAG, "Invalid CMS signature format")
            throw Exception("Invalid signature format in CMS structure")
        }
    }

    @Throws(Exception::class)
    private fun convertDERtoRS(derSignature: ByteArray): ByteArray {
        var index = 2
        if (derSignature[1].toInt() and 0xFF > 0x80) {
            index += (derSignature[1].toInt() and 0xFF) - 0x80
        }

        fun extractInteger(): ByteArray {
            if (index >= derSignature.size || derSignature[index] != INTEGER) {
                Log.e(TAG, "Invalid integer at $index")
                throw Exception("Invalid integer marker at position $index")
            }
            index++
            val length = derSignature[index].toInt() and 0xFF
            index++
            val result = derSignature.slice(index until (index + length)).toByteArray()
            index += length
            return result
        }

        val r = extractInteger()
        val s = extractInteger()

        fun normalize(integer: ByteArray): ByteArray {
            return when {
                integer.size > 32 -> integer.takeLast(32).toByteArray()
                integer.size < 32 -> ByteArray(32 - integer.size) + integer
                else -> integer
            }
        }

        return normalize(r) + normalize(s)
    }

    private fun ByteArray.toHexString() = joinToString("") { "%02x".format(it) }
}
