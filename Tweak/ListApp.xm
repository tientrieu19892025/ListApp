#import "ListAppConstants.h"
#import "ListAppPrefs.h"
#import "ListAppSafety.h"
#import "ListAppContainerView.h"

extern void ListAppInitSpringBoard(void);

static void HandleReloadPrefs(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [ListAppPrefs reload];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ListAppContainerView sharedView] applyConfiguration];
    });
}

static BOOL IsSpringBoardProcess(void) {
    NSString *bid = [NSBundle mainBundle].bundleIdentifier;
    if (bid && [bid isEqualToString:@"com.apple.springboard"]) {
        return YES;
    }
    NSString *pname = [NSProcessInfo processInfo].processName;
    if (pname && [pname isEqualToString:@"SpringBoard"]) {
        return YES;
    }
    return NO;
}

%ctor {
    @autoreleasepool {
        if (!IsSpringBoardProcess()) {
            return;
        }

        [ListAppSafety start];
        [ListAppPrefs startObserving];

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            HandleReloadPrefs,
            (__bridge CFStringRef)kListAppReloadNotification,
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );

        ListAppInitSpringBoard();
        NSLog(@"[ListApp] Successfully loaded in SpringBoard (v%@ - %@)", kListAppVersion, kListAppCodename);
    }
}
