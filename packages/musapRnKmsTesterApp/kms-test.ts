import {MusapModule} from "@sphereon/musap-react-native";
import {MusapKeyManagementSystem} from "@sphereon/ssi-sdk-ext.musap-rn-kms";
import {jwtPayload} from "./common";

export const kmsTestRun = async () => {
    const kms: MusapKeyManagementSystem = new MusapKeyManagementSystem(MusapModule)

    try {
        // @ts-ignore
        const keyManagedInfo = await kms.createKey({type: 'secp256r1'})
        console.log('KMS generateKey result keyUri', keyManagedInfo);

        const encoder = new TextEncoder();
        const data = encoder.encode(JSON.stringify(jwtPayload));
        console.log('KMS encoded data', data);
        try {
            const signresult = await kms.sign({data, keyRef: {kid: keyManagedInfo.kid}})
            console.log('KMS signresult', signresult)
        } catch (error) {
            console.error('KMS error', error)
        }

        console.log('KMS Deleted keyUri:', keyManagedInfo)
        kms.deleteKey({kid: keyManagedInfo.kid}).then(value => {
            console.log('KMS Key deleted:', value)

            try {
                const key = MusapModule.getKeyByUri(keyManagedInfo.kid)
                console.log('KMS Deleted key:', key)
            } catch (e) {
                console.log('KMS Deleted key error:', e.message)
            }
        })
    } catch (e) {
        console.error('KMS error', e)
    }

}
