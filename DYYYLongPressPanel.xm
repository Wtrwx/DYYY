#import "AwemeHeaders.h"
#import "DYYYBottomAlertView.h"
#import "DYYYFilterSettingsView.h"
#import "DYYYKeywordListView.h"
#import "DYYYManager.h"

%hook AWELongPressPanelViewGroupModel
%property(nonatomic, assign) BOOL isDYYYCustomGroup;
%end

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
	newGroupModel.isDYYYCustomGroup = YES;
	newGroupModel.groupType = 12;
	newGroupModel.isModern = YES;

	NSMutableArray *viewModels = [NSMutableArray array];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressDownload"]) {
		if (self.awemeModel.awemeType != 68) {
			AWELongPressPanelBaseViewModel *downloadViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
			downloadViewModel.awemeModel = self.awemeModel;
			downloadViewModel.actionType = 666;
			downloadViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
			downloadViewModel.describeString = @"儲存影片";

			downloadViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;
			  AWEMusicModel *musicModel = awemeModel.music;

			  if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeVideo
						  completion:^{
						    [DYYYManager showToast:@"影片已儲存至照片App"];
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
			coverViewModel.describeString = @"儲存封面";

			coverViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;

			  if (videoModel && videoModel.coverURL && videoModel.coverURL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"封面已儲存至照片App"];
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
		audioViewModel.describeString = @"儲存音訊";

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
			imageViewModel.describeString = @"儲存目前圖片";

			AWEImageAlbumImageModel *currimge = self.awemeModel.albumImages[self.awemeModel.currentImageIndex - 1];
			if (currimge.clipVideo != nil) {
				imageViewModel.describeString = @"儲存目前原況";
			}
			imageViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEImageAlbumImageModel *currentImageModel = nil;

			  if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
				  currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
			  } else {
				  currentImageModel = awemeModel.albumImages.firstObject;
			  }
			  // 如果是原況的話
			  if (currimge.clipVideo != nil) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  NSURL *videoURL = [currimge.clipVideo.playURL getDYYYSrcURLDownload];

				  [DYYYManager downloadLivePhoto:url
							videoURL:videoURL
						      completion:^{
							[DYYYManager showToast:@"原況照片已儲存至照片App"];
						      }];
			  } else if (currentImageModel && currentImageModel.urlList.count > 0) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"圖片已儲存至照片App"];
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
				allImagesViewModel.describeString = @"儲存所有圖片";

				// 檢查是否有原況照片並更改按鈕文字
				BOOL hasLivePhoto = NO;
				for (AWEImageAlbumImageModel *imageModel in self.awemeModel.albumImages) {
					if (imageModel.clipVideo != nil) {
						hasLivePhoto = YES;
						break;
					}
				}

				if (hasLivePhoto) {
					allImagesViewModel.describeString = @"儲存所有原況";
				}

				allImagesViewModel.action = ^{
				  AWEAwemeModel *awemeModel = self.awemeModel;
				  NSMutableArray *imageURLs = [NSMutableArray array];

				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.urlList.count > 0) {
						  [imageURLs addObject:imageModel.urlList.firstObject];
					  }
				  }

				  // 檢查是否有原況照片
				  BOOL hasLivePhoto = NO;
				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.clipVideo != nil) {
						  hasLivePhoto = YES;
						  break;
					  }
				  }

				  // 如果有原況照片，使用單獨的downloadLivePhoto方法逐個下載
				  if (hasLivePhoto) {
					  NSMutableArray *livePhotos = [NSMutableArray array];
					  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
						  if (imageModel.urlList.count > 0 && imageModel.clipVideo != nil) {
							  NSURL *photoURL = [NSURL URLWithString:imageModel.urlList.firstObject];
							  NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];

							  [livePhotos addObject:@{@"imageURL" : photoURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
						  }
					  }

					  // 使用批量下載原況照片方法
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
		copyText.describeString = @"複製文案";

		copyText.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
		  [[UIPasteboard generalPasteboard] setString:descText];
		  [DYYYManager showToast:@"文案已複製至剪貼簿"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyText];

		// 新增複製分享連結
		AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyShareLink.awemeModel = self.awemeModel;
		copyShareLink.actionType = 672;
		copyShareLink.duxIconName = @"ic_share_outlined";
		copyShareLink.describeString = @"複製連結";

		copyShareLink.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  [[UIPasteboard generalPasteboard] setString:shareLink];
		  [DYYYManager showToast:@"分享連結已複製至剪貼簿"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyShareLink];
	}

	// 添加接口儲存功能
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
	if (apiKey.length > 0) {
		AWELongPressPanelBaseViewModel *apiDownload = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		apiDownload.awemeModel = self.awemeModel;
		apiDownload.actionType = 673;
		apiDownload.duxIconName = @"ic_cloudarrowdown_outlined_20";
		apiDownload.describeString = @"接口儲存";

		apiDownload.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  if (shareLink.length == 0) {
			  [DYYYManager showToast:@"無法取得分享連結"];
			  return;
		  }

		  // 使用封裝的方法進行解析下載
		  [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:apiDownload];
	}
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterUser"]) {
		// 新增修改過濾規則功能
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 674;
		filterKeywords.duxIconName = @"ic_userban_outlined_20";
		filterKeywords.describeString = @"過濾使用者";

		filterKeywords.action = ^{
		  // 取得目前影片作者資訊
		  AWEUserModel *author = self.awemeModel.author;
		  NSString *nickname = author.nickname ?: @"未知使用者";
		  NSString *shortId = author.shortID ?: @"";

		  // 建立目前使用者的過濾格式 "nickname-shortid"
		  NSString *currentUserFilter = [NSString stringWithFormat:@"%@-%@", nickname, shortId];

		  // 取得儲存的過濾使用者列表
		  NSString *savedUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterUsers"] ?: @"";
		  NSArray *userArray = [savedUsers length] > 0 ? [savedUsers componentsSeparatedByString:@","] : @[];

		  // 檢查目前使用者是否已在過濾列表中
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
		  NSString *actionButtonText = userExists ? @"取消過濾" : @"新增過濾";

		  [DYYYBottomAlertView showAlertWithTitle:@"過濾使用者影片"
		      message:[NSString stringWithFormat:@"使用者: %@ (ID: %@)", nickname, shortId]
		      cancelButtonText:@"管理過濾列表"
		      confirmButtonText:actionButtonText
		      cancelAction:^{
			// 建立並顯示關鍵詞列表視圖
			DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"過濾使用者列表" keywords:userArray];
			// 設定確認回調
			keywordListView.onConfirm = ^(NSArray *users) {
			  // 將使用者陣列轉換為逗號分隔的字串
			  NSString *userString = [users componentsJoinedByString:@","];

			  // 儲存至使用者預設設定
			  [[NSUserDefaults standardUserDefaults] setObject:userString forKey:@"DYYYfilterUsers"];
			  [[NSUserDefaults standardUserDefaults] synchronize];

			  // 顯示提示
			  [DYYYManager showToast:@"過濾使用者列表已更新"];
			};

			[keywordListView show];
		      }
		      confirmAction:^{
			// 新增或移除使用者過濾 - 原來的options[0]操作
			NSMutableArray *updatedUsers = [NSMutableArray arrayWithArray:userArray];

			if (userExists) {
				// 移除使用者
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
				[DYYYManager showToast:@"已從過濾列表中移除此使用者"];
			} else {
				// 新增使用者
				[updatedUsers addObject:currentUserFilter];
				[DYYYManager showToast:@"已新增此使用者至過濾列表"];
			}

			// 儲存更新後的列表
			NSString *updatedUserString = [updatedUsers componentsJoinedByString:@","];
			[[NSUserDefaults standardUserDefaults] setObject:updatedUserString forKey:@"DYYYfilterUsers"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		      }];
		};

		[viewModels addObject:filterKeywords];
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterTitle"]) {
		// 新增修改過濾規則功能
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 675;
		filterKeywords.duxIconName = @"ic_funnel_outlined_20";
		filterKeywords.describeString = @"過濾文案";

		filterKeywords.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];

		  DYYYFilterSettingsView *filterView = [[DYYYFilterSettingsView alloc] initWithTitle:@"過濾關鍵詞調整" text:descText];
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
			    [DYYYManager showToast:[NSString stringWithFormat:@"已新增過濾詞: %@", selectedText]];
		    }
		  };

		  // 設定過濾關鍵詞按鈕回調
		  filterView.onKeywordFilterTap = ^{
		    // 取得儲存的關鍵詞
		    NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"] ?: @"";
		    NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];

		    // 建立並顯示關鍵詞列表視圖
		    DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"設定過濾關鍵詞" keywords:keywordArray];

		    // 設定確認回調
		    keywordListView.onConfirm = ^(NSArray *keywords) {
		      // 將關鍵詞陣列轉換為逗號分隔的字串
		      NSString *keywordString = [keywords componentsJoinedByString:@","];

		      // 儲存至使用者預設設定
		      [[NSUserDefaults standardUserDefaults] setObject:keywordString forKey:@"DYYYfilterKeywords"];
		      [[NSUserDefaults standardUserDefaults] synchronize];

		      // 顯示提示
		      [DYYYManager showToast:@"過濾關鍵詞已更新"];
		    };

		    // 顯示關鍵詞列表視圖
		    [keywordListView show];
		  };

		  [filterView show];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:filterKeywords];
	}

	NSMutableArray<AWELongPressPanelViewGroupModel *> *customGroups = [NSMutableArray array];
        NSInteger totalButtons = viewModels.count;
        // 根据按钮总数确定每行的按钮数
        NSInteger firstRowCount = 0;
        NSInteger secondRowCount = 0;
        if (totalButtons >= 9) {
            firstRowCount = 5;
            secondRowCount = totalButtons - firstRowCount;
        } else if (totalButtons == 8) {
            firstRowCount = 4;
            secondRowCount = 4;
        } else if (totalButtons == 7) {
            firstRowCount = 4;
            secondRowCount = 3;
        } else if (totalButtons == 6) {
            firstRowCount = 4;
            secondRowCount = 2;
        } else if (totalButtons == 5) {
            firstRowCount = 3;
            secondRowCount = 2;
        } else if (totalButtons == 4) {
            firstRowCount = 2;
            secondRowCount = 2;
        } else if (totalButtons == 3) {
            firstRowCount = 2;
            secondRowCount = 1;
        } else if (totalButtons <= 2) {
            firstRowCount = totalButtons;
            secondRowCount = 0;
        }
        // 创建第一行
        if (firstRowCount > 0) {
            NSRange firstRowRange = NSMakeRange(0, firstRowCount);
            NSArray<AWELongPressPanelBaseViewModel *> *firstRowButtons = [viewModels subarrayWithRange:firstRowRange];
            
            AWELongPressPanelViewGroupModel *firstRowGroup = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
            firstRowGroup.isDYYYCustomGroup = YES;
            firstRowGroup.groupType = (firstRowCount <= 3) ? 11 : 12;
            firstRowGroup.isModern = YES;
            firstRowGroup.groupArr = firstRowButtons;
            [customGroups addObject:firstRowGroup];
        }
        // 创建第二行
        if (secondRowCount > 0) {
            NSRange secondRowRange = NSMakeRange(firstRowCount, secondRowCount);
            NSArray<AWELongPressPanelBaseViewModel *> *secondRowButtons = [viewModels subarrayWithRange:secondRowRange];
            
            AWELongPressPanelViewGroupModel *secondRowGroup = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
            secondRowGroup.isDYYYCustomGroup = YES;
            secondRowGroup.groupType = (secondRowCount <= 3) ? 11 : 12;
            secondRowGroup.isModern = YES;
            secondRowGroup.groupArr = secondRowButtons;
            [customGroups addObject:secondRowGroup];
        }
		static BOOL hasProcessedArray = NO;
		if ((originalArray.count > 0 && !hasProcessedArray) && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelDaily"]) {
			NSMutableArray *modifiedArray = [originalArray mutableCopy];
			AWELongPressPanelViewGroupModel *firstGroup = modifiedArray[0];
			if (firstGroup.groupArr.count > 1) {
				NSMutableArray *groupArray = [firstGroup.groupArr mutableCopy];
				[groupArray removeObjectAtIndex:1];
				firstGroup.groupArr = groupArray;
				modifiedArray[0] = firstGroup;
			}
			originalArray = modifiedArray;
			hasProcessedArray = YES;
		}
        return [customGroups arrayByAddingObjectsFromArray:originalArray];
        }
        
%end

%hook AWEModernLongPressHorizontalSettingCell

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.longPressViewGroupModel && [self.longPressViewGroupModel isDYYYCustomGroup]) {
		if (self.dataArray && indexPath.item < self.dataArray.count) {
			CGFloat totalWidth = collectionView.bounds.size.width;
			NSInteger itemCount = self.dataArray.count;
			CGFloat itemWidth = totalWidth / itemCount;
			return CGSizeMake(itemWidth, 73);
		}
		return CGSizeMake(73, 73);
	}

	return %orig;
}

%end

%hook AWEModernLongPressInteractiveCell

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.longPressViewGroupModel && [self.longPressViewGroupModel isDYYYCustomGroup]) {
		if (self.dataArray && indexPath.item < self.dataArray.count) {

			NSInteger itemCount = self.dataArray.count;
			CGFloat totalWidth = collectionView.bounds.size.width - 12 * (itemCount - 1);
			CGFloat itemWidth = totalWidth / itemCount;
			return CGSizeMake(itemWidth, 73);
		}
		return CGSizeMake(73, 73);
	}

	return %orig;
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
			downloadViewModel.describeString = @"儲存影片";

			downloadViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;
			  AWEMusicModel *musicModel = awemeModel.music;

			  if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeVideo
						  completion:^{
						    [DYYYManager showToast:@"影片已儲存至照片App"];
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
			coverViewModel.describeString = @"儲存封面";

			coverViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEVideoModel *videoModel = awemeModel.video;

			  if (videoModel && videoModel.coverURL && videoModel.coverURL.originURLList.count > 0) {
				  NSURL *url = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"封面已儲存至照片App"];
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
		audioViewModel.describeString = @"儲存音訊";

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
			imageViewModel.describeString = @"儲存目前圖片";

			AWEImageAlbumImageModel *currimge = self.awemeModel.albumImages[self.awemeModel.currentImageIndex - 1];
			if (currimge.clipVideo != nil) {
				imageViewModel.describeString = @"儲存目前原況";
			}
			imageViewModel.action = ^{
			  AWEAwemeModel *awemeModel = self.awemeModel;
			  AWEImageAlbumImageModel *currentImageModel = nil;

			  if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
				  currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
			  } else {
				  currentImageModel = awemeModel.albumImages.firstObject;
			  }
			  // 如果是原況的話
			  if (currimge.clipVideo != nil) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  NSURL *videoURL = [currimge.clipVideo.playURL getDYYYSrcURLDownload];

				  [DYYYManager downloadLivePhoto:url
							videoURL:videoURL
						      completion:^{
							[DYYYManager showToast:@"原況照片已儲存至照片App"];
						      }];
			  } else if (currentImageModel && currentImageModel.urlList.count > 0) {
				  NSURL *url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
				  [DYYYManager downloadMedia:url
						   mediaType:MediaTypeImage
						  completion:^{
						    [DYYYManager showToast:@"圖片已儲存至照片App"];
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
				allImagesViewModel.describeString = @"儲存所有圖片";

				// 檢查是否有原況照片並更改按鈕文字
				BOOL hasLivePhoto = NO;
				for (AWEImageAlbumImageModel *imageModel in self.awemeModel.albumImages) {
					if (imageModel.clipVideo != nil) {
						hasLivePhoto = YES;
						break;
					}
				}

				if (hasLivePhoto) {
					allImagesViewModel.describeString = @"儲存所有原況";
				}

				allImagesViewModel.action = ^{
				  AWEAwemeModel *awemeModel = self.awemeModel;
				  NSMutableArray *imageURLs = [NSMutableArray array];

				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.urlList.count > 0) {
						  [imageURLs addObject:imageModel.urlList.firstObject];
					  }
				  }

				  // 檢查是否有原況照片
				  BOOL hasLivePhoto = NO;
				  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
					  if (imageModel.clipVideo != nil) {
						  hasLivePhoto = YES;
						  break;
					  }
				  }

				  // 如果有原況照片，使用單獨的downloadLivePhoto方法逐個下載
				  if (hasLivePhoto) {
					  NSMutableArray *livePhotos = [NSMutableArray array];
					  for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
						  if (imageModel.urlList.count > 0 && imageModel.clipVideo != nil) {
							  NSURL *photoURL = [NSURL URLWithString:imageModel.urlList.firstObject];
							  NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];

							  [livePhotos addObject:@{@"imageURL" : photoURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
						  }
					  }

					  // 使用批量下載原況照片方法
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

	// 添加接口儲存功能
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
	if (apiKey.length > 0) {
		AWELongPressPanelBaseViewModel *apiDownload = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		apiDownload.awemeModel = self.awemeModel;
		apiDownload.actionType = 673;
		apiDownload.duxIconName = @"ic_cloudarrowdown_outlined_20";
		apiDownload.describeString = @"接口儲存";

		apiDownload.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  if (shareLink.length == 0) {
			  [DYYYManager showToast:@"無法取得分享連結"];
			  return;
		  }

		  // 使用封裝的方法進行解析下載
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
		copyText.describeString = @"複製文案";

		copyText.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
		  [[UIPasteboard generalPasteboard] setString:descText];
		  [DYYYManager showToast:@"文案已複製至剪貼簿"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyText];

		// 新增複製分享連結
		AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		copyShareLink.awemeModel = self.awemeModel;
		copyShareLink.actionType = 672;
		copyShareLink.duxIconName = @"ic_share_outlined";
		copyShareLink.describeString = @"複製連結";

		copyShareLink.action = ^{
		  NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
		  [[UIPasteboard generalPasteboard] setString:shareLink];
		  [DYYYManager showToast:@"分享連結已複製至剪貼簿"];

		  AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
		  [panelManager dismissWithAnimation:YES completion:nil];
		};

		[viewModels addObject:copyShareLink];
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterUser"]) {
		// 新增修改過濾規則功能
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 674;
		filterKeywords.duxIconName = @"ic_userban_outlined_20";
		filterKeywords.describeString = @"過濾使用者影片";

		filterKeywords.action = ^{
		  // 取得目前影片作者資訊
		  AWEUserModel *author = self.awemeModel.author;
		  NSString *nickname = author.nickname ?: @"未知使用者";
		  NSString *shortId = author.shortID ?: @"";

		  // 建立目前使用者的過濾格式 "nickname-shortid"
		  NSString *currentUserFilter = [NSString stringWithFormat:@"%@-%@", nickname, shortId];

		  // 取得儲存的過濾使用者列表
		  NSString *savedUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterUsers"] ?: @"";
		  NSArray *userArray = [savedUsers length] > 0 ? [savedUsers componentsSeparatedByString:@","] : @[];

		  // 檢查目前使用者是否已在過濾列表中
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
		  NSString *actionButtonText = userExists ? @"取消過濾" : @"新增過濾";

		  [DYYYBottomAlertView showAlertWithTitle:@"過濾使用者影片"
		      message:[NSString stringWithFormat:@"使用者: %@ (ID: %@)", nickname, shortId]
		      cancelButtonText:@"管理過濾列表"
		      confirmButtonText:actionButtonText
		      cancelAction:^{
			// 建立並顯示關鍵詞列表視圖
			DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"過濾使用者列表" keywords:userArray];
			// 設定確認回調
			keywordListView.onConfirm = ^(NSArray *users) {
			  // 將使用者陣列轉換為逗號分隔的字串
			  NSString *userString = [users componentsJoinedByString:@","];

			  // 儲存至使用者預設設定
			  [[NSUserDefaults standardUserDefaults] setObject:userString forKey:@"DYYYfilterUsers"];
			  [[NSUserDefaults standardUserDefaults] synchronize];

			  // 顯示提示
			  [DYYYManager showToast:@"過濾使用者列表已更新"];
			};

			[keywordListView show];
		      }
		      confirmAction:^{
			// 新增或移除使用者過濾 - 原來的options[0]操作
			NSMutableArray *updatedUsers = [NSMutableArray arrayWithArray:userArray];

			if (userExists) {
				// 移除使用者
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
				[DYYYManager showToast:@"已從過濾列表中移除此使用者"];
			} else {
				// 新增使用者
				[updatedUsers addObject:currentUserFilter];
				[DYYYManager showToast:@"已新增此使用者至過濾列表"];
			}

			// 儲存更新後的列表
			NSString *updatedUserString = [updatedUsers componentsJoinedByString:@","];
			[[NSUserDefaults standardUserDefaults] setObject:updatedUserString forKey:@"DYYYfilterUsers"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		      }];
		};

		[viewModels addObject:filterKeywords];
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterTitle"]) {
		// 新增修改過濾規則功能
		AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
		filterKeywords.awemeModel = self.awemeModel;
		filterKeywords.actionType = 675;
		filterKeywords.duxIconName = @"ic_funnel_outlined_20";
		filterKeywords.describeString = @"過濾關鍵詞調整";

		filterKeywords.action = ^{
		  NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];

		  DYYYFilterSettingsView *filterView = [[DYYYFilterSettingsView alloc] initWithTitle:@"過濾關鍵詞調整" text:descText];
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
			    [DYYYManager showToast:[NSString stringWithFormat:@"已新增過濾詞: %@", selectedText]];
		    }
		  };

		  // 設定過濾關鍵詞按鈕回調
		  filterView.onKeywordFilterTap = ^{
		    // 取得儲存的關鍵詞
		    NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYfilterKeywords"] ?: @"";
		    NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];

		    // 建立並顯示關鍵詞列表視圖
		    DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"設定過濾關鍵詞" keywords:keywordArray];

		    // 設定確認回調
		    keywordListView.onConfirm = ^(NSArray *keywords) {
		      // 將關鍵詞陣列轉換為逗號分隔的字串
		      NSString *keywordString = [keywords componentsJoinedByString:@","];

		      // 儲存至使用者預設設定
		      [[NSUserDefaults standardUserDefaults] setObject:keywordString forKey:@"DYYYfilterKeywords"];
		      [[NSUserDefaults standardUserDefaults] synchronize];

		      // 顯示提示
		      [DYYYManager showToast:@"過濾關鍵詞已更新"];
		    };

		    // 顯示關鍵詞列表視圖
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