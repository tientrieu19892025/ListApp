#import "ListAppPrefs.h"
#import "ListAppConstants.h"
#import "ListAppPaths.h"

static NSDictionary *sPrefsDict = nil;
static dispatch_queue_t sPrefsQueue = nil;

static void ReloadPrefsCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [ListAppPrefs reload];
}

@implementation ListAppPrefs

+ (void)initialize {
    if (self == [ListAppPrefs class]) {
        sPrefsQueue = dispatch_queue_create("com.jinken.listapp.prefs", DISPATCH_QUEUE_SERIAL);
        [self reload];
    }
}

+ (void)startObserving {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       NULL,
                                       ReloadPrefsCallback,
                                       (__bridge CFStringRef)kListAppReloadNotification,
                                       NULL,
                                       CFNotificationSuspensionBehaviorDeliverImmediately);
        [self reload];
    });
}

+ (void)reload {
    CFPreferencesAppSynchronize((__bridge CFStringRef)kListAppPrefsIdentifier);
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    // Read direct plist fallback
    for (NSString *path in [ListAppPaths preferenceFilePaths]) {
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
        if (d) {
            [dict addEntriesFromDictionary:d];
            break;
        }
    }

    // Overlay CFPreferences
    NSArray *keys = @[
        kListAppEnabled, kListAppGridColumns, kListAppContainerHeightRatio,
        kListAppCornerRadius, kListAppIntensity, kListAppBlurStyle,
        kListAppSpecular, kListAppBorderGlow, kListAppShowSearchBar,
        kListAppHideStockIcons, kListAppHideDock, kListAppHidePageDots,
        kListAppHaptics, kListAppIconSize, kListAppCrashProtection,
        kListAppRespectReduceTransparency, kListAppRespectReduceMotion,
        kListAppCheapBlurOnLPM, kListAppFrameDesign, kListAppGlassColor,
        kListAppShowBadges, kListAppBadgePosition
    ];

    for (NSString *key in keys) {
        CFPropertyListRef val = CFPreferencesCopyAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)kListAppPrefsIdentifier);
        if (val) {
            dict[key] = (__bridge_transfer id)val;
        }
    }

    dispatch_sync(sPrefsQueue, ^{
        sPrefsDict = [dict copy];
    });
}

+ (id)objectForKey:(NSString *)key defaultVal:(id)def {
    __block id val = nil;
    dispatch_sync(sPrefsQueue, ^{
        val = sPrefsDict[key];
    });
    return val ?: def;
}

+ (BOOL)enabled {
    return [[self objectForKey:kListAppEnabled defaultVal:@YES] boolValue];
}

+ (NSInteger)gridColumns {
    NSInteger val = [[self objectForKey:kListAppGridColumns defaultVal:@(kListAppDefaultGridColumns)] integerValue];
    if (val < 1 || val > 4) val = kListAppDefaultGridColumns;
    return val;
}

+ (CGFloat)containerHeightRatio {
    CGFloat val = [[self objectForKey:kListAppContainerHeightRatio defaultVal:@(kListAppDefaultHeightRatio)] doubleValue];
    if (val < 0.4) val = 0.4;
    if (val > 0.95) val = 0.95;
    return val;
}

+ (CGFloat)cornerRadius {
    CGFloat val = [[self objectForKey:kListAppCornerRadius defaultVal:@(kListAppDefaultCornerRadius)] doubleValue];
    if (val < 8.0) val = 8.0;
    if (val > 44.0) val = 44.0;
    return val;
}

+ (CGFloat)intensity {
    CGFloat val = [[self objectForKey:kListAppIntensity defaultVal:@(kListAppDefaultIntensity)] doubleValue];
    if (val < 0.0) val = 0.0;
    if (val > 1.0) val = 1.0;
    return val;
}

+ (NSInteger)blurStyle {
    return [[self objectForKey:kListAppBlurStyle defaultVal:@0] integerValue];
}

+ (BOOL)specular {
    return [[self objectForKey:kListAppSpecular defaultVal:@YES] boolValue];
}

+ (BOOL)borderGlow {
    return [[self objectForKey:kListAppBorderGlow defaultVal:@YES] boolValue];
}

+ (BOOL)showSearchBar {
    return [[self objectForKey:kListAppShowSearchBar defaultVal:@YES] boolValue];
}

+ (BOOL)hideStockIcons {
    return [[self objectForKey:kListAppHideStockIcons defaultVal:@YES] boolValue];
}

+ (BOOL)hideDock {
    return [[self objectForKey:kListAppHideDock defaultVal:@NO] boolValue];
}

+ (BOOL)hidePageDots {
    return [[self objectForKey:kListAppHidePageDots defaultVal:@YES] boolValue];
}

+ (BOOL)haptics {
    return [[self objectForKey:kListAppHaptics defaultVal:@YES] boolValue];
}

+ (CGFloat)iconSize {
    CGFloat val = [[self objectForKey:kListAppIconSize defaultVal:@(kListAppDefaultIconSize)] doubleValue];
    if (val < 40.0) val = 40.0;
    if (val > 80.0) val = 80.0;
    return val;
}

+ (BOOL)crashProtection {
    return [[self objectForKey:kListAppCrashProtection defaultVal:@YES] boolValue];
}

+ (BOOL)respectReduceTransparency {
    return [[self objectForKey:kListAppRespectReduceTransparency defaultVal:@YES] boolValue];
}

+ (BOOL)respectReduceMotion {
    return [[self objectForKey:kListAppRespectReduceMotion defaultVal:@YES] boolValue];
}

+ (BOOL)cheapBlurOnLPM {
    return [[self objectForKey:kListAppCheapBlurOnLPM defaultVal:@YES] boolValue];
}

+ (NSInteger)frameDesign {
    return [[self objectForKey:kListAppFrameDesign defaultVal:@(ListAppFrameDesignCapsule)] integerValue];
}

+ (NSInteger)glassColor {
    return [[self objectForKey:kListAppGlassColor defaultVal:@(ListAppGlassColorCrystal)] integerValue];
}

+ (BOOL)showBadges {
    return [[self objectForKey:kListAppShowBadges defaultVal:@YES] boolValue];
}

+ (NSInteger)badgePosition {
    return [[self objectForKey:kListAppBadgePosition defaultVal:@(ListAppBadgePositionRight)] integerValue];
}

@end
