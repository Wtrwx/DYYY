#
#  DYYY
#
#  Copyright (c) 2024 huami. All rights reserved.
#  Channel: @huamidev
#  Created on: 2024/10/04
#

TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e

export DEBUG = 0
INSTALL_TARGET_PROCESSES = Aweme

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DYYY

DYYY_LIBRARY_SEARCH_PATHS = $(THEOS_PROJECT_DIR)/libs
DYYY_HEADER_SEARCH_PATHS = $(THEOS_PROJECT_DIR)/libs/include

DYYY_FILES = DYYY.xm DYYYHide.xm DYYYFloatClearButton.xm DYYYFloatSpeedButton.xm DYYYSettings.xm DYYYABTestHook.xm DYYYLongPressPanel.xm DYYYSaveMedia.xm DYYYDoubleClickMenu.xm DYYYSettingViewController.m DYYYBottomAlertView.m DYYYCustomInputView.m DYYYOptionsSelectionView.m DYYYIconOptionsDialogView.m DYYYAboutDialogView.m DYYYKeywordListView.m DYYYFilterSettingsView.m DYYYManager.m DYYYUtils.m CityManager.m
DYYY_CFLAGS = -fobjc-arc -w -I$(DYYY_HEADER_SEARCH_PATHS)
DYYY_LDFLAGS = -L$(DYYY_LIBRARY_SEARCH_PATHS) -lwebp -weak_framework AVFAudio
DYYY_FRAMEWORKS = CoreAudio
CXXFLAGS += -std=c++11
CCFLAGS += -std=c++11
DYYY_LOGOS_DEFAULT_GENERATOR = internal

export THEOS_STRICT_LOGOS=0
export ERROR_ON_WARNINGS=0
export LOGOS_DEFAULT_GENERATOR=internal

include $(THEOS_MAKE_PATH)/tweak.mk