/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React from 'react'
import type {PropsWithChildren} from 'react'
import {
    SafeAreaView,
    ScrollView,
    StatusBar,
    StyleSheet,
    Text,
    useColorScheme,
    View,
} from 'react-native'

import {
    Colors,
    DebugInstructions,
    Header,
    LearnMoreLinks,
    ReloadInstructions,
} from 'react-native/Libraries/NewAppScreen'
import {MusapKeyManagementSystem} from "@sphereon/ssi-sdk-ext.musap-rn-kms/dist/agent/MusapKeyManagerSystem"
import {
    KeyGenReq, mapKeyAlgorithmToJWTAlgorithm,
    MusapKey,
    MusapModule,
    signatureAlgorithmFromKeyAlgorithm,
    SignatureReq,
    SscdInfo
} from "@sphereon/musap-react-native"
import uuid from 'react-native-uuid'

const jwtPayload = {
    iss: "test_issuer",
    sub: "test_subject",
    aud: "test_audience",
    iat: Math.floor(Date.now()),
    exp: Math.floor(Date.now()) + (1000 * 180),
    vp: {
        "@context": [
            "https://www.w3.org/2018/credentials/v1",
            "https://identity.foundation/presentation-exchange/submission/v1"
        ],
        "presentation_submission": {
            "id": "accd5adf-1dbf-4ed9-9ba2-d687476126cb",
            "definition_id": "31e2f0f1-6b70-411d-b239-56aed5321884",
            "descriptor_map": [
                {
                    "id": "867bfe7a-5b91-46b2-9ba4-70028b8d9cc8",
                    "format": "ldp_vp",
                    "path": "$.verifiableCredential[0]"
                }
            ]
        },
        "type": [
            "VerifiablePresentation",
            "PresentationSubmission"
        ],
        "verifiableCredential": [
            {
                "@context": [
                    "https://www.w3.org/2018/credentials/v1"
                ],
                "credentialSchema": [
                    {
                        "id": "https://www.w3.org/TR/vc-data-model/#types"
                    }
                ],
                "credentialSubject": {
                    "age": 19,
                    "details": {
                        "citizenship": [
                            "eu"
                        ]
                    },
                    "country": [
                        {
                            "abbr": "NLD"
                        }
                    ],
                    "birthPlace": "Maarssen"
                },
                "id": "2dc74354-e965-4883-be5e-bfec48bf60c7",
                "issuer": "",
                "type": [
                    "VerifiableCredential"
                ],
                "proof": {
                    "type": "BbsBlsSignatureProof2020",
                    "created": "2020-04-25",
                    "verificationMethod": "did:example:489398593#test",
                    "proofPurpose": "assertionMethod",
                    "proofValue": "kTTbA3pmDa6Qia/JkOnIXDLmoBz3vsi7L5t3DWySI/VLmBqleJ/Tbus5RoyiDERDBEh5rnACXlnOqJ/U8yFQFtcp/mBCc2FtKNPHae9jKIv1dm9K9QK1F3GI1AwyGoUfjLWrkGDObO1ouNAhpEd0+et+qiOf2j8p3MTTtRRx4Hgjcl0jXCq7C7R5/nLpgimHAAAAdAx4ouhMk7v9dXijCIMaG0deicn6fLoq3GcNHuH5X1j22LU/hDu7vvPnk/6JLkZ1xQAAAAIPd1tu598L/K3NSy0zOy6obaojEnaqc1R5Ih/6ZZgfEln2a6tuUp4wePExI1DGHqwj3j2lKg31a/6bSs7SMecHBQdgIYHnBmCYGNQnu/LZ9TFV56tBXY6YOWZgFzgLDrApnrFpixEACM9rwrJ5ORtxAAAAAgE4gUIIC9aHyJNa5TBklMOh6lvQkMVLXa/vEl+3NCLXblxjgpM7UEMqBkE9/QcoD3Tgmy+z0hN+4eky1RnJsEg=",
                    "nonce": "6i3dTz5yFfWJ8zgsamuyZa4yAHPm75tUOOXddR6krCvCYk77sbCOuEVcdBCDd/l6tIY="
                }
            }
        ]
    }
}

type SectionProps = PropsWithChildren<{
    title: string
}>

function Section({children, title}: SectionProps): React.JSX.Element {
    const isDarkMode = useColorScheme() === 'dark'
    return (
        <View style={styles.sectionContainer}>
            <Text
                style={[
                    styles.sectionTitle,
                    {
                        color: isDarkMode ? Colors.white : Colors.black,
                    },
                ]}>
                {title}
            </Text>
            <Text
                style={[
                    styles.sectionDescription,
                    {
                        color: isDarkMode ? Colors.light : Colors.dark,
                    },
                ]}>
                {children}
            </Text>
        </View>
    )
}

function base64Encode(str: string): string {
    return btoa(unescape(encodeURIComponent(str)))
}

function base64UrlEncode(str: string): string {
    return base64Encode(str)
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '')
}

function base64UrlDecode(str: string): string {
    str = str.replace(/-/g, '+').replace(/_/g, '/')
    switch (str.length % 4) {
        case 0:
            break
        case 2:
            str += '=='
            break
        case 3:
            str += '='
            break
        default:
            throw new Error('Invalid base64url string')
    }
    return atob(str)
}

function base64ToHex(base64: string): string {
    const raw = atob(base64)
    let result = ''
    for (let i = 0; i < raw.length; i++) {
        const hex = raw.charCodeAt(i).toString(16)
        result += (hex.length === 2 ? hex : '0' + hex)
    }
    return result
}

function hexToBase64Url(hex: string): string {
    const raw = hex.match(/\w{2}/g)!.map(function (a) {
        return String.fromCharCode(parseInt(a, 16))
    }).join('')
    return btoa(raw)
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '')
}

function uint8ArrayToBase64(array: Uint8Array): string {
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

// Utility functions
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


function buildJwtHeaderAndPayload(key: MusapKey, jwtPayload: object): string {
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

async function noKMSRun(sscdInfo: SscdInfo) {
    const keyGenRequest: KeyGenReq = {
        attributes: [
            {name: 'purpose', value: 'encrypt'},
            {name: 'purpose', value: 'decrypt'}
        ],
        did: 'did:example:123456789abcdefghi',
        keyAlgorithm: "ECCP256R1",
        keyAlias: uuid.v4().toString(), // Alias must be unique, at least for iOS otherwise error code 900 is thrown
        keyUsage: "sign",
        role: "administrator",
    }


    try {
        console.log('Clearing keystore')
        /*  const allKeys = MusapModule.listKeys()
          for (const key: MusapKey of allKeys) {
              console.log('Removing key ', key)
              MusapModule.removeKey(key.keyUri)
          }
  */
        const keyUri = await MusapModule.generateKey('TEE', keyGenRequest)
        console.log(`Key successfully generated: ${keyUri}`)

        console.log("ListKeys", MusapModule.listKeys())

        // Works on Android
        const key = MusapModule.getKeyByUri(keyUri) as MusapKey

        console.log('der', key.publicKey.der)
        console.log('derb64', uint8ArrayToBase64(new Uint8Array(key.publicKey.der)))
        console.log(`NOKMS GetKeyByUri(): ${key}`)
        console.log(`NOKMS key`, key)
        const jwtHeaderAndPayload = buildJwtHeaderAndPayload(key, jwtPayload)
        console.log('jwtHeaderAndPayload', jwtHeaderAndPayload)
        sign(key, jwtHeaderAndPayload, sscdInfo)
    } catch (e) {
        console.error('sign failed', e)
    }
}


const sign = async (key: MusapKey, jwtHeaderAndPayload: string, sscdInfo: SscdInfo) => {
    console.log('key.keyUri', key.keyUri)
    const req: SignatureReq = {
        keyUri: key.keyUri,
        data: jwtHeaderAndPayload,
        displayText: "test",
        format: 'RAW',
        algorithm: signatureAlgorithmFromKeyAlgorithm(key.algorithm),
        attributes: [{name: "key", value: "value"}],
    }
    //const reqData = sscdInfo.sscdName === "SE" ? req : JSON.stringify(req)
    console.log('NOKMS signatureReq', JSON.stringify(req))
    try {
        const signature = await MusapModule.sign(req)
        const jwt = `${jwtHeaderAndPayload}.${signature}`
        console.log("NOKMS Data successfully signed:")
        console.log(`jwt`, jwt)
    } catch (e) {
        console.log("NOKMS An error occurred.\n")
        console.log(e)
    }
}


function App(): React.JSX.Element {
    const isDarkMode = useColorScheme() === 'dark'

    const backgroundStyle = {
        backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
    }


    MusapModule.enableSscd('TEE')
    const sscds = MusapModule.listEnabledSscds()
    console.log(sscds)
    const sscdInfo = sscds[0].sscdInfo

    /* const kms:MusapKeyManagementSystem = new MusapKeyManagementSystem(MusapModule)

     async function generateKey() {
       // @ts-ignore
       const result = await kms.createKey({type: 'secp256r1'})
       console.log('kms.createKey() result', result)
       return result
     }

     generateKey()
         .then(value => {
           console.log('generateKey result', value)
           const keyUri = (value as any).keyUri.uri
           console.log('Deleted keyUri:', keyUri)
           kms.deleteKey({kid: keyUri}).then(value => {
             console.log('Key deleted:', value)

             try {
               const key = MusapModule.getKeyByUri(keyUri)
               console.log('Deleted key:', key)
             } catch (e) {
               console.log('Deleted key error:', e.message)
             }
           })
         })
         .catch(reason => {
           console.error(reason)
         })
   */
    noKMSRun(sscdInfo)

    //console.log(MusapModule.listEnabledSscds())

    return (
        <SafeAreaView style={backgroundStyle}>
            <StatusBar
                barStyle={isDarkMode ? 'light-content' : 'dark-content'}
                backgroundColor={backgroundStyle.backgroundColor}
            />
            <ScrollView
                contentInsetAdjustmentBehavior="automatic"
                style={backgroundStyle}>
                <Header/>
                <View
                    style={{
                        backgroundColor: isDarkMode ? Colors.black : Colors.white,
                    }}>
                    <Section title="Step One">
                        Edit <Text style={styles.highlight}>App.tsx</Text> to change this
                        screen and then come back to see your edits.
                    </Section>
                    <Section title="See Your Changes">
                        <ReloadInstructions/>
                    </Section>
                    <Section title="Debug">
                        <DebugInstructions/>
                    </Section>
                    <Section title="Learn More">
                        Read the docs to discover what to do next:
                    </Section>
                    <LearnMoreLinks/>
                </View>
            </ScrollView>
        </SafeAreaView>
    )
}

const styles = StyleSheet.create({
    sectionContainer: {
        marginTop: 32,
        paddingHorizontal: 24,
    },
    sectionTitle: {
        fontSize: 24,
        fontWeight: '600',
    },
    sectionDescription: {
        marginTop: 8,
        fontSize: 18,
        fontWeight: '400',
    },
    highlight: {
        fontWeight: '700',
    },
})

export default App
