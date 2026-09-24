#import <UIKit/UIKit.h>

@interface ListAppContainerView : UIView

+ (instancetype)sharedView;
- (void)reloadApps;
- (void)applyConfiguration;

@end
