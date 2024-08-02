import {MusapKey, MusapModule} from "@sphereon/musap-react-native";
import {jwtPayload} from "./common";
import {buildJwtHeaderAndPayload} from "./jwt-functions";
import {MusapKeyManagementSystem} from "@sphereon/ssi-sdk-ext.kms-musap-rn";

export const kmsTestRun = async () => {
    console.log(">>>>>>>>>>>>. kmsTestRun started!");
    const kms: MusapKeyManagementSystem = new MusapKeyManagementSystem()
    console.log(">>>>>>>>>>>>. kmsTestRun: KMS created!");

    try {
        // @ts-ignore
        const keyManagedInfo = await kms.createKey({type: 'ECCP256R1'})
        console.log('KMS generateKey result keyUri', keyManagedInfo);

        const key = MusapModule.getKeyById(keyManagedInfo.kid) as MusapKey
        console.log(`KMS GetKeyByUri(): ${JSON.stringify(key)}`)
        const jwtHeaderAndPayload = buildJwtHeaderAndPayload(key, jwtPayload)
        console.log('KMS jwtHeaderAndPayload', jwtHeaderAndPayload)

        const encoder = new TextEncoder();
        const data = encoder.encode(jwtHeaderAndPayload)

        try {
            const signature = await kms.sign({data, keyRef: {kid: keyManagedInfo.kid}, algorithm: 'SHA256withECDSA'})
            console.log('KMS signature', signature)

            const jwt = `${jwtHeaderAndPayload}.${signature}`
            console.log(`jwt`, jwt)
            console.log("NOKMS Data successfully signed:")
        } catch (error) {
            console.error('KMS error', error)
        }

        console.log('KMS Deleted keyUri:', keyManagedInfo)
        kms.deleteKey({kid: keyManagedInfo.kid}).then(value => {
            console.log('KMS Key deleted:', value)

            try {
                const key = MusapModule.getKeyById(keyManagedInfo.kid)
                console.log('KMS Deleted key:', key)
            } catch (e) {
                console.log('KMS Deleted key error:', e.message)
            }
        })
    } catch (e) {
        console.error('KMS error', e)
    }

}
