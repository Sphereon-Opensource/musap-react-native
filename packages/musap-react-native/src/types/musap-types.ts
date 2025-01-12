import {NativeModules} from "react-native"

export type KeyAlgorithmPrimitive = 'RSA' | 'EC'

export type SignatureAlgorithmType = 'SHA256withECDSA' | 'SHA384withECDSA' | 'SHA512withECDSA' | 'NONEwithECDSA' | 'NONEwithEdDSA' | 'SHA256withRSA' | 'SHA384withRSA'
    | 'SHA512withRSA' | 'NONEwithRSA' | 'SHA256withRSASSA-PSS' | 'SHA384withRSASSA-PSS' | 'SHA512withRSASSA-PSS' | 'NONEwithRSASSA-PSS'

export type JWSAlgorithm = 'ES256' | 'ES256K' | 'ES384' | 'RS256' | 'RS384' | 'RS512' | 'EdDSA'

export type KeyAlgorithmType =
    | 'RSA1K'
    | 'RSA2K'
    | 'RSA4K'
    | 'ECCP256K1'
    | 'ECCP256R1'
//    | 'ECCP256R1'
    | 'ECCP384K1'
    | 'ECCP384R1'
//    | 'ECC_ED25519'
 //   | 'secp256k1'
 //   | 'SECP384K1'
 //   | 'secp256r1'
 //   | 'secp384r1'
 //   | 'Ed25519'

export type SignatureFormatType = 'CMS' | 'RAW' | 'PKCS1'

export type SignatureFormat = 'CMS' | 'RAW'

export interface SscdInfo {
    sscdName: string
    sscdType: string
    sscdId: string
    country: string
    provider: string
    keygenSupported: boolean
    supportedAlgorithms: KeyAlgorithm[]
}

export interface MusapSscd {
    sscdId: string
    sscdInfo: SscdInfo
    settings: Map<String, String>
}

export type KeyAlgorithm = 'eccp256k1' | 'eccp256r1' | 'eccp384k1' | 'eccp384r1' | 'rsa2k' | 'rsa4k'

export interface KeyAttribute {
    name: string
    value: string
}

export interface StepUpPolicy {
}

export interface KeyGenReq {
    keyAlias: string
    role: string
    keyUsage: string
    stepUpPolicy?: StepUpPolicy
    attributes: KeyAttribute[]
    keyAlgorithm: KeyAlgorithmType
}

export interface MusapKey {
    keyUri: string
    keyAlias: string
    keyType: KeyAlgorithmType
    keyId: string
    sscdId: string
    sscdType: SscdType
    createdDate: string | number // ISO date string
    publicKey: PublicKey
    certificate: MusapCertificate
    certificateChain: MusapCertificate[]
    attributes: KeyAttribute[]
    keyUsages: string[]
    loa: MusapLoA[]
    algorithm: KeyAlgorithm
    state: string
    attestation: KeyAttestation
}

export interface PublicKey {
    der: Uint8Array // FIXME we can't map Uint8Array
    pem: string
}

export interface MusapCertificate {
    subject: string
    certificate: Uint8Array // FIXME we can't map Uint8Array
    publicKey: PublicKey
    getGivenName(): string
    getSurname(): string
    getSerialNumber(): string
    getEmail(): string
    getSubjectAttribute(attrName: string): string
    getSubject(): string
    getCertificate(): Uint8Array
    getPublicKey(): PublicKey
}

export interface MusapLoA extends Comparable<MusapLoA> {
    loa: string
    scheme: string
    number: number
    compareLoA(other: MusapLoA): boolean
}

export interface KeyAttestation {
    attestationType: string
    signature: Uint8Array
    certificate: MusapCertificate
    certificateChain: MusapCertificate[]
    aaguid: string
}

export interface SignatureAttribute {
    name: string
    value: string
}

export interface SignatureReq {
    keyUri: string
    data: string // TODO if we want to support binary data we need to send an array of numbers (or go base64)
    displayText?: string
    algorithm?: SignatureAlgorithmType
    format: SignatureFormat
    attributes?: SignatureAttribute[]
    transId?: string
}


interface Comparable<T> {
    compareTo(other: T): number
}

export type MusapLoAScheme = 'EIDAS-2014' | 'ISO-29115'
export const LOA_SCHEME_EIDAS: MusapLoAScheme = 'EIDAS-2014'
export const LOA_SCHEME_ISO: MusapLoAScheme = 'ISO-29115'

export type SscdType = 'TEE' | 'YUBI_KEY'

export interface MusapModuleType {
    listEnabledSscds(): Array<MusapSscd>
    listActiveSscds(): Array<MusapSscd>
    enableSscd(sscdType: SscdType): void
    generateKey (sscdType: SscdType, req: KeyGenReq): Promise<string>
    sign(req: SignatureReq): Promise<string>
    removeKey(keyIdOrUri: String): number
    listKeys(): MusapKey[]
    getKeyByUri(keyUri: string): MusapKey
    getKeyById(keyId: string): MusapKey
    getSscdInfo(sscdId: string): SscdInfo
    getSettings(sscdId: string): Map<string, string>
}


export const MusapModule: MusapModuleType = NativeModules.MusapModule as MusapModuleType

