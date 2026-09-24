#import <UIKit/UIKit.h>

@interface ListAppGlassView : UIView

@property (nonatomic, assign) CGFloat intensity;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) BOOL specularEnabled;
@property (nonatomic, assign) BOOL borderGlowEnabled;
@property (nonatomic, readonly) UIView *contentContainerView;

- (void)applyStyle;

@end
