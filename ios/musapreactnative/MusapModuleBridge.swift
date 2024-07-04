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
          completion([musapKey.getKeyUri()?.getUri() ?? "Non-existent keyUri"])
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

      let musapCallback: (Result<MusapSignature, MusapError>) -> Void = { result in
        switch result {
        case .success(let musapSignature):
          completion(["Data successfully signed: \(musapSignature.getB64Signature())"])
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
  func getSscdInfo(_ sscdId: String) -> NSDictionary? {
    return MusapClient.listEnabledSscds()?.first { $0.getSscdId() == sscdId }?.getSscdInfo()?.toNSDictionary()
  }
  
  @objc
  func getSscdSettings(_ sscdId: String) -> NSDictionary? {
    return MusapClient.listEnabledSscds()?.first { $0.getSscdId() == sscdId }?.getSettingsAsNSDisctionary()
  }
  
  @objc
  func getKeyByUri(_ keyUri: String) -> NSDictionary? {
    return MusapClient.getKeyByUri(keyUri: keyUri)?.toNSDictionary()
  }
  
  @objc
  func listKeys() -> NSArray {
    let keys = MusapClient.listKeys()
    let keysList = keys.map { $0.toNSDictionary() }
    return keysList as NSArray
  }
}

extension SscdInfo {
  func toNSDictionary() -> NSDictionary {
    
    let supportedAlgorithms = NSMutableArray()
    self.getSupportedAlgorithms().forEach {
      supportedAlgorithms.add($0.toNSDictionary())
    }
    
    let writableMap = NSMutableDictionary()
    writableMap["sscdId"] = self.getSscdId()
    writableMap["sscdType"] = self.getSscdType()
    writableMap["sscdName"] = self.getSscdName()
    writableMap["country"] = self.getCountry()
    writableMap["provider"] = self.getProvider()
    writableMap["isKeyGenSupported"] = self.isKeygenSupported()
    writableMap["supportedAlgorithms"] = supportedAlgorithms
    return writableMap
  }
}

extension PublicKey {
  func toNSDictionary() -> NSDictionary {
    let writableMap = NSMutableDictionary()
    writableMap["der"] = self.getDER().base64EncodedString()
    writableMap["pem"] = self.getPEM()
    return writableMap
  }
}

extension MusapCertificate {
  func toNSDictionary() -> NSDictionary {
    let writableMap = NSMutableDictionary()
    writableMap["subject"] = self.getSubject()
    writableMap["publicKey"] = self.getPublicKey().toNSDictionary()
    writableMap["certificate"] = self.getCertificate().base64EncodedString()
    return writableMap
  }
}

extension KeyAttribute {
  func toNSDictionary() -> NSDictionary {
    let writableMap = NSMutableDictionary()
    writableMap["name"] = self.name
    writableMap["value"] = self.value
    return writableMap
  }
}

extension MusapLoa {
  func toNSDictionary() -> NSDictionary {
    let writableMap = NSMutableDictionary()
    writableMap["loa"] = self.getLoa()
    writableMap["scheme"] = self.getScheme()
    writableMap["number"] = getNumber(self.getLoa())
    return writableMap
  }
  
  private func getNumber(_ loa: String) -> Int {
    switch (loa) {
    case "low", "loa1", "ial1", "aal1":
      return 1
    case "loa2", "ial2", "aal2":
      return 2
    case "substantial", "loa3", "ial3", "aal3":
      return 3
    case "high", "loa4":
      return 4
    default:
      print("Invalid loa: \(loa)")
      return 0
    }
  }
}

extension KeyAlgorithm {
  func toNSDictionary() -> NSDictionary {
    let writableDictionary = NSMutableDictionary()
    writableDictionary["primitive"] = (self.primitive == "73" ? "EC" : "RSA")
    writableDictionary["curve"] = self.curve
    writableDictionary["bits"] = self.bits
    writableDictionary["isEc"] = self.isEc()
    writableDictionary["isRsa"] = self.isRsa()
    return writableDictionary
  }
}

extension MusapKey {
  func toNSDictionary() -> NSDictionary {
    let writableMap = NSMutableDictionary()
    writableMap["keyId"] = self.getKeyId()
    writableMap["keyAlias"] = self.getKeyAlias()
    writableMap["keyType"] = self.getKeyType()
    writableMap["sscdId"] = self.getSscdId()
    writableMap["sscdType"] = self.getSscdType()
    writableMap["createdDate"] = self.getCreatedDate()?.ISO8601Format()
    writableMap["publicKey"] = self.getPublicKey()?.toNSDictionary()
    writableMap["certificate"] = self.getCertificate()?.toNSDictionary()
    let certificateChain = NSMutableArray()
    self.getCertificateChain()?.forEach { certificateChain.add($0.toNSDictionary()) }
    writableMap["certificateChain"] = certificateChain
    let attributes = NSMutableArray()
    self.getAttributes()?.forEach { attributes.add($0.toNSDictionary()) }
    writableMap["attributes"] = attributes
    let keyUsages = NSMutableArray()
    self.getKeyUsages()?.forEach { keyUsages.add($0) }
    writableMap["keyUsages"] = keyUsages
    let loa = NSMutableArray()
    self.getLoa()?.forEach { loa.add($0.toNSDictionary()) }
    writableMap["loa"] = loa
    writableMap["algorithm"] = self.getAlgorithm()?.toNSDictionary()
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
  func toNSDictionary() -> NSDictionary {
    let writableMap = NSMutableDictionary()

    guard let sscdInfo = self.getSscdInfo() else {
      return writableMap
    }

    let supportedAlgorithms = NSMutableArray()
    sscdInfo.getSupportedAlgorithms().forEach {
      supportedAlgorithms.add($0.toNSDictionary())
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
    writableMap["settings"] = self.getSettingsAsNSDisctionary()

    return writableMap
  }
  
  func getSettingsAsNSDisctionary() -> NSDictionary {
    let settings = NSMutableDictionary()
    // The settings are only accessible from the child class
    switch(self.impl) {
      case is SecureEnclaveSscd:
        (self.impl as! SecureEnclaveSscd).getSettings()?.forEach {
          settings[$0.key] = $0.value
        }
      case is KeychainSscd:
        (self.impl as! KeychainSscd).getSettings()?.forEach {
          settings[$0.key] = $0.value
        }
      case is ExternalSscd:
        (self.impl as! ExternalSscd).getSettings()?.forEach {
          settings[$0.key] = $0.value
        }
      default:
        NSLog("There is no such SSCD type")
    }
    return settings
  }
}

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


  enum InvalidKeyAlgorithm: Error {
    case invalidPrimitiveArg(message: String)
    case invalidBitsArg(message: String)
    case invalidCurveArg(message: String)
  }

  public static func stringToPrimitive(string: String?) throws -> String {
    switch string?.uppercased() {
    case "EC": // 73
      return KeyAlgorithm.PRIMITIVE_EC
    case "RSA": // 42
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
