import {NativeModules} from "react-native";

interface MusapCallback<T> {
    onSuccess: (var1: T) => void
    onException: (var1: Error) => void
}

interface MusapModuleType {
    listEnabledSscds(): any;
    listActiveSscds(): any;
    // FIXME must be fixed when the typescript code is generated
    generateKey (sscd: unknown, req: unknown, callBack: MusapCallback<any>): Promise<void>
    sign(req: unknown, calback: Function): void
}

const { MusapModule } = NativeModules;
export default MusapModule as MusapModuleType;
