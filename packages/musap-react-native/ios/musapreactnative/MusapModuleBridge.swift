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
  func generateKey(_ sscdId: String, req: NSDictionary, completion: @escaping RCTResponseSenderBlock) {
      guard let sscd = MusapClient.listEnabledSscds()?.first(where: { $0.getSscdId() == sscdId }) else {
        completion(["Error: SSCD not found"])
        return
      }

      var completed = false
      let musapCallback: (Result<MusapKey, MusapError>) -> Void = { result in
        if(completed) {
          return
        }
        switch result {
        case .success(let musapKey):
          completed = true
          completion([musapKey.getKeyUri()?.getUri() ?? "No key URI"])
        case .failure(let error):
          completed = true
          /*
           Error codes:
             wrongParam: 101
             missingParam: 102
             invalidAlgorithm:  103
             unknownKey:        105
             unsupportedData:   107
             keygenUnsupported: 108
             bindUnsupported:   109
             timedOut:          208
             userCancel:        401
             keyBlocked:        402
             sscdBlocked:       403
             internalError:     900
             illegalArgument:   900
             * Duplicated unique value returns 900 too
           */
          completion(["Error creating key: \(error.localizedDescription): Error code: \(error.errorCode)"])
        }
      }

      do {
        let reqObj = try req.toKeyGenReq()
        Task {
          await MusapClient.generateKey(sscd: sscd, req: reqObj, completion: musapCallback)
        }
      } catch let error {
        completion(["Error creating key: \(error.localizedDescription)"])
      }
    }

  @objc
  func sign(_ req: NSDictionary, completion: @escaping RCTResponseSenderBlock) {
    do {
      let reqObj = try req.toSignatureReq()

      let key = reqObj.key
      let keyAlgo = key.getAlgorithm()
      let signatureAlgorithm = keyAlgo?.isEc() ?? false ? SignatureAlgorithm.SHA256withECDSA : SignatureAlgorithm.SHA256withRSA

      let musapCallback: (Result<MusapSignature, MusapError>) -> Void = { result in
        switch result {
        case .success(let musapSignature):
          NSLog("Signature \(musapSignature.getB64Signature())")
          let header = Data("{\"typ\":\"JWT\",\"kid\":\"\(String(describing: key.getKeyId()))\",\"alg\":\"\(signatureAlgorithm)\"}".utf8).base64EncodedString()
          let payload = reqObj.data.base64EncodedString()
          let signature = musapSignature.getRawSignature().base64EncodedString()
          completion(["\(header).\(payload).\(signature)"])
        case .failure(let error):
          completion(["Error signing the data: \(error.localizedDescription)"])
        }
      }

      Task {
        await MusapClient.sign(req: reqObj, completion: musapCallback)
      }
    } catch let error {
      completion(["Error signing the data: \(error.localizedDescription)"])
    }
  }

  @objc
  func enableSscd(_ sscdType: String) -> Any? { // -> Void crashes the app
      let sscd: any MusapSscdProtocol
      switch sscdType {
      case "TEE":
          sscd = SecureEnclaveSscd()
      case "YUBI_KEY":
          sscd = YubikeySscd()
      default:
          NSException(name: NSExceptionName.invalidArgumentException, reason: "Unsupported SSCD type", userInfo: nil).raise()
          return nil
      }
      MusapClient.enableSscd(sscd: sscd, sscdId: sscdType)
    return nil
  }

  @objc
  func listEnabledSscds() -> NSArray {
    guard let sscds = MusapClient.listEnabledSscds() else {
         return NSArray()
     }
    let sscdList = sscds.map{ $0.toNSDictionary() }
    return sscdList as NSArray
  }

  @objc
  func listActiveSscds() -> NSArray {
    let sscds = MusapClient.listActiveSscds()
    let sscdList = sscds.map { $0.toNSDictionary() }
    return sscdList as NSArray
  }

  @objc
  func getKeyByUri(_ keyUri: String) -> NSDictionary? {
    let result = MusapClient.getKeyByUri(keyUri: keyUri)
    NSLog("\(result.debugDescription)")
    return result?.toNSDictionary()
  }

  @objc
  func listKeys() -> NSArray {
      let keys = MusapClient.listKeys()
      let keysList = keys.map { $0.toNSDictionary() }
      print("keys: \(keysList)")
    return keysList as NSArray
  }

  @objc
  func getSscdInfo(_ sscdId: String) -> NSDictionary? {
    return MusapClient.listEnabledSscds()?.first { $0.getSscdId() == sscdId }?.getSscdInfo()?.toNSDictionary()
  }

  @objc
  func getSettings(_ sscdId: String) -> NSDictionary? {
    return MusapClient.listEnabledSscds()?.first { $0.getSscdId() == sscdId }?.getSettings() as? NSDictionary
  }
}

extension SscdInfo {
  func toNSDictionary() -> NSDictionary {

    let supportedAlgorithms = NSMutableArray()
    self.getSupportedAlgorithms().forEach {
      let algorithm = NSMutableDictionary()
      algorithm["curve"] = $0.curve
      algorithm["primitive"] = $0.primitive
      algorithm["bits"] = $0.bits
      algorithm["isRsa"] = $0.isRsa
      algorithm["isEc"] = $0.isEc
      supportedAlgorithms.add(algorithm)
    }

    let writableMap = NSMutableDictionary()
    writableMap["sscdName"] = self.getSscdName()
    writableMap["sscdType"] = self.getSscdType()
    writableMap["sscdId"] = self.getSscdId()
    writableMap["country"] = self.getCountry()
    writableMap["provider"] = self.getProvider()
    writableMap["keygenSupported"] = self.isKeygenSupported()
    writableMap["algorithms"] = supportedAlgorithms
    //writableMap["formats"] = nil //There is no accessor for formats
    return writableMap
  }
}

extension PublicKey {
  func toNSDictionary() -> NSDictionary {
    let writableMap = NSMutableDictionary()
    writableMap["publicKeyDer"] = self.getDER()
    return writableMap
  }
}

extension MusapCertificate {
  func toNSDictionary() -> NSDictionary {
    let writableMap = NSMutableDictionary()
    writableMap["subject"] = self.getSubject()
    writableMap["certificate"] = self.getCertificate()
    writableMap["publicKey"] = self.getPublicKey().toNSDictionary()
    return writableMap
  }
}

extension KeyAttribute {
  func toNSDictionary() -> NSDictionary {
    let writableMap = NSMutableDictionary()
    writableMap["name"] = self.getName()
    writableMap["value"] = self.getValue()
    return writableMap
  }
}

extension MusapLoa {
  func toNSDictionary() -> NSDictionary {
    let writableMap = NSMutableDictionary()
    writableMap["loa"] = self.getLoa()
    writableMap["scheme"] = self.getScheme()
    switch(self.getLoa()) {
    case "low", "loa1", "ial1", "aal1":
      writableMap["number"] = 1
    case "loa2", "ial2", "aal2":
      writableMap["number"] = 2
    case "substantial", "loa3", "ial3", "aal3":
      writableMap["number"] = 3
    case "high":
      writableMap["number"] = 4
    default:
      writableMap["number"] = nil
    }
    return writableMap
  }
}


extension KeyAlgorithm {
    func toEnumString() -> String {
        switch self {
        case .ECC_ED25519:
            return "ecc_ed25519"
        case .ECC_P256_K1:
            return "eccp256k1"
        case .ECC_P256_R1:
            return "eccp256r1"
        case .ECC_P384_K1:
            return "eccp384k1"
        case .ECC_P384_R1:
            return "eccp384r1"
        case .RSA_2K:
            return "rsa2k"
        case .RSA_4K:
            return "rsa4k"
        default:
            fatalError("Unknown KeyAlgorithm")
        }
    }
}

extension String {
    func toKeyAlgorithm() -> KeyAlgorithm? {
        return KeyAlgorithm.fromString(self)
    }
}


extension MusapKey {
  func toNSDictionary() -> NSDictionary {
    let writableMap = NSMutableDictionary()
    writableMap["keyAlias"] = self.getKeyAlias()
    writableMap["keyType"] = self.getKeyType()
    writableMap["keyId"] = self.getKeyId()
    writableMap["sscdId"] = self.getSscdId()
    writableMap["sscdType"] = self.getSscdType()
    writableMap["createDate"] = self.getCreatedDate().toISOString()
    writableMap["publicKey"] = self.getPublicKey()?.toNSDictionary()
    writableMap["certificate"] = self.getCertificate()?.toNSDictionary()
    writableMap["certificateChain"] = self.getCertificateChain()?.map { $0.toNSDictionary() } as! NSArray
    writableMap["attributes"] = self.getAttributes()?.map{ $0.toNSDictionary() } as! NSArray
    writableMap["keyUsages"] = self.getKeyUsages()
    writableMap["loa"] = self.getLoa()?.map { $0.getLoa() }
    writableMap["algorithm"] = self.getAlgorithm()?.toEnumString()
    writableMap["keyUri"] = self.getKeyUri()?.getUri()
    writableMap["isBiometricRequired"] = self.getIsBiometricRequired()
    writableMap["did"] = self.getDid()
    writableMap["state"] = self.getState()
    return writableMap
  }
}
extension NSDictionary {
  func toKeyGenReq() throws -> KeyGenReq {
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
      // The enum must be used
      let primitiveValue = try KeyAlgorithm.stringToPrimitive(string: primitive)
      let bitsValue = try KeyAlgorithm.validateNumBits(bits: bits)
      let curveValue = try KeyAlgorithm.curveMapper(curve: curve)
      keyAlgorithm = curveValue != nil ? KeyAlgorithm(primitive: primitiveValue, curve: curveValue!, bits: bitsValue) : KeyAlgorithm(primitive: primitiveValue, bits: bitsValue)
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

  
  extension String {
      func toMusapLoA() throws -> MusapLoA {
          switch self.lowercased() {
          case "low":
              return MusapLoA.EIDAS_LOW
          case "substantial":
              return MusapLoA.EIDAS_SUBSTANTIAL
          case "high":
              return MusapLoA.EIDAS_HIGH
          case "loa1":
              return MusapLoA.ISO_LOA1
          case "loa2":
              return MusapLoA.ISO_LOA2
          case "loa3":
              return MusapLoA.ISO_LOA3
          case "loa4":
              return MusapLoA.ISO_LOA4
          case "ial1":
              return MusapLoA.NIST_IAL1
          case "ial2":
              return MusapLoA.NIST_IAL2
          case "ial3":
              return MusapLoA.NIST_IAL3
          case "aal1":
              return MusapLoA.NIST_AAL1
          case "aal2":
              return MusapLoA.NIST_AAL2
          case "aal3":
              return MusapLoA.NIST_AAL3
          default:
              throw NSError(domain: "MusapLoAError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown LoA: \(self)"])
          }
      }
    
    var toSignatureAlgorithm: SignatureAlgorithm {
        switch self {
        case "SHA256withECDSA":
            return SignatureAlgorithm.SHA256withECDSA
        case "SHA384withECDSA":
            return SignatureAlgorithm.SHA384withECDSA
        case "SHA512withECDSA":
            return SignatureAlgorithm.SHA512withECDSA
        case "SHA256withRSA":
            return SignatureAlgorithm.SHA256withRSA
        case "SHA384withRSA":
            return SignatureAlgorithm.SHA384withRSA
        case "SHA512withRSA":
            return SignatureAlgorithm.SHA512withRSA
        case "SHA256withRSAPSS":
            return SignatureAlgorithm.SHA256withRSAPSS
        case "SHA384withRSAPSS":
            return SignatureAlgorithm.SHA384withRSAPSS
        case "SHA512withRSAPSS":
            return SignatureAlgorithm.SHA512withRSAPSS
        default:
            return SignatureAlgorithm.SHA256withECDSA
        }
    }
    
    var toDate: Date? {
           let formatter = ISO8601DateFormatter()
           formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
           return formatter.date(from: self)
       }
  }
  
  
  extension Date {
      var toISOString: String {
          let formatter = ISO8601DateFormatter()
          formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
          return formatter.string(from: self)
      }
  }
  
  
  func toSignatureReq() throws -> SignatureReq {
   
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
     let keyUri: KeyURI? = (keyMap["keyUri"] as? String).flatMap { KeyURI(keyUri: $0) }
     let isBiometricRequired = keyMap["isBiometricRequired"] as? Bool ?? false


      key = MusapKey(
        keyAlias: keyMap["keyAlias"] as? String ?? "",
        keyType: keyMap["keyType"] as? String,
        keyId: keyMap["keyId"] as? String,
        sscdId: keyMap["sscdId"] as? String,
        sscdType: keyMap["sscdType"] as? String ?? "",
        createdDate: keyMap["createdDate"] as? String).toDate(),
        publicKey: publicKey!,
        certificate: certificate,
        certificateChain: certificateChain,
        attributes: attributes,
        keyUsages: keyUsages,
        loa: (keyMap["loa"] as! String).toMusapLoA(),
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
    
    let algorithmString = self["algorithm"] as? String ?? "SHA256withECDSA"

    return SignatureReq(
        key: key!,
        data: data!,
        algorithm: algorithmString.toKeyAlgorithm(),
        format: SignatureFormat.fromString(format: format),
        displayText: displayText!,
        attributes: attributes!
    )
  }
}

extension MusapSscd {
  func toNSDictionary() -> NSDictionary {
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

extension KeyAlgorithm {
  func toNSDictionary() -> NSDictionary {
        let writableMap = NSMutableDictionary()
        let description = self.description().split(separator: "/")
        writableMap["primitive"] = description[0].replacingOccurrences(of: "[", with: "")
        writableMap["curve"] = description[1]
        writableMap["bits"] = description[2].replacingOccurrences(of: "]", with: "")
        writableMap["isEc"] = self.isEc()
        writableMap["isRSA"] = self.isRsa()
        return writableMap
      }
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


  enum InvalidKeyAlgorithm: Error {
    case invalidPrimitiveArg(message: String)
    case invalidBitsArg(message: String)
    case invalidCurveArg(message: String)
  }

  public static func stringToPrimitive(string: String?) throws -> String {
    switch string?.uppercased() {
    case "EC":
      return KeyAlgorithm.PRIMITIVE_EC
    case "RSA":
      return KeyAlgorithm.PRIMITIVE_RSA
    default:
      throw InvalidKeyAlgorithm.invalidPrimitiveArg(message: "Primitive must be EC or RSA")
    }
  }

  public static func validateNumBits(bits: Int) throws -> Int {
    let validNumBits: Set<Int> = [256, 384, 1024, 2048, 4096]
    if !validNumBits.contains(bits) {
      throw InvalidKeyAlgorithm.invalidBitsArg(message: "Bits must be the one of: \(validNumBits)")
    }
    return bits
  }

  public static func curveMapper(curve: String?) throws -> String? {
    if (curve != nil) {
      switch(curve) {
        case "secp256r1":
          return "ecc_p256_r1"
        case "secp384r1":
          return "ecc_p384_r1"
        case "secp256k1":
          return "ecc_p256_k1"
        case "secp384k1":
          return "ecc_p384_k1"
      default:
        throw InvalidKeyAlgorithm.invalidCurveArg(message: "Elliptic curve not supported.")
      }
    }
    return curve
  }
}


enum SignatureReqError: Error {
    case invalidPublicKey
    case invalidFormat
    case missingRequiredField(String)
}
