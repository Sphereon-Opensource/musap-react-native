import {JWSAlgorithm, KeyAlgorithm, SignatureAlgorithmType} from "./types/musap-types"

const signatureAlgorithms: ReadonlySet<SignatureAlgorithmType> = new Set([
    'SHA256withECDSA', 'SHA384withECDSA', 'SHA512withECDSA', 'NONEwithECDSA', 'NONEwithEdDSA',
    'SHA256withRSA', 'SHA384withRSA', 'SHA512withRSA', 'NONEwithRSA',
    'SHA256withRSASSA-PSS', 'SHA384withRSASSA-PSS', 'SHA512withRSASSA-PSS', 'NONEwithRSASSA-PSS'
]);

export const isSignatureAlgorithmType = (algorithm: string): algorithm is SignatureAlgorithmType => signatureAlgorithms.has(algorithm as SignatureAlgorithmType);

export const signatureAlgorithmFromKeyAlgorithm = (keyAlgorithm: KeyAlgorithm | JWSAlgorithm): SignatureAlgorithmType => {
    switch (keyAlgorithm) {
        case 'eccp256k1':
        case 'eccp256r1':
        case 'ES256': // Also map Veramo translated JWS algorithm identifiers
        case 'ES256K':
            return 'SHA256withECDSA'
        case 'eccp384k1':
        case 'eccp384r1':
            return 'SHA384withECDSA'
        case 'rsa2k':
        case 'rsa4k':
            return 'SHA256withRSA'
        case 'EdDSA':
            return 'NONEwithEdDSA'
        case 'ecc_ed25519':
            return 'NONEwithEdDSA'
        default:
            throw new Error(`Unsupported key algorithm: ${keyAlgorithm}`)
    }
}

export const mapKeyAlgorithmToJWTAlgorithm = (keyAlgorithm: KeyAlgorithm): JWSAlgorithm => {
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
        case 'ecc_ed25519':
            return 'EdDSA'
        default:
            throw new Error(`Unsupported key algorithm: ${keyAlgorithm}`)
    }
}
