<h1 align="center">
  <br>
  <a href="https://www.sphereon.com"><img src="https://sphereon.com/content/themes/sphereon/assets/img/logo.svg" alt="Sphereon" width="400"></a>
  <br>Test application for the MUSAP React Native module
  <br>
</h1>

---

# About This Application

This test application is designed to demonstrate and validate the functionality of the MUSAP (Mobile Universal Signing Application Protocol) React Native module. MUSAP is a library that provides a standardized way to interact with various secure signature creation devices (SSCDs) and key management systems (KMS) in mobile environments.

## Key Features

1. **SSCD Integration**: The app tests the integration with Trusted Execution Environment (TEE) as an SSCD.
2. **Key Management**: Demonstrates key generation, retrieval, and deletion using both direct MUSAP module calls and a Key Management System (KMS).
3. **JWT Signing**: Shows the process of creating and signing JSON Web Tokens (JWTs) using generated keys.
4. **Multiple Test Scenarios**: Includes both direct MUSAP module testing (`testRunDirect`) and KMS-based testing (`kmsTestRun`).

## What This App Does

When you run this application:

1. It initializes the MUSAP module and enables the TEE SSCD.
2. Generates cryptographic keys using both direct MUSAP calls and the KMS.
3. Creates a sample JWT payload and header.
4. Signs the JWT using the generated keys.
5. Outputs the signed JWT to the console.
6. Demonstrates key deletion and error handling.

This process helps verify that all components of the MUSAP ecosystem are working correctly together in a React Native environment.

# Getting Started



## Step 1: Start the Metro Server

First, you will need to start **Metro**, the JavaScript _bundler_ that ships _with_ React Native.

To start Metro, run the following command from the _root_ of your React Native project:

```bash
# using npm
npm start

# OR using Yarn
yarn start
```

## Step 2: Start your Application

Let Metro Bundler run in its _own_ terminal. Open a _new_ terminal from the _root_ of your React Native project. Run the following command to start your _Android_ or _iOS_ app:

### For Android

```bash
# using npm
npm run android

# OR using Yarn
yarn android
```

### For iOS

```bash
# using npm
npm run ios

# OR using Yarn
yarn ios
```

If everything is set up _correctly_, you should see your new app running in your _Android Emulator_ or _iOS Simulator_ shortly provided you have set up your emulator/simulator correctly.

This is one way to run your app — you can also run it directly from within Android Studio and Xcode respectively.


### Test output

When all goes well the console log spits out a verifiable JWT
```
 LOG  jwt eyJ0eXAiOiJKV1QiLCJraWQiOiIyMjJGQzZGMi1COUY0LTQzNDQtOUFGNi03QTkzOTdCNDJENTciLCJhbGciOiJFUzI1NiIsImp3ayI6eyJrdHkiOiJFQyIsImNydiI6IlAtMjU2IiwieCI6IjV4bnFjcEg0dGxQZjFZMzdSRERLbGRheUJuVFhVeDRQU0ZEWUlvVUxYTjQiLCJ5IjoiVG5uRmwtcEM5anRqZk1NN3AyUkxxNDB5VU52dS03d3hlZ1RlRWtTUGlHVSIsInVzZSI6InNpZyJ9fQ.eyJpc3MiOiJ0ZXN0X2lzc3VlciIsInN1YiI6InRlc3Rfc3ViamVjdCIsImF1ZCI6InRlc3RfYXVkaWVuY2UiLCJpYXQiOjE3MjE5MDQ0NzIyMzEsImV4cCI6MTcyMTkwNDY1MjIzMSwidnAiOnsiQGNvbnRleHQiOlsiaHR0cHM6Ly93d3cudzMub3JnLzIwMTgvY3JlZGVudGlhbHMvdjEiLCJodHRwczovL2lkZW50aXR5LmZvdW5kYXRpb24vcHJlc2VudGF0aW9uLWV4Y2hhbmdlL3N1Ym1pc3Npb24vdjEiXSwicHJlc2VudGF0aW9uX3N1Ym1pc3Npb24iOnsiamndci46MzFlMmYwZjEtNmI3MC00MTFkLWIyMzktNTZhZWQ1MzIxODg0IiwiZGVzY3JpcHRvcl9tYXAiOlt7ImlkIjoiODY3YmZlN2EtNWI5MS00NmIyLTliYTQtNzAwMjhiOGQ5Y2M4IiwiZm9ybWF0IjoibGRwX3ZwIiwicGF0aCI6IiQudmVyaWZpYWJsZUNyZWRlbnRpYWxbMF0ifV19LCJ0eXBlIjpbIlZlcmlmaWFibGVQcmVzZW50YXRpb24iLCJQcmVzZW50YXRpb25TdWJtaXNzaW9uIl0sInZlcmlmaWFibGVDcmVkZW50aWFsIjpbeyJAY29udGV4dCI6WyJodHRwczovL3d3dy53My5vcmcvMjAxOC9jcmVkZW50aWFscy92MSJdLCJjcmVkZW50aWFsU2NoZW1hIjpbeyJpZCI6Imh0dHBzOi8vd3d3LnczLm9yZy9UUi92Yy1kYXRhLW1vZGVsLyN0eXBlcyJ9XSwiY3JlZGVudGlhbFN1YmplY3QiOnsiYWdlIjoxOSwiZGV0YWlscyI6eyJjaXRpemVuc2hpcCI6WyJldSJdfSwiY291bnRyeSI6W3siYWJiciI6Ik5MRCJ9XSwiYmlydGhQbGFjZSI6Ik1hYXJzc2VuIn0sImlkIjoiMmRjNzQzNTQtZTk2NS00ODgzLWJlNWUtYmZlYzQ4YmY2MGM3IiwiaXNzdWVyIjoiIiwidHlwZSI6WyJWZXJpZmlhYmxlQ3JlZGVudGlhbCJdLCJwcm9vZiI6eyJ0eXBlIjoiQmJzQmxzU2lnbmF0dXJlUHJvb2YyMDIwIiwiY3JlYXRlZCI6IjIwMjAtMDQtMjUiLCJ2ZXJpZmljYXRpb25NZXRob2QiOiJkaWQ6ZXhhbXBsZTo0ODkzOTg1OTMjdGVzdCIsInByb29mUHVycG9zZSI6ImFzc2VydGlvbk1ldGhvZCIsInByb29mVmFsdWUiOiJrVFRiQTNwbURhNlFpYS9Ka09uSVhETG1vQnozdnNpN0w1dDNEV3lTSS9WTG1CcWxlSi9UYnVzNVJveWlERVJEQkVoNXJuQUNYbG5PcUovVTh5RlFGdGNwL21CQ2MyRnRLTlBIYWU5aktJdjFkbTlLOVFLMUYzR0kxQXd5R29VZmpMV3JrR0RPYk8xb3VOQWhwRWQwK2V0K3FpT2YyajhwM01UVHRSUng0SGdqY2wwalhDcTdDN1I1L25McGdpbUhBQUFBZEF4NG91aE1rN3Y5ZFhpakNJTWFHMGRlaWNuNmZMb3EzR2NOSHVINVgxajIyTFUvaER1N3Z2UG5rLzZKTGtaMXhRQUFBQUlQZDF0dTU5OEwvSzNOU3kwek95Nm9iYW9qRW5hcWMxUjVJaC82WlpnZkVsbjJhNnR1VXA0d2VQRXhJMURHSHF3ajNqMmxLZzMxYS82YlNzN1NNZWNIQlFkZ0lZSG5CbUNZR05RbnUvTFo5VEZWNTZ0QlhZNllPV1pnRnpnTERyQXBuckZwaXhFQUNNOXJ3cko1T1J0eEFBQUFBZ0U0Z1VJSUM5YUh5Sk5hNVRCa2xNT2g2bHZRa01WTFhhL3ZFbCszTkNMWGJseGpncE03VUVNcUJrRTkvUWNvRDNUZ215K3owaE4rNGVreTFSbkpzRWc9Iiwibm9uY2UiOiI2aTNkVHo1eUZmV0o4emdzYW11eVphNHlBSFBtNzV0VU9PWGRkUjZrckN2Q1lrNzdzYkNPdUVWY2RCQ0RkL2w2dElZPSJ9fV19fQ.S4kpCAafwR-0wVmXBRn0ThEoZ4GOCpCbkmxcZGSuUvCp-udKwG5N6BShHDpKnHbMtO1MUpwcrNZAz8bDsRgFNA
```

This JWT can be decoded and verified using tools like [jwt.io](https://jwt.io/) to confirm the correct functioning of the MUSAP module.

>**Note**: This code is still under construction. The end goal is to enable detox for testing, but this is not yet functional.


For more information about MUSAP and its capabilities, please visit [Methics's website](https://www.methics.fi/musap/).  
For more information about credential wallets & SSI technology, please visit [Sphereon's website](https://www.sphereon.com).



### License
This project is licensed under the Apache-2 License.
