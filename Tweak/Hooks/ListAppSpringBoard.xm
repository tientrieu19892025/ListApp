#import "ListAppConstants.h"
#import "ListAppPrefs.h"
#import "ListAppSafety.h"
#import "ListAppContainerView.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface SBRootFolderView : UIView @end
@interface SBDockView : UIView @end
@interface SBFloatingDockView : UIView @end
@interface SBIconListPageControl : UIView @end
@interface SBIconScrollView : UIScrollView @end
@interface SBIconController : UIViewController @end

static void AttachListAppToRoot(SBRootFolderView *root) {
    if (!root || ![root isKindOfClass:[UIView class]]) return;
    ListAppContainerView *container = [ListAppContainerView sharedView];
    if (!container) return;

    if (![ListAppPrefs enabled]) {
        if (container.superview) {
            [container removeFromSuperview];
        }
        return;
    }

    if (container.superview != root) {
        [container removeFromSuperview];
        [root addSubview:container];
    }

    // Completely covers the Home Screen
    container.frame = root.bounds;
    [root bringSubviewToFront:container];

    // Completely hide and disable all stock icon pages and folders
    for (UIView *sub in root.subviews) {
        if (sub == container) continue;
        sub.alpha = 0.0;
        sub.hidden = YES;
        sub.userInteractionEnabled = NO;
    }
}

%group ListAppHomeScreen

%hook SBRootFolderView

- (void)didMoveToWindow {
    %orig;
    if (self.window && [ListAppPrefs enabled]) {
        AttachListAppToRoot(self);
        [[ListAppContainerView sharedView] reloadApps];
    }
}

- (void)layoutSubviews {
    %orig;
    if (![ListAppPrefs enabled]) {
        ListAppContainerView *container = [ListAppContainerView sharedView];
        if (container.superview) {
            [container removeFromSuperview];
        }
        return;
    }

    AttachListAppToRoot(self);
}

%end

// Completely disable and hide stock horizontal icon page scrolling
%hook SBIconScrollView
- (void)layoutSubviews {
    %orig;
    if ([ListAppPrefs enabled]) {
        self.scrollEnabled = NO;
        self.alpha = 0.0;
        self.hidden = YES;
        self.userInteractionEnabled = NO;
    } else {
        self.scrollEnabled = YES;
        self.alpha = 1.0;
        self.hidden = NO;
        self.userInteractionEnabled = YES;
    }
}
%end

// Hide stock Dock to dedicate entire screen to the ListApp launcher
%hook SBDockView
- (void)layoutSubviews {
    %orig;
    if ([ListAppPrefs enabled]) {
        self.alpha = 0.0;
        self.hidden = YES;
        self.userInteractionEnabled = NO;
    } else {
        self.alpha = 1.0;
        self.hidden = NO;
        self.userInteractionEnabled = YES;
    }
}
%end

%hook SBFloatingDockView
- (void)layoutSubviews {
    %orig;
    if ([ListAppPrefs enabled]) {
        self.alpha = 0.0;
        self.hidden = YES;
        self.userInteractionEnabled = NO;
    } else {
        self.alpha = 1.0;
        self.hidden = NO;
        self.userInteractionEnabled = YES;
    }
}
%end

// Hide stock page indicator dots
%hook SBIconListPageControl
- (void)layoutSubviews {
    %orig;
    if ([ListAppPrefs enabled]) {
        self.alpha = 0.0;
        self.hidden = YES;
        self.userInteractionEnabled = NO;
    } else {
        self.alpha = 1.0;
        self.hidden = NO;
        self.userInteractionEnabled = YES;
    }
}
%end

// Do NOT trigger full reload on every viewWillAppear (when closing apps) to keep transitions 120 FPS buttery smooth
%hook SBIconController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
}
%end

%end // ListAppHomeScreen

void ListAppInitSpringBoard(void) {
    if (objc_getClass("SBRootFolderView")) {
        %init(ListAppHomeScreen);
    }
}
