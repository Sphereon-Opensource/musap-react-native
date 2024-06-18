import {NativeModules} from "react-native";
import {KeyGenReq, MusapKey, SscdInfo} from "@/types/musap-types";

const {MusapModule} = NativeModules;
MusapModule as MusapModuleType;


interface MusapModuleType {
    listEnabledSscdsInfos(): string;

    generateKey(sscdId: String, keyGenRequestPayload: String): string
}


export class MusapClient {
    public static listEnabledSscdsInfos(): Array<SscdInfo> {
        const listEnabledSscds = JSON.parse(MusapModule?.listEnabledSscdsInfos())
        return listEnabledSscds as Array<SscdInfo>
    }

    public static generateKey(sscdId: String, keyGenRequest: KeyGenReq): MusapKey {
        const keyPayload = MusapModule?.generateKey(sscdId, JSON.stringify(keyGenRequest))
        return JSON.parse(keyPayload) as MusapKey
    }
}
