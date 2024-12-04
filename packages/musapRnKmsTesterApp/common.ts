import {
  MusapClient,
  MusapKey,
  signatureAlgorithmFromKeyAlgorithm,
  SignatureReq,
  SscdInfo,
} from '@sphereon/musap-react-native';

export const sign = async (
  key: MusapKey,
  jwtHeaderAndPayload: string,
  sscdInfo: SscdInfo,
  attributes?: {name: string; value: string}[],
) => {
  console.log('key.keyUri', key.keyUri);
  const req: SignatureReq = {
    keyUri: key.keyUri,
    data: jwtHeaderAndPayload,
    displayText: 'Please enter your pin to sign with your eSim',
    format: 'RAW',
    algorithm: signatureAlgorithmFromKeyAlgorithm(key.algorithm),
    ...(attributes && {attributes}),
  };
  console.log('NOKMS signatureReq', JSON.stringify(req));
  try {
    const signature = await MusapClient.sign(req);
    const jwt = `${jwtHeaderAndPayload}.${signature}`;
    console.log('NOKMS Data successfully signed:');
    console.log('jwt', jwt);
  } catch (e) {
    console.log('NOKMS An error occurred.\n');
    console.log(e);
  }
};

export const jwtPayloadTiny = {
  iss: 'test_issuer',
};

export const jwtPayload = {
  iss: 'test_issuer',
  sub: 'test_subject',
  aud: 'test_audience',
  iat: Math.floor(Date.now()),
  exp: Math.floor(Date.now()) + 1000 * 180,
  vp: {
    '@context': [
      'https://www.w3.org/2018/credentials/v1',
      'https://identity.foundation/presentation-exchange/submission/v1',
    ],
    presentation_submission: {
      id: 'accd5adf-1dbf-4ed9-9ba2-d687476126cb',
      definition_id: '31e2f0f1-6b70-411d-b239-56aed5321884',
      descriptor_map: [
        {
          id: '867bfe7a-5b91-46b2-9ba4-70028b8d9cc8',
          format: 'ldp_vp',
          path: '$.verifiableCredential[0]',
        },
      ],
    },
    type: ['VerifiablePresentation', 'PresentationSubmission'],
    verifiableCredential: [
      {
        '@context': ['https://www.w3.org/2018/credentials/v1'],
        credentialSchema: [
          {
            id: 'https://www.w3.org/TR/vc-data-model/#types',
          },
        ],
        credentialSubject: {
          age: 19,
          details: {
            citizenship: ['eu'],
          },
          country: [
            {
              abbr: 'NLD',
            },
          ],
          birthPlace: 'Maarssen',
        },
        id: '2dc74354-e965-4883-be5e-bfec48bf60c7',
        issuer: '',
        type: ['VerifiableCredential'],
        proof: {
          type: 'BbsBlsSignatureProof2020',
          created: '2020-04-25',
          verificationMethod: 'did:example:489398593#test',
          proofPurpose: 'assertionMethod',
          proofValue:
            'kTTbA3pmDa6Qia/JkOnIXDLmoBz3vsi7L5t3DWySI/VLmBqleJ/Tbus5RoyiDERDBEh5rnACXlnOqJ/U8yFQFtcp/mBCc2FtKNPHae9jKIv1dm9K9QK1F3GI1AwyGoUfjLWrkGDObO1ouNAhpEd0+et+qiOf2j8p3MTTtRRx4Hgjcl0jXCq7C7R5/nLpgimHAAAAdAx4ouhMk7v9dXijCIMaG0deicn6fLoq3GcNHuH5X1j22LU/hDu7vvPnk/6JLkZ1xQAAAAIPd1tu598L/K3NSy0zOy6obaojEnaqc1R5Ih/6ZZgfEln2a6tuUp4wePExI1DGHqwj3j2lKg31a/6bSs7SMecHBQdgIYHnBmCYGNQnu/LZ9TFV56tBXY6YOWZgFzgLDrApnrFpixEACM9rwrJ5ORtxAAAAAgE4gUIIC9aHyJNa5TBklMOh6lvQkMVLXa/vEl+3NCLXblxjgpM7UEMqBkE9/QcoD3Tgmy+z0hN+4eky1RnJsEg=',
          nonce:
            '6i3dTz5yFfWJ8zgsamuyZa4yAHPm75tUOOXddR6krCvCYk77sbCOuEVcdBCDd/l6tIY=',
        },
      },
    ],
  },
};

export function clearKeystore() {
  console.log('DIRECT Clearing keystore');
  const allKeys: MusapKey[] = MusapClient.listKeys();
  for (const key of allKeys) {
    console.log('Removing key ', key.keyUri);
    MusapClient.removeKey(key.keyUri);
  }
}
