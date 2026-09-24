#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ListAppItem : NSObject

@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, strong) UIImage *cachedIcon;

- (UIImage *)iconImageWithScale:(CGFloat)scale;

@end

@interface ListAppModel : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, readonly) NSArray<ListAppItem *> *allItems;
@property (nonatomic, readonly) BOOL isLoading;

- (void)loadInstalledApplicationsWithCompletion:(void(^)(NSArray<ListAppItem *> *apps))completion;
- (NSArray<ListAppItem *> *)filteredAppsWithQuery:(NSString *)query;
- (void)launchApp:(ListAppItem *)item;
- (void)clearIconCache;

@end
