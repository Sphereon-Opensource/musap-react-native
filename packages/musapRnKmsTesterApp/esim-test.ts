import {
  ExternalSscdSettings,
  MusapClient,
  SscdInfo,
} from '@sphereon/musap-react-native';
import {jwtPayloadTiny, sign} from './common';
import {buildJwtHeaderAndPayload} from './jwt-functions';

export const testRunEsim = async () => {
  try {
    const sscdId = 'eSim Swisscom';
    const msisdn = '+41796861241';
    const couplingCode = '9QNZM8';

    const bindAttrs = [{name: 'msisdn', value: msisdn}];
    const signAttrs = [
      {name: 'msisdn', value: msisdn},
      {name: 'mimetype', value: 'application/x-sha256'},
      {name: 'signaturetype', value: 'pkcs1'},
    ];

    console.log('eSIM start');

    const sscds1 = MusapClient.listEnabledSscds();
    console.log('eSIM listEnabledSscds1', sscds1);

    let activeSscds = MusapClient.listActiveSscds();
    console.log('eSIM listActiveSscds', activeSscds);

    /*let sscdInfo: SscdInfo;
    if (sscds1.length === 0) {
      const settings: ExternalSscdSettings = {
        clientId: 'SCO',
        sscdName: sscdId,
        provider: 'eSim',
      };
      MusapClient.enableSscd('EXTERNAL', sscdId, settings);
    }*/

    activeSscds = MusapClient.listActiveSscds();
    console.log('eSIM listActiveSscds', activeSscds);

    /*  const existingKeys = MusapClient.listKeys();
    console.log(' existing keys', JSON.stringify(existingKeys));
*/
    const linkId = MusapClient.getLink();
    const mustActivate = linkId == null;
    if (linkId == null) {
      const musapId = await MusapClient.enableLink(
        'https://demo.methics.fi/sphereon/musaplink/musap?',
        null,
      );
      console.log('eSIM enabled link, musapId=', musapId);
    } else {
      console.log('eSIM Found existing link', linkId);
    }

    let sscdInfo: SscdInfo;
    if (sscds1.length === 0) {
      const settings: ExternalSscdSettings = {
        clientId: 'SCO',
        sscdName: sscdId,
        provider: 'eSim',
      };
      MusapClient.enableSscd('EXTERNAL', sscdId, settings);
      const sscds2 = MusapClient.listEnabledSscds();
      console.log('eSIM listEnabledSscds2', sscds2);
      sscdInfo = sscds2[0].sscdInfo;
    } else {
      sscdInfo = sscds1[0].sscdInfo;
    }

    const existingKeys = MusapClient.listKeys();
    console.log(`Found ${existingKeys.length} existing keys`);
    if (mustActivate || !existingKeys || existingKeys.length === 0) {
      console.log('eSIM cleaning up old keys');
      existingKeys
        .filter(value => value.keyAlias.startsWith('eSim-'))
        .forEach(value => {
          MusapClient.removeKey(value.keyUri);
        });

      const newLinkId = await MusapClient.coupleWithRelyingParty(couplingCode);
      console.log('eSIM Coupled with RP, linkId=', newLinkId);

      console.log('eSIM before bindKey()');
      const bindKeyResponse = await MusapClient.bindKey(sscdId, {
        keyAlias: `eSim-${Date.now()}`,
        attributes: bindAttrs,
        keyUsages: ['personal'],
      });
      console.log('eSIM bindKey():', bindKeyResponse);
    }

    console.log('eSIM listKeys()');
    const keys = MusapClient.listKeys();
    keys.forEach(value =>
      console.log(
        `eSIM listKeys() result: keyUri=${value.keyUri}, keyAlias=${value.keyAlias}, keyId=${value.keyId}, attributes=${value.attributes}`,
      ),
    );

    const jwtHeaderAndPayload = buildJwtHeaderAndPayload(
      keys[0],
      jwtPayloadTiny,
    );
    console.log('eSIM jwtHeaderAndPayload', jwtHeaderAndPayload);
    console.log('eSIM sign');
    await sign(keys[0], jwtHeaderAndPayload, sscdInfo, signAttrs);
  } catch (e) {
    console.error('eSim test failed', e);
  }
};
