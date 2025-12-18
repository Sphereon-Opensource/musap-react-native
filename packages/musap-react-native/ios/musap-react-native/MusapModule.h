//
//  MusapModule.h
//  musap-react-native
//
//  Objective-C++ TurboModule header
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Musap Native Module for React Native
/// This is the main entry point for the TurboModule implementation
@interface MusapModule : NSObject

/// Initialize the module
- (instancetype)init;

// MARK: - SSCD Management

/// Enable an SSCD
/// @param sscdType The type of SSCD ("TEE", "YUBI_KEY", "EXTERNAL")
/// @param sscdId Optional SSCD identifier
/// @param settings Optional settings dictionary for EXTERNAL SSCDs
/// @param resolve Promise resolve block
/// @param reject Promise reject block
- (void)enableSscd:(NSString *)sscdType
            sscdId:(NSString * _Nullable)sscdId
          settings:(NSDictionary * _Nullable)settings
           resolve:(void (^)(id _Nullable result))resolve
            reject:(void (^)(NSString *code, NSString *message, NSError * _Nullable error))reject;

/// List enabled SSCDs
/// @return Array of SSCD dictionaries
- (NSArray *)listEnabledSscds;

/// List active SSCDs
/// @return Array of SSCD dictionaries
- (NSArray *)listActiveSscds;

// MARK: - Key Management

/// Generate a new key
/// @param sscdId SSCD identifier
/// @param request Key generation request dictionary
/// @param resolve Promise resolve block
/// @param reject Promise reject block
- (void)generateKey:(NSString *)sscdId
            request:(NSDictionary *)request
            resolve:(void (^)(NSString *keyUri))resolve
             reject:(void (^)(NSString *code, NSString *message, NSError * _Nullable error))reject;

/// List all keys
/// @return Array of key dictionaries
- (NSArray *)listKeys;

/// Get key by URI
/// @param keyUri Key URI
/// @return Key dictionary or nil
- (NSDictionary * _Nullable)getKeyByUri:(NSString *)keyUri;

// MARK: - Signature Operations

/// Sign data with a key
/// @param request Signature request dictionary
/// @param resolve Promise resolve block with base64 signature
/// @param reject Promise reject block
- (void)sign:(NSDictionary *)request
     resolve:(void (^)(NSString *signature))resolve
      reject:(void (^)(NSString *code, NSString *message, NSError * _Nullable error))reject;

// MARK: - Link Management

/// Get current MUSAP link
/// @return MUSAP ID or nil
- (NSString * _Nullable)getLink;

/// Enable MUSAP link
/// @param url Link URL
/// @param fcmToken Optional FCM token
/// @param resolve Promise resolve block with MUSAP ID
/// @param reject Promise reject block
- (void)enableLink:(NSString *)url
          fcmToken:(NSString * _Nullable)fcmToken
           resolve:(void (^)(NSString *musapId))resolve
            reject:(void (^)(NSString *code, NSString *message, NSError * _Nullable error))reject;

@end

NS_ASSUME_NONNULL_END
