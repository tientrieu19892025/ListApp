#import "ListAppGlassView.h"
#import "ListAppPrefs.h"
#import "ListAppConstants.h"
#import <QuartzCore/QuartzCore.h>

@implementation ListAppGlassView {
    UIView *_cardView;
    UIVisualEffectView *_blurView;
    UIView *_tintView;
    CAGradientLayer *_specularLayer;
    CAGradientLayer *_rimLayer;
    CALayer *_hairlineBorder;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return self;
    
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    
    _intensity = [ListAppPrefs intensity];
    _cornerRadius = [ListAppPrefs cornerRadius];
    _specularEnabled = [ListAppPrefs specular];
    _borderGlowEnabled = [ListAppPrefs borderGlow];

    // Card View (clipped with continuous corner radius)
    _cardView = [[UIView alloc] initWithFrame:self.bounds];
    _cardView.clipsToBounds = YES;
    _cardView.backgroundColor = [UIColor clearColor];
    [self addSubview:_cardView];

    // Blur Effect
    UIBlurEffect *blurEffect = [self currentBlurEffect];
    _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    _blurView.userInteractionEnabled = NO;
    [_cardView addSubview:_blurView];

    // Tint View
    _tintView = [[UIView alloc] initWithFrame:self.bounds];
    _tintView.userInteractionEnabled = NO;
    [_cardView addSubview:_tintView];

    // Specular Highlight (Liquid Glass diagonal glare)
    _specularLayer = [CAGradientLayer layer];
    _specularLayer.startPoint = CGPointMake(0.0, 0.0);
    _specularLayer.endPoint = CGPointMake(1.0, 1.0);
    [_cardView.layer addSublayer:_specularLayer];

    // Top Rim Light (Glass refraction edge)
    _rimLayer = [CAGradientLayer layer];
    _rimLayer.startPoint = CGPointMake(0.5, 0.0);
    _rimLayer.endPoint = CGPointMake(0.5, 1.0);
    [_cardView.layer addSublayer:_rimLayer];

    // Content container view (for subviews)
    _contentContainerView = [[UIView alloc] initWithFrame:self.bounds];
    _contentContainerView.backgroundColor = [UIColor clearColor];
    [_cardView addSubview:_contentContainerView];

    // Hairline border
    _hairlineBorder = [CALayer layer];
    [_cardView.layer addSublayer:_hairlineBorder];

    [self applyStyle];
    return self;
}

- (UIBlurEffect *)currentBlurEffect {
    if ([ListAppPrefs respectReduceTransparency] && UIAccessibilityIsReduceTransparencyEnabled()) {
        return [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    }
    if ([ListAppPrefs cheapBlurOnLPM] && [NSProcessInfo processInfo].lowPowerModeEnabled) {
        if (@available(iOS 13.0, *)) {
            return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThickMaterial];
        }
        return [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    }
    
    NSInteger style = [ListAppPrefs blurStyle];
    if (@available(iOS 13.0, *)) {
        switch (style) {
            case 1: return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
            case 2: return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
            case 3: return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
            case 4: return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialLight];
            default: return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
        }
    }
    return [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
}

- (void)applyStyle {
    _intensity = [ListAppPrefs intensity];
    _cornerRadius = [ListAppPrefs cornerRadius];
    _specularEnabled = [ListAppPrefs specular];
    _borderGlowEnabled = [ListAppPrefs borderGlow];

    // Update blur
    UIBlurEffect *blur = [self currentBlurEffect];
    if (_blurView.effect != blur) {
        _blurView.effect = blur;
    }

    // Adaptive tint color
    BOOL isDark = YES;
    if (@available(iOS 13.0, *)) {
        isDark = (self.traitCollection.userInterfaceStyle != UIUserInterfaceStyleLight);
    }
    
    CGFloat white = isDark ? 0.08 : 0.96;
    CGFloat alpha = isDark ? (0.15 + _intensity * 0.35) : (0.12 + _intensity * 0.28);
    _tintView.backgroundColor = [UIColor colorWithWhite:white alpha:alpha];

    // Specular diagonal glare
    if (_specularEnabled) {
        _specularLayer.hidden = NO;
        CGFloat glareAlpha = isDark ? (0.24 - _intensity * 0.08) : (0.35 - _intensity * 0.10);
        if (glareAlpha < 0.06) glareAlpha = 0.06;
        _specularLayer.colors = @[
            (id)[UIColor colorWithWhite:1.0 alpha:glareAlpha].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:glareAlpha * 0.3].CGColor
        ];
        _specularLayer.locations = @[@0.0, @0.45, @1.0];
    } else {
        _specularLayer.hidden = YES;
    }

    // Top Rim Refraction
    if (_borderGlowEnabled) {
        _rimLayer.hidden = NO;
        _rimLayer.colors = @[
            (id)[UIColor colorWithWhite:1.0 alpha:0.32].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.04].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.16].CGColor
        ];
        _rimLayer.locations = @[@0.0, @0.6, @1.0];
        _rimLayer.opacity = 0.6;
    } else {
        _rimLayer.hidden = YES;
    }

    // Hairline border
    CGFloat borderAlpha = isDark ? MAX(0.12, 0.40 - _intensity * 0.15) : MAX(0.18, 0.50 - _intensity * 0.15);
    _hairlineBorder.borderColor = [UIColor colorWithWhite:1.0 alpha:borderAlpha].CGColor;
    _hairlineBorder.borderWidth = 1.0 / MAX([UIScreen mainScreen].scale, 2.0);

    // Continuous Corner Radii
    _cardView.layer.cornerRadius = _cornerRadius;
    _hairlineBorder.cornerRadius = _cornerRadius;
    if (@available(iOS 13.0, *)) {
        _cardView.layer.cornerCurve = kCACornerCurveContinuous;
        _hairlineBorder.cornerCurve = kCACornerCurveContinuous;
    }

    // Floating drop shadow on outer view
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = isDark ? 0.28 : 0.16;
    self.layer.shadowRadius = 26.0;
    self.layer.shadowOffset = CGSizeMake(0, 12);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _cardView.frame = self.bounds;
    _blurView.frame = _cardView.bounds;
    _tintView.frame = _cardView.bounds;
    _specularLayer.frame = _cardView.bounds;
    _rimLayer.frame = _cardView.bounds;
    _contentContainerView.frame = _cardView.bounds;
    _hairlineBorder.frame = _cardView.bounds;
    _hairlineBorder.cornerRadius = _cornerRadius;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self applyStyle];
        }
    }
}

@end
