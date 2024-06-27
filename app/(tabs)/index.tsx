import { Image, StyleSheet, Platform } from 'react-native';

import { HelloWave } from '@/components/HelloWave';
import ParallaxScrollView from '@/components/ParallaxScrollView';
import { ThemedText } from '@/components/ThemedText';
import { ThemedView } from '@/components/ThemedView';
import {KeyGenReq, MusapModule} from '@/types/musap-types';

export default function HomeScreen() {

    MusapModule?.enableSscd('SECURITY_ENCLAVE')
    const listEnabledSscds = MusapModule?.listEnabledSscds()
    const listActiveSscds = MusapModule?.listActiveSscds()
    try {
        console.log(`active SSCDs: ${JSON.stringify(listActiveSscds)}\n\n`)
        console.log(`enabled SSCDs: ${JSON.stringify(listEnabledSscds)}\n\n`)

        const musapSscd = listEnabledSscds[0]
        console.log(JSON.stringify(Object.keys((musapSscd))))

        const keyGenRequest: KeyGenReq = {
            attributes: [
                { name: 'purpose', value: 'encrypt' },
                { name: 'purpose', value: 'decrypt' }
            ],
            did: 'did:example:123456789abcdefghi',
            // we cannot just use the values from the SSCD, MUSAP may be expecting something different
            keyAlgorithm: { primitive: "EC", curve: "ecc_p256_k1", bits: 256 },
            keyAlias: "testKey6", // Alias must be unique, at least for iOS otherwise error code 900 is thrown
            keyUsage: "sign",
            role: "administrator",
        }

        console.log(`Generating key for sscdId ${musapSscd.sscdId}...\n`)
        MusapModule.generateKey(musapSscd.sscdId, keyGenRequest, console.log)

     } catch(e) {
        console.log("Catch clause entered")
        console.log(e)
        console.log((e as Error).message)
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
