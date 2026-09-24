#import <Foundation/Foundation.h>

@interface ListAppPaths : NSObject

+ (NSString *)jailbreakPrefix;
+ (NSArray<NSString *> *)preferenceFilePaths;
+ (NSString *)writablePreferencePath;
+ (BOOL)ensureDirectory:(NSString *)path;

@end
