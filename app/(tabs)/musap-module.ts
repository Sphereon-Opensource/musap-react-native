import {NativeModules} from "react-native";

interface MusapModuleType {
    listEnabledSscdsAsJson(): string;
    listActiveSscdsAsJson(): string;
}

const { MusapModule } = NativeModules;
export default MusapModule as MusapModuleType;
