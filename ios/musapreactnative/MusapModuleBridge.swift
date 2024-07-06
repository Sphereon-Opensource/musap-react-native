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
      let key = reqObj.getKey()
      let keyAlgo = key.getAlgorithm()
      let signatureAlgorithm = keyAlgo?.isEc() ?? false ? SignatureAlgorithm.SHA256withECDSA : SignatureAlgorithm.SHA256withRSA
      
      let musapCallback: (Result<MusapSignature, MusapError>) -> Void = { result in
        switch result {
        case .success(let musapSignature):
          
          let header = "{\"typ\":\"JWT\",\"kid\":\"\(key.getKeyId() ?? "")\",\"alg\":\"\(signatureAlgorithm)\"}".data(using: .utf8)?.encodeToBase64URL()
          let payload = reqObj.data.encodeToBase64URL()
          let signature = musapSignature.getRawSignature().encodeToBase64URL()
          completion(["\(header ?? "").\(payload).\(signature)"])
        case .failure(let error):
          completion(["Error signing the data: \(error.localizedDescription): Error code: \(error.errorCode)"])
        }
      }

      Task {
        await MusapClient.sign(req: reqObj, completion: musapCallback)
      }
    } catch let error {
      completion(["Error signing the data: \(error.localizedDescription): Error code: \(error)"])
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
  func getSettings(_ sscdId: String) -> NSDictionary? {
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

extension Data {
  func encodeToBase64URL() -> String {
    return self.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}

extension String {
  func decodeBase64URLString() -> Data? {
    var base64String = self
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    let padLength = Int(4 - base64String.count % 4) % 4
    base64String = base64String.padding(toLength: base64String.count + padLength, withPad: "=", startingAt: 0)
    return Data(base64Encoded: base64String)
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
  
  /**
   {
     "keyUri":"keyuri:key?loa=loa3&name=b2fcc689-b51c-40dd-90df-335bb2ea3a0c&sscd=SE",
     "publicKey":{
        "pem":"-----BEGIN PUBLIC KEY-----\nBHFzY99xWTEN1JWa3r9RtaKtdXsnwDgr9cMsghjaF7Dsq1a8KDaDemajvTZaWyII\nhKZPCWsHCSEj7TTFTJ6uBAo=\n-----END PUBLIC KEY-----\n",
        "der":"BHFzY99xWTEN1JWa3r9RtaKtdXsnwDgr9cMsghjaF7Dsq1a8KDaDemajvTZaWyIIhKZPCWsHCSEj7TTFTJ6uBAo="
     },
     "loa":[
        {
          "number":3,
          "scheme":"EIDAS-2014",
          "loa":"substantial"
        },
        {
          "number":3,
          "scheme":"ISO-29115",
          "loa":"loa3"
        }
      ],
     "createdDate":"2024-07-05T10:00:19Z",
     "certificateChain":[],
     "sscdType":"SE",
     "keyUsages":[],
     "isBiometricRequired":false,
     "keyId":"F56BE4DC-A06C-4B38-B65A-FD74533B6088",
     "keyAlias":"b2fcc689-b51c-40dd-90df-335bb2ea3a0c",
     "attributes":[],
     "algorithm":{
        "isRsa":false,
        "bits":256,
        "primitive":"EC",
        "curve":"ecc_p256_r1",
        "isEc":true
     },
     "sscdId":"TEE"
   }
   */
  
  func toPublicKey() throws -> PublicKey {
  
    guard let publicKey = self["publicKey"] as? [String: Any] else {
      throw PublicKeyError.invalidDER
    }
      
      guard let der = self["der"] as? String else {
        throw PublicKeyError.invalidDER
      }
      
      guard let data = der.data(using: .utf8) else {
        throw PublicKeyError.invalidDER
      }
      
      return PublicKey(publicKey: data)
  }
  
  func toMusapCertificate() throws -> MusapCertificate {
    
      guard let subject = self["subject"] as? String else {
        throw MusapCertificateError.invalidSubject
      }
      
      guard let cert = self["certificate"] as? String else {
        throw MusapCertificateError.invalidCertificate
      }
    
      guard let certificate = cert.data(using: .utf8) else {
        throw MusapCertificateError.invalidCertificate
      }
      
      guard let pk = self["publicKey"] as? [String: Any] else {
        throw PublicKeyError.invalidDER
      }
    
      guard let der = pk["der"] as? String else {
        throw PublicKeyError.invalidDER
      }
    
      guard let publicKeyData = der.data(using: .utf8) else {
        throw PublicKeyError.invalidDER
      }
      return MusapCertificate(subject: subject, certificate: certificate, publicKey: PublicKey(publicKey: publicKeyData))
    }
  
  func toKeyAttribute() throws -> KeyAttribute? {
    if let name = self["name"] as? String, let certDataBase64 = self["value"] as? String {
      if let certData = Data(base64Encoded: certDataBase64),
         let cert = SecCertificateCreateWithData(nil, certData as CFData) {
        return KeyAttribute(name: name, cert: cert)
      }
    }
    return nil
  }
  
  func toSignatureAttribute() -> SignatureAttribute? {
    if let name = self["name"] as? String, let value = self["value"] as? String {
        return SignatureAttribute(name: name, value: value)
    }
    return nil
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

    if let keyMap = self["key"] as? NSDictionary {
      
      var certificate: MusapCertificate?
      
      guard let pk = (keyMap["publicKey"] as? NSDictionary) else {
        throw PublicKeyError.invalidDER
      }
      
      let publicKey = try pk.toPublicKey()
      
      guard let cert = keyMap["certificate"] as? NSDictionary else {
        throw MusapCertificateError.invalidCertificate
      }
      
      certificate = try cert.toMusapCertificate()
      
      guard let certChain = keyMap["certificateChain"] as? NSArray else {
        throw MusapCertificateError.invalidCertificate
      }
      
      let dictArray = certChain.compactMap { $0 as? NSDictionary }
      let certificateChain = try dictArray.compactMap { try $0.toMusapCertificate() }
      
      
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
        publicKey: publicKey,
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

    guard let dataString = self["data"] as? String else {
      throw SignatureReqError.missingRequiredField("data")
    }
    
    guard let data = dataString.data(using: .utf8) else {
      throw SignatureReqError.missingRequiredField("data")
    }

    guard let displayText = self["displayText"] as? String else {
      throw SignatureReqError.missingRequiredField("displayText")
    }
    
    let format = self["format"] as? String ?? "RAW"
    
    guard let attributesNSArray = self["attributes"] as? NSArray else {
      throw SignatureReqError.missingRequiredField("attributes:1")
    }
    
    let attributes = attributesNSArray.compactMap { ($0 as? NSDictionary)?.toSignatureAttribute() }

    return SignatureReq(
        key: key!,
        data: data,
        algorithm: SignatureAlgorithm(algorithm: algorithm),
        format: SignatureFormat(format),
        displayText: displayText,
        attributes: attributes
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

enum MusapCertificateError: Error {
  case invalidSubject
  case invalidCertificate
  case invalidKey
}

enum PublicKeyError: Error {
  case invalidDER
}
