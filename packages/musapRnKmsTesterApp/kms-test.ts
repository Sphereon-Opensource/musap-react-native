import {MusapKey, MusapModule} from "@sphereon/musap-react-native";
import {MusapKeyManagementSystem} from "@sphereon/ssi-sdk-ext.musap-rn-kms";
import {jwtPayload} from "./common";

export const kmsTestRun = async () => {
    const kms: MusapKeyManagementSystem = new MusapKeyManagementSystem(MusapModule)

    try {
        const value = await generateKey(kms)
        console.log('KMS generateKey result', value);
        const keyUri = (value as any).keyUri.uri

        console.log('KMS Deleted keyUri:', keyUri)
        kms.deleteKey({kid: keyUri}).then(value => {
            console.log('KMS Key deleted:', value)

            try {
                const key = MusapModule.getKeyByUri(keyUri)
                console.log('KMS Deleted key:', key)
            } catch (e) {
                console.log('KMS Deleted key error:', e.message)
            }
        })
    } catch (e) {
        console.error('KMS error', e)
    }

}

async function generateKey(kms: MusapKeyManagementSystem) {
    // @ts-ignore
    const result = await kms.createKey({type: 'secp256r1'})
    console.log('KMS createKey() result', result)
    const encoder = new TextEncoder();
    const data = encoder.encode(JSON.stringify(jwtPayload));
    console.log('KMS encoded data', data);
    try {
        const keyUri = ((result as unknown as MusapKey).keyUri as any).uri
        console.log('KMS keyUri result:', keyUri)
        const signresult = await kms.sign({data, keyRef: {kid: keyUri}})
        console.log('KMS signresult', signresult)
    } catch (error) {
        console.error('KMS error', error)
    }
    return result
}
