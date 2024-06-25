import {NativeModules} from "react-native";

interface MusapCallback<T> {
    onSuccess: (var1: T) => void
    onException: (var1: Error) => void
}

interface MusapModuleType {
    listEnabledSscds(): any;
    // FIXME must be fixed when the typescript code is generated
    generateKey (sscdId: String, req: unknown, callBack: Function): Promise<void>
}

const { MusapModule } = NativeModules;
export default MusapModule as MusapModuleType;
