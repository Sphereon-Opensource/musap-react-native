import {NativeModules} from "react-native"

export type KeyAlgorithmPrimitive = 'RSA' | 'EC' | 'AES'

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
    | 'AES'
//    | 'ECC_ED25519'
 //   | 'secp256k1'
 //   | 'SECP384K1'
 //   | 'secp256r1'
 //   | 'secp384r1'
 //   | 'Ed25519'

export type SignatureFormatType = 'CMS' | 'RAW' | 'PKCS1'

export type SignatureFormat = 'CMS' | 'RAW'

export type ExternalSscdAtt = 'msisdn' | 'nospamcode' | 'eventid' | 'sscdname'

export interface ExternalSscdSettings {
    clientId: string
    sscdName?: string
    provider?: string
    timeout?: number  // in minutes
}

export interface BindKeyResponse {
    keyUri: string
    transId?: string
}

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

export type KeyAlgorithm = 'eccp256k1' | 'eccp256r1' | 'eccp384k1' | 'eccp384r1' | 'rsa2k' | 'rsa4k' | 'aes'

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

export interface KeyBindReq {
    keyAlias: string
    attributes: KeyAttribute[]
    keyUsages: String[]
    displayText?: string
    did?: string
    role?: string
    stepUpPolicy?: boolean
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
    encryptionKeyRef: SecretKey
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

export interface SecretKey {
    algorithm: string
    format: string
    encoded: Uint8Array // FIXME we can't map Uint8Array
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

export interface EncryptionReq {
    keyUri: string
    base64Data: string
    base64Salt: string
}

export interface DecryptionReq {
    keyUri: string
    base64Data: string
    base64Salt: string
}

interface Comparable<T> {
    compareTo(other: T): number
}

export type MusapLoAScheme = 'EIDAS-2014' | 'ISO-29115'
export const LOA_SCHEME_EIDAS: MusapLoAScheme = 'EIDAS-2014'
export const LOA_SCHEME_ISO: MusapLoAScheme = 'ISO-29115'

export type SscdType = 'TEE' | 'YUBI_KEY' | 'EXTERNAL'

export interface IMusapClient {
    listEnabledSscds(): Array<MusapSscd>
    listActiveSscds(): Array<MusapSscd>
    enableSscd(sscdType: SscdType, sscdId?: string, settings?: ExternalSscdSettings): void
    generateKey(sscdId: string, req: KeyGenReq): Promise<string>
    bindKey(sscdId: string, req: KeyBindReq): Promise<BindKeyResponse>
    sign(req: SignatureReq): Promise<string>
    encryptData(req: EncryptionReq): Promise<string>
    decryptData(req: DecryptionReq): Promise<string>
    removeKey(keyIdOrUri: string): Promise<boolean>
    listKeys(): MusapKey[]
    getKeyByUri(keyUri: string): MusapKey
    getKeyById(keyId: string): MusapKey
    getSscdInfo(sscdId: string): SscdInfo
    getSettings(sscdId: string): Map<string, string>
    getLink(): string
    enableLink(url: string, fcmToken?: string): Promise<string>
    disconnectLink(): void
    coupleWithRelyingParty(couplingCode: string): Promise<string>
}


export const MusapClient: IMusapClient = NativeModules.MusapBridge as IMusapClient

