export THEOS ?= $(HOME)/theos

TOOLCHAIN ?= /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
export TARGET_CC ?= $(TOOLCHAIN)/clang
export TARGET_CXX ?= $(TOOLCHAIN)/clang++
export TARGET_LD ?= $(TOOLCHAIN)/clang
export TARGET_STRIP ?= $(TOOLCHAIN)/strip
export TARGET_LIPO ?= $(TOOLCHAIN)/lipo
export TARGET_CODESIGN_ALLOCATE ?= $(TOOLCHAIN)/codesign_allocate
export TARGET_LIBTOOL ?= $(TOOLCHAIN)/libtool

INSTALL_TARGET_PROCESSES = SpringBoard Preferences

ARCHS = arm64 arm64e
TARGET = iphone:clang:27.0:15.0
SDKVERSION = 27.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ListApp

ListApp_FILES = \
	Tweak/ListApp.xm \
	Tweak/Hooks/ListAppSpringBoard.xm \
	Tweak/Core/ListAppPrefs.m \
	Tweak/Core/ListAppPaths.m \
	Tweak/Safety/ListAppSafety.m \
	Tweak/UI/ListAppGlassView.m \
	Tweak/UI/ListAppGridCell.m \
	Tweak/UI/ListAppModel.m \
	Tweak/UI/ListAppContainerView.m

ListApp_CFLAGS = -fobjc-arc \
	-IShared \
	-ITweak/Core \
	-ITweak/Safety \
	-ITweak/UI \
	-Wno-unused-variable \
	-Wno-unused-function \
	-Wno-deprecated-declarations

ListApp_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore MobileCoreServices

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "sbreload || killall -9 SpringBoard"
