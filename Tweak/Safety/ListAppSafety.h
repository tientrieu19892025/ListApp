#import <Foundation/Foundation.h>

#define LISTAPP_TRY(feature, ...) \
    do { \
        if (![ListAppSafety isFeatureAvailable:(feature)]) break; \
        @try { \
            __VA_ARGS__; \
        } @catch (NSException *__exc) { \
            [ListAppSafety recordFailureForFeature:(feature) exception:__exc]; \
        } \
    } while (0)

@interface ListAppSafety : NSObject

+ (void)start;
+ (BOOL)isFeatureAvailable:(NSString *)feature;
+ (void)recordFailureForFeature:(NSString *)feature exception:(NSException *)exception;
+ (void)resetFailures;

@end
