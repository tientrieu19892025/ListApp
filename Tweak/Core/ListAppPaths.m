#import "ListAppPaths.h"
#import "ListAppConstants.h"

@implementation ListAppPaths

+ (NSString *)jailbreakPrefix {
    static NSString *prefix;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:@"/var/jb/usr/lib/TweakInject"] || [fm fileExistsAtPath:@"/var/jb/Library/MobileSubstrate"]) {
            prefix = @"/var/jb";
        } else if ([fm fileExistsAtPath:@"/usr/lib/TweakInject"] || [fm fileExistsAtPath:@"/Library/MobileSubstrate"]) {
            prefix = @"";
        } else {
            prefix = [fm fileExistsAtPath:@"/var/jb"] ? @"/var/jb" : @"";
        }
    });
    return prefix;
}

+ (NSArray<NSString *> *)preferenceFilePaths {
    NSString *jb = [self jailbreakPrefix];
    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    NSString *file = [@"/var/mobile/Library/Preferences/" stringByAppendingString:[kListAppPrefsIdentifier stringByAppendingString:@".plist"]];
    if (jb.length) {
        [paths addObject:[jb stringByAppendingString:file]];
    }
    [paths addObject:file];
    return paths;
}

+ (NSString *)writablePreferencePath {
    NSString *jb = [self jailbreakPrefix];
    NSString *file = [@"/var/mobile/Library/Preferences/" stringByAppendingString:[kListAppPrefsIdentifier stringByAppendingString:@".plist"]];
    if (jb.length) return [jb stringByAppendingString:file];
    return file;
}

+ (BOOL)ensureDirectory:(NSString *)path {
    if (path.length == 0) return NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:path isDirectory:&isDir]) return isDir;
    return [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions: @0755} error:nil];
}

@end
