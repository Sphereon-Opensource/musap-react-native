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
import {MusapKey, MusapModule} from "@sphereon/musap-react-native";


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
    // @ts-ignore
    const result = await kms.createKey({type: 'secp256r1'})
    console.log('kms.createKey() result', result)
    const encoder = new TextEncoder();
    const data = encoder.encode('test');
    console.log('>>>>>> App.tsx: encoded data', data);
    try {
      const keyUri = ((result as unknown as MusapKey).keyUri as any).uri
      console.log('getting the keyUri:', keyUri)
      const signresult = await kms.sign({data, keyRef: {kid: keyUri}})
      console.log('signresult', signresult)
    } catch (error) {
      console.log('>>>>>> App.tsx:', error)
    }
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
