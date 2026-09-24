#import "ListAppRootListController.h"
#import "ListAppConstants.h"
#import <SafariServices/SafariServices.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <spawn.h>
#import <unistd.h>

extern char **environ;

static UIColor *LAAccentColor(void) {
    return [UIColor colorWithRed:0.22 green:0.67 blue:0.98 alpha:1.0];
}

static NSBundle *LABundle(void) {
    return [NSBundle bundleForClass:[LARootListController class]];
}

static NSString *L(NSString *key) {
    if (key.length == 0) return key;
    return [LABundle() localizedStringForKey:key value:key table:@"Localizable"];
}

static void LAOpenURL(NSString *urlStr, UIViewController *host) {
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) return;
    if (@available(iOS 9.0, *)) {
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url];
        [host presentViewController:safari animated:YES completion:nil];
    } else {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

static void LARespring(void) {
    pid_t pid;
    const char *reloadPaths[] = { "/var/jb/usr/bin/sbreload", "/usr/bin/sbreload", NULL };
    for (int i = 0; reloadPaths[i]; i++) {
        if (access(reloadPaths[i], X_OK) != 0) continue;
        const char *args[] = { reloadPaths[i], NULL };
        if (posix_spawn(&pid, reloadPaths[i], NULL, NULL, (char *const *)args, environ) == 0) return;
    }
    const char *killPaths[] = { "/var/jb/usr/bin/killall", "/usr/bin/killall", NULL };
    for (int i = 0; killPaths[i]; i++) {
        if (access(killPaths[i], X_OK) != 0) continue;
        const char *args[] = { killPaths[i], "-9", "SpringBoard", NULL };
        if (posix_spawn(&pid, killPaths[i], NULL, NULL, (char *const *)args, environ) == 0) return;
    }
}

@implementation LAHeaderCell {
    UIImageView *_banner;
    UIView *_scrim;
    UILabel *_title;
    UILabel *_subtitle;
    UILabel *_version;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if (!self) return self;

    self.backgroundColor = [UIColor clearColor];
    self.backgroundView = [UIView new];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    if ([self respondsToSelector:@selector(textLabel)]) {
        self.textLabel.hidden = YES;
    }

    _banner = [UIImageView new];
    _banner.contentMode = UIViewContentModeScaleAspectFill;
    _banner.clipsToBounds = YES;
    _banner.layer.cornerRadius = 16;
    _banner.backgroundColor = [UIColor colorWithRed:0.06 green:0.12 blue:0.24 alpha:1.0];
    if (@available(iOS 13.0, *)) _banner.layer.cornerCurve = kCACornerCurveContinuous;

    NSString *path = [LABundle() pathForResource:@"banner" ofType:@"png"];
    if (!path) path = [LABundle() pathForResource:@"banner@2x" ofType:@"png"];
    if (path) _banner.image = [UIImage imageWithContentsOfFile:path];
    [self.contentView addSubview:_banner];

    _scrim = [UIView new];
    _scrim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.32];
    [_banner addSubview:_scrim];

    _title = [UILabel new];
    _title.text = @"ListApp";
    _title.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    _title.textColor = [UIColor whiteColor];
    [self.contentView addSubview:_title];

    _subtitle = [UILabel new];
    _subtitle.text = L(@"HEADER_SUBTITLE");
    _subtitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    _subtitle.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
    _subtitle.numberOfLines = 2;
    [self.contentView addSubview:_subtitle];

    _version = [UILabel new];
    _version.text = [NSString stringWithFormat:@"  v%@  ", kListAppVersion];
    _version.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    _version.textColor = [UIColor whiteColor];
    _version.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.24];
    _version.textAlignment = NSTextAlignmentCenter;
    _version.layer.cornerRadius = 10;
    _version.clipsToBounds = YES;
    [self.contentView addSubview:_version];

    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    return 150.0;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat inset = 12.0;
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    _banner.frame = CGRectMake(inset, 4.0, w - inset * 2.0, h - 8.0);
    _scrim.frame = _banner.bounds;
    _title.frame = CGRectMake(_banner.frame.origin.x + 18, _banner.frame.origin.y + 18, _banner.frame.size.width - 36, 34);
    _subtitle.frame = CGRectMake(_title.frame.origin.x, CGRectGetMaxY(_title.frame) + 2, _banner.frame.size.width - 36, 34);
    [_version sizeToFit];
    CGFloat vw = MAX(60, _version.bounds.size.width + 14);
    _version.frame = CGRectMake(_title.frame.origin.x, CGRectGetMaxY(_banner.frame) - 30, vw, 20);
}

@end

@implementation LABaseListController

- (NSBundle *)bundle {
    return LABundle();
}

- (NSString *)plistName {
    return @"Root";
}

- (NSArray *)specifiers {
    if (!_cachedSpecifiers) {
        NSArray *loaded = [self loadSpecifiersFromPlistName:[self plistName] target:self];
        NSMutableArray *specs = [NSMutableArray array];
        for (PSSpecifier *sp in loaded ?: @[]) {
            if (sp.name.length) {
                sp.name = L(sp.name);
            }
            NSString *footer = [sp propertyForKey:@"footerText"];
            if ([footer isKindOfClass:[NSString class]] && footer.length) {
                [sp setProperty:L(footer) forKey:@"footerText"];
            }
            NSString *title = [sp propertyForKey:@"title"];
            if ([title isKindOfClass:[NSString class]] && title.length) {
                [sp setProperty:L(title) forKey:@"title"];
            }
            NSArray *validTitles = [sp propertyForKey:@"validTitles"];
            if ([validTitles isKindOfClass:[NSArray class]]) {
                NSMutableArray *locTitles = [NSMutableArray array];
                for (id t in validTitles) {
                    if ([t isKindOfClass:[NSString class]]) {
                        [locTitles addObject:L(t)];
                    } else {
                        [locTitles addObject:t];
                    }
                }
                [sp setProperty:[locTitles copy] forKey:@"validTitles"];
            }
            [specs addObject:sp];
        }
        _cachedSpecifiers = [specs copy];
        
        Ivar ivar = class_getInstanceVariable([PSListController class], "_specifiers");
        if (ivar) {
            object_setIvar(self, ivar, _cachedSpecifiers);
        }
    }
    return _cachedSpecifiers;
}

- (void)reloadSpecifiers {
    _cachedSpecifiers = nil;
    Ivar ivar = class_getInstanceVariable([PSListController class], "_specifiers");
    if (ivar) {
        object_setIvar(self, ivar, nil);
    }
    [super reloadSpecifiers];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (key.length == 0) return;
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, (__bridge CFStringRef)kListAppPrefsIdentifier);
    CFPreferencesAppSynchronize((__bridge CFStringRef)kListAppPrefsIdentifier);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge CFStringRef)kListAppReloadNotification,
                                         NULL, NULL, YES);
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (key.length == 0) return [specifier propertyForKey:@"default"];
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)kListAppPrefsIdentifier);
    if (value) return (__bridge_transfer id)value;
    return [specifier propertyForKey:@"default"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [gen impactOccurred];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        self.view.tintColor = LAAccentColor();
    }
}

@end

@implementation LARootListController

- (NSString *)plistName {
    return @"Root";
}

- (void)respring {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"RESPRING")
                                                                   message:L(@"RESPRING_MSG")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:L(@"CANCEL") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:L(@"RESPRING") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        (void)action;
        LARespring();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetSettings {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"RESET")
                                                                   message:L(@"RESET_MSG")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:L(@"CANCEL") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:L(@"RESET") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        (void)action;
        CFPreferencesSetMultiple(NULL, NULL, (__bridge CFStringRef)kListAppPrefsIdentifier,
                                 kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        CFPreferencesAppSynchronize((__bridge CFStringRef)kListAppPrefsIdentifier);
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                             (__bridge CFStringRef)kListAppReloadNotification,
                                             NULL, NULL, YES);
        [self reloadSpecifiers];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

@implementation LASubListController

- (NSString *)plistName {
    NSString *name = [self.specifier propertyForKey:@"laPlist"];
    return name.length ? name : @"About";
}

- (void)openGitHub { LAOpenURL(@"https://github.com/jinkennguyen/ListApp", self); }
- (void)openX { LAOpenURL(@"https://x.com/jinkennguyen", self); }
- (void)openKofi { LAOpenURL(@"https://ko-fi.com/jinkennguyen", self); }
- (void)openPayPal { LAOpenURL(@"https://paypal.me/jinkennguyen", self); }
- (void)openSponsors { LAOpenURL(@"https://github.com/sponsors/jinkennguyen", self); }
- (void)openTheos { LAOpenURL(@"https://theos.dev", self); }
- (void)openLibroot { LAOpenURL(@"https://github.com/opa334/libroot", self); }
- (void)openElleKit { LAOpenURL(@"https://github.com/evelyneee/ellekit", self); }

@end
