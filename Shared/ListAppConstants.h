#ifndef LISTAPP_CONSTANTS_H
#define LISTAPP_CONSTANTS_H

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

static NSString * const kListAppPrefsIdentifier = @"com.jinken.listapp";
static NSString * const kListAppReloadNotification = @"com.jinken.listapp/ReloadPrefs";
static NSString * const kListAppRespringNotification = @"com.jinken.listapp/Respring";

// Configuration keys
static NSString * const kListAppEnabled = @"Enabled";
static NSString * const kListAppGridColumns = @"GridColumns";
static NSString * const kListAppContainerHeightRatio = @"ContainerHeightRatio";
static NSString * const kListAppCornerRadius = @"CornerRadius";
static NSString * const kListAppIntensity = @"Intensity";
static NSString * const kListAppBlurStyle = @"BlurStyle";
static NSString * const kListAppFrameDesign = @"FrameDesign";
static NSString * const kListAppGlassColor = @"GlassColor";
static NSString * const kListAppSpecular = @"SpecularHighlight";
static NSString * const kListAppBorderGlow = @"BorderGlow";
static NSString * const kListAppShowSearchBar = @"ShowSearchBar";
static NSString * const kListAppHideStockIcons = @"HideStockIcons";
static NSString * const kListAppHideDock = @"HideDock";
static NSString * const kListAppHidePageDots = @"HidePageDots";
static NSString * const kListAppHaptics = @"Haptics";
static NSString * const kListAppIconSize = @"IconSize";
static NSString * const kListAppCrashProtection = @"CrashProtection";
static NSString * const kListAppRespectReduceTransparency = @"RespectReduceTransparency";
static NSString * const kListAppRespectReduceMotion = @"RespectReduceMotion";
static NSString * const kListAppCheapBlurOnLPM = @"CheapBlurOnLPM";
static NSString * const kListAppShowBadges = @"ShowBadges";
static NSString * const kListAppBadgePosition = @"BadgePosition";

// Badge positions
typedef NS_ENUM(NSInteger, ListAppBadgePosition) {
    ListAppBadgePositionRight = 0,   // Bên phải trong khung (cạnh chevron)
    ListAppBadgePositionCenter = 1   // Ở giữa khung (sau tên ứng dụng)
};
typedef NS_ENUM(NSInteger, ListAppFrameDesign) {
    ListAppFrameDesignCapsule = 0,        // Bo tròn viên thuốc mượt mà (Full Pill)
    ListAppFrameDesignRounded = 1,        // Hình chữ nhật bo nhẹ 12pt (Rounded 12pt)
    ListAppFrameDesignSquircle = 2,       // Squircle chuẩn iOS 18pt
    ListAppFrameDesignBordered = 3,       // Khung viền kính kép nổi bật (Double Glow)
    ListAppFrameDesignMinimal = 4,        // Tối giản trong suốt không viền (Minimal)
    ListAppFrameDesignNeonGlow = 5,       // Viền đèn Neon phát sáng huyền ảo (Neon Glow)
    ListAppFrameDesignCyberpunk = 6,      // Phong cách viền góc vát hiện đại (Chiseled/Cyber)
    ListAppFrameDesignFloatingShadow = 7, // Thẻ nổi 3D đổ bóng sâu siêu thực (Deep Float)
    ListAppFrameDesignDiamondCut = 8      // Bo góc kim cương sang trọng (Diamond Cut)
};

// Glass colors
typedef NS_ENUM(NSInteger, ListAppGlassColor) {
    ListAppGlassColorCrystal = 0,     // Pha lê trong suốt (tự nhiên)
    ListAppGlassColorObsidian = 1,    // Đen tuyền bóng đêm
    ListAppGlassColorSapphire = 2,    // Xanh dương Sapphire
    ListAppGlassColorEmerald = 3,     // Xanh ngọc lục bảo
    ListAppGlassColorAmethyst = 4,    // Tím thạch anh
    ListAppGlassColorSunset = 5,      // Đỏ ruby hoàng hôn
    ListAppGlassColorFrostedWhite = 6 // Trắng sương mù tuyết phủ
};

// Features for safety tracking
static NSString * const kListAppFeatureGrid = @"grid";
static NSString * const kListAppFeatureSearch = @"search";
static NSString * const kListAppFeatureGlass = @"glass";

// Defaults
static const NSInteger kListAppDefaultGridColumns = 1; // 1 column for elongated pills
static const CGFloat kListAppDefaultHeightRatio = 0.74;
static const CGFloat kListAppDefaultCornerRadius = 18.0;
static const CGFloat kListAppDefaultIntensity = 0.38;
static const CGFloat kListAppDefaultIconSize = 42.0;
static const NSInteger kListAppFailureDisableThreshold = 15;

static NSString * const kListAppVersion = @"1.2.2";
static NSString * const kListAppCodename = @"Crystal";

#endif
