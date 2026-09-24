#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ListAppPrefs : NSObject

+ (void)startObserving;
+ (void)reload;

+ (BOOL)enabled;
+ (NSInteger)gridColumns;
+ (CGFloat)containerHeightRatio;
+ (CGFloat)cornerRadius;
+ (CGFloat)intensity;
+ (NSInteger)blurStyle;
+ (BOOL)specular;
+ (BOOL)borderGlow;
+ (BOOL)showSearchBar;
+ (BOOL)hideStockIcons;
+ (BOOL)hideDock;
+ (BOOL)hidePageDots;
+ (BOOL)haptics;
+ (CGFloat)iconSize;
+ (BOOL)crashProtection;
+ (BOOL)respectReduceTransparency;
+ (BOOL)respectReduceMotion;
+ (BOOL)cheapBlurOnLPM;
+ (NSInteger)frameDesign;
+ (NSInteger)glassColor;

@end
