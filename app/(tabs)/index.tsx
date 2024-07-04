import { Image, StyleSheet, Platform } from 'react-native';
import uuid from 'react-native-uuid'

import { HelloWave } from '@/components/HelloWave';
import ParallaxScrollView from '@/components/ParallaxScrollView';
import { ThemedText } from '@/components/ThemedText';
import { ThemedView } from '@/components/ThemedView';
import {KeyGenReq, MusapModule, SignatureReq } from '@/types/musap-types';

export default function HomeScreen() {

  const musapDemo = async () => {
    MusapModule?.enableSscd('TEE')
    const listEnabledSscds = MusapModule?.listEnabledSscds()
    const listActiveSscds = MusapModule?.listActiveSscds()
    const listKeys = MusapModule?.listKeys()
    try {
      //console.log(`active SSCDs: ${JSON.stringify(listActiveSscds)}\n\n`)
      //console.log(`enabled SSCDs: ${JSON.stringify(listEnabledSscds)}\n\n`)
      //console.log(`list keys: ${JSON.stringify(listKeys)}\n\n`)
      const musapSscd = listEnabledSscds[0]

      const keyGenRequest: KeyGenReq = {
        attributes: [
          { name: 'purpose', value: 'encrypt' },
          { name: 'purpose', value: 'decrypt' }
        ],
        did: 'did:example:123456789abcdefghi',
        keyAlgorithm: { primitive: "EC", curve: "secp256r1", bits: 256 },
        keyAlias: uuid.v4(), // Alias must be unique, at least for iOS otherwise error code 900 is thrown
        keyUsage: "sign",
        role: "administrator",
      }

      const jwt = {
          iss: "test_issuer",
          sub: "test_subject",
          aud: "test_audience",
          iat: Math.floor(Date.now()),
          exp: Math.floor(Date.now()) + 900,
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

      console.log(`Generating key for sscdId ${musapSscd.sscdId}...\n\n`)
      // iOS uses the error as result
      await MusapModule.generateKey(musapSscd.sscdId, keyGenRequest, (error: any, result: any) => {
//           if (error) {
//             console.log(error)
//           }
            result = error as String
          if (result) {
            console.log("Key successfully generated.\n\n")
            const key = MusapModule.getKeyByUri(result)
            console.log(`Get key by URI: ${JSON.stringify(key)}\n\n`)
            const req: SignatureReq = {
              key,
              data: jwt
            }

            MusapModule.sign(JSON.stringify(req), (error: any, result: any) => {
              if (error) {
                console.log("An error occurred.\n")
                console.log(error)
              }
              if (result) {
                console.log("Data successfully signed:")
                console.log(result)
              }
            })
          }
      })
      console.log(`List keys: ${JSON.stringify(JSON.parse(MusapModule.listKeys()))}\n\n`)
      console.log(`Get SSCD info: ${JSON.stringify(MusapModule.getSscdInfo("TEE"))}\n\n`)
      console.log(`Get SSCD Settings: ${JSON.stringify(MusapModule.getSscdSettings("TEE"))}\n\n`)

    } catch(e) {
      console.log("Catch clause entered")
      console.log(e)
      console.log((e as Error).message)
    }
  }
  musapDemo().then(() => console.log("Musap code executed"))
  return (
    <ParallaxScrollView
      headerBackgroundColor={{ light: '#A1CEDC', dark: '#1D3D47' }}
      headerImage={
        <Image
          source={require('@/assets/images/partial-react-logo.png')}
          style={styles.reactLogo}
        />
      }>
      <ThemedView style={styles.titleContainer}>
        <ThemedText type="title">Title</ThemedText>
        <HelloWave />
      </ThemedView>
      <ThemedView style={styles.stepContainer}>
        <ThemedText type="subtitle">Step 1: Try it</ThemedText>
        <ThemedText>
          Edit <ThemedText type="defaultSemiBold">app/(tabs)/index.tsx</ThemedText> to see changes.
          Press{' '}
          <ThemedText type="defaultSemiBold">
            {Platform.select({ ios: 'cmd + d', android: 'cmd + m' })}
          </ThemedText>{' '}
          to open developer tools.
        </ThemedText>
      </ThemedView>
      <ThemedView style={styles.stepContainer}>
        <ThemedText type="subtitle">Step 2: Explore</ThemedText>
        <ThemedText>
          Tap the Explore tab to learn more about what's included in this starter app.
        </ThemedText>
      </ThemedView>
      <ThemedView style={styles.stepContainer}>
        <ThemedText type="subtitle">Step 3: Get a fresh start</ThemedText>
        <ThemedText>
          When you're ready, run{' '}
          <ThemedText type="defaultSemiBold">npm run reset-project</ThemedText> to get a fresh{' '}
          <ThemedText type="defaultSemiBold">app</ThemedText> directory. This will move the current{' '}
          <ThemedText type="defaultSemiBold">app</ThemedText> to{' '}
          <ThemedText type="defaultSemiBold">app-example</ThemedText>.
        </ThemedText>
      </ThemedView>
    </ParallaxScrollView>
  );
}

const styles = StyleSheet.create({
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  stepContainer: {
    gap: 8,
    marginBottom: 8,
  },
  reactLogo: {
    height: 178,
    width: 290,
    bottom: 0,
    left: 0,
    position: 'absolute',
  },
});
