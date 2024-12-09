//
//  MusapModuleBridge.swift
//  musapreactnative
//
//  Created by Zoë Maas on 20/06/2024
//
import Foundation
import React
import musap_ios
import os

let logger = Logger(subsystem: "com.sphereon.musaprn", category: "debugging")
// To log: xcrun simctl spawn booted log stream --level debug --style compact > /tmp/log.txt


@objc(MusapModule)
class MusapModule: NSObject {
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    override init() {
        super.init()
    }
    
    
    @objc(bindKey:req:resolver:rejecter:)
    func bindKey(_ sscdId: String, req: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        logger.debug("bindKey called")
        guard let sscd = MusapClient.listEnabledSscds()?.first(where: { $0.getSscdId() == sscdId }) else {
            rejecter("BIND_KEY_ERROR", "Error: SSCD not found", nil)
            return
        }
        
        do {
            let reqObj = try req.toKeyBindReq()
            logger.debug("bindKey request \(stringify(reqObj))")
            let queue = DispatchQueue(label: "com.sphereon.bindKey")
            var isResolved = false
            
            Task {
                await MusapClient.bindKey(sscd: sscd, req: reqObj) { result in
                    queue.sync {
                        guard !isResolved else { return }
                        isResolved = true
                        
                        switch result {
                        case .success(let musapKey):
                            if let keyUri = musapKey.getKeyUri()?.getUri() {
                                let result: [String: Any] = ["keyUri": keyUri]
                                resolver(result as NSDictionary)
                            } else {
                                rejecter("BIND_KEY_ERROR", "Bound key has no URI", nil)
                            }
                        case .failure(let error):
                            rejecter("BIND_KEY_ERROR", "Error binding key: \(error.localizedDescription)", error)
                        }
                    }
                }
            }
        } catch {
            logger.error("bindKey error \(stringify(error))")
            rejecter("BIND_KEY_ERROR", "Error creating bind request object: \(error.localizedDescription)", error)
        }
    }
    /*
    @objc(encryptData:resolver:rejecter:)
    func encryptData(_ req: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        do {
            let encryptionReq = try req.toEncryptionReq()
            logger.debug("encryptData called")
            let queue = DispatchQueue(label: "com.sphereon.encrypt")
            var isResolved = false
            
            Task {
                await MusapClient.encryptData(req: encryptionReq) { result in
                    queue.sync {
                        guard !isResolved else { return }
                        isResolved = true
                        
                        switch result {
                        case .success(let encryptedData):
                            let base64String = encryptedData.base64EncodedString()
                            resolver(base64String)
                        case .failure(let error):
                            rejecter("ENCRYPTION_ERROR", "Error encrypting data: \(error.localizedDescription)", error)
                        }
                    }
                }
            }
        } catch {
            logger.error("encryptData error \(error.localizedDescription)")
            rejecter("ENCRYPTION_ERROR", "Error preparing encryption request: \(error.localizedDescription)", error)
        }
    }
    
    @objc(decryptData:resolver:rejecter:)
    func decryptData(_ req: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        do {
            let decryptionReq = try req.toDecryptionReq()
            logger.debug("decryptData called")
            let queue = DispatchQueue(label: "com.sphereon.decrypt")
            var isResolved = false
            
            Task {
                await MusapClient.decryptData(req: decryptionReq) { result in
                    queue.sync {
                        guard !isResolved else { return }
                        isResolved = true
                        
                        switch result {
                        case .success(let decryptedData):
                            let base64String = decryptedData.base64EncodedString()
                            resolver(base64String)
                        case .failure(let error):
                            rejecter("DECRYPTION_ERROR", "Error decrypting data: \(error.localizedDescription)", error)
                        }
                    }
                }
            }
        } catch {
            logger.error("decryptData error \(error.localizedDescription)")
            rejecter("DECRYPTION_ERROR", "Error preparing decryption request: \(error.localizedDescription)", error)
        }
    }
    */
    
    @objc
    func getLink() -> String? {
        return MusapClient.getMusapLink()?.getMusapId()
    }
    
     func removeKey(keyName: String) throws {
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: keyName.data(using: .utf8)!
            ]
            
            let status = SecItemDelete(deleteQuery as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            }
     }
        
    @objc(enableLink:fcmToken:resolver:rejecter:)
    func enableLink(_ url: String, fcmToken: String?, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        logger.debug("enableLink called")
        let queue = DispatchQueue(label: "com.sphereon.enableLink")
        var isResolved = false
        
        if let existingLink = MusapClient.getMusapLink() {
            resolver(existingLink.getMusapId())
            return
        }
        
         Task {
            do {
              try self.removeKey(keyName: MusapKeyGenerator.MAC_KEY_ALIAS)
              try self.removeKey(keyName: MusapKeyGenerator.TRANSPORT_KEY_ALIAS)
            } catch {
                logger.error("Could not remove MAC_KEY_ALIAS & TRANSPORT_KEY_ALIAS keys")
            }   
         
             if let musapLink = await MusapClient.enableLink(url: url, apnsToken: fcmToken) {
                 queue.sync {
                     guard !isResolved else { return }
                     isResolved = true
                     resolver(musapLink.getMusapId())
                 }
             } else {
                 queue.sync {
                     guard !isResolved else { return }
                     isResolved = true
                     rejecter("ENABLE_LINK_ERROR", "Error enabling link", nil)
                 }
             }
         }
    }
    
    @objc
    func disconnectLink() {
        MusapClient.disableLink()
    }
    
    // Added relying party coupling functionality
    @objc(coupleWithRelyingParty:resolver:rejecter:)
    func coupleWithRelyingParty(_ couplingCode: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        logger.debug("coupleWithRelyingParty called")
        let queue = DispatchQueue(label: "com.sphereon.couple")
        var isResolved = false
        
        Task {
            await MusapClient.coupleWithRelyingParty(couplingCode: couplingCode) { result in
                queue.sync {
                    guard !isResolved else { return }
                    isResolved = true
                    
                    switch result {
                    case .success(let relyingParty):
                        resolver(relyingParty.getLinkId())
                    case .failure(let error):
                        rejecter("COUPLE_RP_ERROR", "Error coupling with relying party: \(error.localizedDescription)", error)
                    }
                }
            }
        }
    }
    
    
    
    @objc(generateKey:req:resolver:rejecter:)
    func generateKey(_ sscdId: String, req: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        logger.debug("generateKey called")
        guard let sscd = MusapClient.listEnabledSscds()?.first(where: { $0.getSscdId() == sscdId }) else {
            rejecter("GENERATE_KEY_ERROR", "Error: SSCD not found", nil)
            return
        }
        
        do {
            let reqObj = try req.toKeyGenReq()
            logger.debug("generateKey request \(stringify(reqObj))")
            let queue = DispatchQueue(label: "com.sphereon.generateKey")
            var isResolved = false
            
            Task {
                await MusapClient.generateKey(sscd: sscd, req: reqObj) { result in
                    queue.sync {
                        guard !isResolved else { return }
                        isResolved = true
                        
                        switch result {
                        case .success(let musapKey):
                            if let keyUri = musapKey.getKeyUri()?.getUri() {
                                resolver(keyUri)
                            } else {
                                rejecter("GENERATE_KEY_ERROR", "Generated key has no URI", nil)
                            }
                        case .failure(let error):
                            let errorCode: String
                            switch error.errorCode {
                            case 101: errorCode = "wrongParam"
                            case 102: errorCode = "missingParam"
                            case 103: errorCode = "invalidAlgorithm"
                            case 105: errorCode = "unknownKey"
                            case 107: errorCode = "unsupportedData"
                            case 108: errorCode = "keygenUnsupported"
                            case 109: errorCode = "bindUnsupported"
                            case 208: errorCode = "timedOut"
                            case 401: errorCode = "userCancel"
                            case 402: errorCode = "keyBlocked"
                            case 403: errorCode = "sscdBlocked"
                            case 900: errorCode = "internalError"
                            default: errorCode = "unknownError"
                            }
                            let errorMessage = "Error creating key: \(error.localizedDescription): Error code: \(errorCode)"
                            rejecter("GENERATE_KEY_ERROR", errorMessage, error)
                        }
                    }
                }
            }
        } catch {
            logger.error("generateKey error \(stringify(error))")
            rejecter("GENERATE_KEY_ERROR", "Error creating request object: \(error.localizedDescription)", error)
        }
    }
    
    @objc(sign:resolver:rejecter:)
    func sign(_ req: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        do {
            let signatureRequest = try req.toSignatureReq()
            logger.debug("sign called \(stringify(signatureRequest))")
            let queue = DispatchQueue(label: "com.sphereon.sign")
            var isResolved = false
            let convertToRS = true // FIXME move to SignatureReq
            
            Task {
                await MusapClient.sign(req: signatureRequest) { result in
                    queue.sync {
                        guard !isResolved else { return }
                        isResolved = true
                        
                        switch result {
                        case .success(let musapSignature):
                            let rawSignature = musapSignature.getRawSignature()
                            var signatureToEncode = rawSignature
                            
                            if convertToRS {
                                do {
                                    signatureToEncode = try self.convertDERtoRS(derSignature: rawSignature)
                                } catch {
                                    rejecter("SIGNATURE_CONVERSION_ERROR", "Error converting DER to R|S: \(error.localizedDescription)", error)
                                    return
                                }
                            }
                            
                            let b64Signature = signatureToEncode.base64URLEncodedStringNoPadding()
                            resolver(b64Signature)
                        case .failure(let error):
                            rejecter("SIGN_ERROR", "Error signing the data: \(error.localizedDescription)", error)
                        }
                    }
                }
            }
        } catch JWTError.unsupportedAlgorithm(let algorithm) {
            rejecter("UNSUPPORTED_ALGORITHM", "Unsupported algorithm: \(algorithm)", JWTError.unsupportedAlgorithm(algorithm))
        } catch JWTError.missingAlgorithm {
            rejecter("MISSING_ALGORITHM", "No algorithm specified", JWTError.missingAlgorithm)
        } catch {
            logger.error("sign error \(error.localizedDescription)")
            rejecter("SIGN_ERROR", "Error preparing signature request: \(error.localizedDescription)", error)
        }
    }
    
    @objc(enableSscd:sscdId:settings:)
    func enableSscd(_ sscdType: String, sscdId: String?, settings: NSDictionary?) -> Any? {
        logger.debug("enabledSscd called for type: \(sscdType), id: \(sscdId ?? "nil"), settings: \(settings?.description ?? "nil")")
        
        let selectedSscdId = sscdId ?? sscdType
        
        do {
            if sscdType == "EXTERNAL" {
                // Remove existing SSCDs with the same ID
                if let existingSscds = MusapClient.listEnabledSscds() {
                    existingSscds
                        .filter { $0.getSscdId() == selectedSscdId }
                        .forEach { MusapClient.removeSscd(musapSscd: $0.getSscdInfo()!) }
                }
                
                // Create new EXTERNAL SSCD with settings
                if let externalSettings = try? settings?.toExternalSscdSettings() {
                    let sscd = ExternalSscd(
                        settings: externalSettings,
                        clientid: externalSettings.getClientId()!, 
                        musapLink: externalSettings.getMusapLink()!
                    )
                    MusapClient.enableSscd(sscd: sscd, sscdId: selectedSscdId)
                } else {
                    throw NSError(domain: "SSCD_ERROR", code: 1, userInfo: [NSLocalizedDescriptionKey: "External SSCD requires settings"])
                }
            } else {
                // For non-EXTERNAL types, check if SSCD already exists
                if let existingSscds = MusapClient.listEnabledSscds(),
                   !existingSscds.contains(where: { $0.getSscdId() == selectedSscdId }) {
                    
                    // Create new SSCD instance
                    let sscd: any MusapSscdProtocol
                    switch sscdType {
                    case "TEE":
                        sscd = SecureEnclaveSscd()
                    case "YUBI_KEY":
                        sscd = YubikeySscd()
                    default:
                        throw NSError(domain: "SSCD_ERROR", code: 2,
                                      userInfo: [NSLocalizedDescriptionKey: "Unsupported SSCD type: \(sscdType)"])
                    }
                    
                    MusapClient.enableSscd(sscd: sscd, sscdId: selectedSscdId)
                }
            }
            return nil
        } catch {
            logger.error("enableSscd error: \(error.localizedDescription)")
            NSException(name: NSExceptionName.invalidArgumentException,
                        reason: error.localizedDescription,
                        userInfo: nil).raise()
            return nil
        }
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
        return result?.toNSDictionary()
    }
    
    @objc
    func getKeyById(_ keyId: String) -> NSDictionary? {
        let result = MusapClient.getKeyByKeyId(keyId: keyId)
        return result?.toNSDictionary()
    }
    
    @objc(removeKey:resolver:rejecter:)
    func removeKey(_ keyIdOrUri: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        do {
            let musapKey: MusapKey?
            if keyIdOrUri.starts(with: "keyuri:") {
                musapKey = MusapClient.getKeyByUri(keyUri: keyIdOrUri)
            } else {
                musapKey = MusapClient.getKeyByKeyId(keyId: keyIdOrUri)
            }
            
            guard let key = musapKey else {
                throw NSError(domain: "REMOVE_KEY_ERROR",
                              code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "No key found for \(keyIdOrUri)"])
            }
            
            let result = MusapClient.removeKey(musapKey: key)
            resolver(NSNumber(value: result))
        } catch {
            logger.error("removeKey error: \(error.localizedDescription)")
            rejecter("REMOVE_KEY_ERROR", error.localizedDescription, error)
        }
    }
    
    @objc
    func listKeys() -> NSArray {
        let keys = MusapClient.listKeys()
        let keysList = keys.map { $0.toNSDictionary() }
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
    
    @objc(sendKeygenCallback:transId:resolver:rejecter:)
    func sendKeygenCallback(_ keyUri: String, transId: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        logger.debug("sendKeygenCallback called")
        
        guard let musapKey = MusapClient.getKeyByUri(keyUri: keyUri) else {
            rejecter("SEND_KEY_CALLBACK_ERROR", "Key not found for URI: \(keyUri)", nil)
            return
        }
        
        do {
            let result = try MusapClient.sendKeygenCallback(key: musapKey, txnId: transId)
            resolver(result)
        } catch {
            logger.error("sendKeygenCallback error: \(error.localizedDescription)")
            rejecter("SEND_KEY_CALLBACK_ERROR", error.localizedDescription, error)
        }
    }
    
    @objc
    func convertDERtoRS(derSignature: Data) throws -> Data {
        logger.debug("Input DER signature: \(derSignature.map { String(format: "%02hhx", $0) }.joined())")
        
        var derBytes = [UInt8](derSignature)
        guard derBytes.count > 8, derBytes[0] == 0x30 else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid DER signature"])
        }
        
        // Skip header byte and signature length byte
        var index = 2
        
        // Skip extra length bytes if present
        if derBytes[1] > 0x80 {
            index += Int(derBytes[1] - 0x80)
        }
        
        func extractInteger() throws -> [UInt8] {
            guard index < derBytes.count, derBytes[index] == 0x02 else {
                throw NSError(domain: "SignatureError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid integer marker"])
            }
            index += 1
            let length = Int(derBytes[index])
            index += 1
            let valueStartIndex = index
            index += length
            return Array(derBytes[valueStartIndex..<index])
        }
        
        let r = try extractInteger()
        let s = try extractInteger()
        
        // Ensure R and S are 32 bytes each, left-pad with zeros if necessary
        func normalize(_ integer: [UInt8]) -> [UInt8] {
            let targetLength = 32
            if integer.count > targetLength {
                return Array(integer.suffix(targetLength))
            } else if integer.count < targetLength {
                return Array(repeating: 0, count: targetLength - integer.count) + integer
            }
            return integer
        }
        
        let normalizedR = normalize(r)
        let normalizedS = normalize(s)
        
        let result = Data(normalizedR + normalizedS)
        logger.debug("Output R|S signature: \(result.map { String(format: "%02hhx", $0) }.joined())")
        
        return result
    }
}

