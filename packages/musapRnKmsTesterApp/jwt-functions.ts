import {mapKeyAlgorithmToJWTAlgorithm, MusapKey} from "@sphereon/musap-react-native"

export function base64Encode(str: string): string {
    return btoa(
        encodeURIComponent(str).replace(
            /%([0-9A-F]{2})/g,
            (match, p1) => String.fromCharCode(Number('0x' + p1))
        )
    )
}

export const base64UrlEncode = (str: string): string => base64Encode(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')

export const uint8ArrayToBase64 = (array: Uint8Array): string => {
    if (!(array instanceof Uint8Array)) {
        throw new Error('Input must be a Uint8Array')
    }

    let binary = ''
    const len = array.byteLength
    const chunkSize = 0x8000 // 32 KB chunks

    for (let i = 0; i < len; i += chunkSize) {
        const chunk = array.subarray(i, Math.min(i + chunkSize, len))
        binary += String.fromCharCode.apply(null, chunk as unknown as number[])
    }

    return btoa(binary)
}


const base64ToUint8Array = (base64: string): Uint8Array => {
    const binaryString = atob(base64)
    const len = binaryString.length
    const bytes = new Uint8Array(len)
    for (let i = 0; i < len; i++) {
        bytes[i] = binaryString.charCodeAt(i)
    }
    return bytes
}

const uint8ArrayToBase64Url = (array: Uint8Array): string => {
    return btoa(String.fromCharCode.apply(null, array as unknown as number[]))
        .replace(/=/g, '')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
}

const buildJwk = (pem: string): object => {
    // Remove PEM headers and newlines
    const base64Content = pem
        .replace('-----BEGIN PUBLIC KEY-----', '')
        .replace('-----END PUBLIC KEY-----', '')
        .replace(/\s/g, '')

    // Convert base64 to Uint8Array
    const keyData = base64ToUint8Array(base64Content)

    let publicKey: Uint8Array

    if (keyData[0] === 0x30) { // ASN.1 sequence
        // Simple ASN.1 parser for ECDSA public keys
        let offset = 2 // Skip sequence tag and length
        offset += keyData[offset] === 0x30 ? keyData[offset + 1] + 2 : 0 // Skip AlgorithmIdentifier if present
        if (keyData[offset] === 0x03) { // BitString
            offset += 2 // Skip BitString tag and length
            if (keyData[offset] === 0x00) { // Skip unused bits
                offset++
            }
            publicKey = keyData.slice(offset)
        } else {
            throw new Error('Invalid ASN.1 structure for public key')
        }
    } else if (keyData[0] === 0x04) { // Raw public key
        publicKey = keyData
    } else {
        throw new Error('Invalid public key format')
    }

    // Ensure we have the correct length for P-256
    if (publicKey.length !== 65) { // 1 byte prefix + 32 bytes X + 32 bytes Y
        throw new Error('Invalid public key length for P-256 curve')
    }

    // Extract X and Y coordinates (32 bytes each)
    const x = publicKey.slice(1, 33)
    const y = publicKey.slice(33, 65)

    // Convert X and Y to Base64URL format
    const xBase64 = uint8ArrayToBase64Url(x)
    const yBase64 = uint8ArrayToBase64Url(y)

    // Construct the JWK
    const jwk = {
        kty: 'EC',
        crv: 'P-256',
        x: xBase64,
        y: yBase64,
        use: 'sig',
    }

    return jwk
}


export const buildJwtHeaderAndPayload = (key: MusapKey, jwtPayload: object): string => {
    const headerMap: object = {
        typ: "JWT",
        kid: key.keyId,
        alg: mapKeyAlgorithmToJWTAlgorithm(key.algorithm),
        jwk: buildJwk(key.publicKey.pem)
    }
    const header = base64UrlEncode(JSON.stringify(headerMap))
    const payload = base64UrlEncode(JSON.stringify(jwtPayload))
    return `${header}.${payload}`
}
