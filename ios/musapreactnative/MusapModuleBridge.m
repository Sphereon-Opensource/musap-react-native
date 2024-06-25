//
//  MusapModuleBridge.m
//  musapreactnative
//
//  Created by Zoë Maas on 20/06/2024.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(MusapModule, NSObject)

RCT_EXTERN_METHOD(listActiveSscds:(RCTPromiseResolveBlock)resolver rejecter:(RCTPromiseRejectBlock)reject)


RCT_EXTERN_METHOD(listEnabledSscds:(RCTPromiseResolveBlock)resolver rejecter:(RCTPromiseRejectBlock)reject)


RCT_EXTERN_METHOD(generateKeys: sscd: (NSDictionary *) sscd req: (NSDictionary *) req completion: (RCTResponseSenderBlock *) completion)

RCT_EXTERN_METHOD(sign: req: (NSDictionary *) req completion: (RCTResponseSenderBlock *) completion)

RCT_EXTERN_METHOD(enableSscd: sscd: (NSDictionary *) sscd sscdId: (NSString) sscdId)

RCT_EXTERN_METHOD(getSscdInstance: type: (NSString) type)

@end
