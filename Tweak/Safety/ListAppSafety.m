#import "ListAppSafety.h"
#import "ListAppConstants.h"
#import "ListAppPrefs.h"

static NSMutableDictionary<NSString *, NSNumber *> *sFailureCounts = nil;
static dispatch_queue_t sSafetyQueue = nil;

@implementation ListAppSafety

+ (void)start {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sFailureCounts = [NSMutableDictionary dictionary];
        sSafetyQueue = dispatch_queue_create("com.jinken.listapp.safety", DISPATCH_QUEUE_SERIAL);
    });
}

+ (BOOL)isFeatureAvailable:(NSString *)feature {
    if (![ListAppPrefs crashProtection]) return YES;
    if (!feature) return YES;
    __block BOOL available = YES;
    dispatch_sync(sSafetyQueue ?: dispatch_get_main_queue(), ^{
        NSNumber *cnt = sFailureCounts[feature];
        if (cnt && [cnt integerValue] >= kListAppFailureDisableThreshold) {
            available = NO;
        }
    });
    return available;
}

+ (void)recordFailureForFeature:(NSString *)feature exception:(NSException *)exception {
    if (!feature) return;
    NSLog(@"[ListApp Safety] Exception in feature '%@': %@\nReason: %@", feature, exception.name, exception.reason);
    dispatch_async(sSafetyQueue ?: dispatch_get_main_queue(), ^{
        NSInteger count = [sFailureCounts[feature] integerValue] + 1;
        sFailureCounts[feature] = @(count);
        if (count >= kListAppFailureDisableThreshold) {
            NSLog(@"[ListApp Safety] Feature '%@' disabled after %ld consecutive exceptions to protect SpringBoard!", feature, (long)count);
        }
    });
}

+ (void)resetFailures {
    dispatch_async(sSafetyQueue ?: dispatch_get_main_queue(), ^{
        [sFailureCounts removeAllObjects];
    });
}

@end
