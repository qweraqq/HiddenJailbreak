DEBUG = 0
FINALPACKAGE = 1
THEOS_PACKAGE_SCHEME := rootless
THEOS_PACKAGE_INSTALL_PREFIX := /var/jb
ARCHS := arm64 arm64e
TARGET := iphone:clang:latest:15.0


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = jb-bypass

jb-bypass_FILES = Tweak.x Core/hidden_path.m Core/manual_hook.m
jb-bypass_OBJ_FILES += libdobby.a
jb-bypass_LDFLAGS = -ldobby -lstdc++
jb-bypass_CFLAGS = -fobjc-arc
jb-bypass_EXTRA_FRAMEWORKS = AltList

include $(THEOS_MAKE_PATH)/tweak.mk
