# Changelog

All notable changes to **ListApp** will be documented in this file.

## [1.2.3] - 2026-09-27

### Fixed
- **120 FPS Buttery-Smooth Open & Close Animations**: Eliminated home screen hitching and animation stutter when exiting/closing apps by decoupling repetitive app list reloading during SpringBoard transition cycles.
- **Instant Launch Responsiveness**: Optimized runloop execution to guarantee perfectly fluid icon zoom-in and zoom-out transitions without frame drops.

## [1.2.2] - 2026-09-26

### Fixed
- **HD Ultra-Crisp Icons**: Completely fixed blurry/fuzzy icon display on all Super Retina / ProMotion screens with trilinear minification filtering and native 2x/3x rasterization scale.
- **Butter-Smooth App Launch**: Eliminated launch lag and frame stutter by explicitly caching GPU `shadowPath`, removing gesture delay conflicts, and prioritizing native SpringBoard icon activation.

## [1.2.1] - 2026-09-26

### Fixed
- **Safe Mode Crash Fix**: Resolved a critical SpringBoard crash (Safe Mode) caused by unsafe icon image struct dispatch and badge value integer primitive dereference.
- **Enhanced Badge Extraction**: Safe type-introspection for SpringBoard icon and application badge counts.

## [1.2.0] - 2026-09-26

### Added
- **Notification Badges Inside Frame**: Displays unread notification count badge in each app card.
- **Customizable Badge Placement**: Users can configure the badge position:
  - **Right**: Right inside the frame, adjacent to chevron.
  - **Center**: Centered inside the frame, right next to the app title.
- **Dynamic Row & Icon Sizing**: App row height dynamically adjusts when changing icon size slider.

### Fixed
- **HD Crisp Icons**: Fixed blurry icons on modern retina and Super Retina displays by reading native SpringBoard format 2 assets.
- **SnowBoard & Custom Theme Support**: Now renders theme icons and dynamic calendar/clock icons properly.
- **Icon Size Persistence**: Fixed preference slider not applying on some devices by ensuring proper `PostNotification` and layout invalidation.

## [1.1.0] - 2026-09-26

### Fixed
- **Touch Bounds Hit-Testing**: Fixed an issue where tapping outside the 2/3 width floating glass card could trigger app opening. Only touches landing strictly within the glass pill frame are now accepted.

### Added
- **4 New Frame Designs**:
  - **Neon Rim Glow**: Glowing neon perimeter with custom hue matching glass colors.
  - **Chiseled Cyberpunk**: Futuristic chiseled corner geometry with dual cyan and magenta ambient lighting.
  - **Deep Floating 3D**: High elevation card with rich 18pt drop shadows for realistic depth.
  - **Luxury Diamond Cut**: Beveled jewel corner geometry with crisp diamond reflections.
- **Multilingual Support**: Updated strings for Vietnamese, English, Japanese, and Simplified Chinese.

## [1.0.0] - 2026-09-24

### Added
- **Full Home Screen Replacement**: Replaces stock icon pages, dock, and page dots with a vertical list immediately upon device unlock.
- **Elongated Liquid Glass Pills**: Each application is housed in its own individual elongated capsule taking up exactly 2/3 of the screen width, centered on screen.
- **Settings-like Design**: Left-aligned 42pt squircle icon, bold title in middle, subtle chevron on right.
- **Top Search Pill**: Matching 2/3 width liquid glass search bar with instant real-time app filtering.
- **Fixed Preferences Loading**: Added missing `Info.plist` with `CFBundleExecutable` and `NSPrincipalClass: LARootListController` so Settings opens reliably on all iOS versions.
- **4 Languages Supported**: Vietnamese (`vi`), English (`en`), Japanese (`ja`), and Simplified Chinese (`zh-Hans`).
- **Complete Credits & Donations**: Integrated Ko-fi, PayPal, GitHub Sponsors, and MoMo/VietQR banking for Vietnam.
- **Triple Build Schemes**: Rootful (`iphoneos-arm`), Rootless (`iphoneos-arm64`), and RootHide (`iphoneos-arm64e`).
