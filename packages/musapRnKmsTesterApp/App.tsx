/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React from 'react';
import uuid from 'react-native-uuid'
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
import {KeyGenReq, MusapModule} from "@sphereon/musap-react-native";


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

function App(): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };



  MusapModule.enableSscd('TEE')

  const kms:MusapKeyManagementSystem = new MusapKeyManagementSystem(MusapModule)

  async function generateKey() {
    const keyGenRequest: KeyGenReq = {
      attributes: [
        {name: 'purpose', value: 'encrypt'},
        {name: 'purpose', value: 'decrypt'}
      ],
      did: 'did:example:123456789abcdefghi',
      keyAlgorithm: {primitive: "EC", curve: "secp256r1", bits: 256},
      keyAlias: uuid.v4().toString(), // Alias must be unique, at least for iOS otherwise error code 900 is thrown
      keyUsage: "sign",
      role: "administrator",
    }
    const result = await kms.createKey({type: 'Secp256r1', meta: {keyMetadata: keyGenRequest}})
    return result
  }

  generateKey()
      .then(value => console.log('generateKey', value))
      .catch(reason => {
        console.error(reason)
      })


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
