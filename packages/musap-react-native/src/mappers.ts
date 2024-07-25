import {JWTAlgorithm, KeyAlgorithm, SignatureAlgorithmType} from "./types/musap-types"

export const signatureAlgorithmFromKeyAlgorithm = (keyAlgorithm: KeyAlgorithm): SignatureAlgorithmType => {
    switch (keyAlgorithm) {
        case 'eccp256k1':
        case 'eccp256r1':
            return 'SHA256withECDSA'
        case 'eccp384k1':
        case 'eccp384r1':
            return 'SHA384withECDSA'
        case 'rsa2k':
        case 'rsa4k':
            return 'SHA256withRSA'
        default:
            throw new Error(`Unsupported key algorithm: ${keyAlgorithm}`)
    }
}

export const mapKeyAlgorithmToJWTAlgorithm = (keyAlgorithm: KeyAlgorithm): JWTAlgorithm => {
    switch (keyAlgorithm) {
        case 'eccp256k1':
        case 'eccp256r1':
            return 'ES256'
        case 'eccp384k1':
        case 'eccp384r1':
            return 'ES384'
        case 'rsa2k':
            return 'RS256'
        case 'rsa4k':
            return 'RS512'
        default:
            throw new Error(`Unsupported key algorithm: ${keyAlgorithm}`)
    }
}
