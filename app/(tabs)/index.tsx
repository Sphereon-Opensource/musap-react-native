import { Image, StyleSheet, Platform } from 'react-native';

import { HelloWave } from '@/components/HelloWave';
import ParallaxScrollView from '@/components/ParallaxScrollView';
import { ThemedText } from '@/components/ThemedText';
import { ThemedView } from '@/components/ThemedView';
import MusapModule from "@/app/(tabs)/musap-module";

export default function HomeScreen() {
    const listEnabledSscds = MusapModule?.listEnabledSscds()
    try {
        console.log(listEnabledSscds)
        console.log(`sign: ${MusapModule.sign}`)
        console.log(`generateKey: ${MusapModule.generateKey}`)

        const sscdInfo = listEnabledSscds[0].sscdInfo
        console.log(`SscdInfo: ${JSON.stringify(sscdInfo)}`)

        const keyGenRequest: KeyGenReq = {
            attributes: [
                { name: 'purpose', value: 'encrypt' },
                { name: 'purpose', value: 'decrypt' }
            ],
            did: 'did:example:123456789abcdefghi',
            keyAlgorithm: {primitive: 'secp256r1', bits: 2048, curve: 'P-256'},
            keyAlias: "testKey",
            keyUsage: "sign",
            role: "admin",
        }

        console.log(`Generating key for sscdId ${sscdInfo.sscdId}`)
        const musapKey = MusapModule.generateKey(sscdInfo, keyGenRequest, {
              onSuccess: (data) => console.log(data),
            onException: (e) => new Error(`Cannot create key: ${JSON.stringify(e)}`)
        })
        console.log(JSON.stringify(musapKey))
    } catch(e) {
        console.log(JSON.stringify(e))
    }
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
