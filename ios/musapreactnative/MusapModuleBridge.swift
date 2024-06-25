//
//  MusapModuleBridge.swift
//  musapreactnative
//
//  Created by Zoë Maas on 20/06/2024.
//
import Foundation
//
//  MusapModuleBridge.swift
//  musapreactnative
//
//  Created by Zoë Maas on 20/06/2024.
//
import Foundation
import React
import musap_ios

@objc(MusapModule)
class MusapModule: NSObject {

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return false
  }

  override init() {
    super.init()
  }

  @objc
  func generateKey(_ sscdID: String, req: NSDictionary, callback: @escaping RCTResponseSenderBlock) {
      guard let sscd = MusapClient.listEnabledSscds()?.first(where: { $0.getSscdId() == sscdID }) else {
        callback(["Error: SSCD not found"])
        return
      }

      let musapCallback: (Result<MusapKey, MusapError>) -> Void = { result in
        switch result {
        case .success(let musapKey):
          callback(["Key successfully created: \(musapKey.getKeyId())"])
        case .failure(let error):
          callback(["Error creating key: \(error.localizedDescription)"])
        }
      }

      let reqObj = req.toKeyGenReq()
      Task {
        await MusapClient.generateKey(sscd: sscd, req: reqObj, completion: musapCallback)
      }
    }

  @objc
  func sign(_ req: NSDictionary, callback: @escaping RCTResponseSenderBlock) {
    do {
      let reqObj = try req.toSignatureReq()
      
      let musapCallback: (Result<MusapSignature, MusapError>) -> Void = { result in
        switch result {
        case .success(let musapSignature):
          callback(["Data successfully signed: \(musapSignature.getB64Signature())"])
        case .failure(let error):
          callback(["Error signing the data: \(error.localizedDescription)"])
        }
      }
      
      Task {
        await MusapClient.sign(req: reqObj, completion: musapCallback)
      }
    } catch let error {
      callback(["Error signing the data: \(error.localizedDescription)"])
    }
  }

  @objc
  func listEnabledSscds(_ resolver: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
    guard let sscds = MusapClient.listEnabledSscds() else {
      reject("Error", "Unable to list enabled SSCDs", nil)
      return
    }
    let sscdList = sscds.map { $0.toWritableMap() }
    resolver(sscdList)
  }

  @objc
  func listActiveSscds(_ resolver: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
    let sscds = MusapClient.listActiveSscds()
    let sscdList = sscds.map { $0.toWritableMap() }
    resolver(sscdList)
  }
}


extension NSDictionary {
  func toKeyGenReq() -> KeyGenReq {
    let keyAlias = self["keyAlias"] as? String ?? ""
    let did = self["did"] as? String
    let role = self["role"] as? String ?? ""
    let stepUpPolicy = self["stepUpPolicy"] != nil ? StepUpPolicy() : nil
    
    var attributes: [KeyAttribute]?
    if let attributesArray = self["attributes"] as? [[String: Any]] {
      attributes = attributesArray.compactMap { attributeMap in
        if let name = attributeMap["name"] as? String, let certDataBase64 = attributeMap["value"] as? String {
          if let certData = Data(base64Encoded: certDataBase64),
             let cert = SecCertificateCreateWithData(nil, certData as CFData) {
            return KeyAttribute(name: name, cert: cert)
          }
        }
        return nil
      }
    }
  
    var keyAlgorithm: KeyAlgorithm?
    if let keyAlgorithmMap = self["keyAlgorithm"] as? [String: Any],
       let primitive = keyAlgorithmMap["primitive"] as? String,
       let bits = keyAlgorithmMap["bits"] as? Int {
      let curve = keyAlgorithmMap["curve"] as? String
      keyAlgorithm = curve != nil ? KeyAlgorithm(primitive: primitive, curve: curve!, bits: bits) : KeyAlgorithm(primitive: primitive, bits: bits)
    }

    return KeyGenReq(
      keyAlias: keyAlias,
      did: did,
      role: role,
      stepUpPolicy: stepUpPolicy,
      attributes: attributes,
      keyAlgorithm: keyAlgorithm
    )
  }

  func toSignatureReq() throws -> SignatureReq {
    let algorithmString = self["algorithm"] as? String ?? "SHA256withECDSA"
    let algorithm: SecKeyAlgorithm

    switch algorithmString {
    case "SHA256withECDSA":
      algorithm = SignatureAlgorithm.SHA256withECDSA
    case "SHA384withECDSA":
      algorithm = SignatureAlgorithm.SHA384withECDSA
    case "SHA512withECDSA":
      algorithm = SignatureAlgorithm.SHA512withECDSA
    case "SHA256withRSA":
      algorithm = SignatureAlgorithm.SHA256withRSA
    case "SHA384withRSA":
      algorithm = SignatureAlgorithm.SHA384withRSA
    case "SHA512withRSA":
      algorithm = SignatureAlgorithm.SHA512withRSA
    case "SHA256withRSAPSS":
      algorithm = SignatureAlgorithm.SHA256withRSAPSS
    case "SHA384withRSAPSS":
      algorithm = SignatureAlgorithm.SHA384withRSAPSS
    case "SHA512withRSAPSS":
      algorithm = SignatureAlgorithm.SHA512withRSAPSS
    default:
      algorithm = SignatureAlgorithm.SHA256withECDSA
    }

    var key: MusapKey? = nil

    if let keyMap = self["key"] as? [String: Any] {
      var publicKey: PublicKey? = nil
      if let publicKeyBase64 = keyMap["publicKey"] as? String,
         let publicKeyData = Data(base64Encoded: publicKeyBase64) {
        publicKey = PublicKey(publicKey: publicKeyData)
      } else if let publicKeyBytes = keyMap["publicKey"] as? [UInt8] {
        let publicKeyData = Data(publicKeyBytes)
        publicKey = PublicKey(publicKey: publicKeyData)
      }
      
      if(publicKey == nil) {
        throw SignatureReqError.invalidPublicKey
      }
      
      let certificate: MusapCertificate? = (keyMap["certificate"] as? String).flatMap { certBase64 in
          if let certData = Data(base64Encoded: certBase64),
             let cert = SecCertificateCreateWithData(nil, certData as CFData) {
              return MusapCertificate(cert: cert)
          }
          return nil
      }

      let certificateChain: [MusapCertificate]? = (keyMap["certificateChain"] as? [String])?.compactMap { certBase64 in
          if let certData = Data(base64Encoded: certBase64),
             let cert = SecCertificateCreateWithData(nil, certData as CFData) {
              return MusapCertificate(cert: cert)
          }
          return nil
      }
   
      var attributes: [KeyAttribute]?
      if let attributesArray = self["attributes"] as? [[String: Any]] {
        attributes = attributesArray.compactMap { attributeMap in
          if let name = attributeMap["name"] as? String, let certDataBase64 = attributeMap["value"] as? String {
            if let certData = Data(base64Encoded: certDataBase64),
               let cert = SecCertificateCreateWithData(nil, certData as CFData) {
              return KeyAttribute(name: name, cert: cert)
            }
          }
          return nil
        }
      }

     let keyUsages: [String]? = keyMap["keyUsages"] as? [String]

     let loa: [MusapLoa]? = (keyMap["loa"] as? [[String: Any]])?.compactMap { loaMap in
         if let loa = loaMap["loa"] as? String, let number = loaMap["number"] as? Int, let scheme = loaMap["scheme"] as? String {
             return MusapLoa(loa: loa, number: number, scheme: scheme)
         }
         return nil
     }

     let keyUri: KeyURI? = (keyMap["keyUri"] as? String).flatMap { KeyURI(keyUri: $0) }

      let createdDateString = keyMap["createdDate"] as? String
      let createdDate: Date
      if let createdDateString = createdDateString {
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd"
          if let date = dateFormatter.date(from: createdDateString) {
              createdDate = date
          } else {
              createdDate = Date() // Default to current date if parsing fails
          }
      } else {
          createdDate = Date() // Default to current date if not provided
      }

      let isBiometricRequired = keyMap["isBiometricRequired"] as? Bool ?? false

      
      key = MusapKey(
        keyAlias: keyMap["keyAlias"] as? String ?? "",
        keyType: keyMap["keyType"] as? String,
        keyId: keyMap["keyId"] as? String,
        sscdId: keyMap["sscdId"] as? String,
        sscdType: keyMap["sscdType"] as? String ?? "",
        createdDate: createdDate,
        publicKey: publicKey!,
        certificate: certificate,
        certificateChain: certificateChain,
        attributes: attributes,
        keyUsages: keyUsages,
        loa: loa,
        algorithm: KeyAlgorithm.fromString(keyMap["algorithm"] as! String),
        keyUri: keyUri,
        isBiometricRequired: isBiometricRequired,
        did: keyMap["did"] as? String,
        state: keyMap["state"] as? String)
    }
    

    var data: Data? = nil
    if let dataArray = self["data"] as? [Int] {
      data = Data(dataArray.map { UInt8($0) })
    }

    let displayText = self["displayText"] as? String ?? self["display"] as? String
    guard let format = self["format"] as? String else {
        throw SignatureReqError.invalidFormat
    }
    var attributes: [SignatureAttribute]?
    if let attributesArray = self["attributes"] as? [[String: Any]] {
      attributes = attributesArray.compactMap { attributeMap in
        if let name = attributeMap["name"] as? String, let value = attributeMap["value"] as? String {
          return SignatureAttribute(name: name, value: value)
        }
        return nil
      }
    }

    guard let format = self["format"] as? String else {
        throw SignatureReqError.invalidFormat
    }
    return SignatureReq(
        key: key!,
        data: data!,
        algorithm: SignatureAlgorithm(algorithm: algorithm),
        format: SignatureFormat.fromString(format: format),
        displayText: displayText!,
        attributes: attributes!
    )
  }
}

extension MusapSscd {
  func toWritableMap() -> NSDictionary {
    let writableMap = NSMutableDictionary()

    guard let sscdInfo = self.getSscdInfo() else {
      return writableMap
    }

    let supportedAlgorithms = NSMutableArray()
    sscdInfo.getSupportedAlgorithms().forEach {
      let algorithm = NSMutableDictionary()
      algorithm["curve"] = $0.curve
      algorithm["primitive"] = $0.primitive
      algorithm["bits"] = $0.bits
      algorithm["isRsa"] = $0.isRsa
      algorithm["isEc"] = $0.isEc
      supportedAlgorithms.add(algorithm)
    }

    let sscdInfoMap = NSMutableDictionary()
    sscdInfoMap["sscdId"] = sscdInfo.getSscdId()
    sscdInfoMap["sscdType"] = sscdInfo.getSscdType()
    sscdInfoMap["sscdName"] = sscdInfo.getSscdName()
    sscdInfoMap["country"] = sscdInfo.getCountry()
    sscdInfoMap["provider"] = sscdInfo.getProvider()
    sscdInfoMap["isKeyGenSupported"] = sscdInfo.isKeygenSupported()
    sscdInfoMap["supportedAlgorithms"] = supportedAlgorithms

    writableMap["sscdId"] = self.getSscdId()
    writableMap["sscdInfo"] = sscdInfoMap

    // Uncomment and adjust this block if you have settings to include
    // let settings = NSMutableDictionary()
    // self.getSettings()?.settings?.forEach {
    //   settings[$0.key] = $0.value
    // }
    // writableMap["settings"] = settings

    return writableMap
  }
}

import Foundation

extension KeyAlgorithm {
    public static func fromString(_ string: String) -> KeyAlgorithm? {
        switch string.lowercased() {
        case "rsa_1k":
            return KeyAlgorithm(primitive: KeyAlgorithm.PRIMITIVE_RSA, bits: 1024)
        case "rsa_2k":
            return KeyAlgorithm(primitive: KeyAlgorithm.PRIMITIVE_RSA, bits: 2048)
        case "rsa_4k":
            return KeyAlgorithm(primitive: KeyAlgorithm.PRIMITIVE_RSA, bits: 4096)
        case "ecc_p256_k1":
            return KeyAlgorithm(primitive: KeyAlgorithm.PRIMITIVE_EC, curve: KeyAlgorithm.CURVE_SECP256K1, bits: 256)
        case "ecc_p384_k1":
            return KeyAlgorithm(primitive: KeyAlgorithm.PRIMITIVE_EC, curve: KeyAlgorithm.CURVE_SECP384K1, bits: 384)
        case "ecc_p256_r1":
            return KeyAlgorithm(primitive: KeyAlgorithm.PRIMITIVE_EC, curve: KeyAlgorithm.CURVE_SECP256R1, bits: 256)
        case "ecc_p384_r1":
            return KeyAlgorithm(primitive: KeyAlgorithm.PRIMITIVE_EC, curve: KeyAlgorithm.CURVE_SECP384R1, bits: 384)
        default:
            return nil
        }
    }
}


enum SignatureReqError: Error {
    case invalidPublicKey
    case invalidFormat
    case missingRequiredField(String)
}
