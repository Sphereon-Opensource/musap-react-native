import {MusapKey, MusapClient} from '@sphereon/musap-react-native';
import {MusapKeyManagementSystem} from '@sphereon/ssi-sdk-ext.kms-musap-rn';
import {jwtPayload} from './common';
import {buildJwtHeaderAndPayload} from './jwt-functions';
import uuid from 'react-native-uuid';

export const kmsTestRun = async () => {
  MusapClient.enableSscd('TEE');

  console.log('>>>>>>>>>>>>. kmsTestRun started!');
  const kms: MusapKeyManagementSystem = new MusapKeyManagementSystem();
  console.log('>>>>>>>>>>>>. kmsTestRun: KMS created!');

  try {
    const keyAlias: string = String(uuid.v4());
    const keyManagedInfo = await kms.createKey({
      type: 'Secp256r1',
      meta: {keyAlias: keyAlias},
    });
    console.log('KMS generateKey result keyUri', keyManagedInfo);

    const key = MusapClient.getKeyById(keyManagedInfo.kid) as MusapKey;
    console.log(`KMS GetKeyByUri(): ${JSON.stringify(key)}`);
    const jwtHeaderAndPayload = buildJwtHeaderAndPayload(key, jwtPayload);
    console.log('KMS jwtHeaderAndPayload', jwtHeaderAndPayload);

    const encoder = new TextEncoder();
    const data = encoder.encode(jwtHeaderAndPayload);

    try {
      const signature = await kms.sign({
        data,
        keyRef: {kid: keyManagedInfo.kid},
        algorithm: 'SHA256withECDSA',
      });
      console.log('KMS signature', signature);

      const jwt = `${jwtHeaderAndPayload}.${signature}`;
      console.log('jwt', jwt);
      console.log('NOKMS Data successfully signed:');
    } catch (error) {
      console.error('KMS error', error.stack);
    }

    console.log('KMS Deleted keyUri:', keyManagedInfo);
    kms.deleteKey({kid: keyManagedInfo.kid}).then(value => {
      console.log('KMS Key deleted:', value);

      try {
        const key = MusapClient.getKeyById(keyManagedInfo.kid);
        console.log('KMS Deleted key:', key);
      } catch (e) {
        console.log('KMS Deleted key error:', e.message);
      }
    });
  } catch (e) {
    console.error('KMS error', e.stack);
  }
};
