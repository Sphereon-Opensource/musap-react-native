//
//  MusapModuleBridge.m
//  musapreactnative
//
//  Created by Zoë Maas on 20/06/2024
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(MusapBridge, NSObject)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(listActiveSscds)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(listEnabledSscds)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(enableSscd:(NSString *)sscdType
                                        sscdId:(nullable NSString *)sscdId
                                        settings:(nullable NSDictionary *)settings)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(getKeyByUri: (NSString) keyUri)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(getKeyById: (NSString) keyId)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(listKeys)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(getSscdInfo: (NSString) sscdId)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(getSettings: (NSString) sscdId)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(removeKey: (NSString) keyUri)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(getLink)

RCT_EXTERN_METHOD(generateKey:(NSString *)sscdId
                  req:(NSDictionary *)req
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

RCT_EXTERN_METHOD(bindKey:(NSString *)sscdId
                  req:(NSDictionary *)req
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

RCT_EXTERN_METHOD(sign:(NSDictionary *)req
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

/* 
RCT_EXTERN_METHOD(encryptData:(NSDictionary *)req
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

RCT_EXTERN_METHOD(decryptData:(NSDictionary *)req
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)
 */

RCT_EXTERN_METHOD(enableLink:(NSString *)url
                  fcmToken:(NSString *)fcmToken
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

RCT_EXTERN_METHOD(disconnectLink)

RCT_EXTERN_METHOD(coupleWithRelyingParty:(NSString *)couplingCode
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

RCT_EXTERN_METHOD(getSscdInstance: type: (NSString) type)

RCT_EXTERN_METHOD(sendKeygenCallback:(NSString *)keyUri
                  transId:(NSString *)transId
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

@end
