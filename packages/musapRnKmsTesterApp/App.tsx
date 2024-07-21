/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React from 'react';
import type {PropsWithChildren} from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  useColorScheme,
  View,
} from 'react-native';

import {
  Colors,
  DebugInstructions,
  Header,
  LearnMoreLinks,
  ReloadInstructions,
} from 'react-native/Libraries/NewAppScreen';
import {MusapKeyManagementSystem} from "@sphereon/ssi-sdk-ext.musap-rn-kms/dist/agent/MusapKeyManagerSystem";
import {KeyGenReq, MusapKey, MusapModule, SignatureReq, SscdInfo} from "@sphereon/musap-react-native";
import uuid from 'react-native-uuid';


type SectionProps = PropsWithChildren<{
  title: string;
}>;

function Section({children, title}: SectionProps): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
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
  );
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

    try {
        const keyUri = await MusapModule.generateKey('TEE', keyGenRequest)
        console.log(`Key successfully generated: ${keyUri}`)

        console.log(MusapModule.listKeys())

        // Works on Android
        const key = MusapModule.getKeyByUri(keyUri) as MusapKey

        console.log(`NOKMS GetKeyByUri(): ${key}`)
        console.log(`NOKMS key`, key)
        sign(key, jwt, sscdInfo);
    } catch (e) {
        console.error('generateKey failed', e)
    }
}


const sign = async (key: MusapKey, jwt: object, sscdInfo: SscdInfo) => {
    const req: SignatureReq = {
        key,
        data: JSON.stringify(jwt),
        displayText: "test",
        format: 'RAW',
        attributes: [{name: "key", value: "value"}],
    }
    //const reqData = sscdInfo.sscdName === "SE" ? req : JSON.stringify(req)
    console.log('NOKMS signatureReq', JSON.stringify(req))
    try {
        const result = await MusapModule.sign(req)
        console.log("NOKMS Data successfully signed:")
        console.log(result)
    } catch (e) {
        console.log("NOKMS An error occurred.\n")
        console.log(e)
    }
};


function App(): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };



  MusapModule.enableSscd('TEE')
    const sscds = MusapModule.listEnabledSscds();
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
        console.log('generateKey result', value);
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
    noKMSRun(sscdInfo);

    //console.log(MusapModule.listEnabledSscds());

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar
        barStyle={isDarkMode ? 'light-content' : 'dark-content'}
        backgroundColor={backgroundStyle.backgroundColor}
      />
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        style={backgroundStyle}>
        <Header />
        <View
          style={{
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
          }}>
          <Section title="Step One">
            Edit <Text style={styles.highlight}>App.tsx</Text> to change this
            screen and then come back to see your edits.
          </Section>
          <Section title="See Your Changes">
            <ReloadInstructions />
          </Section>
          <Section title="Debug">
            <DebugInstructions />
          </Section>
          <Section title="Learn More">
            Read the docs to discover what to do next:
          </Section>
          <LearnMoreLinks />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
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
});

export default App;
