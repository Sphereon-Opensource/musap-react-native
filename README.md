<h1 align="center">
  <br>
  <a href="https://www.sphereon.com"><img src="https://sphereon.com/content/themes/sphereon/assets/img/logo.svg" alt="Sphereon" width="400"></a>
  <br>MUSAP Library wrapper for React Native
  <br>
</h1>

---

This is a mono-repository containing modules to wrap the MUSAP libraries for Android & iOS and 
contains a bridge module for React Native.

### Packages
- [musap-native](./packages/musap-native/README.md): NPM package wrapper which makes the module easier to link in a React Native pods project.
- [musap-react-native](./packages/musap-react-native/README.md): The React Native bridge code resulting in a NPM package
- [musapRnKmsTesterApp](./packages/musapRnKmsTesterApp/README.md): An interactive test application where the MUSAP React Native libraries are tested.


Package musap-native contains a git sub-module, so after cloning the following commands should be executed: 
```shell
git submodule update --init --recursive
```
For details see package [musap-native README](./packages/musap-native/README.md)

### Usage
Detailed usage of the API can be found [here - musap-react-native](./packages/musap-react-native/README.md)
The [test application](./packages/musapRnKmsTesterApp/README.md) shows how to use the library to sign a JWT.

### License
This project is licensed under the Apache-2 License.

### Support
If you encounter any issues or have questions, please file an issue on our GitHub issue tracker.
