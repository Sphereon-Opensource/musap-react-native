<h1 align="center">
  <br>
  <a href="https://www.sphereon.com"><img src="https://sphereon.com/content/themes/sphereon/assets/img/logo.svg" alt="Sphereon" width="400"></a>
  <br>React Native bridge for the MUSAP library
  <br>
</h1>


### Getting started

`$ yarn add @sphereon/react-native-musap`


### Usage
The MUSAP (Mobile Universal Signing Application Protocol) library provides a set of functions for key management and signing operations. Here's how to use the main features:

### Importing the Module

```typescript
import { MusapModule, KeyGenReq, SignatureReq } from "@sphereon/musap-react-native";
```

### Enabling SSCD (Secure Signature Creation Device)

Before using the module, enable the SSCD:

```typescript
MusapModule.enableSscd('TEE');
```
\* Use 'TEE' for the mobile devices secure keystore, use 'YUBI_KEY' when targeting a external Yubi key device

### Listing Enabled SSCDs

To get a list of enabled SSCDs:

```typescript
const sscds = MusapModule.listEnabledSscds();
console.log('Enabled SSCDs:', sscds);
```

### Generating a Key

To generate a new key: (with example values)

```typescript
const keyGenRequest: KeyGenReq = {
    attributes: [
        {name: 'purpose', value: 'encrypt'},
        {name: 'purpose', value: 'decrypt'}
    ],
    keyAlgorithm: "ECCP256R1",
    keyAlias: "unique-alias-here", // Must be unique
    keyUsage: "sign",
    role: "administrator",
};

const keyUri = await MusapModule.generateKey('TEE', keyGenRequest);
console.log(`Key generated: ${keyUri}`);
```

### Listing Keys

To list all keys:

```typescript
const allKeys = MusapModule.listKeys();
console.log("All keys:", allKeys);
```

### Getting a Key by URI

To retrieve a specific key:

```typescript
const key = MusapModule.getKeyByUri(keyUri);
console.log("Key details:", key);
```

### Signing Data

To sign data using a generated key:

```typescript
const signatureRequest: SignatureReq = {
    keyUri: key.keyUri,
    data: "data-to-be-signed",
    displayText: "Signing operation",
    format: 'RAW',
    algorithm: signatureAlgorithmFromKeyAlgorithm(key.algorithm),
    attributes: [{name: "key", value: "value"}],
};

try {
    const signature = await MusapModule.sign(signatureRequest);
    console.log("Signature:", signature);
} catch (error) {
    console.error("Signing failed:", error);
}
```

### Removing a Key

To remove a key:

```typescript
const result = MusapModule.removeKey(keyUri);
console.log("Key removal result:", result);
```

Remember to handle errors appropriately in a production environment, as these operations can throw exceptions.


## MUSAP typescript API Reference

### MUSAP Module Interface

```typescript
interface MusapModuleType {
    listEnabledSscds(): Array<MusapSscd>
    listActiveSscds(): Array<MusapSscd>
    enableSscd(sscdType: SscdType): void
    generateKey(sscdType: SscdType, req: KeyGenReq): Promise<string>
    sign(req: SignatureReq): Promise<string>
    removeKey(keyIdOrUri: String): number
    listKeys(): MusapKey[]
    getKeyByUri(keyUri: string): MusapKey
    getKeyById(keyId: string): MusapKey
    getSscdInfo(sscdId: string): SscdInfo
    getSettings(sscdId: string): Map<string, string>
}
```

### Types

#### Key and Algorithm Types

- `KeyAlgorithmPrimitive`: `'RSA' | 'EC'`
- `SignatureAlgorithmType`: Various signature algorithms (e.g., 'SHA256withECDSA', 'SHA256withRSA', etc.)
- `JWTAlgorithm`: `'ES256' | 'ES384' | 'RS256' | 'RS384' | 'RS512'`
- `KeyAlgorithmType`: Various key algorithms (e.g., 'RSA2K', 'ECCP256R1', etc.)
- `KeyAlgorithm`: `'eccp256k1' | 'eccp256r1' | 'eccp384k1' | 'eccp384r1' | 'rsa2k' | 'rsa4k'`

#### Signature Types

- `SignatureFormatType`: `'CMS' | 'RAW' | 'PKCS1'`
- `SignatureFormat`: `'CMS' | 'RAW'`

#### SSCD Types

- `SscdType`: `'TEE' | 'YUBI_KEY'`

#### Other Types

- `MusapLoAScheme`: `'EIDAS-2014' | 'ISO-29115'`

### Interfaces

#### SSCD Interfaces

```typescript
interface SscdInfo {
    sscdName: string
    sscdType: string
    sscdId: string
    country: string
    provider: string
    keygenSupported: boolean
    supportedAlgorithms: KeyAlgorithm[]
}

interface MusapSscd {
    sscdId: string
    sscdInfo: SscdInfo
    settings: Map<String, String>
}
```

#### Key Interfaces

```typescript
interface KeyAttribute {
    name: string
    value: string
}

interface KeyGenReq {
    keyAlias: string
    did: string
    role: string
    keyUsage: string
    stepUpPolicy?: StepUpPolicy
    attributes: KeyAttribute[]
    keyAlgorithm: KeyAlgorithmType
}

interface MusapKey {
    keyUri: string
    keyAlias: string
    keyType: string
    keyId: string
    sscdId: string
    sscdType: string
    createdDate: string | number
    publicKey: PublicKey
    certificate: MusapCertificate
    certificateChain: MusapCertificate[]
    attributes: KeyAttribute[]
    keyUsages: string[]
    loa: MusapLoA[]
    algorithm: KeyAlgorithm
    did: string
    state: string
    attestation: KeyAttestation
}

interface PublicKey {
    der: Uint8Array
    pem: string
}

interface KeyAttestation {
    attestationType: string
    signature: Uint8Array
    certificate: MusapCertificate
    certificateChain: MusapCertificate[]
    aaguid: string
}
```

#### Certificate Interface

```typescript
interface MusapCertificate {
    subject: string
    certificate: Uint8Array
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
```

#### Signature Interface

```typescript
interface SignatureAttribute {
    name: string
    value: string
}

interface SignatureReq {
    keyUri: string
    data: string
    displayText?: string
    algorithm?: SignatureAlgorithmType
    format: SignatureFormat
    attributes?: SignatureAttribute[]
    transId?: string
}
```

#### Level of Assurance (LoA) Interface

```typescript
interface MusapLoA extends Comparable<MusapLoA> {
    loa: string
    scheme: string
    number: number
    compareLoA(other: MusapLoA): boolean
}
```

## Constants

- `LOA_SCHEME_EIDAS`: `'EIDAS-2014'`
- `LOA_SCHEME_ISO`: `'ISO-29115'`

This API reference provides an overview of the main types, interfaces, and functions available in the MUSAP library. For detailed usage examples, please refer to the Usage Guide section of this README.

### License
This project is licensed under the Apache-2 License.
