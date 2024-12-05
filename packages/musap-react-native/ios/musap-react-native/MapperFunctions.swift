//
//  MapperFunctions.swift
//  musap-react-native
//
//  Created by Sphereon on 22/07/2024.
//

import Foundation
import musap_ios
import CommonCrypto

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
            fatalError("Unknown or unsupported KeyAlgorithm")
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
        
        if let publicKey = self.getPublicKey() {
            let publicKeyMap = NSMutableDictionary()
            let derData = publicKey.getDER()
            publicKeyMap["der"] = [UInt8](derData) // Convert Data to [UInt8]
            publicKeyMap["pem"] = publicKey.getPEM()
            writableMap["publicKey"] = publicKeyMap
        }
        
        writableMap["keyAlias"] = self.getKeyAlias()
        writableMap["keyType"] = self.getKeyType()
        writableMap["keyId"] = self.getKeyId()
        writableMap["sscdId"] = self.getSscdId()
        writableMap["sscdType"] = self.getSscdType()
        writableMap["createdDate"] = self.getCreatedDate()?.toISOString
        writableMap["certificate"] = self.getCertificate()?.toNSDictionary()
        writableMap["certificateChain"] = self.getCertificateChain()?.map { $0.toNSDictionary() } as NSArray?
        writableMap["attributes"] = self.getAttributes()?.map{ $0.toNSDictionary() } as NSArray?
        writableMap["keyUsages"] = self.getKeyUsages()
        writableMap["loa"] = self.getLoa()?.map { $0.getLoa() }
        
        if let algorithm = self.getAlgorithm() {
            writableMap["algorithm"] = algorithm.toEnumString()
            
            let defaultSignatureAlgorithm = NSMutableDictionary()
            defaultSignatureAlgorithm["javaAlgorithm"] = algorithm.isEc() ? "ES256" : "RS256"
            defaultSignatureAlgorithm["hashAlgorithm"] = "SHA256"
            defaultSignatureAlgorithm["isRsa"] = algorithm.isRsa()
            defaultSignatureAlgorithm["jwsAlgorithm"] = algorithm.isEc() ? "ES256" : "RS256"
            defaultSignatureAlgorithm["scheme"] = algorithm.isEc() ? "ECDSA" : "RSA"
            defaultSignatureAlgorithm["isEc"] = algorithm.isEc()
            writableMap["defaultsignatureAlgorithm"] = defaultSignatureAlgorithm
        }
        
        if let keyUri = self.getKeyUri() {
            writableMap["keyUri"] = keyUri.getUri()
        }
        
        writableMap["isBiometricRequired"] = self.getIsBiometricRequired()
        writableMap["did"] = self.getDid()
        writableMap["state"] = self.getState()
        
        let sscdMap = NSMutableDictionary()
        if let sscdInfo = self.getSscdInfo() {
            sscdMap["sscdId"] = sscdInfo.getSscdId()
            
            let sscdInfoMap = NSMutableDictionary()
            sscdInfoMap["country"] = sscdInfo.getCountry()
            sscdInfoMap["provider"] = sscdInfo.getProvider()
            sscdInfoMap["sscdName"] = sscdInfo.getSscdName()
            sscdInfoMap["supportedAlgorithms"] = sscdInfo.getSupportedAlgorithms().map { $0.toEnumString() }
            sscdInfoMap["isKeyGenSupported"] = sscdInfo.isKeygenSupported()
            sscdInfoMap["sscdType"] = sscdInfo.getSscdType()
            sscdInfoMap["sscdId"] = sscdInfo.getSscdId()
            
            sscdMap["sscdInfo"] = sscdInfoMap
            
            let settingsMap = NSMutableDictionary()
            settingsMap["id"] = sscdInfo.getSscdId()
            sscdMap["settings"] = settingsMap
        }
        writableMap["sscd"] = sscdMap
        
        return writableMap
    }
}


extension NSDictionary {
    func toKeyBindReq() throws -> KeyBindReq {
        let keyAlias = self["keyAlias"] as? String ?? ""
        let displayText = self["displayText"] as? String ?? ""
        let did = self["did"] as? String ?? ""
        let role = self["role"] as? String ?? ""
        let stepUpPolicy = self["stepUpPolicy"] != nil ? StepUpPolicy() : StepUpPolicy()
        
        var attributes: [KeyAttribute] = []
        if let attributesArray = self["attributes"] as? [[String: Any]] {
            attributes = attributesArray.compactMap { attributeMap in
                if let name = attributeMap["name"] as? String,
                   let certDataBase64 = attributeMap["value"] as? String,
                   let certData = Data(base64Encoded: certDataBase64),
                   let cert = SecCertificateCreateWithData(nil, certData as CFData) {
                    return KeyAttribute(name: name, cert: cert)
                }
                return nil
            }
        }
        
        return KeyBindReq(
            keyAlias: keyAlias,
            did: did,
            role: role,
            stepUpPolicy: stepUpPolicy,
            attributes: attributes,
            generateNewKey: false,  // Using default value
            displayText: displayText
        )
    }
    
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
        
        if let keyAlgorithmString = self["keyAlgorithm"] as? String {
            keyAlgorithm = KeyAlgorithm.fromString(keyAlgorithmString)
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
        guard let keyUriString = self["keyUri"] as? String else {
            throw SignatureReqError.missingKeyUri
        }
        
        // Get the key first so we can use it for data processing
        guard let key = MusapClient.getKeyByUri(keyUri: keyUriString) else {
            throw SignatureReqError.invalidKey
        }
        
        guard let dataValue = self["data"] else {
            throw SignatureReqError.missingData
        }
        
        guard let sscdType = key.getSscdType()?.lowercased() else {
               throw SignatureReqError.invalidKey
           }
                
                // Process data based on SSCD type
                let processedData: Data
                if let stringData = dataValue as? String {
                    let rawData = stringData.data(using: .utf8) ?? Data()
                    if sscdType == "external" || sscdType == "external signature" {
                        // Use SHA256 for external SSCD type
                        let sha256Data = SHA256.hash(data: rawData)
                        processedData = Data(sha256Data)
                    } else {
                        processedData = rawData
                    }
                } else if let intArray = dataValue as? [Int] {
                    let rawData = Data(intArray.map { UInt8($0) })
                    if sscdType == "external" || sscdType == "external signature" {
                        // Use SHA256 for external SSCD type
                        let sha256Data = SHA256.hash(data: rawData)
                        processedData = Data(sha256Data)
                    } else {
                        processedData = rawData
                    }
                } else {
                    throw SignatureReqError.invalidDataFormat
                }
        
        let displayText = self["displayText"] as? String ?? self["display"] as? String
        
        guard let format = self["format"] as? String else {
            throw SignatureReqError.invalidFormat
        }
        
        var sigAttributes: [SignatureAttribute]?
        if let attributesArray = self["attributes"] as? [[String: Any]] {
            sigAttributes = attributesArray.compactMap { attributeMap in
                if let name = attributeMap["name"] as? String, let value = attributeMap["value"] as? String {
                    return SignatureAttribute(name: name, value: value)
                }
                return nil
            }
        }
        
        let algorithmString = self["algorithm"] as? String ?? "SHA256withECDSA"
        
        return SignatureReq(
            key: key,
            data: processedData,
            algorithm: algorithmString.toSignatureAlgorithm,
            format: SignatureFormat.fromString(format: format),
            displayText: displayText ?? "",
            attributes: sigAttributes ?? []
        )
    }
    
    enum SignatureReqError: Error {
        case missingKeyUri
        case missingData
        case invalidFormat
        case invalidDataFormat
        case invalidKey
    }
}


extension String {
    func toMusapLoA() throws -> MusapLoa {
        switch self.lowercased() {
        case "low":
            return MusapLoa.EIDAS_LOW
        case "substantial":
            return MusapLoa.EIDAS_SUBSTANTIAL
        case "high":
            return MusapLoa.EIDAS_HIGH
        case "loa1":
            return MusapLoa.ISO_LOA1
        case "loa2":
            return MusapLoa.ISO_LOA2
        case "loa3":
            return MusapLoa.ISO_LOA3
        case "loa4":
            return MusapLoa.ISO_LOA4
        case "ial1":
            return MusapLoa.NIST_IAL1
        case "ial2":
            return MusapLoa.NIST_IAL2
        case "ial3":
            return MusapLoa.NIST_IAL3
        case "aal1":
            return MusapLoa.NIST_AAL1
        case "aal2":
            return MusapLoa.NIST_AAL2
        case "aal3":
            return MusapLoa.NIST_AAL3
        default:
            throw NSError(domain: "MusapLoaError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown LoA: \(self)"])
        }
    }
    
    var toSignatureAlgorithm: SignatureAlgorithm {
        switch self {
        case "SHA256withECDSA":
            return SignatureAlgorithm(algorithm: SignatureAlgorithm.SHA256withECDSA)
        case "SHA384withECDSA":
            return SignatureAlgorithm(algorithm: SignatureAlgorithm.SHA384withECDSA)
        case "SHA512withECDSA":
            return SignatureAlgorithm(algorithm: SignatureAlgorithm.SHA512withECDSA)
        case "SHA256withRSA":
            return SignatureAlgorithm(algorithm: SignatureAlgorithm.SHA256withRSA)
        case "SHA384withRSA":
            return SignatureAlgorithm(algorithm: SignatureAlgorithm.SHA384withRSA)
        case "SHA512withRSA":
            return SignatureAlgorithm(algorithm: SignatureAlgorithm.SHA512withRSA)
        case "SHA256withRSAPSS":
            return SignatureAlgorithm(algorithm: SignatureAlgorithm.SHA256withRSAPSS)
        case "SHA384withRSAPSS":
            return SignatureAlgorithm(algorithm: SignatureAlgorithm.SHA384withRSAPSS)
        case "SHA512withRSAPSS":
            return SignatureAlgorithm(algorithm: SignatureAlgorithm.SHA512withRSAPSS)
        default:
            return SignatureAlgorithm(algorithm: SignatureAlgorithm.SHA256withECDSA)
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

extension Data {
    func base64URLEncodedStringNoPadding() -> String {
        let base64String = self.base64EncodedString()
        
        // Remove padding characters
        let unpaddedString = base64String.trimmingCharacters(in: ["="])
        
        // Replace characters for URL-safe base64
        return unpaddedString
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}



extension SecKeyAlgorithm {
    func toJWTAlgorithmString() throws -> String {
        switch self {
        case .ecdsaSignatureMessageX962SHA256:
            return "ES256"
        case .ecdsaSignatureMessageX962SHA384:
            return "ES384"
        case .ecdsaSignatureMessageX962SHA512:
            return "ES512"
        case .rsaSignatureMessagePKCS1v15SHA256:
            return "RS256"
        case .rsaSignatureMessagePKCS1v15SHA384:
            return "RS384"
        case .rsaSignatureMessagePKCS1v15SHA512:
            return "RS512"
        case .rsaSignatureMessagePSSSHA256:
            return "PS256"
        case .rsaSignatureMessagePSSSHA384:
            return "PS384"
        case .rsaSignatureMessagePSSSHA512:
            return "PS512"
        default:
            throw JWTError.unsupportedAlgorithm(self)
        }
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
        case "rsa1k":
            return KeyAlgorithm.RSA_1K
        case "rsa2k":
            return KeyAlgorithm.RSA_2K
        case "rsa4k":
            return KeyAlgorithm.RSA_4K
        case "eccp256k1":
            return KeyAlgorithm.ECC_P256_K1
        case "eccp384k1":
            return KeyAlgorithm.ECC_P384_K1
        case "eccp256r1":
            return KeyAlgorithm.ECC_P256_R1
        case "eccp384r1":
            return KeyAlgorithm.ECC_P384_R1
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

extension NSDictionary {
    func toExternalSscdSettings() throws -> ExternalSscdSettings {
        guard let clientId = self["clientId"] as? String else {
            throw SSCDError.missingClientId
        }
        
        let settings = ExternalSscdSettings(clientId: clientId)
        
        if let sscdName = self["sscdName"] as? String {
            settings.setSscdName(name: sscdName)
        }
        
        if let timeout = self["timeout"] as? Double {
            let timeoutMillis = Int64(timeout * 60 * 1000)
            settings.setSetting(key: ExternalSscdSettings.SETTINGS_TIMEOUT, value: String(timeoutMillis))
        }
        
        return settings
    }
}

enum SSCDError: Error {
    case missingClientId
}

enum SignatureReqError: Error {
    case invalidPublicKey
    case invalidFormat
    case missingRequiredField(String)
}

enum JWTError: Error {
    case unsupportedAlgorithm(SecKeyAlgorithm)
    case missingAlgorithm
}


func stringify(_ object: Any) -> String {
    let mirror = Mirror(reflecting: object)
    var output = "{\n"
    for (label, value) in mirror.children {
        if let label = label {
            output += "  \(label): \(value)\n"
        }
    }
    output += "}"
    return output
}


struct SHA256 {
    static func hash(data: Data) -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return hash
    }
}
