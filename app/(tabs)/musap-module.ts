import {NativeModules} from "react-native";

interface MusapModuleType {
    listEnabledSscds(): string;
    // FIXME must be fixed when the typescript code is generated
    generateKey (sscd: unknown, req: unknown, callBack: unknown): Promise<void>
    enableSscd(sscd: unknown, sscdId: String): void
}

const { MusapModule } = NativeModules;
export default MusapModule as MusapModuleType;
