export THEOS ?= $(HOME)/theos

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ListAppPrefs

ListAppPrefs_FILES = ListAppRootListController.m
LISTAPP_ROOT = $(abspath ..)
ListAppPrefs_FRAMEWORKS = UIKit CoreGraphics QuartzCore SafariServices
ListAppPrefs_PRIVATE_FRAMEWORKS =
ListAppPrefs_INSTALL_PATH = /Library/PreferenceBundles
ListAppPrefs_CFLAGS = -fobjc-arc -I../Shared -Wno-deprecated-declarations -F$(LISTAPP_ROOT)/vendor
ListAppPrefs_LDFLAGS = -F$(LISTAPP_ROOT)/vendor -framework Preferences
ListAppPrefs_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/bundle.mk
