/** @type {Detox.DetoxConfig} */
module.exports = {
    testRunner: {
        args: {
            config: 'e2e/config.json',
        },
        forwardEnv: true,
    },
    apps: {
        "myApp.android": {
            "type": "android.apk",
            "binaryPath": "android/app/build/outputs/apk/debug/app-debug.apk",
            "build": "cd android && gradlew.bat assembleDebug assembleAndroidTest -DtestBuildType=debug && cd .."
        }
    },
    devices: {
        "attachedDevice": {
            "type": "android.attached",
            "device": {
                "adbName": "ZY22J2279M"
            }
        }
    },
    configurations: {
        "android.device.debug": {
            "device": "attachedDevice",
            "app": "myApp.android"
        }
    }
};
