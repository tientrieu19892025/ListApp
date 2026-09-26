#import "ListAppModel.h"
#import "ListAppSafety.h"
#import "ListAppConstants.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface UIImage (PrivateListApp)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSString *localizedName;
@property (nonatomic, readonly) NSString *applicationType;
@property (nonatomic, readonly) BOOL isInstalled;
@property (nonatomic, readonly) BOOL isPlaceholder;
@property (nonatomic, readonly) BOOL isRestricted;
@end

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (NSArray<LSApplicationProxy *> *)allApplications;
- (NSArray<LSApplicationProxy *> *)allInstalledApplications;
- (BOOL)openApplicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface FBSOpenApplicationService : NSObject
+ (instancetype)serviceWithDefaultEndpoint;
- (void)openApplication:(NSString *)bundleIdentifier withOptions:(NSDictionary *)options completion:(void(^)(id, id))completion;
@end

@interface SBApplication : NSObject
- (NSString *)bundleIdentifier;
- (NSString *)displayName;
@end

@interface SBApplicationController : NSObject
+ (instancetype)sharedInstance;
- (NSArray<SBApplication *> *)allApplications;
- (SBApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface SBUIController : NSObject
+ (instancetype)sharedInstance;
- (void)activateApplication:(SBApplication *)application;
@end

@interface SBIcon : NSObject
- (NSString *)applicationBundleID;
- (NSString *)leafIdentifier;
- (id)application;
- (NSString *)displayName;
- (UIImage *)getIconImage:(int)format;
@end

@interface SBHIconManager : NSObject
- (id)iconModel;
- (void)launchIcon:(id)icon;
@end

@interface SBIconModel : NSObject
- (NSArray *)allApplicationIcons;
- (NSArray *)leafIcons;
- (id)applicationIconForBundleIdentifier:(NSString *)bundleID;
- (id)expectedIconForDisplayIdentifier:(NSString *)bundleID;
@end

@interface SBIconController : UIViewController
+ (instancetype)sharedInstance;
- (id)model;
- (id)iconManager;
- (void)launchIcon:(id)icon;
@end

@interface FBSOpenApplicationOptions : NSObject
+ (instancetype)optionsWithDictionary:(NSDictionary *)dict;
@end

@implementation ListAppItem

- (UIImage *)iconImageWithScale:(CGFloat)scale {
    if (self.cachedIcon) return self.cachedIcon;

    CGFloat screenScale = [UIScreen mainScreen].scale;
    if (screenScale < 2.0) screenScale = 2.0;

    UIImage *icon = nil;

    // 1. First priority: SBIcon getIconImage:2 (format 2 is native 60x60 @2x/@3x SpringBoard icon, 120px / 180px)
    @try {
        Class icClass = objc_getClass("SBIconController");
        if (icClass) {
            id iconCtrl = [icClass sharedInstance];
            id model = [iconCtrl respondsToSelector:@selector(model)] ? [iconCtrl model] : nil;
            if (!model && [iconCtrl respondsToSelector:@selector(iconManager)]) {
                id mgr = [iconCtrl iconManager];
                if ([mgr respondsToSelector:@selector(iconModel)]) {
                    model = [mgr iconModel];
                }
            }
            if (model && [model respondsToSelector:@selector(applicationIconForBundleIdentifier:)]) {
                id sbIcon = [model applicationIconForBundleIdentifier:self.bundleIdentifier];
                if (sbIcon && [sbIcon respondsToSelector:@selector(getIconImage:)]) {
                    icon = [sbIcon getIconImage:2];
                }
            }
        }
    } @catch (NSException *e) {}

    // 2. Second priority: _applicationIconImageForBundleIdentifier format 2 at native screen scale
    if (!icon && [UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
        @try {
            icon = [UIImage _applicationIconImageForBundleIdentifier:self.bundleIdentifier format:2 scale:screenScale];
            if (!icon) {
                icon = [UIImage _applicationIconImageForBundleIdentifier:self.bundleIdentifier format:0 scale:screenScale];
            }
        } @catch (NSException *e) {}
    }

    // 3. Fallback: app.fill system image
    if (!icon) {
        if (@available(iOS 13.0, *)) {
            icon = [UIImage systemImageNamed:@"app.fill"];
        }
    }

    self.cachedIcon = icon;
    return icon;
}

- (id)sbIconObject {
    @try {
        Class icClass = objc_getClass("SBIconController");
        if (icClass) {
            id iconCtrl = [icClass sharedInstance];
            id model = [iconCtrl respondsToSelector:@selector(model)] ? [iconCtrl model] : nil;
            if (!model && [iconCtrl respondsToSelector:@selector(iconManager)]) {
                id mgr = [iconCtrl iconManager];
                if ([mgr respondsToSelector:@selector(iconModel)]) {
                    model = [mgr iconModel];
                }
            }
            if (model && [model respondsToSelector:@selector(applicationIconForBundleIdentifier:)]) {
                return [model applicationIconForBundleIdentifier:self.bundleIdentifier];
            }
        }
    } @catch (NSException *e) {}
    return nil;
}

static NSInteger ListAppExtractIntegerFromTargetAndSelector(id target, SEL selector) {
    if (!target || !selector || ![target respondsToSelector:selector]) return 0;
    @try {
        NSMethodSignature *sig = [target methodSignatureForSelector:selector];
        if (!sig) return 0;
        const char *returnType = [sig methodReturnType];
        if (!returnType) return 0;

        // If return type is an Objective-C object (@)
        if (returnType[0] == '@') {
            id obj = ((id (*)(id, SEL))objc_msgSend)(target, selector);
            if ([obj respondsToSelector:@selector(integerValue)]) {
                return [obj integerValue];
            }
            return 0;
        }

        // If return type is an integer type (q = long long/NSInteger on 64-bit, i = int, l = long, Q = unsigned long long, I = unsigned int)
        if (returnType[0] == 'q' || returnType[0] == 'l' || returnType[0] == 'Q') {
            NSInteger val = ((NSInteger (*)(id, SEL))objc_msgSend)(target, selector);
            return val;
        }
        if (returnType[0] == 'i' || returnType[0] == 'I' || returnType[0] == 's' || returnType[0] == 'S') {
            int val = ((int (*)(id, SEL))objc_msgSend)(target, selector);
            return (NSInteger)val;
        }
    } @catch (NSException *e) {}
    return 0;
}

- (NSInteger)badgeCount {
    @try {
        id sbIcon = [self sbIconObject];
        if (sbIcon) {
            NSInteger count = ListAppExtractIntegerFromTargetAndSelector(sbIcon, @selector(badgeValue));
            if (count > 0) return count;

            count = ListAppExtractIntegerFromTargetAndSelector(sbIcon, @selector(badgeNumberOrString));
            if (count > 0) return count;
        }

        // Secondary check via SBApplication
        Class appCtrlClass = objc_getClass("SBApplicationController");
        if (appCtrlClass) {
            id appCtrl = [appCtrlClass sharedInstance];
            if ([appCtrl respondsToSelector:@selector(applicationWithBundleIdentifier:)]) {
                id sbApp = [appCtrl applicationWithBundleIdentifier:self.bundleIdentifier];
                if (sbApp) {
                    NSInteger count = ListAppExtractIntegerFromTargetAndSelector(sbApp, @selector(badgeValue));
                    if (count > 0) return count;
                }
            }
        }
    } @catch (NSException *e) {}
    return 0;
}

- (NSString *)badgeString {
    NSInteger count = [self badgeCount];
    if (count <= 0) return nil;
    if (count > 99) return @"99+";
    return [NSString stringWithFormat:@"%ld", (long)count];
}

@end

@implementation ListAppModel {
    NSArray<ListAppItem *> *_items;
    dispatch_queue_t _workerQueue;
}

+ (instancetype)sharedInstance {
    static ListAppModel *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ListAppModel alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (!self) return self;

    _workerQueue = dispatch_queue_create("com.jinken.listapp.model", DISPATCH_QUEUE_SERIAL);
    _items = @[];
    _isLoading = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearIconCache)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    return self;
}

- (NSArray<ListAppItem *> *)allItems {
    return _items ?: @[];
}

- (void)clearIconCache {
    for (ListAppItem *item in _items) {
        item.cachedIcon = nil;
    }
}

- (void)loadInstalledApplicationsWithCompletion:(void(^)(NSArray<ListAppItem *> *apps))completion {
    if (_isLoading) {
        if (completion) completion(_items ?: @[]);
        return;
    }
    _isLoading = YES;

    dispatch_async(_workerQueue, ^{
        NSMutableArray<ListAppItem *> *results = [NSMutableArray array];
        NSMutableSet<NSString *> *seenBids = [NSMutableSet set];

        NSSet<NSString *> *blacklist = [NSSet setWithObjects:
            @"com.apple.springboard",
            @"com.apple.DiagnosticsService",
            @"com.apple.ScreenshotServicesService",
            @"com.apple.PreBoard",
            @"com.apple.CarPlay",
            @"com.apple.InCallService",
            @"com.apple.sidecar",
            @"com.apple.PassbookUIService",
            @"com.apple.WebContentFilter.remoteUI.bar",
            @"com.apple.purplebuddy",
            @"com.apple.CoreAuthUI",
            @"com.apple.StoreDemoViewService",
            @"com.apple.DataActivation",
            @"com.apple.ios.StoreKitUIService",
            @"com.apple.AskPermissionUI",
            @"com.apple.CompassCalibrationViewService",
            @"com.apple.HealthPrivacyHost",
            @"com.apple.MailCompositionService",
            @"com.apple.MusicUIService",
            @"com.apple.SharingViewService",
            @"com.apple.SafariViewService",
            @"com.apple.TrustMe",
            @"com.apple.CheckerBoard",
            @"com.apple.AccountAuthenticationDialog",
            @"com.apple.SubCredentialUIService",
            @"com.apple.CoreServices.UIRecording",
            @"com.apple.SiriViewService",
            @"com.apple.ScreenTimeUnlock",
            @"com.apple.DDActionsService",
            @"com.apple.PhotosViewService",
            @"com.apple.PrintKitUI",
            @"com.apple.quicklook",
            @"com.apple.quicklook.extension",
            @"com.apple.mobilesms.compose",
            @"com.apple.AdPlatformsViewService",
            nil
        ];

        // 1. First priority: SBIconModel from SBIconController (contains only real user-facing Home Screen apps)
        @try {
            Class icClass = objc_getClass("SBIconController");
            if (icClass) {
                id iconCtrl = [icClass sharedInstance];
                id model = [iconCtrl respondsToSelector:@selector(model)] ? [iconCtrl model] : nil;
                if (!model && [iconCtrl respondsToSelector:@selector(iconManager)]) {
                    id mgr = [iconCtrl iconManager];
                    if ([mgr respondsToSelector:@selector(iconModel)]) {
                        model = [mgr iconModel];
                    }
                }
                if (model) {
                    NSArray *icons = nil;
                    if ([model respondsToSelector:@selector(allApplicationIcons)]) {
                        icons = [model allApplicationIcons];
                    } else if ([model respondsToSelector:@selector(leafIcons)]) {
                        icons = [model leafIcons];
                    }
                    if (icons && icons.count > 0) {
                        for (id icon in icons) {
                            if (!icon) continue;
                            if ([icon isKindOfClass:objc_getClass("SBBookmarkIcon")] ||
                                [icon isKindOfClass:objc_getClass("SBWebClipIcon")]) {
                                continue;
                            }
                            NSString *bid = nil;
                            if ([icon respondsToSelector:@selector(applicationBundleID)]) {
                                bid = [icon applicationBundleID];
                            } else if ([icon respondsToSelector:@selector(application)]) {
                                id app = [icon application];
                                if ([app respondsToSelector:@selector(bundleIdentifier)]) {
                                    bid = [app bundleIdentifier];
                                }
                            } else if ([icon respondsToSelector:@selector(leafIdentifier)]) {
                                bid = [icon leafIdentifier];
                            }
                            if (!bid || bid.length == 0) continue;
                            if ([blacklist containsObject:bid]) continue;
                            if ([seenBids containsObject:bid]) continue;

                            // Exclude internal backend helpers
                            if ([bid hasPrefix:@"com.apple.WebKit."] ||
                                [bid hasSuffix:@"Service"] ||
                                [bid hasSuffix:@"ViewService"] ||
                                [bid hasSuffix:@"Daemon"] ||
                                [bid hasSuffix:@"Helper"] ||
                                [bid hasSuffix:@"Plugin"] ||
                                [bid hasSuffix:@"Extension"] ||
                                [bid hasSuffix:@"XPCService"]) {
                                continue;
                            }

                            NSString *name = nil;
                            if ([icon respondsToSelector:@selector(displayName)]) {
                                name = [icon displayName];
                            }
                            if (!name || name.length == 0) continue;

                            UIImage *testIcon = nil;
                            if ([icon respondsToSelector:@selector(getIconImage:)]) {
                                testIcon = [icon getIconImage:2];
                            }
                            if (!testIcon && [UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
                                CGFloat screenScale = [UIScreen mainScreen].scale;
                                testIcon = [UIImage _applicationIconImageForBundleIdentifier:bid format:2 scale:screenScale];
                                if (!testIcon) {
                                    testIcon = [UIImage _applicationIconImageForBundleIdentifier:bid format:0 scale:screenScale];
                                }
                            }
                            if (!testIcon) continue;

                            [seenBids addObject:bid];
                            ListAppItem *item = [[ListAppItem alloc] init];
                            item.bundleIdentifier = bid;
                            item.displayName = name;
                            item.cachedIcon = testIcon;
                            [results addObject:item];
                        }
                    }
                }
            }
        } @catch (NSException *e) {
            NSLog(@"[ListApp] SBIconModel query exception: %@", e);
        }

        // 2. Secondary fallback: SBApplicationController
        if (results.count == 0) {
            @try {
                Class sbClass = objc_getClass("SBApplicationController");
                if (sbClass) {
                    id ctrl = [sbClass sharedInstance];
                    if (ctrl && [ctrl respondsToSelector:@selector(allApplications)]) {
                        NSArray *sbApps = [ctrl allApplications];
                        for (id sbApp in sbApps) {
                            NSString *bid = [sbApp respondsToSelector:@selector(bundleIdentifier)] ? [sbApp bundleIdentifier] : nil;
                            NSString *name = [sbApp respondsToSelector:@selector(displayName)] ? [sbApp displayName] : nil;
                            if (bid.length > 0 && name.length > 0) {
                                if ([blacklist containsObject:bid]) continue;
                                if ([seenBids containsObject:bid]) continue;

                                if ([bid hasPrefix:@"com.apple.WebKit."] ||
                                    [bid hasSuffix:@"Service"] ||
                                    [bid hasSuffix:@"ViewService"] ||
                                    [bid hasSuffix:@"Daemon"] ||
                                    [bid hasSuffix:@"Helper"] ||
                                    [bid hasSuffix:@"Plugin"] ||
                                    [bid hasSuffix:@"Extension"] ||
                                    [bid hasSuffix:@"XPCService"]) {
                                    continue;
                                }

                                UIImage *testIcon = nil;
                                if ([UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
                                    CGFloat screenScale = [UIScreen mainScreen].scale;
                                    testIcon = [UIImage _applicationIconImageForBundleIdentifier:bid format:2 scale:screenScale];
                                    if (!testIcon) {
                                        testIcon = [UIImage _applicationIconImageForBundleIdentifier:bid format:0 scale:screenScale];
                                    }
                                }
                                if (!testIcon) continue;

                                [seenBids addObject:bid];
                                ListAppItem *item = [[ListAppItem alloc] init];
                                item.bundleIdentifier = bid;
                                item.displayName = name;
                                item.cachedIcon = testIcon;
                                [results addObject:item];
                            }
                        }
                    }
                }
            } @catch (NSException *e) {
                NSLog(@"[ListApp] SBApplicationController query exception: %@", e);
            }
        }

        // 3. Tertiary fallback: LSApplicationWorkspace (strictly filtering out backend daemons)
        if (results.count == 0) {
            @try {
                Class wsClass = objc_getClass("LSApplicationWorkspace");
                if (wsClass && [wsClass respondsToSelector:@selector(defaultWorkspace)]) {
                    LSApplicationWorkspace *ws = [wsClass defaultWorkspace];
                    NSArray<LSApplicationProxy *> *proxies = nil;
                    if ([ws respondsToSelector:@selector(allInstalledApplications)]) {
                        proxies = [ws allInstalledApplications];
                    } else if ([ws respondsToSelector:@selector(allApplications)]) {
                        proxies = [ws allApplications];
                    }

                    for (LSApplicationProxy *proxy in proxies) {
                        if (!proxy) continue;
                        NSString *bid = proxy.applicationIdentifier;
                        if (!bid || bid.length == 0) continue;
                        if ([blacklist containsObject:bid]) continue;
                        if ([seenBids containsObject:bid]) continue;

                        if ([proxy respondsToSelector:@selector(isPlaceholder)] && proxy.isPlaceholder) continue;
                        if ([proxy respondsToSelector:@selector(isRestricted)] && proxy.isRestricted) continue;

                        NSString *type = [proxy respondsToSelector:@selector(applicationType)] ? proxy.applicationType : nil;
                        if (type && ![type isEqualToString:@"User"] && ![type isEqualToString:@"System"]) continue;

                        if ([bid hasPrefix:@"com.apple.WebKit."] ||
                            [bid hasSuffix:@"Service"] ||
                            [bid hasSuffix:@"ViewService"] ||
                            [bid hasSuffix:@"Daemon"] ||
                            [bid hasSuffix:@"Helper"] ||
                            [bid hasSuffix:@"Plugin"] ||
                            [bid hasSuffix:@"Extension"] ||
                            [bid hasSuffix:@"XPCService"]) {
                            continue;
                        }

                        NSString *name = proxy.localizedName;
                        if (!name || name.length == 0) continue;

                        UIImage *testIcon = nil;
                        if ([UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
                            CGFloat screenScale = [UIScreen mainScreen].scale;
                            testIcon = [UIImage _applicationIconImageForBundleIdentifier:bid format:2 scale:screenScale];
                            if (!testIcon) {
                                testIcon = [UIImage _applicationIconImageForBundleIdentifier:bid format:0 scale:screenScale];
                            }
                        }
                        if (!testIcon) continue;

                        [seenBids addObject:bid];
                        ListAppItem *item = [[ListAppItem alloc] init];
                        item.bundleIdentifier = bid;
                        item.displayName = name;
                        item.cachedIcon = testIcon;
                        [results addObject:item];
                    }
                }
            } @catch (NSException *e) {
                NSLog(@"[ListApp] LSApplicationWorkspace query exception: %@", e);
            }
        }

        // Sort alphabetically by displayName
        [results sortUsingComparator:^NSComparisonResult(ListAppItem *a, ListAppItem *b) {
            return [a.displayName localizedCaseInsensitiveCompare:b.displayName];
        }];

        dispatch_async(dispatch_get_main_queue(), ^{
            self->_items = [results copy];
            self->_isLoading = NO;
            if (completion) {
                completion(self->_items);
            }
        });
    });
}

- (NSArray<ListAppItem *> *)filteredAppsWithQuery:(NSString *)query {
    if (!query || query.length == 0) {
        return _items ?: @[];
    }

    NSString *cleanQuery = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (cleanQuery.length == 0) return _items ?: @[];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"displayName CONTAINS[cd] %@ OR bundleIdentifier CONTAINS[cd] %@", cleanQuery, cleanQuery];
    return [_items filteredArrayUsingPredicate:pred] ?: @[];
}

- (void)launchApp:(ListAppItem *)item {
    if (!item || item.bundleIdentifier.length == 0) return;
    NSString *bundleID = item.bundleIdentifier;

    @try {
        // Method 1: SBIconController launchIcon: (Provides native SpringBoard zoom & springboard transition)
        Class icClass = objc_getClass("SBIconController");
        if (icClass) {
            id iconCtrl = [icClass sharedInstance];
            if (iconCtrl) {
                id model = [iconCtrl respondsToSelector:@selector(model)] ? [iconCtrl model] : nil;
                if (!model && [iconCtrl respondsToSelector:@selector(iconManager)]) {
                    id mgr = [iconCtrl iconManager];
                    if ([mgr respondsToSelector:@selector(iconModel)]) {
                        model = [mgr iconModel];
                    }
                }
                if (model) {
                    id icon = nil;
                    if ([model respondsToSelector:@selector(applicationIconForBundleIdentifier:)]) {
                        icon = [model applicationIconForBundleIdentifier:bundleID];
                    } else if ([model respondsToSelector:@selector(expectedIconForDisplayIdentifier:)]) {
                        icon = [model expectedIconForDisplayIdentifier:bundleID];
                    }
                    if (icon && [iconCtrl respondsToSelector:@selector(launchIcon:)]) {
                        [iconCtrl launchIcon:icon];
                        return;
                    }
                }
            }
        }

        // Method 2: SBApplicationController + SBUIController activateApplication:
        Class sbAppClass = objc_getClass("SBApplicationController");
        if (sbAppClass) {
            SBApplicationController *appCtrl = [sbAppClass sharedInstance];
            if (appCtrl && [appCtrl respondsToSelector:@selector(applicationWithBundleIdentifier:)]) {
                SBApplication *sbApp = [appCtrl applicationWithBundleIdentifier:bundleID];
                if (sbApp) {
                    Class sbUIClass = objc_getClass("SBUIController");
                    if (sbUIClass) {
                        SBUIController *uiCtrl = [sbUIClass sharedInstance];
                        if ([uiCtrl respondsToSelector:@selector(activateApplication:)]) {
                            [uiCtrl activateApplication:sbApp];
                            return;
                        }
                    }
                }
            }
        }

        // Method 3: SpringBoard native launchApplicationWithIdentifier:suspended:
        UIApplication *app = [UIApplication sharedApplication];
        if ([app respondsToSelector:@selector(launchApplicationWithIdentifier:suspended:)]) {
            ((void(*)(id, SEL, NSString *, BOOL))objc_msgSend)(app, @selector(launchApplicationWithIdentifier:suspended:), bundleID, NO);
            return;
        }

        // Method 4: LSApplicationWorkspace openApplicationWithBundleIdentifier:
        Class wsClass = objc_getClass("LSApplicationWorkspace");
        if (wsClass && [wsClass respondsToSelector:@selector(defaultWorkspace)]) {
            LSApplicationWorkspace *ws = [wsClass defaultWorkspace];
            if ([ws respondsToSelector:@selector(openApplicationWithBundleIdentifier:)]) {
                if ([ws openApplicationWithBundleIdentifier:bundleID]) {
                    return;
                }
            }
        }

        // Method 5: FBSOpenApplicationService with unlock options
        Class fbsClass = objc_getClass("FBSOpenApplicationService");
        Class fbsOptionsClass = objc_getClass("FBSOpenApplicationOptions");
        if (fbsClass) {
            FBSOpenApplicationService *service = [fbsClass serviceWithDefaultEndpoint];
            if (service && [service respondsToSelector:@selector(openApplication:withOptions:completion:)]) {
                id options = nil;
                if (fbsOptionsClass && [fbsOptionsClass respondsToSelector:@selector(optionsWithDictionary:)]) {
                    options = [fbsOptionsClass optionsWithDictionary:@{
                        @"__UnlockDevice": @YES,
                        @"__PromptUnlockIfNecessary": @YES
                    }];
                }
                [service openApplication:bundleID withOptions:options completion:nil];
                return;
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[ListApp] Exception launching %@: %@", bundleID, e);
    }
}

@end
