//
//  MusapModuleBridge.m
//  musapreactnative
//
//  Created by Zoë Maas on 20/06/2024
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(MusapModule, NSObject)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(listActiveSscds)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(listEnabledSscds)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(enableSscd: (NSString) sscdType)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(getKeyByUri: (NSString) keyUri)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(getKeyById: (NSString) keyId)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(listKeys)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(getSscdInfo: (NSString) sscdId)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(getSettings: (NSString) sscdId)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(removeKey: (NSString) keyUri)

RCT_EXTERN_METHOD(generateKey:(NSString *)sscdId
                  req:(NSDictionary *)req
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

RCT_EXTERN_METHOD(sign:(NSDictionary *)req
                  resolver:(RCTPromiseResolveBlock)resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

RCT_EXTERN_METHOD(getSscdInstance: type: (NSString) type)

@end
