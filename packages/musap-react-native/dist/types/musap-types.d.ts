export type KeyAlgorithmPrimitive = 'RSA' | 'EC';
export type KeyAlgorithmType = 'RSA' | 'EC' | 'RSA2K' | 'RSA4K' | 'ECCP256K1' | 'ECCP256R1' | 'ECCP384K1' | 'ECCP384R1' | 'ECC_ED25519' | 'secp256k1' | 'secp384k1' | 'secp256r1' | 'secp384r1' | 'Ed25519';
export type SignatureFormatType = 'CMS' | 'RAW' | 'PKCS1';
export interface SscdInfo {
    sscdName: string;
    sscdType: string;
    sscdId: string;
    country: string;
    provider: string;
    keygenSupported: boolean;
    supportedAlgorithms: KeyAlgorithm[];
    formats: SignatureFormat[];
}
export interface MusapSscd {
    sscdId: string;
    sscdInfo: SscdInfo;
    settings: Map<String, String>;
}
export interface KeyAlgorithm {
    primitive: KeyAlgorithmType;
    curve?: string;
    bits: number;
}
export interface SignatureFormat {
    format: SignatureFormatType;
}
export interface KeyAttribute {
    name: string;
    value: string;
}
export interface StepUpPolicy {
}
export interface KeyGenReq {
    keyAlias: string;
    did: string;
    role: string;
    keyUsage: string;
    stepUpPolicy?: StepUpPolicy;
    attributes: KeyAttribute[];
    keyAlgorithm: KeyAlgorithm;
}
export interface MusapKey {
    keyUri: string;
    keyAlias: string;
    keyType: string;
    keyId: string;
    sscdId: string;
    sscdType: string;
    createdDate: string | number;
    publicKey: PublicKey;
    certificate: MusapCertificate;
    certificateChain: MusapCertificate[];
    attributes: KeyAttribute[];
    keyUsages: string[];
    loa: MusapLoA[];
    algorithm: KeyAlgorithm;
    did: string;
    state: string;
    attestation: KeyAttestation;
}
interface PublicKey {
    publickeyDer: Uint8Array;
    getDER(): Uint8Array;
    getPEM(): string;
}
interface MusapCertificate {
    subject: string;
    certificate: Uint8Array;
    publicKey: PublicKey;
    getGivenName(): string;
    getSurname(): string;
    getSerialNumber(): string;
    getEmail(): string;
    getSubjectAttribute(attrName: string): string;
    getSubject(): string;
    getCertificate(): Uint8Array;
    getPublicKey(): PublicKey;
}
interface MusapLoA extends Comparable<MusapLoA> {
    loa: string;
    scheme: string;
    number: number;
    compareLoA(other: MusapLoA): boolean;
}
interface KeyAttestation {
    attestationType: string;
    signature: Uint8Array;
    certificate: MusapCertificate;
    certificateChain: MusapCertificate[];
    aaguid: string;
}
interface SignatureAttribute {
    name: string;
    value: string;
}
export interface SignatureReq {
    key: MusapKey;
    data: string;
    displayText?: string;
    algorithm?: 'SHA256withECDSA' | 'SHA384withECDSA' | 'SHA512withECDSA' | 'NONEwithECDSA' | 'NONEwithEdDSA' | 'SHA256withRSA' | 'SHA384withRSA' | 'SHA512withRSA' | 'NONEwithRSA' | 'SHA256withRSASSA-PSS' | 'SHA384withRSASSA-PSS' | 'SHA512withRSASSA-PSS' | 'NONEwithRSASSA-PSS';
    format?: 'CMS' | 'RAW';
    attributes?: SignatureAttribute[];
    transId?: string;
}
interface Comparable<T> {
    compareTo(other: T): number;
}
type SscdType = 'TEE' | 'YUBI_KEY';
export interface MusapModuleType {
    listEnabledSscds(): Array<MusapSscd>;
    listActiveSscds(): Array<MusapSscd>;
    enableSscd(sscdType: SscdType): void;
    generateKey(sscdType: SscdType, req: KeyGenReq, callback: Function): Promise<void>;
    sign(req: SignatureReq, callback: Function): Promise<void>;
    listKeys(): MusapKey[] | string;
    getKeyByUri(keyUri: string): MusapKey | string;
    getSscdInfo(sscdId: string): SscdInfo;
    getSettings(sscdId: string): Map<string, string>;
}
export declare const MusapModule: MusapModuleType;
export {};
//# sourceMappingURL=musap-types.d.ts.map