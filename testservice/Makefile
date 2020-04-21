include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = testservice

testservice_FILES = $(wildcard *.m)
testservice_FRAMEWORKS = UIKit CoreGraphics
testservice_CFLAGS = -fobjc-arc -include ../Headers.h
testservice_CODESIGN_FLAGS = -Sentitlements.xml

include $(THEOS_MAKE_PATH)/application.mk