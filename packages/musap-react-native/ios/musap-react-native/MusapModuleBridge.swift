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

    @objc(generateKey:req:resolver:rejecter:)
    func generateKey(_ sscdId: String, req: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        guard let sscd = MusapClient.listEnabledSscds()?.first(where: { $0.getSscdId() == sscdId }) else {
            rejecter("GENERATE_KEY_ERROR", "Error: SSCD not found", nil)
            return
        }

        do {
            let reqObj = try req.toKeyGenReq()

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
            rejecter("GENERATE_KEY_ERROR", "Error creating request object: \(error.localizedDescription)", error)
        }
    }

    @objc(sign:resolver:rejecter:)
    func sign(_ req: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        do {
            let signatureRequest = try req.toSignatureReq()

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
            rejecter("SIGN_ERROR", "Error preparing signature request: \(error.localizedDescription)", error)
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
    return result?.toNSDictionary()
  }

  @objc
  func getKeyById(_ keyId: String) -> NSDictionary? {
    let result = MusapClient.getKeyByKeyId(keyId: keyId)
    return result?.toNSDictionary()
  }

  @objc
  func removeKey(_ keyUri: String) -> NSNumber {
      if let key = MusapClient.getKeyByUri(keyUri: keyUri) {
          let result = MusapClient.removeKey(musapKey: key)
          return result ? 1 : 0
      }
      return 0
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

    @objc
    func convertDERtoRS(derSignature: Data) throws -> Data {
        logger.info("Input DER signature: \(derSignature.map { String(format: "%02hhx", $0) }.joined())")

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
        logger.info("Output R|S signature: \(result.map { String(format: "%02hhx", $0) }.joined())")

        return result
    }
}

