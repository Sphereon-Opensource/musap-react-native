//
//  MusapModuleBridge.swift
//  musapreactnative
//
//  Created by Zoë Maas on 20/06/2024.
//

import Foundation;
import musap_ios;

@objc(MusapModule)
class MusapModuleDelegate: NSObject {
  
  // active = that can generate or bind keys
  @objc
  public static func listActiveSscds() -> [MusapSscd]? {
    return MusapClient.listActiveSscds()
  }
  
  // enabled = supported by MUSAP
  @objc
  public static func listEnabledSscds() -> [MusapSscd]? {
    return MusapClient.listEnabledSscds()
  }
  
  @objc
  public static func generateKeys(sscd: MusapSscd, req: KeyGenReq, completion: @escaping (Result<MusapKey, MusapError>) -> Void) async {
    return await MusapClient.generateKey(sscd, req, completion)
  }
  
  @objc
  public static func sign(req: SignatureReq, completion: @escaping (Result<MusapSignature, MusapError>) -> Void) async {
    return await MusapClient.sign(req, completion)
  }
  
  @objc
  public static func enableSscd(sscd: any MusapSscdProtocol, sscdId: String) {
    MusapClient.enableSscd(sscd, sscdId)
  }
  
  @objc
  public static getSscdInstance(type: String) -> MusapSscdProtocol {
    switch type {
    case "SE":
      return SecureEnclaveSscd()
    default:
      throw Error("\(type) is not a valid SSCD")
    }
  }
}
