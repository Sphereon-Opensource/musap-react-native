//
//  MusapBridge.swift
//  musap-react-native
//
//  Swift Facade Pattern: Bridges between Objective-C++ and pure Swift musap-ios
//

import Foundation
import musap_ios
import os

let bridgeLogger = Logger(subsystem: "com.sphereon.musaprn.bridge", category: "bridge")

/// Swift facade that exposes musap-ios functionality to Objective-C++
/// This class acts as a data sanitizer, accepting simple Objective-C types
/// and converting them to complex Swift types internally.
@objc(MusapBridge)
public class MusapBridge: NSObject {

    @objc
    public static let shared = MusapBridge()

    private override init() {
        super.init()
    }

    // MARK: - SSCD Management

    /// Enables an SSCD with the given type and settings
    /// - Parameters:
    ///   - sscdType: SSCD type as NSString ("TEE", "YUBI_KEY", "EXTERNAL")
    ///   - sscdId: Optional SSCD identifier
    ///   - settings: Optional settings dictionary for EXTERNAL SSCDs
    ///   - completion: Completion block with success flag and optional error dictionary
    @objc
    public func enableSscd(
        _ sscdType: NSString,
        sscdId: NSString?,
        settings: NSDictionary?,
        completion: @escaping (Bool, NSDictionary?) -> Void
    ) {
        bridgeLogger.debug("enableSscd called for type: \(sscdType)")

        let typeString = sscdType as String
        let selectedSscdId = (sscdId as String?) ?? typeString

        do {
            if typeString == "EXTERNAL" {
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
                    completion(true, nil)
                } else {
                    let error: NSDictionary = [
                        "code": "SSCD_ERROR",
                        "message": "External SSCD requires valid settings"
                    ]
                    completion(false, error)
                }
            } else {
                // For non-EXTERNAL types, check if SSCD already exists
                if let existingSscds = MusapClient.listEnabledSscds(),
                   !existingSscds.contains(where: { $0.getSscdId() == selectedSscdId }) {

                    // Create new SSCD instance
                    let sscd: any MusapSscdProtocol
                    switch typeString {
                    case "TEE":
                        sscd = SecureEnclaveSscd()
                    case "YUBI_KEY":
                        sscd = YubikeySscd()
                    default:
                        let error: NSDictionary = [
                            "code": "SSCD_ERROR",
                            "message": "Unsupported SSCD type: \(typeString)"
                        ]
                        completion(false, error)
                        return
                    }

                    MusapClient.enableSscd(sscd: sscd, sscdId: selectedSscdId)
                }
                completion(true, nil)
            }
        } catch {
            bridgeLogger.error("enableSscd error: \(error.localizedDescription)")
            let errorDict: NSDictionary = [
                "code": "SSCD_ERROR",
                "message": error.localizedDescription
            ]
            completion(false, errorDict)
        }
    }

    /// Lists enabled SSCDs
    /// - Returns: Array of SSCD dictionaries with simple Objective-C types
    @objc
    public func listEnabledSscds() -> NSArray {
        guard let sscds = MusapClient.listEnabledSscds() else {
            return NSArray()
        }
        let sscdList = sscds.map { $0.toNSDictionary() }
        return sscdList as NSArray
    }

    /// Lists active SSCDs
    /// - Returns: Array of SSCD dictionaries with simple Objective-C types
    @objc
    public func listActiveSscds() -> NSArray {
        let sscds = MusapClient.listActiveSscds()
        let sscdList = sscds.map { $0.toNSDictionary() }
        return sscdList as NSArray
    }

    // MARK: - Key Management

    /// Generates a new key
    /// - Parameters:
    ///   - sscdId: SSCD identifier
    ///   - request: Key generation request as NSDictionary
    ///   - completion: Completion block with key URI string or error dictionary
    @objc
    public func generateKey(
        _ sscdId: NSString,
        request: NSDictionary,
        completion: @escaping (NSString?, NSDictionary?) -> Void
    ) {
        bridgeLogger.debug("generateKey called for sscdId: \(sscdId)")

        guard let sscd = MusapClient.listEnabledSscds()?.first(where: { $0.getSscdId() == sscdId as String }) else {
            let error: NSDictionary = ["code": "GENERATE_KEY_ERROR", "message": "SSCD not found"]
            completion(nil, error)
            return
        }

        do {
            let reqObj = try request.toKeyGenReq()

            Task {
                await MusapClient.generateKey(sscd: sscd, req: reqObj) { result in
                    switch result {
                    case .success(let musapKey):
                        if let keyUri = musapKey.getKeyUri()?.getUri() {
                            completion(keyUri as NSString, nil)
                        } else {
                            let error: NSDictionary = ["code": "GENERATE_KEY_ERROR", "message": "Generated key has no URI"]
                            completion(nil, error)
                        }
                    case .failure(let error):
                        let errorDict: NSDictionary = [
                            "code": "GENERATE_KEY_ERROR",
                            "message": error.localizedDescription
                        ]
                        completion(nil, errorDict)
                    }
                }
            }
        } catch {
            let errorDict: NSDictionary = [
                "code": "GENERATE_KEY_ERROR",
                "message": "Error creating request object: \(error.localizedDescription)"
            ]
            completion(nil, errorDict)
        }
    }

    /// Lists all keys
    /// - Returns: Array of key dictionaries with simple Objective-C types
    @objc
    public func listKeys() -> NSArray {
        let keys = MusapClient.listKeys()
        let keysList = keys.map { $0.toNSDictionary() }
        return keysList as NSArray
    }

    /// Gets a key by URI
    /// - Parameter keyUri: Key URI as NSString
    /// - Returns: Key dictionary or nil
    @objc
    public func getKeyByUri(_ keyUri: NSString) -> NSDictionary? {
        let result = MusapClient.getKeyByUri(keyUri: keyUri as String)
        return result?.toNSDictionary()
    }

    // MARK: - Signature Operations

    /// Signs data with a key
    /// - Parameters:
    ///   - request: Signature request as NSDictionary
    ///   - completion: Completion block with base64 signature string or error dictionary
    @objc
    public func sign(
        _ request: NSDictionary,
        completion: @escaping (NSString?, NSDictionary?) -> Void
    ) {
        do {
            let signatureRequest = try request.toSignatureReq()
            bridgeLogger.debug("sign called")

            Task {
                await MusapClient.sign(req: signatureRequest) { result in
                    switch result {
                    case .success(let musapSignature):
                        let rawSignature = musapSignature.getRawSignature()
                        let b64Signature = rawSignature.base64EncodedString()
                        completion(b64Signature as NSString, nil)
                    case .failure(let error):
                        let errorDict: NSDictionary = [
                            "code": "SIGN_ERROR",
                            "message": "Error signing the data: \(error.localizedDescription)"
                        ]
                        completion(nil, errorDict)
                    }
                }
            }
        } catch {
            let errorDict: NSDictionary = [
                "code": "SIGN_ERROR",
                "message": "Error preparing signature request: \(error.localizedDescription)"
            ]
            completion(nil, errorDict)
        }
    }

    // MARK: - Link Management

    /// Gets the current MUSAP link
    /// - Returns: MUSAP ID or nil
    @objc
    public func getLink() -> NSString? {
        if let musapId = MusapClient.getMusapLink()?.getMusapId() {
            return musapId as NSString
        }
        return nil
    }

    /// Enables MUSAP link
    /// - Parameters:
    ///   - url: Link URL
    ///   - fcmToken: Optional FCM token
    ///   - completion: Completion block with MUSAP ID or error dictionary
    @objc
    public func enableLink(
        _ url: NSString,
        fcmToken: NSString?,
        completion: @escaping (NSString?, NSDictionary?) -> Void
    ) {
        bridgeLogger.debug("enableLink called")

        if let existingLink = MusapClient.getMusapLink(),
           let musapId = existingLink.getMusapId() {
            completion(musapId as NSString, nil)
            return
        }

        Task {
            if let musapLink = await MusapClient.enableLink(url: url as String, apnsToken: fcmToken as String?),
               let musapId = musapLink.getMusapId() {
                completion(musapId as NSString, nil)
            } else {
                let error: NSDictionary = [
                    "code": "ENABLE_LINK_ERROR",
                    "message": "Error enabling link; enabledLink returned null"
                ]
                completion(nil, error)
            }
        }
    }
}
