import {
  DecryptionReq,
  EncryptionReq,
  KeyGenReq,
  MusapClient,
} from '@sphereon/musap-react-native';
import {clearKeystore} from './common';
import uuid from 'react-native-uuid';

export const encryptionTestRun = async () => {
  MusapClient.enableSscd('TEE');

  const generateKey = async () => {
    const keyGenRequest: KeyGenReq = {
      attributes: [],
      keyAlgorithm: 'AES',
      keyAlias: uuid.v4().toString(), // Alias must be unique, at least for iOS otherwise error code 900 is thrown
      keyUsage: 'encrypt,decrypt',
      role: 'administrator',
    };

    console.log('ENC/DEC keyGenRequest:', keyGenRequest);
    const keyUri = await MusapClient.generateKey('TEE', keyGenRequest);
    console.log(`ENC/DEC Key successfully generated: ${keyUri}`);

    console.log('ENC/DEC ListKeys', MusapClient.listKeys());
    return keyUri;
  };

  try {
    clearKeystore();
    const keyUri = await generateKey();

    const textEncoder = new TextEncoder();
    const salt = fromByteArray(textEncoder.encode('123456'));
    const payload = textEncoder.encode('Hello World!');
    const encryptReq = {
      keyUri: keyUri,
      base64Data: fromByteArray(payload),
      base64Salt: salt,
    } satisfies EncryptionReq;

    console.log('calling encryptData', encryptReq);
    const encDataBase64: string = await MusapClient.encryptData(encryptReq);
    const encData = toByteArray(encDataBase64);
    console.log('encryptedData', encData);

    const decryptReq = {
      keyUri: keyUri,
      base64Data: encDataBase64,
      base64Salt: salt,
    } satisfies DecryptionReq;
    console.log('calling decryptData', decryptReq);
    const decDataBase64 = await MusapClient.decryptData(decryptReq);
    const decData = toByteArray(decDataBase64);
    const decText = decodeUTF8(decData); // TextDecoder is unavailable
    console.log('decText', decText);
    if (decText !== 'Hello World!') {
      throw Error('encrypt / decrypt data not equal');
    }
  } catch (e) {
    console.error('ENC/DEC failed', e);
  }
};

const fromByteArray = (uint8Array: Uint8Array): string => {
  let binary = '';
  const len = uint8Array.byteLength;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(uint8Array[i]);
  }
  return btoa(binary);
};

const toByteArray = (base64: string): Uint8Array => {
  const binaryString = atob(base64);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
};

const decodeUTF8 = (bytes: Uint8Array): string => String.fromCharCode.apply(null, Array.from(bytes));
