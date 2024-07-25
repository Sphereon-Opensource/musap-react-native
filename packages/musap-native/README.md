<h1 align="center">
  <br>
  <a href="https://www.sphereon.com"><img src="https://sphereon.com/content/themes/sphereon/assets/img/logo.svg" alt="Sphereon" width="400"></a>
  <br>MUSAP NPM Package Wrapper
  <br>
</h1>

---

### Overview

This package wraps the Methics MUSAP (Mobile Universal Signing Application Protocol) libraries for iOS and Android, making them easily accessible in NPM projects, particularly for React Native applications.
It is a dependency of package [musap-react-native](../musap-react-native)

### Source Repositories

The wrapper includes code from the following Methics MUSAP GitHub repositories:
- iOS: https://github.com/methics/musap-ios
- Android: https://github.com/methics/musap-android

### Package Contents

- **Android**: Includes an embedded Maven repository.
- **iOS**: Contains the iOS native code with an extra podspec descriptor for easier linking in React Native pod projects.

### Installation

The iOS Git repository is mounted as a submodule in `packages/musap-native/musap-ios.github`. After cloning this repository, execute the following commands:

```shell
git submodule update --init --recursive
```

#### Updating iOS Library Version

To update the musap-ios library to the latest version:

```shell
git pull --recurse-submodules
git submodule update --remote --merge
```


### License
This project is licensed under the Apache-2 License.
