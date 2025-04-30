#import "AwemeHeaders.h"

%hook AWEFeedLiveMarkView
- (void)setHidden:(BOOL)hidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"]) {
		hidden = YES;
	}

	%orig(hidden);
}
%end

// 隱藏頭像加號和透明
%hook LOTAnimationView
- (void)layoutSubviews {
	%orig;

	// 檢查是否需要隱藏加號
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLOTAnimationView"]) {
		[self removeFromSuperview];
		return;
	}

	// 應用透明度設置
	NSString *transparencyValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYAvatarViewTransparency"];
	if (transparencyValue && transparencyValue.length > 0) {
		CGFloat alphaValue = [transparencyValue floatValue];
		if (alphaValue >= 0.0 && alphaValue <= 1.0) {
			self.alpha = alphaValue;
		}
	}
}
%end

// 首頁頭像隱藏和透明
%hook AWEAdAvatarView
- (void)layoutSubviews {
	%orig;

	// 檢查是否需要隱藏頭像
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"]) {
		[self removeFromSuperview];
		return;
	}

	// 應用透明度設置
	NSString *transparencyValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYAvatarViewTransparency"];
	if (transparencyValue && transparencyValue.length > 0) {
		CGFloat alphaValue = [transparencyValue floatValue];
		if (alphaValue >= 0.0 && alphaValue <= 1.0) {
			self.alpha = alphaValue;
		}
	}
}
%end

// 移除同城吃喝玩樂提示框
%hook AWENearbySkyLightCapsuleView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideNearbyCapsuleView"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 移除共創頭像列表
%hook AWEPlayInteractionCoCreatorNewInfoView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGongChuang"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隱藏右下音樂和取消靜音按鈕
%hook AFDCancelMuteAwemeView
- (void)layoutSubviews {
	%orig;

	UIView *superview = self.superview;

	if ([superview isKindOfClass:NSClassFromString(@"AWEBaseElementView")]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCancelMute"]) {
			self.hidden = YES;
		}
	}
}
%end

// 隱藏彈幕按鈕
%hook AWEPlayDanmakuInputContainView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDanmuButton"]) {
		self.hidden = YES;
	}
}

%end

// 隱藏作者店鋪
%hook AWEECommerceEntryView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideHisShop"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隱藏評論搜尋
%hook AWECommentSearchAnchorView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		[self setHidden:YES];
	}
}

%end

// 隱藏評論區定位
%hook AWEPOIEntryAnchorView

- (void)p_addViews {
	// 檢查使用者偏好設定
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		// 直接跳過視圖添加流程
		return;
	}
	// 執行原始方法
	%orig;
}

- (void)setIconUrls:(id)arg1 defaultImage:(id)arg2 {
	// 根據需求選擇是否攔截資源載入
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		// 可選：傳入空值阻止資源載入
		%orig(nil, nil);
		return;
	}
	// 正常傳遞參數
	%orig(arg1, arg2);
}

- (void)setContentSize:(CGSize)arg1 {
	// 可選：動態調整尺寸計算邏輯
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		// 計算不包含評論視圖的尺寸
		CGSize newSize = CGSizeMake(arg1.width, arg1.height - 44); // 示例減法
		%orig(newSize);
		return;
	}
	// 保持原有尺寸計算
	%orig(arg1);
}

%end

// 隱藏評論音樂
%hook AWECommentGuideLunaAnchorView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		[self setHidden:YES];
	}
}

%end

// Swift 類組 - 這些會在 %ctor 中動態初始化
%group CommentHeaderGeneralGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderGeneralView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		[self setHidden:YES];
	}
}
%end
%end
%group CommentHeaderGoodsGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderGoodsView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		[self setHidden:YES];
	}
}
%end
%end
%group CommentHeaderTemplateGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderTemplateAnchorView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"]) {
		[self setHidden:YES];
	}
}
%end
%end
// Swift 類初始化
%ctor {

	// 動態獲取 Swift 類並初始化對應的組
	Class commentHeaderGeneralClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderGeneralView");
	if (commentHeaderGeneralClass) {
		%init(CommentHeaderGeneralGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderGeneralView = commentHeaderGeneralClass);
	}

	Class commentHeaderGoodsClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderGoodsView");
	if (commentHeaderGoodsClass) {
		%init(CommentHeaderGoodsGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderGoodsView = commentHeaderGoodsClass);
	}

	Class commentHeaderTemplateClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderTemplateAnchorView");
	if (commentHeaderTemplateClass) {
		%init(CommentHeaderTemplateGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderTemplateAnchorView = commentHeaderTemplateClass);
	}
}

// 隱藏大家都在搜
%hook AWESearchAnchorListModel

- (BOOL)hideWords {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentViews"];
}

%end

// 隱藏觀看歷史搜尋
%hook AWEDiscoverFeedEntranceView
- (id)init {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideInteractionSearch"]) {
		return nil;
	}
	return %orig;
}
%end

// 隱藏校園提示
%hook AWETemplateTagsCommonView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTemplateTags"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隱藏挑戰貼紙
%hook AWEFeedStickerContainerView

- (BOOL)isHidden {
	BOOL origHidden = %orig;
	BOOL hideRecommend = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"];
	return origHidden || hideRecommend;
}

- (void)setHidden:(BOOL)hidden {
	BOOL forceHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"];
	%orig(forceHide ? YES : hidden);
}

%end

// 去除"我的"加入挑戰橫幅
%hook AWEPostWorkViewController
- (BOOL)isDouGuideTipViewShow {
	BOOL r = %orig;
	NSLog(@"Original value: %@", @(r));
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"]) {
		NSLog(@"Force return YES");
		return YES;
	}
	return r;
}
%end

// 隱藏訊息頁頂欄頭像氣泡
%hook AFDSkylightCellBubble
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenAvatarBubble"]) {
		[self removeFromSuperview];
		return;
	}
}
%end

// 隱藏訊息頁開啟通知提示
%hook AWEIMMessageTabOptPushBannerView

- (instancetype)initWithFrame:(CGRect)frame {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePushBanner"]) {
		return %orig(CGRectMake(frame.origin.x, frame.origin.y, 0, 0));
	}
	return %orig;
}

%end

// 隱藏拍同款
%hook AWEFeedAnchorContainerView

- (BOOL)isHidden {
	BOOL origHidden = %orig;
	BOOL hideSamestyle = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFeedAnchorContainer"];
	return origHidden || hideSamestyle;
}

- (void)setHidden:(BOOL)hidden {
	BOOL forceHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFeedAnchorContainer"];
	%orig(forceHide ? YES : hidden);
}

%end

// 隱藏合集和聲明
%hook AWEAntiAddictedNoticeBarView
- (void)layoutSubviews {
	%orig;

	// 獲取 tipsLabel 屬性
	UILabel *tipsLabel = [self valueForKey:@"tipsLabel"];

	if (tipsLabel && [tipsLabel isKindOfClass:%c(UILabel)]) {
		NSString *labelText = tipsLabel.text;

		if (labelText) {
			// 明確判斷是合集還是作者聲明
			if ([labelText containsString:@"合集"]) {
				// 如果是合集，只檢查合集的開關
				if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTemplateVideo"]) {
					[self removeFromSuperview];
				}
			} else {
				// 如果不是合集（即作者聲明），只檢查聲明的開關
				if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAntiAddictedNotice"]) {
					[self removeFromSuperview];
				}
			}
		}
	}
}
%end

// 隱藏分享給朋友提示
%hook AWEPlayInteractionStrongifyShareContentView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareContentView"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 移除下面推薦框黑條
%hook AWEPlayInteractionRelatedVideoView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideBottomRelated"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

%hook AWEFeedRelatedSearchTipView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideBottomRelated"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

%hook AWENormalModeTabBarBadgeContainerView

- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenBottomDot"]) {
		for (UIView *subview in [self subviews]) {
			if ([subview isKindOfClass:NSClassFromString(@"DUXBadge")]) {
				[subview setHidden:YES];
			}
		}
	}
}

%end

%hook AWELeftSideBarEntranceView

- (void)layoutSubviews {

	__block BOOL isInTargetController = NO;
	UIResponder *currentResponder = self;

	while ((currentResponder = [currentResponder nextResponder])) {
		if ([currentResponder isKindOfClass:NSClassFromString(@"AWEUserHomeViewControllerV2")]) {
			isInTargetController = YES;
			break;
		}
	}

	if (!isInTargetController && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenLeftSideBar"]) {
		for (UIView *subview in self.subviews) {
			subview.hidden = YES;
		}
	}
}

%end

%hook AWEFeedVideoButton

- (void)layoutSubviews {
	%orig;

	NSString *accessibilityLabel = self.accessibilityLabel;

	if ([accessibilityLabel isEqualToString:@"點讚"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLikeButton"]) {
			[self removeFromSuperview];
			return;
		}

		// 隱藏讚好數值標籤
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLikeLabel"]) {
			for (UIView *subview in self.subviews) {
				if ([subview isKindOfClass:[UILabel class]]) {
					subview.hidden = YES;
				}
			}
		}
	} else if ([accessibilityLabel isEqualToString:@"評論"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentButton"]) {
			[self removeFromSuperview];
			return;
		}

		// 隱藏評論數值標籤
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLabel"]) {
			for (UIView *subview in self.subviews) {
				if ([subview isKindOfClass:[UILabel class]]) {
					subview.hidden = YES;
				}
			}
		}
	} else if ([accessibilityLabel isEqualToString:@"分享"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareButton"]) {
			[self removeFromSuperview];
			return;
		}

		// 隱藏分享數值標籤
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareLabel"]) {
			for (UIView *subview in self.subviews) {
				if ([subview isKindOfClass:[UILabel class]]) {
					subview.hidden = YES;
				}
			}
		}
	} else if ([accessibilityLabel isEqualToString:@"收藏"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectButton"]) {
			[self removeFromSuperview];
			return;
		}

		// 隱藏收藏數值標籤
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectLabel"]) {
			for (UIView *subview in self.subviews) {
				if ([subview isKindOfClass:[UILabel class]]) {
					subview.hidden = YES;
				}
			}
		}
	}
}

%end

%hook AWEMusicCoverButton

- (void)layoutSubviews {
	%orig;

	NSString *accessibilityLabel = self.accessibilityLabel;

	if ([accessibilityLabel isEqualToString:@"音樂詳情"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMusicButton"]) {
			[self removeFromSuperview];
			return;
		}
	}
}

%end

%hook AWEPlayInteractionListenFeedView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMusicButton"]) {
		[self removeFromSuperview];
		return;
	}
}
%end

%hook AWEPlayInteractionFollowPromptView

- (void)layoutSubviews {
	%orig;

	NSString *accessibilityLabel = self.accessibilityLabel;

	if ([accessibilityLabel isEqualToString:@"關注"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"]) {
			[self removeFromSuperview];
			return;
		}
	}
}

%end

%hook AWENormalModeTabBar

- (void)layoutSubviews {
    %orig;

    BOOL hideShop = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShopButton"];
    BOOL hideMsg = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMessageButton"];
    BOOL hideFri = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFriendsButton"];
    BOOL hideMe = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMyButton"];

    NSMutableArray *visibleButtons = [NSMutableArray array];
    Class generalButtonClass = %c(AWENormalModeTabBarGeneralButton);
    Class plusButtonClass = %c(AWENormalModeTabBarGeneralPlusButton);

    for (UIView *subview in self.subviews) {
        if (![subview isKindOfClass:generalButtonClass] && ![subview isKindOfClass:plusButtonClass])
            continue;

        NSString *label = subview.accessibilityLabel;
        BOOL shouldHide = NO;

        if ([label isEqualToString:@"商城"]) {
            shouldHide = hideShop;
        } else if ([label containsString:@"訊息"]) {
            shouldHide = hideMsg;
        } else if ([label containsString:@"朋友"]) {
            shouldHide = hideFri;
        } else if ([label containsString:@"我"]) {
            shouldHide = hideMe;
        }

        if (!shouldHide) {
            [visibleButtons addObject:subview];
        } else {
            [subview removeFromSuperview];
        }
    }

    [visibleButtons sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
      return [@(a.frame.origin.x) compare:@(b.frame.origin.x)];
    }];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // iPad端佈局邏輯
        UIView *targetView = nil;
        CGFloat containerWidth = self.bounds.size.width;
        CGFloat offsetX = 0;

        // 查找目標容器視圖
        for (UIView *subview in self.subviews) {
            if ([subview class] == [UIView class] && fabs(subview.frame.size.width - self.bounds.size.width) > 0.1) {
                targetView = subview;
                containerWidth = subview.frame.size.width;
                offsetX = subview.frame.origin.x;
                break;
            }
        }

        // 在目標容器內均勻分佈按鈕
        CGFloat buttonWidth = containerWidth / visibleButtons.count;
        for (NSInteger i = 0; i < visibleButtons.count; i++) {
            UIView *button = visibleButtons[i];
            button.frame = CGRectMake(offsetX + (i * buttonWidth), button.frame.origin.y, buttonWidth, button.frame.size.height);
        }
    } else {
        // iPhone端佈局邏輯
        CGFloat totalWidth = self.bounds.size.width;
        CGFloat buttonWidth = totalWidth / visibleButtons.count;

        for (NSInteger i = 0; i < visibleButtons.count; i++) {
            UIView *button = visibleButtons[i];
            button.frame = CGRectMake(i * buttonWidth, button.frame.origin.y, buttonWidth, button.frame.size.height);
        }
    }
}

- (void)setHidden:(BOOL)hidden {
	%orig(hidden);

	BOOL hideShop = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShopButton"];
	BOOL hideMsg = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMessageButton"];
	BOOL hideFri = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFriendsButton"];

	NSMutableArray *visibleButtons = [NSMutableArray array];
	NSMutableArray *buttonTypes = [NSMutableArray array];
	Class generalButtonClass = %c(AWENormalModeTabBarGeneralButton);
	Class plusButtonClass = %c(AWENormalModeTabBarGeneralPlusButton);

	// 收集所有可見按鈕並記錄它們的類型
	for (UIView *subview in self.subviews) {
		if (![subview isKindOfClass:generalButtonClass] && ![subview isKindOfClass:plusButtonClass])
			continue;

		NSString *label = subview.accessibilityLabel;
		BOOL shouldHide = NO;
		NSString *buttonType = @"unknown";

		if ([label isEqualToString:@"首頁"]) {
			buttonType = @"home";
		} else if ([label isEqualToString:@"商城"]) {
			shouldHide = hideShop;
			buttonType = @"shop";
		} else if ([label containsString:@"訊息"]) {
			shouldHide = hideMsg;
			buttonType = @"message";
		} else if ([label containsString:@"朋友"]) {
			shouldHide = hideFri;
			buttonType = @"friends";
		} else if ([label isEqualToString:@"我"]) {
			buttonType = @"profile";
		}

		if (!shouldHide) {
			[visibleButtons addObject:subview];
			[buttonTypes addObject:buttonType];
		} else {
			[subview removeFromSuperview];
		}
	}

	// 按照x座標排序按鈕
	NSMutableArray *pairedObjects = [NSMutableArray array];
	for (NSInteger i = 0; i < visibleButtons.count; i++) {
		[pairedObjects addObject:@{@"button" : visibleButtons[i], @"type" : buttonTypes[i], @"x" : @(((UIView *)visibleButtons[i]).frame.origin.x)}];
	}

	[pairedObjects sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
	  return [a[@"x"] compare:b[@"x"]];
	}];

	// 更新排序後的陣列
	[visibleButtons removeAllObjects];
	[buttonTypes removeAllObjects];
	for (NSDictionary *pair in pairedObjects) {
		[visibleButtons addObject:pair[@"button"]];
		[buttonTypes addObject:pair[@"type"]];
	}


	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenBottomBg"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
		for (UIView *subview in self.subviews) {
			if ([subview class] == [UIView class]) {
				BOOL hasImageView = NO;
				for (UIView *childView in subview.subviews) {
					if ([childView isKindOfClass:[UIImageView class]]) {
						hasImageView = YES;
						break;
					}
				}

				if (hasImageView) {
					// 預設隱藏背景
					BOOL shouldShowBackground = NO;

					// 獲取當前選中的索引
					NSInteger selectedIndex = self.yy_viewController.selectedIndex;
					// 如果索引有效，檢查當前選中的是什麼類型的按鈕
					if (selectedIndex >= 0 && selectedIndex < buttonTypes.count) {
						NSString *selectedType = buttonTypes[selectedIndex];

						if ([selectedType isEqualToString:@"message"] || [selectedType isEqualToString:@"profile"]) {
							shouldShowBackground = YES;
						}
					}
					subview.hidden = !shouldShowBackground;
					break;
				}
			}
		}
	} else {
	}
// 隐藏分隔虾线
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
				for (UIView *subview in self.subviews) {
					if (![subview isKindOfClass:[UIView class]]) continue;
					if (subview.frame.size.height <= 0.5 && subview.frame.size.width > 300) {
						subview.hidden = YES;
						CGRect frame = subview.frame;
						frame.size.height = 0;
						subview.frame = frame;
						subview.alpha = 0;
					}
				}
			}
// 隱藏分隔線結束
}

%end

// 隱藏雙指縮放線
%hook AWELoadingAndVolumeView

- (void)layoutSubviews {
	%orig;

	if ([self respondsToSelector:@selector(removeFromSuperview)]) {
		[self removeFromSuperview];
	}
	self.hidden = YES;
	return;
}

%end

%hook AWEFeedRootViewController

- (BOOL)prefersStatusBarHidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHideStatusbar"]) {
		return YES;
	} else {
		return %orig;
	}
}

%end

%hook AWEFeedTemplateAnchorView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLocation"]) {
		[self removeFromSuperview];
		return;
	}
}

%end

%hook AWEPlayInteractionSearchAnchorView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideInteractionSearch"]) {
		[self removeFromSuperview];
		return;
	}
}

%end

%hook AWEAwemeMusicInfoView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideQuqishuiting"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隱藏短劇合集
%hook AWETemplatePlayletView

- (void)layoutSubviews {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTemplatePlaylet"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隱藏作者作品集搜尋
%hook AWESearchEntranceView

- (void)layoutSubviews {

	Class targetClass = NSClassFromString(@"AWESearchEntranceView");
	if (!targetClass)
		return;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideInteractionSearch"]) {

		SEL removeSel = NSSelectorFromString(@"removeFromSuperview");
		if ([targetClass instancesRespondToSelector:removeSel]) {
			[self performSelector:removeSel];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}

%end

// 隱藏視頻滑條
%hook AWEStoryProgressSlideView

- (void)layoutSubviews {
	%orig;

	BOOL shouldHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideStoryProgressSlide"];
	if (!shouldHide)
		return;
	__block UIView *targetView = nil;
	[self.subviews enumerateObjectsUsingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
	  if ([obj isKindOfClass:NSClassFromString(@"UISlider")] || obj.frame.size.height < 5) {
		  targetView = obj.superview;
		  *stop = YES;
	  }
	}];

	if (targetView) {
		targetView.hidden = YES;
	} else {
	}
}

%end

// 隱藏好友分享私信
%hook AFDNewFastReplyView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePrivateMessages"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

%hook AWETemplateHotspotView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideHotspot"]) {
		[self removeFromSuperview];
		return;
	}
}

%end

// 隱藏關注直播
%hook AWEConcernSkylightCapsuleView
- (void)setHidden:(BOOL)hidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideConcernCapsuleView"]) {
		[self removeFromSuperview];
		return;
	}

	%orig(hidden);
}
%end

// 隱藏直播發現
%hook AWEFeedLiveTabRevisitControlView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveDiscovery"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
}
%end

// 隱藏直播點歌
%hook IESLiveKTVSongIndicatorView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideKTVSongIndicator"]) {
		self.hidden = YES;
		[self removeFromSuperview];
	}
}
%end

// 隱藏圖片滑條
%hook AWEStoryProgressContainerView
- (BOOL)isHidden {
	BOOL originalValue = %orig;
	BOOL customHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDotsIndicator"];
	return originalValue || customHide;
}

- (void)setHidden:(BOOL)hidden {
	BOOL forceHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDotsIndicator"];
	%orig(forceHide ? YES : hidden);
}
%end

// 隱藏暱稱右側
%hook UILabel
- (void)layoutSubviews {
	%orig;

	BOOL hideRightLabel = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideRightLable"];
	if (!hideRightLabel)
		return;

	NSString *accessibilityLabel = self.accessibilityLabel;
	if (!accessibilityLabel || accessibilityLabel.length == 0)
		return;

	NSString *trimmedLabel = [accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	BOOL shouldHide = NO;

	if ([trimmedLabel hasSuffix:@"人共創"]) {
		NSString *prefix = [trimmedLabel substringToIndex:trimmedLabel.length - 3];
		NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
		shouldHide = ([prefix rangeOfCharacterFromSet:nonDigits].location == NSNotFound);
	}

	if (!shouldHide) {
		shouldHide = [trimmedLabel isEqualToString:@"章節要點"] || [trimmedLabel isEqualToString:@"圖集"];
	}

	if (shouldHide) {
		self.hidden = YES;

		// 找到父視圖是否為 UIStackView
		UIView *superview = self.superview;
		if ([superview isKindOfClass:[UIStackView class]]) {
			UIStackView *stackView = (UIStackView *)superview;
			// 刷新 UIStackView 的佈局
			[stackView layoutIfNeeded];
		}
	}
}
%end

// 隱藏頂欄關注下的提示線
%hook AWEFeedMultiTabSelectedContainerView

- (void)setHidden:(BOOL)hidden {
	BOOL forceHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidentopbarprompt"];

	if (forceHide) {
		%orig(YES);
	} else {
		%orig(hidden);
	}
}

%end

%hook AFDRecommendToFriendEntranceLabel
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideRecommendTips"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隱藏自己無公開作品的視圖
%hook AWEProfileMixCollectionViewCell
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePostView"]) {
		self.hidden = YES;
	}
}
%end

%hook AWEProfileTaskCardStyleListCollectionViewCell
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePostView"]) {
		self.hidden = YES;
	}
}
%end

// 隱藏關注直播頂端
%hook AWENewLiveSkylightViewController

// 隱藏頂部直播視圖 - 添加條件判斷
- (void)showSkylight:(BOOL)arg0 animated:(BOOL)arg1 actionMethod:(unsigned long long)arg2 {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidenLiveView"]) {
		return;
	}
	%orig(arg0, arg1, arg2);
}

- (void)updateIsSkylightShowing:(BOOL)arg0 {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidenLiveView"]) {
		%orig(NO);
	} else {
		%orig(arg0);
	}
}

%end

// 隱藏同城頂端
%hook AWENearbyFullScreenViewModel

- (void)setShowSkyLight:(id)arg1 {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMenuView"]) {
		arg1 = nil;
	}
	%orig(arg1);
}

- (void)setHaveSkyLight:(id)arg1 {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMenuView"]) {
		arg1 = nil;
	}
	%orig(arg1);
}

%end

// 隱藏筆記
%hook AWECorrelationItemTag

- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideItemTag"]) {
		self.frame = CGRectMake(0, 0, 0, 0);
		self.hidden = YES;
	}
}

%end

// 隱藏話題
%hook AWEPlayInteractionTemplateButtonGroup
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTemplateGroup"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

%hook AWEPlayInteractionViewController

- (void)onVideoPlayerViewDoubleClicked:(id)arg1 {
	BOOL isSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDouble"];
	if (!isSwitchOn) {
		%orig;
	}
}
%end

// 隱藏右上搜尋，但可點擊
%hook AWEHPDiscoverFeedEntranceView

- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDiscover"]) {
		for (UIView *subview in self.subviews) {
			subview.hidden = YES;
		}
	}
}

%end

// 隱藏點擊進入直播間
%hook AWELiveFeedStatusLabel
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideEnterLive"]) {
		UIView *parentView = self.superview;
		UIView *grandparentView = parentView.superview;

		if (grandparentView) {
			grandparentView.hidden = YES;
		} else if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}
%end

// 去除訊息群直播提示
%hook AWEIMCellLiveStatusContainerView

- (void)p_initUI {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYGroupLiving"])
		%orig;
}
%end

%hook AWELiveStatusIndicatorView

- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYGroupLiving"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

%hook AWELiveSkylightCatchView
- (void)layoutSubviews {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidenLiveCapsuleView"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}

%end

// 隱藏首頁直播膠囊
%hook AWEHPTopTabItemBadgeContentView

- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveCapsuleView"]) {
		self.frame = CGRectMake(0, 0, 0, 0);
		self.hidden = YES;
	}
}

%end

// 隱藏群商店
%hook AWEIMFansGroupTopDynamicDomainTemplateView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGroupShop"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 去除群聊天輸入框上方快捷方式
%hook AWEIMInputActionBarInteractor

- (void)p_setupUI {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGroupInputActionBar"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隱藏相機定位
%hook AWETemplateCommonView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCameraLocation"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隱藏側欄紅點
%hook AWEHPTopBarCTAItemView

- (void)showRedDot {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYisHiddenSidebarDot"])
		%orig;
}

- (void)hideCountRedDot {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYisHiddenSidebarDot"])
		%orig;
}

- (void)layoutSubviews {
	%orig;
	for (UIView *subview in self.subviews) {
		if ([subview isKindOfClass:[%c(DUXBadge) class]]) {
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenSidebarDot"]) {
				subview.hidden = YES;
			}
		}
	}
}
%end

%hook AWELeftSideBarEntranceView

- (void)setRedDot:(id)redDot {
	%orig(nil);
}

- (void)setNumericalRedDot:(id)numericalRedDot {
	%orig(nil);
}

%end

// 隱藏搜同款
%hook ACCStickerContainerView
- (void)layoutSubviews {
	// 類型安全檢查 + 隱藏邏輯
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideInteractionSearch"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES; // 隱藏更徹底
		return;
	}
	%orig;
}
%end

// 隱藏禮物展館
%hook BDXWebView
- (void)layoutSubviews {
	%orig;

	BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGiftPavilion"];
	if (!enabled)
		return;

	NSString *title = [self valueForKey:@"title"];

	if ([title containsString:@"任務Banner"] || [title containsString:@"活動Banner"]) {
		[self removeFromSuperview];
	}
}
%end

%hook AWEVideoTypeTagView

- (void)setupUI {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideLiveGIF"])
		%orig;
}
%end

%hook IESLiveActivityBannnerView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGiftPavilion"]) {
		self.hidden = YES;
	}
}

%end

// 隱藏直播廣場
%hook IESLiveFeedDrawerEntranceView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLivePlayground"]) {
		self.hidden = YES;
	}
}

%end

// 隱藏頂欄紅點
%hook AWEHPTopTabItemBadgeContentView
- (id)showBadgeWithBadgeStyle:(NSUInteger)style badgeConfig:(id)config count:(NSInteger)count text:(id)text {
	BOOL hideEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTopBarBadge"];

	if (hideEnabled) {
		// 阻斷徽章創建
		return nil; // 返回 nil 阻止視圖生成
	} else {
		// 未啟用隱藏功能時正常顯示
		return %orig(style, config, count, text);
	}
}
%end

// 隱藏直播退出清屏、投屏按鈕
%hook IESLiveButton

- (void)layoutSubviews {
	%orig;

	// 處理清屏按鈕
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomClear"]) {
		if ([self.accessibilityLabel isEqualToString:@"退出清屏"] && self.superview) {
			[self.superview removeFromSuperview];
		}
	}

	// 投屏按鈕
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomMirroring"]) {
		if ([self.accessibilityLabel isEqualToString:@"投屏"] && self.superview) {
			[self.superview removeFromSuperview];
		}
	}
}

%end

// 隱藏直播間流量彈窗
%hook AWELiveFlowAlertView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCellularAlert"]) {
		self.hidden = YES;
	}
}
%end

// 屏蔽青少年模式彈窗
%hook AWEUIAlertView
- (void)show {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideteenmode"])
		%orig;
}
%end

// 屏蔽青少年模式彈窗
%hook AWETeenModeAlertView
- (BOOL)show {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideteenmode"]) {
		return NO;
	}
	return %orig;
}
%end

// 屏蔽青少年模式彈窗
%hook AWETeenModeSimpleAlertView
- (BOOL)show {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideteenmode"]) {
		return NO;
	}
	return %orig;
}
%end

// 強制啟用新版抖音長按 UI（現代風）
%hook AWELongPressPanelManager
- (BOOL)shouldShowModernLongPressPanel {
	return DYYYGetBool(@"DYYYisEnableModern");
}
%end

%hook AWELongPressPanelDataManager
+ (BOOL)enableModernLongPressPanelConfigWithSceneIdentifier:(id)arg1 {
	return DYYYGetBool(@"DYYYisEnableModern");
}
%end

%hook AWELongPressPanelABSettings
+ (NSUInteger)modernLongPressPanelStyleMode {
	return DYYYGetBool(@"DYYYisEnableModern") ? 1 : 0;
}
%end

%hook AWEModernLongPressPanelUIConfig
+ (NSUInteger)modernLongPressPanelStyleMode {
	return DYYYGetBool(@"DYYYisEnableModern") ? 1 : 0;
}
%end

// 聊天視頻底部評論框背景透明
%hook AWEIMFeedBottomQuickEmojiInputBar

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChatCommentBg"]) {
		UIView *parentView = self.superview;
		while (parentView) {
			if ([NSStringFromClass([parentView class]) isEqualToString:@"UIView"]) {
				dispatch_async(dispatch_get_main_queue(), ^{
				  parentView.backgroundColor = [UIColor clearColor];
				  parentView.layer.backgroundColor = [UIColor clearColor].CGColor;
				  parentView.opaque = NO;
				});
				break;
			}
			parentView = parentView.superview;
		}
	}
}

%end

// 移除極速版我的片面紅包橫幅
%hook AWELuckyCatBannerView
- (id)initWithFrame:(CGRect)frame {
		return nil;
	}

- (id)init {
		return nil;
}
%end

// 極速版紅包激勵掛件容器視圖類組（移除邏輯）
%group IncentivePendantGroup
%hook AWEIncentiveSwiftImplDOUYINLite_IncentivePendantContainerView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePendantGroup"]) {
		[self removeFromSuperview]; // 移除視圖
	}
}
%end
%end

// Swift 紅包類初始化
%ctor {

	// 初始化紅包激勵掛件容器視圖類組
	Class incentivePendantClass = objc_getClass("AWEIncentiveSwiftImplDOUYINLite.IncentivePendantContainerView");
	if (incentivePendantClass) {
		%init(IncentivePendantGroup, AWEIncentiveSwiftImplDOUYINLite_IncentivePendantContainerView = incentivePendantClass);
	}
}

%hook AWEFeedChannelManager

- (void)reloadChannelWithChannelModels:(id)arg1 currentChannelIDList:(id)arg2 reloadType:(id)arg3 selectedChannelID:(id)arg4 {
	NSArray *channelModels = arg1;
	NSMutableArray *newChannelModels = [NSMutableArray array];
	NSArray *currentChannelIDList = arg2;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSMutableArray *newCurrentChannelIDList = [NSMutableArray arrayWithArray:currentChannelIDList];

	for (AWEHPTopTabItemModel *tabItemModel in channelModels) {
		NSString *channelID = tabItemModel.channelID;

		if ([channelID isEqualToString:@"homepage_hot_container"]) {
			[newChannelModels addObject:tabItemModel];
			continue;
		}

		BOOL isHideChannel = NO;
		if ([channelID isEqualToString:@"homepage_follow"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideFollow"];
		} else if ([channelID isEqualToString:@"homepage_mediumvideo"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideMediumVideo"];
		} else if ([channelID isEqualToString:@"homepage_mall"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideMall"];
		} else if ([channelID isEqualToString:@"homepage_nearby"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideNearby"];
		} else if ([channelID isEqualToString:@"homepage_groupon"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideGroupon"];
		} else if ([channelID isEqualToString:@"homepage_tablive"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideTabLive"];
		} else if ([channelID isEqualToString:@"homepage_pad_hot"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHidePadHot"];
		} else if ([channelID isEqualToString:@"homepage_hangout"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideHangout"];
		} else if ([channelID isEqualToString:@"homepage_familiar"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideFriend"];
		} else if ([channelID isEqualToString:@"homepage_playlet_stream"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHidePlaylet"];
		} else if ([channelID isEqualToString:@"homepage_pad_cinema"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideCinema"];
		} else if ([channelID isEqualToString:@"homepage_pad_kids_v2"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideKidsV2"];
		} else if ([channelID isEqualToString:@"homepage_pad_game"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideGame"];
		}

		if (!isHideChannel) {
			[newChannelModels addObject:tabItemModel];
		} else {
			[newCurrentChannelIDList removeObject:channelID];
		}
	}

	%orig(newChannelModels, newCurrentChannelIDList, arg3, arg4);
}

%end

%ctor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
	}
}

// 隱藏鍵盤AI
// 隱藏父視圖的子視圖
static void hideParentViewsSubviews(UIView *view) {
    if (!view) return;
    // 獲取第一層父視圖
    UIView *parentView = [view superview];
    if (!parentView) return;
    // 獲取第二層父視圖
    UIView *grandParentView = [parentView superview];
    if (!grandParentView) return;
    // 獲取第三層父視圖
    UIView *greatGrandParentView = [grandParentView superview];
    if (!greatGrandParentView) return;
    // 隱藏所有子視圖
    for (UIView *subview in greatGrandParentView.subviews) {
        subview.hidden = YES;
    }
}
// 遞迴查找目標視圖
static void findTargetViewInView(UIView *view) {
    if ([view isKindOfClass:NSClassFromString(@"AWESearchKeyboardVoiceSearchEntranceView")]) {
        hideParentViewsSubviews(view);
        return;
    }
    for (UIView *subview in view.subviews) {
        findTargetViewInView(subview);
    }
}
// 構造函數
%ctor {
    // 註冊鍵盤通知
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification
                                                    object:nil
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification *notification) {
        // 檢查開關狀態
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidekeyboardai"]) {
            // 執行查找隱藏
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                findTargetViewInView(window);
            }
        }
    }];
}