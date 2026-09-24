#import "ListAppGridCell.h"
#import "ListAppPrefs.h"
#import "ListAppConstants.h"
#import <QuartzCore/QuartzCore.h>

@implementation ListAppGridCell {
    UIView *_pillContainerView;
    UIView *_cardClipView;
    UIVisualEffectView *_blurView;
    UIView *_tintView;
    CAGradientLayer *_specularLayer;
    CALayer *_hairlineBorder;
    UIImageView *_iconImageView;
    UILabel *_titleLabel;
    UIImageView *_chevronImageView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return self;

    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];

    // 1. Pill container with outer drop shadow
    _pillContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    _pillContainerView.backgroundColor = [UIColor clearColor];
    _pillContainerView.userInteractionEnabled = NO;
    _pillContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
    _pillContainerView.layer.shadowOpacity = 0.18;
    _pillContainerView.layer.shadowRadius = 8.0;
    _pillContainerView.layer.shadowOffset = CGSizeMake(0, 3);
    [self.contentView addSubview:_pillContainerView];

    // 2. Inner clipped card view
    _cardClipView = [[UIView alloc] initWithFrame:CGRectZero];
    _cardClipView.clipsToBounds = YES;
    _cardClipView.userInteractionEnabled = NO;
    _cardClipView.backgroundColor = [UIColor clearColor];
    _cardClipView.layer.cornerRadius = 18.0;
    if (@available(iOS 13.0, *)) {
        _cardClipView.layer.cornerCurve = kCACornerCurveContinuous;
    }
    [_pillContainerView addSubview:_cardClipView];

    // 3. Frosted blur effect
    UIBlurEffect *blurEffect = [self currentBlurEffect];
    _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    _blurView.userInteractionEnabled = NO;
    [_cardClipView addSubview:_blurView];

    // 4. Adaptive tint
    _tintView = [[UIView alloc] initWithFrame:CGRectZero];
    _tintView.userInteractionEnabled = NO;
    [_cardClipView addSubview:_tintView];

    // 5. Specular highlight (liquid glass shine)
    _specularLayer = [CAGradientLayer layer];
    _specularLayer.startPoint = CGPointMake(0.0, 0.0);
    _specularLayer.endPoint = CGPointMake(1.0, 1.0);
    [_cardClipView.layer addSublayer:_specularLayer];

    // 6. Hairline border
    _hairlineBorder = [CALayer layer];
    _hairlineBorder.cornerRadius = 18.0;
    if (@available(iOS 13.0, *)) {
        _hairlineBorder.cornerCurve = kCACornerCurveContinuous;
    }
    [_cardClipView.layer addSublayer:_hairlineBorder];

    // 7. App Icon (left)
    _iconImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    _iconImageView.clipsToBounds = YES;
    _iconImageView.userInteractionEnabled = NO;
    _iconImageView.layer.cornerRadius = 10.0;
    if (@available(iOS 13.0, *)) {
        _iconImageView.layer.cornerCurve = kCACornerCurveContinuous;
    }
    [_cardClipView addSubview:_iconImageView];

    // 8. App Title (center-left)
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.userInteractionEnabled = NO;
    _titleLabel.numberOfLines = 1;
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _titleLabel.layer.shadowOpacity = 0.35;
    _titleLabel.layer.shadowRadius = 2.0;
    _titleLabel.layer.shadowOffset = CGSizeMake(0, 1);
    [_cardClipView addSubview:_titleLabel];

    // 9. Chevron indicator (right)
    _chevronImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _chevronImageView.contentMode = UIViewContentModeScaleAspectFit;
    _chevronImageView.userInteractionEnabled = NO;
    if (@available(iOS 13.0, *)) {
        UIImage *chevron = [UIImage systemImageNamed:@"chevron.right"];
        _chevronImageView.image = chevron;
        _chevronImageView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.45];
    }
    [_cardClipView addSubview:_chevronImageView];

    // Direct cell tap gesture recognizer for zero-delay response
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCellTap:)];
    tap.cancelsTouchesInView = NO;
    [self.contentView addGestureRecognizer:tap];

    [self applyStyle];
    return self;
}

- (void)handleCellTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (self.onTapHandler) {
            self.onTapHandler();
        }
    }
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
    CGFloat intensity = [ListAppPrefs intensity];
    BOOL isDark = YES;
    if (@available(iOS 13.0, *)) {
        isDark = (self.traitCollection.userInterfaceStyle != UIUserInterfaceStyleLight);
    }

    _blurView.effect = [self currentBlurEffect];

    NSInteger colorMode = [ListAppPrefs glassColor];
    UIColor *tintColor = nil;
    UIColor *borderColor = nil;
    CGFloat borderAlpha = isDark ? MAX(0.18, 0.42 - intensity * 0.10) : MAX(0.24, 0.52 - intensity * 0.10);

    switch (colorMode) {
        case ListAppGlassColorObsidian:
            tintColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.05 alpha:0.42 + intensity * 0.30];
            borderColor = [UIColor colorWithWhite:1.0 alpha:borderAlpha * 0.65];
            break;
        case ListAppGlassColorSapphire:
            tintColor = [UIColor colorWithRed:0.06 green:0.25 blue:0.62 alpha:0.32 + intensity * 0.28];
            borderColor = [UIColor colorWithRed:0.45 green:0.75 blue:1.0 alpha:borderAlpha];
            break;
        case ListAppGlassColorEmerald:
            tintColor = [UIColor colorWithRed:0.04 green:0.42 blue:0.24 alpha:0.30 + intensity * 0.28];
            borderColor = [UIColor colorWithRed:0.45 green:1.0 blue:0.65 alpha:borderAlpha];
            break;
        case ListAppGlassColorAmethyst:
            tintColor = [UIColor colorWithRed:0.38 green:0.12 blue:0.56 alpha:0.32 + intensity * 0.28];
            borderColor = [UIColor colorWithRed:0.85 green:0.55 blue:1.0 alpha:borderAlpha];
            break;
        case ListAppGlassColorSunset:
            tintColor = [UIColor colorWithRed:0.60 green:0.14 blue:0.25 alpha:0.32 + intensity * 0.28];
            borderColor = [UIColor colorWithRed:1.0 green:0.55 blue:0.65 alpha:borderAlpha];
            break;
        case ListAppGlassColorFrostedWhite:
            tintColor = [UIColor colorWithWhite:0.96 alpha:0.34 + intensity * 0.26];
            borderColor = [UIColor colorWithWhite:1.0 alpha:MIN(borderAlpha * 1.2, 0.85)];
            break;
        case ListAppGlassColorCrystal:
        default: {
            CGFloat tintWhite = isDark ? 0.12 : 0.95;
            CGFloat tintAlpha = isDark ? (0.18 + intensity * 0.28) : (0.16 + intensity * 0.22);
            tintColor = [UIColor colorWithWhite:tintWhite alpha:tintAlpha];
            borderColor = [UIColor colorWithWhite:1.0 alpha:borderAlpha];
            break;
        }
    }

    _tintView.backgroundColor = tintColor;

    if ([ListAppPrefs specular]) {
        _specularLayer.hidden = NO;
        CGFloat glareAlpha = isDark ? 0.22 : 0.35;
        _specularLayer.colors = @[
            (id)[UIColor colorWithWhite:1.0 alpha:glareAlpha].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:glareAlpha * 0.25].CGColor
        ];
        _specularLayer.locations = @[@0.0, @0.5, @1.0];
    } else {
        _specularLayer.hidden = YES;
    }

    NSInteger design = [ListAppPrefs frameDesign];
    CGFloat borderWidth = 1.0 / MAX([UIScreen mainScreen].scale, 2.0);
    if (design == ListAppFrameDesignMinimal) {
        borderWidth = 0.0;
    } else if (design == ListAppFrameDesignBordered) {
        borderWidth = 2.0;
        borderColor = [borderColor colorWithAlphaComponent:MIN(borderAlpha * 1.5, 0.90)];
    }

    _hairlineBorder.borderColor = borderColor.CGColor;
    _hairlineBorder.borderWidth = borderWidth;
}

- (void)configureWithItem:(ListAppItem *)item {
    _titleLabel.text = item.displayName ?: @"";
    CGFloat scale = [UIScreen mainScreen].scale;
    _iconImageView.image = [item iconImageWithScale:scale];
    [self applyStyle];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat totalW = self.contentView.bounds.size.width;
    CGFloat totalH = self.contentView.bounds.size.height;
    if (totalW <= 0 || totalH <= 0) return;

    // The elongated pill occupies 2/3 of the screen width, centered horizontally
    CGFloat pillWidth = floor(totalW * (2.0 / 3.0));
    CGFloat pillX = floor((totalW - pillWidth) / 2.0);
    CGFloat pillHeight = totalH - 8.0;

    _pillContainerView.frame = CGRectMake(pillX, 4.0, pillWidth, pillHeight);
    _cardClipView.frame = _pillContainerView.bounds;
    _blurView.frame = _cardClipView.bounds;
    _tintView.frame = _cardClipView.bounds;
    _specularLayer.frame = _cardClipView.bounds;
    _hairlineBorder.frame = _cardClipView.bounds;

    NSInteger design = [ListAppPrefs frameDesign];
    CGFloat cornerRad = 18.0;
    switch (design) {
        case ListAppFrameDesignCapsule:
            cornerRad = pillHeight / 2.0;
            break;
        case ListAppFrameDesignRounded:
            cornerRad = 12.0;
            break;
        case ListAppFrameDesignSquircle:
            cornerRad = 18.0;
            break;
        case ListAppFrameDesignBordered:
            cornerRad = 16.0;
            break;
        case ListAppFrameDesignMinimal:
            cornerRad = 14.0;
            break;
        default:
            cornerRad = 18.0;
            break;
    }
    _cardClipView.layer.cornerRadius = cornerRad;
    _hairlineBorder.cornerRadius = cornerRad;

    // Icon on left
    CGFloat iconSz = 42.0;
    CGFloat iconY = floor((pillHeight - iconSz) / 2.0);
    _iconImageView.frame = CGRectMake(12.0, iconY, iconSz, iconSz);

    // Chevron on right
    CGFloat chevW = 12.0;
    CGFloat chevH = 16.0;
    CGFloat chevX = pillWidth - chevW - 14.0;
    CGFloat chevY = floor((pillHeight - chevH) / 2.0);
    _chevronImageView.frame = CGRectMake(chevX, chevY, chevW, chevH);

    // Title in middle
    CGFloat titleX = CGRectGetMaxX(_iconImageView.frame) + 14.0;
    CGFloat titleW = chevX - titleX - 8.0;
    CGFloat titleH = 24.0;
    CGFloat titleY = floor((pillHeight - titleH) / 2.0);
    _titleLabel.frame = CGRectMake(titleX, titleY, titleW, titleH);
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.18 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0.6 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        if (highlighted) {
            self->_pillContainerView.transform = CGAffineTransformMakeScale(0.96, 0.96);
            self->_pillContainerView.alpha = 0.85;
        } else {
            self->_pillContainerView.transform = CGAffineTransformIdentity;
            self->_pillContainerView.alpha = 1.0;
        }
    } completion:nil];
}

@end
