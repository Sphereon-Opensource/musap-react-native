import {NativeModules} from "react-native";

interface MusapModuleType {
    listEnabledSscds(): string;
}

const { MusapModule } = NativeModules;
export default MusapModule as MusapModuleType;
