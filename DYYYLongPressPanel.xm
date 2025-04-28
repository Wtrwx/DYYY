#import "AwemeHeaders.h"
#import "DYYYManager.h"
#import "DYYYKeywordListView.h"
#import "DYYYFilterSettingsView.h"
#import "DYYYBottomAlertView.h"

%hook AWEModernLongPressPanelTableViewController

- (NSArray *)dataArray {
	NSArray *originalArray = %orig;

	if (!originalArray) {
		originalArray = @[];
	}

	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
		return originalArray;
	}

	AWELongPressPanelViewGroupModel *newGroupModel = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
	[newGroupModel setIsDYYYCustomGroup:YES];
    newGroupModel.groupType = 12;
    newGroupModel.isModern = YES;

	NSMutableArray *viewModels = [NSMutableArray array];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"]) {
		if (self.awemeModel.awemeType != 68) {
			AWELongPressPanelBaseViewModel *downloadViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			downloadViewModel.awemeModel = self.awemeModel;
			downloadViewModel.actionType = 666;
			downloadViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			downloadViewModel.describeString = @"保存视频";

			downloadViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;
			  AWEMusicModel *musicModel = awemeModel.music;

			  if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeVideo
						  completion:^{
						    [DYYYManager showToast:@"视频已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:downloadViewModel];
		}

		if (self.awemeModel.awemeType != 68) {
			AWELongPressPanelBaseViewModel *coverViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			coverViewModel.awemeModel = self.awemeModel;
			coverViewModel.actionType = 667;
			coverViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			coverViewModel.describeString = @"保存封面";

			coverViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;

			  if (videoModel && videoModel.coverURL && videoModel.coverURL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"封面已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:coverViewModel];
		}

		AWELongPressPanelBaseViewModel *audioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		audioViewModel.awemeModel = self.awemeModel;
		audioViewModel.actionType = 668;
		audioViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
		audioViewModel.describeString = @"保存音频";

		audioViewModel.action = ^{
		  AWEAwemeModel *awemeModel = self.awemeModel;
		  AWEMusicModel *musicModel = awemeModel.music;

		  if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
			  NSURL *url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
			  [DYYYManager downloadMedia:url mediaType:MediaTypeAudio completion:nil];
		  }

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:audioViewModel];

		if (self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
			AWELongPressPanelBaseViewModel *imageViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			imageViewModel.awemeModel = self.awemeModel;
			imageViewModel.actionType = 669;
			imageViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			imageViewModel.describeString = @"保存当前图片";

			AWEImageAlbumImageModel *currimge = self.awemeModel.albumImages[self.awemeModel.currentImageIndex - 1];
			if (currimge.clipVideo != nil) {
				imageViewModel.describeString = @"保存当前实况";
			}
			imageViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEImageAlbumImageModel *currentImageModel = nil;

			  if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
				  currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
			  } else {
				  currentImageModel = awemeModel.albumImages.firstObject;
			  }
			  // 如果是实况的话
			  if (currimge.clipVideo != nil) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  NSURL *videoURL = [currimge.clipVideo.playURL getDYYYSrcURLDownload];

				  [DYYYManager downloadLivePhoto:url
							videoURL:videoURL
						      completion:^{
							[DYYYManager showToast:@"实况照片已保存到相册"];
						      }];
			  } else if (currentImageModel && currentImageModel.urlList.count > 0) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"图片已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:imageViewModel];

			if (self.awemeModel.albumImages.count > 1) {
				AWELongPressPanelBaseViewModel *allImagesViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
				allImagesViewModel.awemeModel = self.awemeModel;
				allImagesViewModel.actionType = 670;
				allImagesViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
				allImagesViewModel.describeString = @"保存所有图片";

				// 检查是否有实况照片并更改按钮文字
				BOOL hasLivePhoto = NO;
				for (AWEImageAlbumImageModel *imageModel in self.awemeModel.albumImages) {
					if (imageModel.clipVideo != nil) {
						hasLivePhoto = YES;
						break;
					}
				}

				if (hasLivePhoto) {
					allImagesViewModel.describeString = @"保存所有实况";
				}

				allImagesViewModel.action = ^{
				  AWEAwemeModel *awemeModel = self.awemeModel;
				  NSMutableArray *imageURLs = [NSMutableArray array];

				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.urlList.count > 0) {
						  [imageURLs addObject:imageModel.urlList.firstObject];
					  }
				  }

				  // 检查是否有实况照片
				  BOOL hasLivePhoto = NO;
				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.clipVideo != nil) {
						  hasLivePhoto = YES;
						  break;
					  }
				  }

				  // 如果有实况照片，使用单独的downloadLivePhoto方法逐个下载
				  if (hasLivePhoto) {
					  NSMutableArray *livePhotos = [NSMutableArray array];
					  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
						  if (imageModel.urlList.count > 0 && imageModel.clipVideo != nil) {
							  NSURL *photoURL = [NSURL URLWithString:imageModel.urlList.firstObject];
							  NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];

							  [livePhotos addObject:@{@"imageURL" : photoURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
						  }
					  }

					  // 使用批量下载实况照片方法
					  [DYYYManager downloadAllLivePhotos:livePhotos];
				  } else if (imageURLs.count > 0) {
					  [DYYYManager downloadAllImages:imageURLs];
				  }

				  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
				  [panelManager dismissWithAnimation:YES completion:nil];
				};

				[viewModels addObject:allImagesViewModel];
			}
		}
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
		AWELongPressPanelBaseViewModel *copyText = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyText.awemeModel = self.awemeModel;
		copyText.actionType = 671;
		copyText.duxIconName = @"ic_xiaoxihuazhonghua_outlined";
		copyText.describeString = @"复制文案";

		copyText.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
		  [[UIPasteboard generalPasteboard] setString:descText];
		  [DYYYManager showToast:@"文案已复制到剪贴板"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyText];

		// 新增复制分享链接
		AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyShareLink.awemeModel = self.awemeModel;
		copyShareLink.actionType = 672;
		copyShareLink.duxIconName = @"ic_share_outlined";
		copyShareLink.describeString = @"复制分享链接";

		copyShareLink.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  [[UIPasteboard generalPasteboard] setString:shareLink];
		  [DYYYManager showToast:@"分享链接已复制到剪贴板"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyShareLink];
	}

	// 添加接口保存功能
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
	if (apiKey.length > 0) {
		AWELongPressPanelBaseViewModel *apiDownload = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		apiDownload.awemeModel = self.awemeModel;
		apiDownload.actionType = 673;
		apiDownload.duxIconName = @"ic_cloudarrowdown_outlined_20";
		apiDownload.describeString = @"接口保存视频";

		apiDownload.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  if (shareLink.length == 0) {
			  [DYYYManager showToast:@"无法获取分享链接"];
			  return;
		  }

		  // 使用封装的方法进行解析下载
		  [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:apiDownload];
	}
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterUser"]) {
		// 新增修改过滤规则功能
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 674;
		filterKeywords.duxIconName = @"ic_userban_outlined_20";
		filterKeywords.describeString = @"过滤用户视频";

		filterKeywords.action = ^{
		  // 获取当前视频作者信息
		  AWEUserModel *author = self.awemeModel.author;
		  NSString *nickname = author.nickname ?: @"未知用户";
		  NSString *shortId = author.shortID ?: @"";

		  // 创建当前用户的过滤格式 "nickname-shortid"
		  NSString *currentUserFilter = [NSString stringWithFormat:@"%@-%@", nickname, shortId];

		  // 获取保存的过滤用户列表
		  NSString *savedUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterUsers"] ?: @"";
		  NSArray *userArray = [savedUsers length] > 0 ? [savedUsers componentsSeparatedByString:@","] : @[];

		  // 检查当前用户是否已在过滤列表中
		  BOOL userExists = NO;
		  for (NSString *userInfo in userArray) {
			  NSArray *components = [userInfo componentsSeparatedByString:@"-"];
			  if (components.count >= 2) {
				  NSString *userId = [components lastObject];
				  if ([userId isEqualToString:shortId] && shortId.length > 0) {
					  userExists = YES;
					  break;
				  }
			  }
		  }
		  NSString *actionButtonText = userExists ? @"取消过滤" : @"添加过滤";

		  [DYYYBottomAlertView showAlertWithTitle:@"过滤用户视频"
		      message:[NSString stringWithFormat:@"用户: %@ (ID: %@)", nickname, shortId]
		      cancelButtonText:@"管理过滤列表"
		      confirmButtonText:actionButtonText
		      cancelAction:^{
			// 创建并显示关键词列表视图
			DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"过滤用户列表" keywords:userArray];
			// 设置确认回调
			keywordListView.onConfirm = ^(NSArray *users) {
			  // 将用户数组转换为逗号分隔的字符串
			  NSString *userString = [users componentsJoinedByString:@","];

			  // 保存到用户默认设置
			  [[NSUserDefaults standardUserDefaults] setObject:userString forKey:@"DYYYfilterUsers"];
			  [[NSUserDefaults standardUserDefaults] synchronize];

			  // 显示提示
			  [DYYYManager showToast:@"过滤用户列表已更新"];
			};

			[keywordListView show];
		      }
		      confirmAction:^{
			// 添加或移除用户过滤 - 原来的options[0]操作
			NSMutableArray *updatedUsers = [NSMutableArray arrayWithArray:userArray];

			if (userExists) {
				// 移除用户
				NSMutableArray *toRemove = [NSMutableArray array];
				for (NSString *userInfo in updatedUsers) {
					NSArray *components = [userInfo componentsSeparatedByString:@"-"];
					if (components.count >= 2) {
						NSString *userId = [components lastObject];
						if ([userId isEqualToString:shortId]) {
							[toRemove addObject:userInfo];
						}
					}
				}
				[updatedUsers removeObjectsInArray:toRemove];
				[DYYYManager showToast:@"已从过滤列表中移除此用户"];
			} else {
				// 添加用户
				[updatedUsers addObject:currentUserFilter];
				[DYYYManager showToast:@"已添加此用户到过滤列表"];
			}

			// 保存更新后的列表
			NSString *updatedUserString = [updatedUsers componentsJoinedByString:@","];
			[[NSUserDefaults standardUserDefaults] setObject:updatedUserString forKey:@"DYYYfilterUsers"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		      }];
		};

		[viewModels addObject:filterKeywords];
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterTitle"]) {
		// 新增修改过滤规则功能
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 675;
		filterKeywords.duxIconName = @"ic_funnel_outlined_20";
		filterKeywords.describeString = @"过滤关键词调整";

		filterKeywords.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];

		  DYYYFilterSettingsView *filterView = [[DYYYFilterSettingsView alloc] initWithTitle:@"过滤关键词调整" text:descText];
		  filterView.onConfirm = ^(NSString *selectedText) {
		    if (selectedText.length > 0) {
			    NSString *currentKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"] ?: @"";
			    NSString *newKeywords;

			    if (currentKeywords.length > 0) {
				    newKeywords = [NSString stringWithFormat:@"%@,%@", currentKeywords, selectedText];
			    } else {
				    newKeywords = selectedText;
			    }

			    [[NSUserDefaults standardUserDefaults] setObject:newKeywords forKey:@"DYYYfilterKeywords"];
			    [[NSUserDefaults standardUserDefaults] synchronize];
			    [DYYYManager showToast:[NSString stringWithFormat:@"已添加过滤词: %@", selectedText]];
		    }
		  };

		  // 设置过滤关键词按钮回调
		  filterView.onKeywordFilterTap = ^{
		    // 获取保存的关键词
		    NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"] ?: @"";
		    NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];

		    // 创建并显示关键词列表视图
		    DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤关键词" keywords:keywordArray];

		    // 设置确认回调
		    keywordListView.onConfirm = ^(NSArray *keywords) {
		      // 将关键词数组转换为逗号分隔的字符串
		      NSString *keywordString = [keywords componentsJoinedByString:@","];

		      // 保存到用户默认设置
		      [[NSUserDefaults standardUserDefaults] setObject:keywordString forKey:@"DYYYfilterKeywords"];
		      [[NSUserDefaults standardUserDefaults] synchronize];

		      // 显示提示
		      [DYYYManager showToast:@"过滤关键词已更新"];
		    };

		    // 显示关键词列表视图
		    [keywordListView show];
		  };

		  [filterView show];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:filterKeywords];
	}

    NSMutableArray<AWELongPressPanelViewGroupModel *> *customGroups = [NSMutableArray array];
    NSInteger maxPerGroup = 5;
    for (NSInteger i = 0; i < viewModels.count; i += maxPerGroup) {
        NSRange range = NSMakeRange(i, MIN(maxPerGroup, viewModels.count - i));
        NSArray<AWELongPressPanelBaseViewModel *> *subArr = [viewModels subarrayWithRange:range];
        AWELongPressPanelViewGroupModel *groupModel = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
        [groupModel setIsDYYYCustomGroup:YES];
        groupModel.groupType = 12;
        groupModel.isModern = YES;
        groupModel.groupArr = subArr;
        [customGroups addObject:groupModel];
    }

    // 返回自定义分组拼接原始分组
    return [customGroups arrayByAddingObjectsFromArray:originalArray];
}

%end

%hook AWELongPressPanelViewGroupModel

%new
- (void)setIsDYYYCustomGroup:(BOOL)isCustom {
    objc_setAssociatedObject(self, @selector(isDYYYCustomGroup), @(isCustom), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (BOOL)isDYYYCustomGroup {
    NSNumber *value = objc_getAssociatedObject(self, @selector(isDYYYCustomGroup));
    return [value boolValue];
}

%end

%hook AWEModernLongPressHorizontalSettingCell

- (void)setLongPressViewGroupModel:(AWELongPressPanelViewGroupModel *)groupModel {
    %orig;
    
    if (groupModel && [groupModel isDYYYCustomGroup]) {
        [self setupCustomLayout];
    }
}
%new
- (void)setupCustomLayout {
    if (self.collectionView) {
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        if (layout) {
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            
            // 根据组索引应用不同的间距
            NSInteger groupIndex = [self.longPressViewGroupModel groupType];
            
            if (groupIndex == 12) {
                // 第一排 - 均匀分布
                layout.minimumInteritemSpacing = 0;
                layout.minimumLineSpacing = 0;
            } else {
                // 第二排 - 卡片样式，带间距（类似第三排）
                layout.minimumInteritemSpacing = 10;
                layout.minimumLineSpacing = 10;
                layout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
            }
            
            [self.collectionView setCollectionViewLayout:layout animated:NO];
        }
    }
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.longPressViewGroupModel && [self.longPressViewGroupModel isDYYYCustomGroup]) {
        if (self.dataArray && indexPath.item < self.dataArray.count) {
            // 根据组索引设置不同尺寸
            NSInteger groupIndex = [self.longPressViewGroupModel groupType];
            
            if (groupIndex == 12) {
                // 第一排 - 均等分割
                CGFloat totalWidth = collectionView.bounds.size.width;
                NSInteger itemCount = self.dataArray.count;
                CGFloat itemWidth = totalWidth / itemCount;
                return CGSizeMake(itemWidth, 75);
            } else {
                // 第二排 - 卡片样式，类似第三排
                AWELongPressPanelBaseViewModel *model = self.dataArray[indexPath.item];
                NSString *text = model.describeString;
                
                // 根据文本计算宽度，但确保至少有最小宽度
                CGFloat textWidth = [self widthForText:text];
                CGFloat cardWidth = MAX(100, textWidth + 30); 
                
                return CGSizeMake(cardWidth, 75);
            }
        }
        return CGSizeMake(75, 75);
    }
    
    return %orig;
}


%new
- (CGFloat)widthForText:(NSString *)text {
    if (!text || text.length == 0) {
        return 0;
    }
    
    UIFont *font = [UIFont systemFontOfSize:12];
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, 20)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:attributes
                                        context:nil].size;
    return textSize.width;
}

%end

%hook AWEModernLongPressHorizontalSettingItemCell

- (void)updateUI:(AWELongPressPanelBaseViewModel *)viewModel {
    %orig;
    
    if (viewModel && viewModel.actionType >= 666 && viewModel.actionType <= 680) {
        // 获取组索引以应用不同的样式
        NSInteger groupIndex = 12; // 默认为第一组
        if ([self.superview.superview isKindOfClass:%c(AWEModernLongPressHorizontalSettingCell)]) {
            AWEModernLongPressHorizontalSettingCell *parentCell = (AWEModernLongPressHorizontalSettingCell *)self.superview.superview;
            groupIndex = [parentCell.longPressViewGroupModel groupType];
        }
        
        CGFloat padding = 0;
        CGFloat contentWidth = self.contentView.bounds.size.width;
        
        CGRect iconFrame = self.buttonIcon.frame;
        iconFrame.origin.x = (contentWidth - iconFrame.size.width) / 2;
        iconFrame.origin.y = padding;
        self.buttonIcon.frame = iconFrame;
        
        CGFloat labelY = CGRectGetMaxY(iconFrame) + 4;
        CGFloat labelWidth = contentWidth;
        CGFloat labelHeight = self.contentView.bounds.size.height - labelY - padding;
        
        self.buttonLabel.frame = CGRectMake(padding, labelY, labelWidth, labelHeight);
        self.buttonLabel.textAlignment = NSTextAlignmentCenter;
        self.buttonLabel.numberOfLines = 2;
        self.buttonLabel.font = [UIFont systemFontOfSize:12];
        
        if (self.separator) {
            // 对于第一排，显示分隔符；对于第二排，隐藏分隔符
            self.separator.hidden = (groupIndex != 12);
        }
    }
}
- (void)layoutSubviews {
    %orig;
    if (self.longPressPanelVM && self.longPressPanelVM.actionType >= 666 && self.longPressPanelVM.actionType <= 680) {
        [self updateUI:self.longPressPanelVM];
    }
}
%end

%hook AWELongPressPanelTableViewController

- (NSArray *)dataArray {
	NSArray *originalArray = %orig;

	if (!originalArray) {
		originalArray = @[];
	}

	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
		return originalArray;
	}

	AWELongPressPanelViewGroupModel *newGroupModel = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
	newGroupModel.groupType = 0;

	NSMutableArray *viewModels = [NSMutableArray array];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"]) {
		if (self.awemeModel.awemeType != 68) {
			AWELongPressPanelBaseViewModel *downloadViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			downloadViewModel.awemeModel = self.awemeModel;
			downloadViewModel.actionType = 666;
			downloadViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			downloadViewModel.describeString = @"保存视频";

			downloadViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;
			  AWEMusicModel *musicModel = awemeModel.music;

			  if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeVideo
						  completion:^{
						    [DYYYManager showToast:@"视频已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:downloadViewModel];
		}

		if (self.awemeModel.awemeType != 68) {
			AWELongPressPanelBaseViewModel *coverViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			coverViewModel.awemeModel = self.awemeModel;
			coverViewModel.actionType = 667;
			coverViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			coverViewModel.describeString = @"保存封面";

			coverViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;

			  if (videoModel && videoModel.coverURL && videoModel.coverURL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"封面已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:coverViewModel];
		}

		AWELongPressPanelBaseViewModel *audioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		audioViewModel.awemeModel = self.awemeModel;
		audioViewModel.actionType = 668;
		audioViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
		audioViewModel.describeString = @"保存音频";

		audioViewModel.action = ^{
		  AWEAwemeModel *awemeModel = self.awemeModel;
		  AWEMusicModel *musicModel = awemeModel.music;

		  if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
			  NSURL *url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
			  [DYYYManager downloadMedia:url mediaType:MediaTypeAudio completion:nil];
		  }

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:audioViewModel];

		if (self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
			AWELongPressPanelBaseViewModel *imageViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			imageViewModel.awemeModel = self.awemeModel;
			imageViewModel.actionType = 669;
			imageViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			imageViewModel.describeString = @"保存当前图片";

			AWEImageAlbumImageModel *currimge = self.awemeModel.albumImages[self.awemeModel.currentImageIndex - 1];
			if (currimge.clipVideo != nil) {
				imageViewModel.describeString = @"保存当前实况";
			}
			imageViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEImageAlbumImageModel *currentImageModel = nil;

			  if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
				  currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
			  } else {
				  currentImageModel = awemeModel.albumImages.firstObject;
			  }
			  // 如果是实况的话
			  if (currimge.clipVideo != nil) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  NSURL *videoURL = [currimge.clipVideo.playURL getDYYYSrcURLDownload];

				  [DYYYManager downloadLivePhoto:url
							videoURL:videoURL
						      completion:^{
							[DYYYManager showToast:@"实况照片已保存到相册"];
						      }];
			  } else if (currentImageModel && currentImageModel.urlList.count > 0) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"图片已保存到相册"];
						  }];
			  }

			  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
			  [panelManager dismissWithAnimation:YES completion:nil];
			};

			[viewModels addObject:imageViewModel];

			if (self.awemeModel.albumImages.count > 1) {
				AWELongPressPanelBaseViewModel *allImagesViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
				allImagesViewModel.awemeModel = self.awemeModel;
				allImagesViewModel.actionType = 670;
				allImagesViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
				allImagesViewModel.describeString = @"保存所有图片";

				// 检查是否有实况照片并更改按钮文字
				BOOL hasLivePhoto = NO;
				for (AWEImageAlbumImageModel *imageModel in self.awemeModel.albumImages) {
					if (imageModel.clipVideo != nil) {
						hasLivePhoto = YES;
						break;
					}
				}

				if (hasLivePhoto) {
					allImagesViewModel.describeString = @"保存所有实况";
				}

				allImagesViewModel.action = ^{
				  AWEAwemeModel *awemeModel = self.awemeModel;
				  NSMutableArray *imageURLs = [NSMutableArray array];

				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.urlList.count > 0) {
						  [imageURLs addObject:imageModel.urlList.firstObject];
					  }
				  }

				  // 检查是否有实况照片
				  BOOL hasLivePhoto = NO;
				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.clipVideo != nil) {
						  hasLivePhoto = YES;
						  break;
					  }
				  }

				  // 如果有实况照片，使用单独的downloadLivePhoto方法逐个下载
				  if (hasLivePhoto) {
					  NSMutableArray *livePhotos = [NSMutableArray array];
					  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
						  if (imageModel.urlList.count > 0 && imageModel.clipVideo != nil) {
							  NSURL *photoURL = [NSURL URLWithString:imageModel.urlList.firstObject];
							  NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];

							  [livePhotos addObject:@{@"imageURL" : photoURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
						  }
					  }

					  // 使用批量下载实况照片方法
					  [DYYYManager downloadAllLivePhotos:livePhotos];
				  } else if (imageURLs.count > 0) {
					  [DYYYManager downloadAllImages:imageURLs];
				  }

				  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
				  [panelManager dismissWithAnimation:YES completion:nil];
				};

				[viewModels addObject:allImagesViewModel];
			}
		}
	}

	// 添加接口保存功能
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
	if (apiKey.length > 0) {
		AWELongPressPanelBaseViewModel *apiDownload = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		apiDownload.awemeModel = self.awemeModel;
		apiDownload.actionType = 673;
		apiDownload.duxIconName = @"ic_cloudarrowdown_outlined_20";
		apiDownload.describeString = @"接口保存";

		apiDownload.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  if (shareLink.length == 0) {
			  [DYYYManager showToast:@"无法获取分享链接"];
			  return;
		  }

		  // 使用封装的方法进行解析下载
		  [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:apiDownload];
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCopyText"]) {
		AWELongPressPanelBaseViewModel *copyText = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyText.awemeModel = self.awemeModel;
		copyText.actionType = 671;
		copyText.duxIconName = @"ic_xiaoxihuazhonghua_outlined";
		copyText.describeString = @"复制文案";

		copyText.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
		  [[UIPasteboard generalPasteboard] setString:descText];
		  [DYYYManager showToast:@"文案已复制到剪贴板"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyText];

		// 新增复制分享链接
		AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyShareLink.awemeModel = self.awemeModel;
		copyShareLink.actionType = 672;
		copyShareLink.duxIconName = @"ic_share_outlined";
		copyShareLink.describeString = @"复制分享链接";

		copyShareLink.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  [[UIPasteboard generalPasteboard] setString:shareLink];
		  [DYYYManager showToast:@"分享链接已复制到剪贴板"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyShareLink];
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterUser"]) {
		// 新增修改过滤规则功能
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 674;
		filterKeywords.duxIconName = @"ic_userban_outlined_20";
		filterKeywords.describeString = @"过滤用户视频";

		filterKeywords.action = ^{
		  // 获取当前视频作者信息
		  AWEUserModel *author = self.awemeModel.author;
		  NSString *nickname = author.nickname ?: @"未知用户";
		  NSString *shortId = author.shortID ?: @"";

		  // 创建当前用户的过滤格式 "nickname-shortid"
		  NSString *currentUserFilter = [NSString stringWithFormat:@"%@-%@", nickname, shortId];

		  // 获取保存的过滤用户列表
		  NSString *savedUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterUsers"] ?: @"";
		  NSArray *userArray = [savedUsers length] > 0 ? [savedUsers componentsSeparatedByString:@","] : @[];

		  // 检查当前用户是否已在过滤列表中
		  BOOL userExists = NO;
		  for (NSString *userInfo in userArray) {
			  NSArray *components = [userInfo componentsSeparatedByString:@"-"];
			  if (components.count >= 2) {
				  NSString *userId = [components lastObject];
				  if ([userId isEqualToString:shortId] && shortId.length > 0) {
					  userExists = YES;
					  break;
				  }
			  }
		  }
		  NSString *actionButtonText = userExists ? @"取消过滤" : @"添加过滤";

		  [DYYYBottomAlertView showAlertWithTitle:@"过滤用户视频"
		      message:[NSString stringWithFormat:@"用户: %@ (ID: %@)", nickname, shortId]
		      cancelButtonText:@"管理过滤列表"
		      confirmButtonText:actionButtonText
		      cancelAction:^{
			// 创建并显示关键词列表视图
			DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"过滤用户列表" keywords:userArray];
			// 设置确认回调
			keywordListView.onConfirm = ^(NSArray *users) {
			  // 将用户数组转换为逗号分隔的字符串
			  NSString *userString = [users componentsJoinedByString:@","];

			  // 保存到用户默认设置
			  [[NSUserDefaults standardUserDefaults] setObject:userString forKey:@"DYYYfilterUsers"];
			  [[NSUserDefaults standardUserDefaults] synchronize];

			  // 显示提示
			  [DYYYManager showToast:@"过滤用户列表已更新"];
			};

			[keywordListView show];
		      }
		      confirmAction:^{
			// 添加或移除用户过滤 - 原来的options[0]操作
			NSMutableArray *updatedUsers = [NSMutableArray arrayWithArray:userArray];

			if (userExists) {
				// 移除用户
				NSMutableArray *toRemove = [NSMutableArray array];
				for (NSString *userInfo in updatedUsers) {
					NSArray *components = [userInfo componentsSeparatedByString:@"-"];
					if (components.count >= 2) {
						NSString *userId = [components lastObject];
						if ([userId isEqualToString:shortId]) {
							[toRemove addObject:userInfo];
						}
					}
				}
				[updatedUsers removeObjectsInArray:toRemove];
				[DYYYManager showToast:@"已从过滤列表中移除此用户"];
			} else {
				// 添加用户
				[updatedUsers addObject:currentUserFilter];
				[DYYYManager showToast:@"已添加此用户到过滤列表"];
			}

			// 保存更新后的列表
			NSString *updatedUserString = [updatedUsers componentsJoinedByString:@","];
			[[NSUserDefaults standardUserDefaults] setObject:updatedUserString forKey:@"DYYYfilterUsers"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		      }];
		};

		[viewModels addObject:filterKeywords];
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterTitle"]) {
		// 新增修改过滤规则功能
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 675;
		filterKeywords.duxIconName = @"ic_funnel_outlined_20";
		filterKeywords.describeString = @"过滤关键词调整";

		filterKeywords.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];

		  DYYYFilterSettingsView *filterView = [[DYYYFilterSettingsView alloc] initWithTitle:@"过滤关键词调整" text:descText];
		  filterView.onConfirm = ^(NSString *selectedText) {
		    if (selectedText.length > 0) {
			    NSString *currentKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"] ?: @"";
			    NSString *newKeywords;

			    if (currentKeywords.length > 0) {
				    newKeywords = [NSString stringWithFormat:@"%@,%@", currentKeywords, selectedText];
			    } else {
				    newKeywords = selectedText;
			    }

			    [[NSUserDefaults standardUserDefaults] setObject:newKeywords forKey:@"DYYYfilterKeywords"];
			    [[NSUserDefaults standardUserDefaults] synchronize];
			    [DYYYManager showToast:[NSString stringWithFormat:@"已添加过滤词: %@", selectedText]];
		    }
		  };

		  // 设置过滤关键词按钮回调
		  filterView.onKeywordFilterTap = ^{
		    // 获取保存的关键词
		    NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"] ?: @"";
		    NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];

		    // 创建并显示关键词列表视图
		    DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤关键词" keywords:keywordArray];

		    // 设置确认回调
		    keywordListView.onConfirm = ^(NSArray *keywords) {
		      // 将关键词数组转换为逗号分隔的字符串
		      NSString *keywordString = [keywords componentsJoinedByString:@","];

		      // 保存到用户默认设置
		      [[NSUserDefaults standardUserDefaults] setObject:keywordString forKey:@"DYYYfilterKeywords"];
		      [[NSUserDefaults standardUserDefaults] synchronize];

		      // 显示提示
		      [DYYYManager showToast:@"过滤关键词已更新"];
		    };

		    // 显示关键词列表视图
		    [keywordListView show];
		  };

		  [filterView show];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:filterKeywords];
	}

	newGroupModel.groupArr = viewModels;

	if (originalArray.count > 0) {
		NSMutableArray *resultArray = [originalArray mutableCopy];
		[resultArray insertObject:newGroupModel atIndex:1];
		return [resultArray copy];
	} else {
		return @[ newGroupModel ];
	}
}

%end

%ctor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
	}
}
