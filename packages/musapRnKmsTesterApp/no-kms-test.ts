import {KeyGenReq, MusapKey, MusapClient} from '@sphereon/musap-react-native';
import uuid from 'react-native-uuid';
import {clearKeystore, jwtPayload, jwtPayloadTiny, sign} from './common';
import {buildJwtHeaderAndPayload} from './jwt-functions';

async function generateKey() {
  const keyGenRequest: KeyGenReq = {
    attributes: [
      {name: 'purpose', value: 'SIGN'},
      {name: 'purpose', value: 'VERIFY'},
    ],
    keyAlgorithm: 'ECCP256R1',
    keyAlias: uuid.v4().toString(), // Alias must be unique, at least for iOS otherwise error code 900 is thrown
    keyUsage: 'sign',
    role: 'administrator',
  };

  console.log('DIRECT keyGenRequest:', keyGenRequest);
  const keyUri = await MusapClient.generateKey('TEE', keyGenRequest);
  console.log(`DIRECT Key successfully generated: ${keyUri}`);

  console.log('DIRECT ListKeys', MusapClient.listKeys());
  return keyUri;
}

export const testRunDirect = async () => {
  console.log('DIRECT testRunDirect');

  try {
    MusapClient.enableSscd('TEE', 'TEE', undefined);
    console.log('DIRECT enabledSscd');
    const sscds = MusapClient.listEnabledSscds();
    console.log('DIRECT listEnabledSscds', sscds);
    const sscdInfo = sscds[0].sscdInfo;

    clearKeystore();
    console.log('DIRECT generateKey');
    const keyUri = await generateKey();

    const key = MusapClient.getKeyByUri(keyUri) as MusapKey;
    console.log(`DIRECT GetKeyByUri(): ${JSON.stringify(key)}`);
    const jwtHeaderAndPayload = buildJwtHeaderAndPayload(key, jwtPayloadTiny);
    console.log('DIRECT jwtHeaderAndPayload', jwtHeaderAndPayload);
    await sign(key, jwtHeaderAndPayload, sscdInfo);
  } catch (e) {
    console.error('DIRECT sign failed', e);
  }
};
