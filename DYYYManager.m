#import "DYYYManager.h"
#import <CoreAudioTypes/CoreAudioTypes.h>
#import <CoreMedia/CMMetadata.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <Photos/Photos.h>
#import <libwebp/decode.h>
#import <libwebp/demux.h>
#import <libwebp/mux.h>
#import <objc/message.h>
#import <objc/runtime.h>

// 自訂進度條視圖類
@interface DYYYManager () {
  AVAssetExportSession *session;
  AVURLAsset *asset;
  AVAssetReader *reader;
  AVAssetWriter *writer;
  dispatch_queue_t queue;
  dispatch_group_t group;
}
@end

@interface DYYYDownloadProgressView : UIView
@property(nonatomic, strong) UIView *containerView;
@property(nonatomic, strong) UIView *progressBarBackground;
@property(nonatomic, strong) UIView *progressBar;
@property(nonatomic, strong) UILabel *progressLabel;
@property(nonatomic, strong) UIButton *cancelButton;
@property(nonatomic, copy) void (^cancelBlock)(void);
@property(nonatomic, assign) BOOL isCancelled;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setProgress:(float)progress;
- (void)show;
- (void)dismiss;

@end

@implementation DYYYDownloadProgressView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
    self.isCancelled = NO;

    // 創建容器視圖，縮小尺寸
    _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 240, 140)];
    _containerView.center =
        CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _containerView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    _containerView.layer.cornerRadius = 12;
    _containerView.clipsToBounds = YES;
    [self addSubview:_containerView];

    // 創建進度條背景
    _progressBarBackground = [[UIView alloc]
        initWithFrame:CGRectMake(20, 50,
                                 CGRectGetWidth(_containerView.frame) - 40, 8)];
    _progressBarBackground.backgroundColor = [UIColor colorWithWhite:0.3
                                                               alpha:1.0];
    _progressBarBackground.layer.cornerRadius = 4;
    [_containerView addSubview:_progressBarBackground];

    // 創建進度條
    _progressBar = [[UIView alloc]
        initWithFrame:CGRectMake(
                          0, 0, 0,
                          CGRectGetHeight(_progressBarBackground.frame))];
    _progressBar.backgroundColor = [UIColor colorWithRed:0.0
                                                   green:0.7
                                                    blue:1.0
                                                   alpha:1.0];
    _progressBar.layer.cornerRadius = 4;
    [_progressBarBackground addSubview:_progressBar];

    // 創建進度標籤
    _progressLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(
                          0, CGRectGetMaxY(_progressBarBackground.frame) + 12,
                          CGRectGetWidth(_containerView.frame), 20)];
    _progressLabel.textAlignment = NSTextAlignmentCenter;
    _progressLabel.textColor = [UIColor whiteColor];
    _progressLabel.font = [UIFont systemFontOfSize:14];
    _progressLabel.text = @"0%";
    [_containerView addSubview:_progressLabel];

    // 創建取消按鈕
    _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _cancelButton.frame =
        CGRectMake((CGRectGetWidth(_containerView.frame) - 80) / 2,
                   CGRectGetMaxY(_progressLabel.frame) + 10, 80, 32);
    _cancelButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[UIColor whiteColor]
                        forState:UIControlStateNormal];
    _cancelButton.layer.cornerRadius = 16;
    [_cancelButton addTarget:self
                      action:@selector(cancelButtonTapped)
            forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:_cancelButton];

    // 添加標題標籤
    UILabel *titleLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(0, 15, CGRectGetWidth(_containerView.frame),
                                 20)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    titleLabel.text = @"正在下載";
    [_containerView addSubview:titleLabel];

    // 設置初始透明度為0，以便動畫顯示
    self.alpha = 0;
  }
  return self;
}

- (void)setProgress:(float)progress {
  // 確保在主執行緒中更新UI
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self setProgress:progress];
    });
    return;
  }

  // 進度值限制在0到1之間
  progress = MAX(0.0, MIN(1.0, progress));

  // 設置進度條長度
  CGRect progressFrame = _progressBar.frame;
  progressFrame.size.width =
      progress * CGRectGetWidth(_progressBarBackground.frame);
  _progressBar.frame = progressFrame;

  // 更新進度百分比
  int percentage = (int)(progress * 100);
  _progressLabel.text = [NSString stringWithFormat:@"%d%%", percentage];
}

- (void)show {
  UIWindow *window = [UIApplication sharedApplication].keyWindow;
  if (!window)
    return;

  [window addSubview:self];

  [UIView animateWithDuration:0.3
                   animations:^{
                     self.alpha = 1.0;
                   }];
}

- (void)dismiss {
  [UIView animateWithDuration:0.3
      animations:^{
        self.alpha = 0;
      }
      completion:^(BOOL finished) {
        [self removeFromSuperview];
      }];
}

- (void)cancelButtonTapped {
  self.isCancelled = YES; // 設置取消標誌
  if (self.cancelBlock) {
    self.cancelBlock();
  }
  [self dismiss];
}

@end

@interface DYYYManager () <NSURLSessionDownloadDelegate>
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, NSURLSessionDownloadTask *> *downloadTasks;
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, DYYYDownloadProgressView *> *progressViews;
@property(nonatomic, strong) NSOperationQueue *downloadQueue;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *>
    *taskProgressMap; // 添加進度映射
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, void (^)(BOOL success, NSURL *fileURL)>
        *completionBlocks; // 添加完成回調儲存
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *>
    *mediaTypeMap; // 添加媒體類型映射

// 批次下載相關屬性
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSString *>
    *downloadToBatchMap; // 下載ID到批次ID的映射
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *>
    *batchCompletedCountMap; // 批次ID到已完成數量的映射
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *>
    *batchSuccessCountMap; // 批次ID到成功數量的映射
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *>
    *batchTotalCountMap; // 批次ID到總數量的映射
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, void (^)(NSInteger current, NSInteger total)
                        > *batchProgressBlocks; // 批次進度回調
@property(nonatomic, strong)
    NSMutableDictionary<NSString *,
                        void (^)(NSInteger successCount, NSInteger totalCount)>
        *batchCompletionBlocks; // 批次完成回調
@end

@implementation DYYYManager

+ (instancetype)shared {
  static DYYYManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _fileLinks = [NSMutableDictionary dictionary];
    _downloadTasks = [NSMutableDictionary dictionary];
    _progressViews = [NSMutableDictionary dictionary];
    _downloadQueue = [[NSOperationQueue alloc] init];
    _downloadQueue.maxConcurrentOperationCount =
        3; // 最多3個並發下載
    _taskProgressMap =
        [NSMutableDictionary dictionary]; // 初始化進度映射
    _completionBlocks =
        [NSMutableDictionary dictionary]; // 初始化完成回調
    _mediaTypeMap =
        [NSMutableDictionary dictionary]; // 初始化媒體類型映射

    // 初始化批次下載相關字典
    _downloadToBatchMap = [NSMutableDictionary dictionary];
    _batchCompletedCountMap = [NSMutableDictionary dictionary];
    _batchSuccessCountMap = [NSMutableDictionary dictionary];
    _batchTotalCountMap = [NSMutableDictionary dictionary];
    _batchProgressBlocks = [NSMutableDictionary dictionary];
    _batchCompletionBlocks = [NSMutableDictionary dictionary];
  }
  return self;
}

+ (UIWindow *)getActiveWindow {
  if (@available(iOS 15.0, *)) {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
      if ([scene isKindOfClass:[UIWindowScene class]] &&
          scene.activationState == UISceneActivationStateForegroundActive) {
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
          if (w.isKeyWindow)
            return w;
        }
      }
    }
    return nil;
  } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [UIApplication sharedApplication].windows.firstObject;
#pragma clang diagnostic pop
  }
}

+ (UIViewController *)getActiveTopController {
  UIWindow *window = [self getActiveWindow];
  if (!window)
    return nil;

  UIViewController *topController = window.rootViewController;
  while (topController.presentedViewController) {
    topController = topController.presentedViewController;
  }

  return topController;
}

+ (UIColor *)colorWithHexString:(NSString *)hexString {
  // 處理rainbow直接生成彩虹色的情況
  if ([hexString.lowercaseString isEqualToString:@"rainbow"] ||
      [hexString.lowercaseString isEqualToString:@"#rainbow"]) {
    CGSize size = CGSizeMake(400, 100);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 彩虹色：紅、橙、黃、綠、青、藍、紫
    UIColor *red = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    UIColor *orange = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
    UIColor *yellow = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0];
    UIColor *green = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    UIColor *cyan = [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0];
    UIColor *blue = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
    UIColor *purple = [UIColor colorWithRed:0.5 green:0.0 blue:0.5 alpha:1.0];
    
    NSArray *colorsArray = @[
      (__bridge id)red.CGColor, 
      (__bridge id)orange.CGColor,
      (__bridge id)yellow.CGColor,
      (__bridge id)green.CGColor,
      (__bridge id)cyan.CGColor,
      (__bridge id)blue.CGColor,
      (__bridge id)purple.CGColor
    ];
    
    // 創建漸層
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colorsArray, NULL);

    CGPoint startPoint = CGPointMake(0, size.height/2);
    CGPoint endPoint = CGPointMake(size.width, size.height/2);

    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    return [UIColor colorWithPatternImage:gradientImage];
  }
  
  // 如果包含半形逗號，則解析兩個顏色代碼並生成漸層色
  if ([hexString containsString:@","]) {
    NSArray *components = [hexString componentsSeparatedByString:@","];
    if (components.count == 2) {
      NSString *firstHex = [[components objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      NSString *secondHex = [[components objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      
      // 分別解析兩個顏色
      UIColor *firstColor = [self colorWithHexString:firstHex];
      UIColor *secondColor = [self colorWithHexString:secondHex];
      
      // 使用漸層layer生成圖片
      CGSize size = CGSizeMake(400, 100);
      UIGraphicsBeginImageContextWithOptions(size, NO, 0);
      CGContextRef context = UIGraphicsGetCurrentContext();
      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
      
      // 普通雙色漸層效果
      CGFloat midR = (CGColorGetComponents(firstColor.CGColor)[0] + CGColorGetComponents(secondColor.CGColor)[0]) / 2;
      CGFloat midG = (CGColorGetComponents(firstColor.CGColor)[1] + CGColorGetComponents(secondColor.CGColor)[1]) / 2;
      CGFloat midB = (CGColorGetComponents(firstColor.CGColor)[2] + CGColorGetComponents(secondColor.CGColor)[2]) / 2;
      UIColor *midColor = [UIColor colorWithRed:midR green:midG blue:midB alpha:1.0];
      
      NSArray *colorsArray = @[
        (__bridge id)firstColor.CGColor,
        (__bridge id)midColor.CGColor,
        (__bridge id)secondColor.CGColor
      ];
      
      // 創建漸層
      CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colorsArray, NULL);

      CGPoint startPoint = CGPointMake(0, size.height/2);
      CGPoint endPoint = CGPointMake(size.width, size.height/2);
      
      CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
      UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      CGGradientRelease(gradient);
      CGColorSpaceRelease(colorSpace);
      
      return [UIColor colorWithPatternImage:gradientImage];
    }
  }
  
  // 處理隨機顏色的情況
  if ([hexString.lowercaseString isEqualToString:@"random"] ||
      [hexString.lowercaseString isEqualToString:@"#random"]) {
    return [UIColor colorWithRed:(CGFloat)arc4random_uniform(256) / 255.0
                           green:(CGFloat)arc4random_uniform(256) / 255.0
                            blue:(CGFloat)arc4random_uniform(256) / 255.0
                           alpha:1.0];
  }
  
  // 去掉"#"前綴並轉為大寫
  NSString *colorString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
  CGFloat alpha = 1.0;
  CGFloat red = 0.0;
  CGFloat green = 0.0;
  CGFloat blue = 0.0;
  
  if (colorString.length == 8) {
    // 8位十六進制：AARRGGBB，前兩位為透明度
    NSScanner *scanner = [NSScanner scannerWithString:[colorString substringWithRange:NSMakeRange(0, 2)]];
    unsigned int alphaValue;
    [scanner scanHexInt:&alphaValue];
    alpha = (CGFloat)alphaValue / 255.0;
    
    scanner = [NSScanner scannerWithString:[colorString substringWithRange:NSMakeRange(2, 2)]];
    unsigned int redValue;
    [scanner scanHexInt:&redValue];
    red = (CGFloat)redValue / 255.0;
    
    scanner = [NSScanner scannerWithString:[colorString substringWithRange:NSMakeRange(4, 2)]];
    unsigned int greenValue;
    [scanner scanHexInt:&greenValue];
    green = (CGFloat)greenValue / 255.0;
    
    scanner = [NSScanner scannerWithString:[colorString substringWithRange:NSMakeRange(6, 2)]];
    unsigned int blueValue;
    [scanner scanHexInt:&blueValue];
    blue = (CGFloat)blueValue / 255.0;
  } else {
    // 處理常規6位十六進制：RRGGBB
    NSScanner *scanner = nil;
    unsigned int hexValue = 0;
    
    if (colorString.length == 6) {
      scanner = [NSScanner scannerWithString:colorString];
    } else if (colorString.length == 3) {
      // 3位簡寫格式：RGB
      NSString *r = [colorString substringWithRange:NSMakeRange(0, 1)];
      NSString *g = [colorString substringWithRange:NSMakeRange(1, 1)];
      NSString *b = [colorString substringWithRange:NSMakeRange(2, 1)];
      colorString = [NSString stringWithFormat:@"%@%@%@%@%@%@", r, r, g, g, b, b];
      scanner = [NSScanner scannerWithString:colorString];
    }
    
    if (scanner && [scanner scanHexInt:&hexValue]) {
      red = ((hexValue & 0xFF0000) >> 16) / 255.0;
      green = ((hexValue & 0x00FF00) >> 8) / 255.0;
      blue = (hexValue & 0x0000FF) / 255.0;
    }
  }
  
  return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (void)showToast:(NSString *)text {
  Class toastClass = NSClassFromString(@"DUXToast");
  if (toastClass && [toastClass respondsToSelector:@selector(showText:)]) {
    [toastClass performSelector:@selector(showText:) withObject:text];
  }
}

+ (void)saveMedia:(NSURL *)mediaURL
        mediaType:(MediaType)mediaType
       completion:(void (^)(void))completion {
  if (mediaType == MediaTypeAudio) {
    return;
  }

  [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
    if (status == PHAuthorizationStatusAuthorized) {
      // 如果是表情包類型，先檢查實際格式
      if (mediaType == MediaTypeHeic) {
        // 檢測檔案的實際格式
        NSString *actualFormat = [self detectFileFormat:mediaURL];

        if ([actualFormat isEqualToString:@"webp"]) {
          // WebP格式處理
          [self convertWebpToGifSafely:mediaURL
                            completion:^(NSURL *gifURL, BOOL success) {
                              if (success && gifURL) {
                                [self
                                    saveGifToPhotoLibrary:gifURL
                                                mediaType:mediaType
                                               completion:^{
                                                 // 清理原始檔案
                                                 [[NSFileManager defaultManager]
                                                     removeItemAtPath:mediaURL
                                                                          .path
                                                                error:nil];
                                                 if (completion) {
                                                   completion();
                                                 }
                                               }];
                              } else {
                                [self showToast:@"轉換失敗"];
                                // 清理臨時檔案
                                [[NSFileManager defaultManager]
                                    removeItemAtPath:mediaURL.path
                                               error:nil];
                                if (completion) {
                                  completion();
                                }
                              }
                            }];
        } else if ([actualFormat isEqualToString:@"heic"] ||
                   [actualFormat isEqualToString:@"heif"]) {
          // HEIC/HEIF格式處理
          [self convertHeicToGif:mediaURL
                      completion:^(NSURL *gifURL, BOOL success) {
                        if (success && gifURL) {
                          [self saveGifToPhotoLibrary:gifURL
                                            mediaType:mediaType
                                           completion:^{
                                             // 清理原始檔案
                                             [[NSFileManager defaultManager]
                                                 removeItemAtPath:mediaURL.path
                                                            error:nil];
                                             if (completion) {
                                               completion();
                                             }
                                           }];
                        } else {
                          [self showToast:@"轉換失敗"];
                          // 清理臨時檔案
                          [[NSFileManager defaultManager]
                              removeItemAtPath:mediaURL.path
                                         error:nil];
                          if (completion) {
                            completion();
                          }
                        }
                      }];
        } else if ([actualFormat isEqualToString:@"gif"]) {
          // 已經是GIF格式，直接儲存
          [self saveGifToPhotoLibrary:mediaURL
                            mediaType:mediaType
                           completion:completion];
        } else {
          // 其他格式，嘗試作為普通圖像儲存
          [[PHPhotoLibrary sharedPhotoLibrary]
              performChanges:^{
                UIImage *image =
                    [UIImage imageWithContentsOfFile:mediaURL.path];
                if (image) {
                  [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                }
              }
              completionHandler:^(BOOL success, NSError *_Nullable error) {
                if (success) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                    [self showToast:[NSString stringWithFormat:
                                                  @"%@已儲存至相簿",
                                                  [self getMediaTypeDescription:
                                                            mediaType]]];
                  });

                  if (completion) {
                    completion();
                  }
                } else {
                  [self showToast:@"儲存失敗"];
                }
                // 不管成功失敗都清理臨時檔案
                [[NSFileManager defaultManager] removeItemAtPath:mediaURL.path
                                                           error:nil];
              }];
        }
      } else {
        // 非表情包類型的正常儲存流程
        [[PHPhotoLibrary sharedPhotoLibrary]
            performChanges:^{
              if (mediaType == MediaTypeVideo) {
                [PHAssetChangeRequest
                    creationRequestForAssetFromVideoAtFileURL:mediaURL];
              } else {
                UIImage *image =
                    [UIImage imageWithContentsOfFile:mediaURL.path];
                if (image) {
                  [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                }
              }
            }
            completionHandler:^(BOOL success, NSError *_Nullable error) {
              if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self showToast:[NSString stringWithFormat:
                                                @"%@已儲存至相簿",
                                                [self getMediaTypeDescription:
                                                          mediaType]]];
                });

                if (completion) {
                  completion();
                }
              } else {
                [self showToast:@"儲存失敗"];
              }
              // 不管成功失敗都清理臨時檔案
              [[NSFileManager defaultManager] removeItemAtPath:mediaURL.path
                                                         error:nil];
            }];
      }
    }
  }];
}

// 檢測檔案格式的方法
+ (NSString *)detectFileFormat:(NSURL *)fileURL {
  // 讀取檔案的整個資料或足夠的位元組用於識別
  NSData *fileData = [NSData dataWithContentsOfURL:fileURL
                                           options:NSDataReadingMappedIfSafe
                                             error:nil];
  if (!fileData || fileData.length < 12) {
    return @"unknown";
  }

  // 轉換為位元組陣列以便檢查
  const unsigned char *bytes = [fileData bytes];

  // 檢查WebP格式："RIFF" + 4位元組 + "WEBP"
  if (bytes[0] == 'R' && bytes[1] == 'I' && bytes[2] == 'F' &&
      bytes[3] == 'F' && bytes[8] == 'W' && bytes[9] == 'E' &&
      bytes[10] == 'B' && bytes[11] == 'P') {
    return @"webp";
  }

  // 檢查HEIF/HEIC格式："ftyp" 在第4-7位元組位置
  if (bytes[4] == 'f' && bytes[5] == 't' && bytes[6] == 'y' &&
      bytes[7] == 'p') {
    if (fileData.length >= 16) {
      // 檢查HEIC品牌
      if (bytes[8] == 'h' && bytes[9] == 'e' && bytes[10] == 'i' &&
          bytes[11] == 'c') {
        return @"heic";
      }
      // 檢查HEIF品牌
      if (bytes[8] == 'h' && bytes[9] == 'e' && bytes[10] == 'i' &&
          bytes[11] == 'f') {
        return @"heif";
      }
      // 可能是其他HEIF變體
      return @"heif";
    }
  }

  // 檢查GIF格式："GIF87a"或"GIF89a"
  if (bytes[0] == 'G' && bytes[1] == 'I' && bytes[2] == 'F') {
    return @"gif";
  }

  // 檢查PNG格式
  if (bytes[0] == 0x89 && bytes[1] == 'P' && bytes[2] == 'N' &&
      bytes[3] == 'G') {
    return @"png";
  }

  // 檢查JPEG格式
  if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return @"jpeg";
  }

  return @"unknown";
}

// 儲存GIF至相簿的方法
+ (void)saveGifToPhotoLibrary:(NSURL *)gifURL
                    mediaType:(MediaType)mediaType
                   completion:(void (^)(void))completion {
  [[PHPhotoLibrary sharedPhotoLibrary]
      performChanges:^{
        // 獲取GIF資料
        NSData *gifData = [NSData dataWithContentsOfURL:gifURL];
        // 創建相簿資源
        PHAssetCreationRequest *request =
            [PHAssetCreationRequest creationRequestForAsset];
        // 實例相簿類資源參數
        PHAssetResourceCreationOptions *options =
            [[PHAssetResourceCreationOptions alloc] init];
        // 定義GIF參數
        options.uniformTypeIdentifier = @"com.compuserve.gif";
        // 儲存GIF圖片
        [request addResourceWithType:PHAssetResourceTypePhoto
                                data:gifData
                             options:options];
      }
      completionHandler:^(BOOL success, NSError *_Nullable error) {
        if (success) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self showToast:[NSString
                                stringWithFormat:
                                    @"%@已儲存至相簿",
                                    [self getMediaTypeDescription:mediaType]]];
          });

          if (completion) {
            completion();
          }
        } else {
          [self showToast:@"儲存失敗"];
        }
        // 不管成功失敗都清理臨時檔案
        [[NSFileManager defaultManager] removeItemAtPath:gifURL.path error:nil];
      }];
}

static void ReleaseWebPData(void *info, const void *data, size_t size) {
  free((void *)data);
}

+ (void)convertWebpToGifSafely:(NSURL *)webpURL
                    completion:
                        (void (^)(NSURL *gifURL, BOOL success))completion {
  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 創建GIF檔案路徑
        NSString *gifFileName =
            [[webpURL.lastPathComponent stringByDeletingPathExtension]
                stringByAppendingPathExtension:@"gif"];
        NSURL *gifURL = [NSURL
            fileURLWithPath:[NSTemporaryDirectory()
                                stringByAppendingPathComponent:gifFileName]];

        // 讀取WebP檔案資料
        NSData *webpData = [NSData dataWithContentsOfURL:webpURL];
        if (!webpData) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
              completion(nil, NO);
            }
          });
          return;
        }

        // 初始化WebP解碼器
        WebPData webp_data;
        webp_data.bytes = webpData.bytes;
        webp_data.size = webpData.length;

        // 創建WebP動畫解碼器
        WebPDemuxer *demux = WebPDemux(&webp_data);
        if (!demux) {
          // 如果無法解碼為動畫，嘗試直接解碼為靜態圖像
          WebPDecoderConfig config;
          WebPInitDecoderConfig(&config);

          // 設置解碼選項，支援透明度
          config.output.colorspace = MODE_RGBA;
          config.options.use_threads = 1;

          // 嘗試解碼
          VP8StatusCode status =
              WebPDecode(webpData.bytes, webpData.length, &config);

          if (status != VP8_STATUS_OK) {
            // 解碼失敗
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) {
                completion(nil, NO);
              }
            });
            return;
          }

          // 成功解碼為靜態圖像，創建UIImage
          CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
          CGDataProviderRef provider = CGDataProviderCreateWithData(
              NULL, config.output.u.RGBA.rgba,
              config.output.width * config.output.height * 4,
              ReleaseWebPData); // 使用定義的C函數作為回調

          CGImageRef imageRef = CGImageCreate(
              config.output.width, config.output.height, 8, 32,
              config.output.width * 4, colorSpace,
              kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast,
              provider, NULL, false, kCGRenderingIntentDefault);

          // 創建靜態GIF
          NSDictionary *gifProperties = @{
            (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
              (__bridge NSString *)kCGImagePropertyGIFLoopCount : @0,
            }
          };

          CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
              (__bridge CFURLRef)gifURL, kUTTypeGIF, 1, NULL);
          if (!destination) {
            CGImageRelease(imageRef);
            CGDataProviderRelease(provider);
            CGColorSpaceRelease(colorSpace);

            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) {
                completion(nil, NO);
              }
            });
            return;
          }

          CGImageDestinationSetProperties(
              destination, (__bridge CFDictionaryRef)gifProperties);

          NSDictionary *frameProperties = @{
            (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
              (__bridge NSString *)kCGImagePropertyGIFDelayTime : @0.1f,
            }
          };

          CGImageDestinationAddImage(destination, imageRef,
                                     (__bridge CFDictionaryRef)frameProperties);
          BOOL success = CGImageDestinationFinalize(destination);

          CGImageRelease(imageRef);
          CGDataProviderRelease(provider);
          CGColorSpaceRelease(colorSpace);
          CFRelease(destination);

          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
              completion(gifURL, success);
            }
          });
          return;
        }

        // 獲取WebP資訊
        uint32_t frameCount = WebPDemuxGetI(demux, WEBP_FF_FRAME_COUNT);
        int canvasWidth = WebPDemuxGetI(demux, WEBP_FF_CANVAS_WIDTH);
        int canvasHeight = WebPDemuxGetI(demux, WEBP_FF_CANVAS_HEIGHT);
        BOOL isAnimated = (frameCount > 1);
        BOOL hasAlpha = WebPDemuxGetI(demux, WEBP_FF_FORMAT_FLAGS) & ALPHA_FLAG;

        // 設置GIF屬性
        NSDictionary *gifProperties = @{
          (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
            (__bridge NSString *)
            kCGImagePropertyGIFLoopCount : @0, // 0表示無限循環
          }
        };

        // 創建GIF圖像目標
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
            (__bridge CFURLRef)gifURL, kUTTypeGIF, isAnimated ? frameCount : 1,
            NULL);
        if (!destination) {
          WebPDemuxDelete(demux);
          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
              completion(nil, NO);
            }
          });
          return;
        }

        // 設置GIF屬性
        CGImageDestinationSetProperties(
            destination, (__bridge CFDictionaryRef)gifProperties);

        // 解碼每一幀並添加到GIF
        BOOL allFramesAdded = YES;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

        // 用於儲存上一幀的畫布
        CGContextRef prevCanvas = CGBitmapContextCreate(
            NULL, canvasWidth, canvasHeight, 8, canvasWidth * 4, colorSpace,
            kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);

        // 用於當前繪製的畫布
        CGContextRef currCanvas = CGBitmapContextCreate(
            NULL, canvasWidth, canvasHeight, 8, canvasWidth * 4, colorSpace,
            kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);

        // 如果畫布創建失敗，則返回錯誤
        if (!prevCanvas || !currCanvas) {
          if (prevCanvas)
            CGContextRelease(prevCanvas);
          if (currCanvas)
            CGContextRelease(currCanvas);
          CGColorSpaceRelease(colorSpace);
          WebPDemuxDelete(demux);
          CFRelease(destination);

          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
              completion(nil, NO);
            }
          });
          return;
        }

        // 初始化為透明背景
        CGContextClearRect(prevCanvas,
                           CGRectMake(0, 0, canvasWidth, canvasHeight));

        for (uint32_t i = 0; i < frameCount; i++) {
          WebPIterator iter;
          if (WebPDemuxGetFrame(demux, i + 1, &iter)) {
            // 解碼當前幀
            WebPDecoderConfig config;
            WebPInitDecoderConfig(&config);

            // 設置解碼配置，強制處理透明度
            config.output.colorspace = MODE_RGBA;
            config.output.is_external_memory = 0;
            config.options.use_threads = 1;

            // 解碼
            VP8StatusCode status =
                WebPDecode(iter.fragment.bytes, iter.fragment.size, &config);

            if (status != VP8_STATUS_OK) {
              WebPDemuxReleaseIterator(&iter);
              continue;
            }

            // 創建幀圖像
            CGDataProviderRef frameProvider = CGDataProviderCreateWithData(
                NULL, config.output.u.RGBA.rgba,
                config.output.width * config.output.height * 4,
                ReleaseWebPData);

            if (!frameProvider) {
              WebPFreeDecBuffer(&config.output);
              WebPDemuxReleaseIterator(&iter);
              continue;
            }

            CGImageRef frameImageRef = CGImageCreate(
                config.output.width, config.output.height, 8, 32,
                config.output.width * 4, colorSpace,
                kCGBitmapByteOrderDefault |
                    (hasAlpha ? kCGImageAlphaLast : kCGImageAlphaNoneSkipLast),
                frameProvider, NULL, false, kCGRenderingIntentDefault);

            if (!frameImageRef) {
              CGDataProviderRelease(frameProvider);
              WebPDemuxReleaseIterator(&iter);
              continue;
            }

            // 準備當前幀畫布 - 根據合成模式處理
            // 首先複製上一幀的狀態到當前幀
            CGContextCopyBytes(currCanvas, prevCanvas, canvasWidth,
                               canvasHeight);

            // 根據混合模式處理當前幀
            if (iter.blend_method == WEBP_MUX_BLEND) {
              // 使用Alpha混合模式，將當前幀混合到背景上
              CGContextDrawImage(currCanvas,
                                 CGRectMake(iter.x_offset,
                                            canvasHeight - iter.y_offset -
                                                config.output.height,
                                            config.output.width,
                                            config.output.height),
                                 frameImageRef);
            } else {
              // 不混合模式，清除目標區域後再繪製
              CGContextClearRect(currCanvas,
                                 CGRectMake(iter.x_offset,
                                            canvasHeight - iter.y_offset -
                                                config.output.height,
                                            config.output.width,
                                            config.output.height));

              CGContextDrawImage(currCanvas,
                                 CGRectMake(iter.x_offset,
                                            canvasHeight - iter.y_offset -
                                                config.output.height,
                                            config.output.width,
                                            config.output.height),
                                 frameImageRef);
            }

            // 從當前畫布創建幀圖像
            CGImageRef canvasImageRef = CGBitmapContextCreateImage(currCanvas);

            // 處理幀間延遲
            float delayTime = iter.duration / 1000.0f;
            if (delayTime <= 0.01f) {
              delayTime = 0.1f; // 預設延遲
            }

            // 創建幀屬性
            NSDictionary *frameProperties = @{
              (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
                (__bridge NSString *)
                kCGImagePropertyGIFDelayTime : @(delayTime),
                (__bridge NSString *)
                kCGImagePropertyGIFHasGlobalColorMap : @YES,
                (__bridge NSString *)kCGImagePropertyColorModel :
                        hasAlpha ? @"RGBA" : @"RGB",
              }
            };

            // 添加幀到GIF
            CGImageDestinationAddImage(
                destination, canvasImageRef,
                (__bridge CFDictionaryRef)frameProperties);

            // 根據處理模式更新上一幀畫布
            if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
              // 處理背景處理模式 - 清除當前幀區域
              CGContextClearRect(prevCanvas,
                                 CGRectMake(iter.x_offset,
                                            canvasHeight - iter.y_offset -
                                                config.output.height,
                                            config.output.width,
                                            config.output.height));
            } else if (iter.dispose_method == WEBP_MUX_DISPOSE_NONE) {
              // 保持當前幀，複製當前畫布到上一幀
              CGContextCopyBytes(prevCanvas, currCanvas, canvasWidth,
                                 canvasHeight);
            }

            // 釋放資源
            CGImageRelease(canvasImageRef);
            CGImageRelease(frameImageRef);
            CGDataProviderRelease(frameProvider);
            WebPDemuxReleaseIterator(&iter);
          } else {
            allFramesAdded = NO;
          }
        }

        // 釋放畫布
        CGContextRelease(prevCanvas);
        CGContextRelease(currCanvas);
        CGColorSpaceRelease(colorSpace);

        // 完成GIF生成
        BOOL success =
            CGImageDestinationFinalize(destination) && allFramesAdded;

        // 釋放資源
        WebPDemuxDelete(demux);
        CFRelease(destination);

        dispatch_async(dispatch_get_main_queue(), ^{
          if (completion) {
            completion(gifURL, success);
          }
        });
      });
}

// 輔助函數：複製上下文像素資料
static void CGContextCopyBytes(CGContextRef dst, CGContextRef src, int width,
                               int height) {
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(src);
  void *srcData = CGBitmapContextGetData(src);
  void *dstData = CGBitmapContextGetData(dst);

  if (srcData && dstData) {
    memcpy(dstData, srcData, bytesPerRow * height);
  }
}

// 將HEIC轉換為GIF的方法
+ (void)convertHeicToGif:(NSURL *)heicURL
              completion:(void (^)(NSURL *gifURL, BOOL success))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 1. 創建ImageSource
        CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef)heicURL, NULL);
        if (!src) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil, NO);
            });
            return;
        }

        // 2. 獲取幀數
        size_t count = CGImageSourceGetCount(src);
        BOOL isAnimated = (count > 1);

        // 3. 生成GIF路徑
        NSString *gifFileName = [[heicURL.lastPathComponent stringByDeletingPathExtension] stringByAppendingPathExtension:@"gif"];
        NSURL *gifURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:gifFileName]];

        // 4. GIF屬性
        NSDictionary *gifProperties = @{
            (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
                (__bridge NSString *)kCGImagePropertyGIFLoopCount : @0
            }
        };

        // 5. 創建GIF目標
        CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)gifURL, kUTTypeGIF, count, NULL);
        if (!dest) {
            CFRelease(src);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil, NO);
            });
            return;
        }
        CGImageDestinationSetProperties(dest, (__bridge CFDictionaryRef)gifProperties);

        // 6. 遍歷幀並寫入GIF
        for (size_t i = 0; i < count; i++) {
            CGImageRef imgRef = CGImageSourceCreateImageAtIndex(src, i, NULL);

            // 獲取幀延遲
            float delayTime = 0.1f;
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(src, i, NULL);
            if (properties) {
                CFDictionaryRef gifDict = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
                if (gifDict) {
                    CFNumberRef delayNum = CFDictionaryGetValue(gifDict, kCGImagePropertyGIFDelayTime);
                    if (delayNum) CFNumberGetValue(delayNum, kCFNumberFloatType, &delayTime);
                }
                if (delayTime <= 0.01f || delayTime > 10.0f) delayTime = 0.1f;
                CFRelease(properties);
            }

            NSDictionary *frameProps = @{
                (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
                    (__bridge NSString *)kCGImagePropertyGIFDelayTime : @(delayTime)
                }
            };

            if (imgRef) {
                CGImageDestinationAddImage(dest, imgRef, (__bridge CFDictionaryRef)frameProps);
                CGImageRelease(imgRef);
            }
        }

        // 7. 完成GIF生成
        BOOL success = CGImageDestinationFinalize(dest);
        CFRelease(dest);
        CFRelease(src);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(gifURL, success);
        });
    });
}

+ (void)downloadLivePhoto:(NSURL *)imageURL
                 videoURL:(NSURL *)videoURL
               completion:(void (^)(void))completion {
  // 獲取共享實例，確保FileLinks字典存在
  DYYYManager *manager = [DYYYManager shared];
  if (!manager.fileLinks) {
    manager.fileLinks = [NSMutableDictionary dictionary];
  }

  // 為圖片和影片URL創建唯一的鍵
  NSString *uniqueKey =
      [NSString stringWithFormat:@"%@_%@", imageURL.absoluteString,
                                 videoURL.absoluteString];

  // 檢查是否已經存在此下載任務
  NSDictionary *existingPaths = manager.fileLinks[uniqueKey];
  if (existingPaths) {
    NSString *imagePath = existingPaths[@"image"];
    NSString *videoPath = existingPaths[@"video"];

    // 使用非同步檢查以避免主執行緒阻塞
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          BOOL imageExists =
              [[NSFileManager defaultManager] fileExistsAtPath:imagePath];
          BOOL videoExists =
              [[NSFileManager defaultManager] fileExistsAtPath:videoPath];

          dispatch_async(dispatch_get_main_queue(), ^{
            if (imageExists && videoExists) {
              [[DYYYManager shared] saveLivePhoto:imagePath videoUrl:videoPath];
              if (completion) {
                completion();
              }
              return;
            } else {
              // 檔案不完整，需要重新下載
              [self startDownloadLivePhotoProcess:imageURL
                                         videoURL:videoURL
                                        uniqueKey:uniqueKey
                                       completion:completion];
            }
          });
        });
  } else {
    // 沒有快取，直接開始下載
    [self startDownloadLivePhotoProcess:imageURL
                               videoURL:videoURL
                              uniqueKey:uniqueKey
                             completion:completion];
  }
}

+ (void)startDownloadLivePhotoProcess:(NSURL *)imageURL
                             videoURL:(NSURL *)videoURL
                            uniqueKey:(NSString *)uniqueKey
                           completion:(void (^)(void))completion {
  // 創建臨時目錄（如果不存在）
  NSString *livePhotoPath =
      [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                           NSUserDomainMask, YES)
              .firstObject stringByAppendingPathComponent:@"LivePhoto"];

  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:livePhotoPath]) {
    [fileManager createDirectoryAtPath:livePhotoPath
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
  }

  // 生成唯一識別符，防止多次呼叫時檔案衝突
  NSString *uniqueID = [NSUUID UUID].UUIDString;
  NSString *imagePath = [livePhotoPath
      stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.heic",
                                                                uniqueID]];
  NSString *videoPath = [livePhotoPath
      stringByAppendingPathComponent:[NSString
                                         stringWithFormat:@"%@.mp4", uniqueID]];

  // 儲存檔案路徑，以便下次下載相同的URL時可以復用
  DYYYManager *manager = [DYYYManager shared];
  [manager.fileLinks setObject:@{@"image" : imagePath, @"video" : videoPath}
                        forKey:uniqueKey];

  dispatch_async(dispatch_get_main_queue(), ^{
    // 創建進度視圖
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    DYYYDownloadProgressView *progressView =
        [[DYYYDownloadProgressView alloc] initWithFrame:screenBounds];
    progressView.progressLabel.text = @"準備下載原況照片...";
    [progressView show];

    // 優化會話配置
    NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 60.0; // 增加超時時間
    configuration.timeoutIntervalForResource = 60.0;
    configuration.HTTPMaximumConnectionsPerHost = 10; // 增加並發連接數
    configuration.requestCachePolicy =
        NSURLRequestReloadIgnoringLocalCacheData; // 強制從網路重新下載

    // 使用共享委託的session以節省資源
    NSURLSession *session =
        [NSURLSession sessionWithConfiguration:configuration
                                      delegate:[DYYYManager shared]
                                 delegateQueue:[NSOperationQueue mainQueue]];

    dispatch_group_t group = dispatch_group_create();
    __block BOOL imageDownloaded = NO;
    __block BOOL videoDownloaded = NO;
    __block float imageProgress = 0.0;
    __block float videoProgress = 0.0;

    // 設置單獨的下載觀察者ID用於進度追蹤
    NSString *imageDownloadID =
        [NSString stringWithFormat:@"image_%@", uniqueID];
    NSString *videoDownloadID =
        [NSString stringWithFormat:@"video_%@", uniqueID];

    // 更新合併進度的計時器
    __block NSTimer *progressTimer = [NSTimer
        scheduledTimerWithTimeInterval:0.1
                               repeats:YES
                                 block:^(NSTimer *_Nonnull timer) {
                                   float totalProgress =
                                       (imageProgress + videoProgress) / 2.0;
                                   [progressView setProgress:totalProgress];

                                   // 更新進度文字
                                   NSString *statusText =
                                       @"正在下載原況照片...";
                                   if (imageDownloaded && !videoDownloaded) {
                                     statusText = @"圖片下載完成，等待影片...";
                                   } else if (!imageDownloaded &&
                                              videoDownloaded) {
                                     statusText = @"影片下載完成，等待圖片...";
                                   } else if (imageDownloaded &&
                                              videoDownloaded) {
                                     statusText = @"下載完成，準備儲存...";
                                     [timer invalidate]; // 全部完成時停止計時器
                                   }
                                   progressView.progressLabel.text = statusText;
                                 }];

    // 下載圖片
    dispatch_group_enter(group);
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:imageURL];
    NSURLSessionDataTask *imageTask =
        [session dataTaskWithRequest:imageRequest
                   completionHandler:^(NSData *_Nullable data,
                                       NSURLResponse *_Nullable response,
                                       NSError *_Nullable error) {
                     if (!error && data) {
                       // 直接寫入檔案，避免臨時檔案移動操作
                       if ([data writeToFile:imagePath atomically:YES]) {
                         imageDownloaded = YES;
                         imageProgress = 1.0;
                       }
                     }
                     dispatch_group_leave(group);
                   }];

    // 設置圖片下載進度觀察
    if ([imageTask respondsToSelector:@selector(taskIdentifier)]) {
      [[manager taskProgressMap] setObject:@(0.0) forKey:imageDownloadID];

      // 使用系統API觀察進度 (iOS 11+)
      if (@available(iOS 11.0, *)) {
        [imageTask.progress addObserver:manager
                             forKeyPath:@"fractionCompleted"
                                options:NSKeyValueObservingOptionNew
                                context:(__bridge void *)(imageDownloadID)];
      }
    }

    // 下載影片
    dispatch_group_enter(group);
    NSURLRequest *videoRequest = [NSURLRequest requestWithURL:videoURL];
    NSURLSessionDataTask *videoTask =
        [session dataTaskWithRequest:videoRequest
                   completionHandler:^(NSData *_Nullable data,
                                       NSURLResponse *_Nullable response,
                                       NSError *_Nullable error) {
                     if (!error && data) {
                       // 直接寫入檔案，避免臨時檔案移動操作
                       if ([data writeToFile:videoPath atomically:YES]) {
                         videoDownloaded = YES;
                         videoProgress = 1.0;
                       }
                     }
                     dispatch_group_leave(group);
                   }];

    // 設置影片下載進度觀察
    if ([videoTask respondsToSelector:@selector(taskIdentifier)]) {
      [[manager taskProgressMap] setObject:@(0.0) forKey:videoDownloadID];

      // 使用系統API觀察進度 (iOS 11+)
      if (@available(iOS 11.0, *)) {
        [videoTask.progress addObserver:manager
                             forKeyPath:@"fractionCompleted"
                                options:NSKeyValueObservingOptionNew
                                context:(__bridge void *)(videoDownloadID)];
      }
    }

    // 設置取消按鈕事件
    progressView.cancelBlock = ^{
      [progressTimer invalidate];
      [imageTask cancel];
      [videoTask cancel];

      // 移除檔案，釋放資源
      [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
      [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
      [manager.fileLinks removeObjectForKey:uniqueKey];

      // 移除進度觀察
      if (@available(iOS 11.0, *)) {
        if ([imageTask respondsToSelector:@selector(progress)]) {
          [imageTask.progress removeObserver:manager
                                  forKeyPath:@"fractionCompleted"];
        }
        if ([videoTask respondsToSelector:@selector(progress)]) {
          [videoTask.progress removeObserver:manager
                                  forKeyPath:@"fractionCompleted"];
        }
      }

      if (completion) {
        completion();
      }
    };

    // 啟動下載任務
    [imageTask resume];
    [videoTask resume];

    // 當兩個下載都完成後，儲存原況照片
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
      // 停止進度計時器
      [progressTimer invalidate];

      // 移除進度觀察
      if (@available(iOS 11.0, *)) {
        if ([imageTask respondsToSelector:@selector(progress)]) {
          [imageTask.progress removeObserver:manager
                                  forKeyPath:@"fractionCompleted"];
        }
        if ([videoTask respondsToSelector:@selector(progress)]) {
          [videoTask.progress removeObserver:manager
                                  forKeyPath:@"fractionCompleted"];
        }
      }

      // 檢查檔案是否真的存在
      BOOL imageExists =
          [[NSFileManager defaultManager] fileExistsAtPath:imagePath];
      BOOL videoExists =
          [[NSFileManager defaultManager] fileExistsAtPath:videoPath];

      // 隱藏進度視圖
      [progressView dismiss];

      if (imageExists && videoExists) {
        @try {
          // 添加iOS版本檢查
          if (@available(iOS 15.0, *)) {
            [[DYYYManager shared] saveLivePhoto:imagePath videoUrl:videoPath];
          }
        } @catch (NSException *exception) {
          // 刪除失敗的檔案
          [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
          [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
          [manager.fileLinks removeObjectForKey:uniqueKey];
          [DYYYManager showToast:@"儲存原況照片失敗"];
        }
      } else {
        // 清理不完整的檔案
        if (imageExists)
          [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
        if (videoExists)
          [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
        [manager.fileLinks removeObjectForKey:uniqueKey];
        [DYYYManager showToast:@"下載原況照片失敗"];
      }

      if (completion) {
        completion();
      }
    });
  });
}

// 需要添加KVO回調方法來處理下載進度
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"fractionCompleted"] &&
      [object isKindOfClass:[NSProgress class]]) {
    NSString *downloadID = (__bridge NSString *)context;
    if (downloadID) {
      NSProgress *progress = (NSProgress *)object;
      float fractionCompleted = progress.fractionCompleted;
      [self.taskProgressMap setObject:@(fractionCompleted) forKey:downloadID];
    }
  } else {
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
  }
}

+ (void)downloadMedia:(NSURL *)url
            mediaType:(MediaType)mediaType
           completion:(void (^)(void))completion {
  [self downloadMediaWithProgress:url
                        mediaType:mediaType
                         progress:nil
                       completion:^(BOOL success, NSURL *fileURL) {
                         if (success) {
                           if (mediaType == MediaTypeAudio) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                               UIActivityViewController *activityVC =
                                   [[UIActivityViewController alloc]
                                       initWithActivityItems:@[ fileURL ]
                                       applicationActivities:nil];

                               [activityVC
                                   setCompletionWithItemsHandler:^(
                                       UIActivityType _Nullable activityType,
                                       BOOL completed,
                                       NSArray *_Nullable returnedItems,
                                       NSError *_Nullable error) {
                                     [[NSFileManager defaultManager]
                                         removeItemAtURL:fileURL
                                                   error:nil];
                                   }];
                               UIViewController *rootVC =
                                   [UIApplication sharedApplication]
                                       .keyWindow.rootViewController;
                               [rootVC presentViewController:activityVC
                                                    animated:YES
                                                  completion:nil];
                             });
                           } else {
                             [self saveMedia:fileURL
                                   mediaType:mediaType
                                  completion:completion];
                           }
                         } else {
                           if (completion) {
                             completion();
                           }
                         }
                       }];
}

+ (void)downloadMediaWithProgress:(NSURL *)url
                        mediaType:(MediaType)mediaType
                         progress:(void (^)(float progress))progressBlock
                       completion:
                           (void (^)(BOOL success, NSURL *fileURL))completion {
  // 創建自訂進度條介面
  dispatch_async(dispatch_get_main_queue(), ^{
    // 創建進度視圖
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    DYYYDownloadProgressView *progressView =
        [[DYYYDownloadProgressView alloc] initWithFrame:screenBounds];

    // 生成下載ID並儲存進度視圖
    NSString *downloadID = [NSUUID UUID].UUIDString;
    [[DYYYManager shared].progressViews setObject:progressView
                                           forKey:downloadID];

    // 顯示進度視圖
    [progressView show];

    // 設置取消按鈕事件
    progressView.cancelBlock = ^{
      NSURLSessionDownloadTask *task =
          [[DYYYManager shared].downloadTasks objectForKey:downloadID];
      if (task) {
        [task cancel];
        [[DYYYManager shared].downloadTasks removeObjectForKey:downloadID];
        [[DYYYManager shared].taskProgressMap removeObjectForKey:downloadID];
      }

      // 已經在取消按鈕中隱藏了進度視圖，無需再次隱藏
      [[DYYYManager shared].progressViews removeObjectForKey:downloadID];

      if (completion) {
        completion(NO, nil);
      }
    };

    // 儲存回調
    [[DYYYManager shared] setCompletionBlock:completion
                               forDownloadID:downloadID];
    [[DYYYManager shared] setMediaType:mediaType forDownloadID:downloadID];

    // 配置下載會話 - 使用帶委託的會話以獲取進度更新
    NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session =
        [NSURLSession sessionWithConfiguration:configuration
                                      delegate:[DYYYManager shared]
                                 delegateQueue:[NSOperationQueue mainQueue]];

    // 創建下載任務 - 不使用completionHandler，使用代理方法
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url];

    // 儲存下載任務
    [[DYYYManager shared].downloadTasks setObject:downloadTask
                                           forKey:downloadID];
    [[DYYYManager shared].taskProgressMap
        setObject:@0.0
           forKey:downloadID]; // 初始化進度為0

    // 開始下載
    [downloadTask resume];
  });
}

+ (NSString *)getMediaTypeDescription:(MediaType)mediaType {
  switch (mediaType) {
  case MediaTypeVideo:
    return @"影片";
  case MediaTypeImage:
    return @"圖片";
  case MediaTypeAudio:
    return @"音訊";
  case MediaTypeHeic:
    return @"表情包";
  default:
    return @"檔案";
  }
}

// 取消所有下載
+ (void)cancelAllDownloads {
  NSArray *downloadIDs = [[DYYYManager shared].downloadTasks allKeys];

  for (NSString *downloadID in downloadIDs) {
    NSURLSessionDownloadTask *task =
        [[DYYYManager shared].downloadTasks objectForKey:downloadID];
    if (task) {
      [task cancel];
    }

    DYYYDownloadProgressView *progressView =
        [[DYYYManager shared].progressViews objectForKey:downloadID];
    if (progressView) {
      [progressView dismiss];
    }
  }

  [[DYYYManager shared].downloadTasks removeAllObjects];
  [[DYYYManager shared].progressViews removeAllObjects];
}

+ (void)downloadAllImages:(NSMutableArray *)imageURLs {
  if (imageURLs.count == 0) {
    return;
  }

  [self downloadAllImagesWithProgress:imageURLs
                             progress:nil
                           completion:^(NSInteger successCount,
                                        NSInteger totalCount) {
                             [self showToast:[NSString
                                                 stringWithFormat:
                                                     @"已儲存 %ld/%ld 張圖片",
                                                     (long)successCount,
                                                     (long)totalCount]];
                           }];
}

+ (void)downloadAllImagesWithProgress:(NSMutableArray *)imageURLs
                             progress:(void (^)(NSInteger current,
                                                NSInteger total))progressBlock
                           completion:
                               (void (^)(NSInteger successCount,
                                         NSInteger totalCount))completion {
  if (imageURLs.count == 0) {
    if (completion) {
      completion(0, 0);
    }
    return;
  }

  // 創建自訂批次下載進度條介面
  dispatch_async(dispatch_get_main_queue(), ^{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    DYYYDownloadProgressView *progressView =
        [[DYYYDownloadProgressView alloc] initWithFrame:screenBounds];
    NSString *batchID = [NSUUID UUID].UUIDString;
    [[DYYYManager shared].progressViews setObject:progressView forKey:batchID];

    // 顯示進度視圖
    [progressView show];

    // 創建下載任務
    __block NSInteger completedCount = 0;
    __block NSInteger successCount = 0;
    NSInteger totalCount = imageURLs.count;

    // 設置取消按鈕事件
    progressView.cancelBlock = ^{
      // 在這裡可以添加取消批次下載的邏輯
      [self cancelAllDownloads];
      if (completion) {
        completion(successCount, totalCount);
      }
    };

    // 儲存批次下載的相關資訊
    [[DYYYManager shared] setBatchInfo:batchID
                            totalCount:totalCount
                         progressBlock:progressBlock
                       completionBlock:completion];

    // 為每個URL創建下載任務
    for (NSString *urlString in imageURLs) {
      NSURL *url = [NSURL URLWithString:urlString];
      if (!url) {
        [[DYYYManager shared]
            incrementCompletedAndUpdateProgressForBatch:batchID
                                                success:NO];
        continue;
      }

      // 創建單個下載任務ID
      NSString *downloadID = [NSUUID UUID].UUIDString;

      // 關聯到批次下載
      [[DYYYManager shared] associateDownload:downloadID withBatchID:batchID];

      // 配置下載會話 - 使用帶委託的會話以獲取進度更新
      NSURLSessionConfiguration *configuration =
          [NSURLSessionConfiguration defaultSessionConfiguration];
      NSURLSession *session =
          [NSURLSession sessionWithConfiguration:configuration
                                        delegate:[DYYYManager shared]
                                   delegateQueue:[NSOperationQueue mainQueue]];

      // 創建下載任務 - 使用代理方法
      NSURLSessionDownloadTask *downloadTask =
          [session downloadTaskWithURL:url];

      // 儲存下載任務
      [[DYYYManager shared].downloadTasks setObject:downloadTask
                                             forKey:downloadID];
      [[DYYYManager shared].taskProgressMap setObject:@0.0 forKey:downloadID];
      [[DYYYManager shared] setMediaType:MediaTypeImage
                           forDownloadID:downloadID];

      // 開始下載
      [downloadTask resume];
    }
  });
}

// 設置批次下載資訊
- (void)setBatchInfo:(NSString *)batchID
          totalCount:(NSInteger)totalCount
       progressBlock:(void (^)(NSInteger current, NSInteger total))progressBlock
     completionBlock:(void (^)(NSInteger successCount,
                               NSInteger totalCount))completionBlock {
  [self.batchTotalCountMap setObject:@(totalCount) forKey:batchID];
  [self.batchCompletedCountMap setObject:@(0) forKey:batchID];
  [self.batchSuccessCountMap setObject:@(0) forKey:batchID];

  if (progressBlock) {
    [self.batchProgressBlocks setObject:[progressBlock copy] forKey:batchID];
  }

  if (completionBlock) {
    [self.batchCompletionBlocks setObject:[completionBlock copy]
                                   forKey:batchID];
  }
}

// 關聯單個下載到批次下載
- (void)associateDownload:(NSString *)downloadID
              withBatchID:(NSString *)batchID {
  [self.downloadToBatchMap setObject:batchID forKey:downloadID];
}

// 增加批次下載完成計數並更新進度
- (void)incrementCompletedAndUpdateProgressForBatch:(NSString *)batchID
                                            success:(BOOL)success {
  @synchronized(self) {
    NSNumber *completedCountNum = self.batchCompletedCountMap[batchID];
    NSInteger completedCount =
        completedCountNum ? [completedCountNum integerValue] + 1 : 1;
    [self.batchCompletedCountMap setObject:@(completedCount) forKey:batchID];

    if (success) {
      NSNumber *successCountNum = self.batchSuccessCountMap[batchID];
      NSInteger successCount =
          successCountNum ? [successCountNum integerValue] + 1 : 1;
      [self.batchSuccessCountMap setObject:@(successCount) forKey:batchID];
    }

    NSNumber *totalCountNum = self.batchTotalCountMap[batchID];
    NSInteger totalCount = totalCountNum ? [totalCountNum integerValue] : 0;

    // 更新批次下載進度視圖
    DYYYDownloadProgressView *progressView = self.progressViews[batchID];
    if (progressView) {
      float progress = totalCount > 0 ? (float)completedCount / totalCount : 0;
      [progressView setProgress:progress];

      // 更新進度標籤
      progressView.progressLabel.text = [NSString
          stringWithFormat:@"%ld/%ld", (long)completedCount, (long)totalCount];
    }

    // 呼叫進度回調
    void (^progressBlock)(NSInteger current, NSInteger total) =
        self.batchProgressBlocks[batchID];
    if (progressBlock) {
      progressBlock(completedCount, totalCount);
    }

    // 如果所有下載都已完成，呼叫完成回調並清理
    if (completedCount >= totalCount) {
      NSInteger successCount =
          [self.batchSuccessCountMap[batchID] integerValue];

      // 呼叫完成回調
      void (^completionBlock)(NSInteger successCount, NSInteger totalCount) =
          self.batchCompletionBlocks[batchID];
      if (completionBlock) {
        completionBlock(successCount, totalCount);
      }

      // 移除進度視圖
      [progressView dismiss];
      [self.progressViews removeObjectForKey:batchID];

      // 清理批次下載相關資訊
      [self.batchCompletedCountMap removeObjectForKey:batchID];
      [self.batchSuccessCountMap removeObjectForKey:batchID];
      [self.batchTotalCountMap removeObjectForKey:batchID];
      [self.batchProgressBlocks removeObjectForKey:batchID];
      [self.batchCompletionBlocks removeObjectForKey:batchID];

      // 移除關聯的下載ID
      NSArray *downloadIDs = [self.downloadToBatchMap allKeysForObject:batchID];
      for (NSString *downloadID in downloadIDs) {
        [self.downloadToBatchMap removeObjectForKey:downloadID];
      }
    }
  }
}

// 儲存完成回調
- (void)setCompletionBlock:(void (^)(BOOL success, NSURL *fileURL))completion
             forDownloadID:(NSString *)downloadID {
  if (completion) {
    [self.completionBlocks setObject:[completion copy] forKey:downloadID];
  }
}

// 儲存媒體類型
- (void)setMediaType:(MediaType)mediaType forDownloadID:(NSString *)downloadID {
  [self.mediaTypeMap setObject:@(mediaType) forKey:downloadID];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
                 didWriteData:(int64_t)bytesWritten
            totalBytesWritten:(int64_t)totalBytesWritten
    totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
  // 確保不會除以0
  if (totalBytesExpectedToWrite <= 0) {
    return;
  }

  // 計算進度
  float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;

  // 在主執行緒更新UI
  dispatch_async(dispatch_get_main_queue(), ^{
    // 找到對應的進度視圖
    NSString *downloadIDForTask = nil;

    // 遍歷找到任務對應的ID
    for (NSString *key in self.downloadTasks.allKeys) {
      NSURLSessionDownloadTask *task = self.downloadTasks[key];
      if (task == downloadTask) {
        downloadIDForTask = key;
        break;
      }
    }

    // 如果找到對應的進度視圖，更新進度
    if (downloadIDForTask) {
      // 更新進度記錄
      [self.taskProgressMap setObject:@(progress) forKey:downloadIDForTask];

      DYYYDownloadProgressView *progressView =
          self.progressViews[downloadIDForTask];
      if (progressView) {
        // 確保進度視圖存在並且沒有被取消
        if (!progressView.isCancelled) {
          [progressView setProgress:progress];
        }
      }
    }
  });
}

// 添加下載完成的代理方法
- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
    didFinishDownloadingToURL:(NSURL *)location {
  // 找到對應的下載ID
  NSString *downloadIDForTask = nil;
  for (NSString *key in self.downloadTasks.allKeys) {
    NSURLSessionDownloadTask *task = self.downloadTasks[key];
    if (task == downloadTask) {
      downloadIDForTask = key;
      break;
    }
  }

  if (!downloadIDForTask) {
    return;
  }

  // 檢查是否屬於批次下載
  NSString *batchID = self.downloadToBatchMap[downloadIDForTask];
  BOOL isBatchDownload = (batchID != nil);

  // 獲取該下載任務的mediaType
  NSNumber *mediaTypeNumber = self.mediaTypeMap[downloadIDForTask];
  MediaType mediaType = MediaTypeImage; // 預設為圖片
  if (mediaTypeNumber) {
    mediaType = (MediaType)[mediaTypeNumber integerValue];
  }

  // 處理下載的檔案
  NSString *fileName = [downloadTask.originalRequest.URL lastPathComponent];

  if (!fileName.pathExtension.length) {
    switch (mediaType) {
    case MediaTypeVideo:
      fileName = [fileName stringByAppendingPathExtension:@"mp4"];
      break;
    case MediaTypeImage:
      fileName = [fileName stringByAppendingPathExtension:@"jpg"];
      break;
    case MediaTypeAudio:
      fileName = [fileName stringByAppendingPathExtension:@"mp3"];
      break;
    case MediaTypeHeic:
      fileName = [fileName stringByAppendingPathExtension:@"heic"];
      break;
    }
  }

  NSURL *tempDir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
  NSURL *destinationURL = [tempDir URLByAppendingPathComponent:fileName];

  NSError *moveError;
  if ([[NSFileManager defaultManager] fileExistsAtPath:destinationURL.path]) {
    [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];
  }

  [[NSFileManager defaultManager] moveItemAtURL:location
                                          toURL:destinationURL
                                          error:&moveError];

  if (isBatchDownload) {
    // 批次下載處理
    if (!moveError) {
      [DYYYManager saveMedia:destinationURL
                   mediaType:mediaType
                  completion:^{
                    [[DYYYManager shared]
                        incrementCompletedAndUpdateProgressForBatch:batchID
                                                            success:YES];
                  }];
    } else {
      [[DYYYManager shared] incrementCompletedAndUpdateProgressForBatch:batchID
                                                                success:NO];
    }

    // 清理下載任務
    [self.downloadTasks removeObjectForKey:downloadIDForTask];
    [self.taskProgressMap removeObjectForKey:downloadIDForTask];
    [self.mediaTypeMap removeObjectForKey:downloadIDForTask];
  } else {
    // 單個下載處理
    // 獲取儲存的完成回調
    void (^completionBlock)(BOOL success, NSURL *fileURL) =
        self.completionBlocks[downloadIDForTask];

    dispatch_async(dispatch_get_main_queue(), ^{
      // 隱藏進度視圖
      DYYYDownloadProgressView *progressView =
          self.progressViews[downloadIDForTask];
      BOOL wasCancelled = progressView.isCancelled;

      [progressView dismiss];
      [self.progressViews removeObjectForKey:downloadIDForTask];
      [self.downloadTasks removeObjectForKey:downloadIDForTask];
      [self.taskProgressMap removeObjectForKey:downloadIDForTask];
      [self.completionBlocks removeObjectForKey:downloadIDForTask];
      [self.mediaTypeMap removeObjectForKey:downloadIDForTask];

      // 如果已取消，直接返回
      if (wasCancelled) {
        return;
      }

      if (!moveError) {
        if (completionBlock) {
          completionBlock(YES, destinationURL);
        }
      } else {
        if (completionBlock) {
          completionBlock(NO, nil);
        }
      }
    });
  }
}

- (void)URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error {
  if (!error) {
    return; // 成功完成的情況已在didFinishDownloadingToURL處理
  }

  // 处理错误情况
  NSString *downloadIDForTask = nil;
  for (NSString *key in self.downloadTasks.allKeys) {
    NSURLSessionTask *existingTask = self.downloadTasks[key];
    if (existingTask == task) {
      downloadIDForTask = key;
      break;
    }
  }

  if (!downloadIDForTask) {
    return;
  }

  // 检查是否属于批量下载
  NSString *batchID = self.downloadToBatchMap[downloadIDForTask];
  BOOL isBatchDownload = (batchID != nil);

  if (isBatchDownload) {
    // 批量下载错误处理
    [[DYYYManager shared] incrementCompletedAndUpdateProgressForBatch:batchID
                                                              success:NO];

    // 清理下载任务
    [self.downloadTasks removeObjectForKey:downloadIDForTask];
    [self.taskProgressMap removeObjectForKey:downloadIDForTask];
    [self.mediaTypeMap removeObjectForKey:downloadIDForTask];
    [self.downloadToBatchMap removeObjectForKey:downloadIDForTask];
  } else {
    // 单个下载错误处理
    void (^completionBlock)(BOOL success, NSURL *fileURL) =
        self.completionBlocks[downloadIDForTask];

    dispatch_async(dispatch_get_main_queue(), ^{
      // 隐藏进度视图
      DYYYDownloadProgressView *progressView =
          self.progressViews[downloadIDForTask];
      [progressView dismiss];

      [self.progressViews removeObjectForKey:downloadIDForTask];
      [self.downloadTasks removeObjectForKey:downloadIDForTask];
      [self.taskProgressMap removeObjectForKey:downloadIDForTask];
      [self.completionBlocks removeObjectForKey:downloadIDForTask];
      [self.mediaTypeMap removeObjectForKey:downloadIDForTask];

      if (error.code != NSURLErrorCancelled) {
        [DYYYManager showToast:@"下載失敗"];
      }

      if (completionBlock) {
        completionBlock(NO, nil);
      }
    });
  }
}

// MARK: 以下都是创建保存实况的调用方法
- (void)saveLivePhoto:(NSString *)imageSourcePath
             videoUrl:(NSString *)videoSourcePath {
  // 首先检查iOS版本
  if (@available(iOS 15.0, *)) {
    // iOS 15及更高版本使用原有的实现
    NSURL *photoURL = [NSURL fileURLWithPath:imageSourcePath];
    NSURL *videoURL = [NSURL fileURLWithPath:videoSourcePath];
    BOOL available = [PHAssetCreationRequest supportsAssetResourceTypes:@[
      @(PHAssetResourceTypePhoto), @(PHAssetResourceTypePairedVideo)
    ]];
    if (!available) {
      return;
    }
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
      if (status != PHAuthorizationStatusAuthorized) {
        return;
      }
      NSString *identifier = [NSUUID UUID].UUIDString;
      [self useAssetWriter:photoURL
                     video:videoURL
                identifier:identifier
                  complete:^(BOOL success, NSString *photoFile,
                             NSString *videoFile, NSError *error) {
                    NSURL *photo = [NSURL fileURLWithPath:photoFile];
                    NSURL *video = [NSURL fileURLWithPath:videoFile];
                    [[PHPhotoLibrary sharedPhotoLibrary]
                        performChanges:^{
                          PHAssetCreationRequest *request =
                              [PHAssetCreationRequest creationRequestForAsset];
                          [request addResourceWithType:PHAssetResourceTypePhoto
                                               fileURL:photo
                                               options:nil];
                          [request
                              addResourceWithType:PHAssetResourceTypePairedVideo
                                          fileURL:video
                                          options:nil];
                        }
                        completionHandler:^(BOOL success,
                                            NSError *_Nullable error) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                            if (success) {
                              // 删除临时文件
                              [[NSFileManager defaultManager]
                                  removeItemAtPath:imageSourcePath
                                             error:nil];
                              [[NSFileManager defaultManager]
                                  removeItemAtPath:videoSourcePath
                                             error:nil];
                              [[NSFileManager defaultManager]
                                  removeItemAtPath:photoFile
                                             error:nil];
                              [[NSFileManager defaultManager]
                                  removeItemAtPath:videoFile
                                             error:nil];
                            }
                          });
                        }];
                  }];
    }];
  } else {
    // iOS 14 兼容处理 - 分别保存图片和视频
    dispatch_async(dispatch_get_main_queue(), ^{
      [DYYYManager
          showToast:@"目前iOS版本不支援原況照片，將分別儲存圖片和影片"];
    });
  }
}

- (void)useAssetWriter:(NSURL *)photoURL
                 video:(NSURL *)videoURL
            identifier:(NSString *)identifier
              complete:(void (^)(BOOL success, NSString *photoFile,
                                 NSString *videoFile, NSError *error))complete {
  NSString *photoName = [photoURL lastPathComponent];
  NSString *photoFile = [self filePathFromDoc:photoName];
  [self addMetadataToPhoto:photoURL outputFile:photoFile identifier:identifier];
  NSString *videoName = [videoURL lastPathComponent];
  NSString *videoFile = [self filePathFromDoc:videoName];
  [self addMetadataToVideo:videoURL outputFile:videoFile identifier:identifier];
  if (!DYYYManager.shared->group)
    return;
  dispatch_group_notify(DYYYManager.shared->group, dispatch_get_main_queue(), ^{
    [self finishWritingTracksWithPhoto:photoFile
                                 video:videoFile
                              complete:complete];
  });
}
- (void)finishWritingTracksWithPhoto:(NSString *)photoFile
                               video:(NSString *)videoFile
                            complete:(void (^)(BOOL success,
                                               NSString *photoFile,
                                               NSString *videoFile,
                                               NSError *error))complete {
  [DYYYManager.shared->reader cancelReading];
  [DYYYManager.shared->writer finishWritingWithCompletionHandler:^{
    if (complete)
      complete(YES, photoFile, videoFile, nil);
  }];
}
- (void)addMetadataToPhoto:(NSURL *)photoURL
                outputFile:(NSString *)outputFile
                identifier:(NSString *)identifier {
  NSMutableData *data = [NSData dataWithContentsOfURL:photoURL].mutableCopy;
  UIImage *image = [UIImage imageWithData:data];
  CGImageRef imageRef = image.CGImage;
  NSDictionary *imageMetadata = @{
    (NSString *)kCGImagePropertyMakerAppleDictionary : @{@"17" : identifier}
  };
  CGImageDestinationRef dest = CGImageDestinationCreateWithData(
      (CFMutableDataRef)data, kUTTypeJPEG, 1, nil);
  CGImageDestinationAddImage(dest, imageRef, (CFDictionaryRef)imageMetadata);
  CGImageDestinationFinalize(dest);
  [data writeToFile:outputFile atomically:YES];
}

- (void)addMetadataToVideo:(NSURL *)videoURL
                outputFile:(NSString *)outputFile
                identifier:(NSString *)identifier {
  NSError *error = nil;
  AVAsset *asset = [AVAsset assetWithURL:videoURL];
  AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset
                                                        error:&error];
  if (error) {
    return;
  }
  NSMutableArray<AVMetadataItem *> *metadata = asset.metadata.mutableCopy;
  AVMetadataItem *item = [self createContentIdentifierMetadataItem:identifier];
  [metadata addObject:item];
  NSURL *videoFileURL = [NSURL fileURLWithPath:outputFile];
  [self deleteFile:outputFile];
  AVAssetWriter *writer =
      [AVAssetWriter assetWriterWithURL:videoFileURL
                               fileType:AVFileTypeQuickTimeMovie
                                  error:&error];
  if (error) {
    return;
  }
  [writer setMetadata:metadata];
  NSArray<AVAssetTrack *> *tracks = [asset tracks];
  for (AVAssetTrack *track in tracks) {
    NSDictionary *readerOutputSettings = nil;
    NSDictionary *writerOuputSettings = nil;
    if ([track.mediaType isEqualToString:AVMediaTypeAudio]) {
      readerOutputSettings = @{AVFormatIDKey : @(kAudioFormatLinearPCM)};
      writerOuputSettings = @{
        AVFormatIDKey : @(kAudioFormatMPEG4AAC),
        AVSampleRateKey : @(44100),
        AVNumberOfChannelsKey : @(2),
        AVEncoderBitRateKey : @(128000)
      };
    }
    AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput
        assetReaderTrackOutputWithTrack:track
                         outputSettings:readerOutputSettings];
    AVAssetWriterInput *input =
        [AVAssetWriterInput assetWriterInputWithMediaType:track.mediaType
                                           outputSettings:writerOuputSettings];
    if ([reader canAddOutput:output] && [writer canAddInput:input]) {
      [reader addOutput:output];
      [writer addInput:input];
    }
  }
  AVAssetWriterInput *input = [self createStillImageTimeAssetWriterInput];
  AVAssetWriterInputMetadataAdaptor *adaptor =
      [AVAssetWriterInputMetadataAdaptor
          assetWriterInputMetadataAdaptorWithAssetWriterInput:input];
  if ([writer canAddInput:input]) {
    [writer addInput:input];
  }
  [writer startWriting];
  [writer startSessionAtSourceTime:kCMTimeZero];
  [reader startReading];
  AVMetadataItem *timedItem = [self createStillImageTimeMetadataItem];
  CMTimeRange timedRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(1, 100));
  AVTimedMetadataGroup *timedMetadataGroup =
      [[AVTimedMetadataGroup alloc] initWithItems:@[ timedItem ]
                                        timeRange:timedRange];
  [adaptor appendTimedMetadataGroup:timedMetadataGroup];
  DYYYManager.shared->reader = reader;
  DYYYManager.shared->writer = writer;
  DYYYManager.shared->queue =
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  DYYYManager.shared->group = dispatch_group_create();
  for (NSInteger i = 0; i < reader.outputs.count; ++i) {
    dispatch_group_enter(DYYYManager.shared->group);
    [self writeTrack:i];
  }
}

- (void)writeTrack:(NSInteger)trackIndex {
  AVAssetReaderOutput *output = DYYYManager.shared->reader.outputs[trackIndex];
  AVAssetWriterInput *input = DYYYManager.shared->writer.inputs[trackIndex];

  [input
      requestMediaDataWhenReadyOnQueue:DYYYManager.shared->queue
                            usingBlock:^{
                              while (input.readyForMoreMediaData) {
                                AVAssetReaderStatus status =
                                    DYYYManager.shared->reader.status;
                                CMSampleBufferRef buffer = NULL;
                                if ((status == AVAssetReaderStatusReading) &&
                                    (buffer = [output copyNextSampleBuffer])) {
                                  BOOL success =
                                      [input appendSampleBuffer:buffer];
                                  CFRelease(buffer);
                                  if (!success) {

                                    [input markAsFinished];
                                    dispatch_group_leave(
                                        DYYYManager.shared->group);
                                    return;
                                  }
                                } else {
                                  if (status == AVAssetReaderStatusReading) {

                                  } else if (status ==
                                             AVAssetReaderStatusCompleted) {

                                  } else if (status ==
                                             AVAssetReaderStatusCancelled) {

                                  } else if (status ==
                                             AVAssetReaderStatusFailed) {
                                  }
                                  [input markAsFinished];
                                  dispatch_group_leave(
                                      DYYYManager.shared->group);
                                  return;
                                }
                              }
                            }];
}
- (AVMetadataItem *)createContentIdentifierMetadataItem:(NSString *)identifier {
  AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
  item.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
  item.key = AVMetadataQuickTimeMetadataKeyContentIdentifier;
  item.value = identifier;
  return item;
}

- (AVAssetWriterInput *)createStillImageTimeAssetWriterInput {
  NSArray *spec = @[ @{
    (NSString *)
    kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier :
        @"mdta/com.apple.quicktime.still-image-time",
    (NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType :
        (NSString *)kCMMetadataBaseDataType_SInt8
  } ];
  CMFormatDescriptionRef desc = NULL;
  CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
      kCFAllocatorDefault, kCMMetadataFormatType_Boxed,
      (__bridge CFArrayRef)spec, &desc);
  AVAssetWriterInput *input =
      [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeMetadata
                                         outputSettings:nil
                                       sourceFormatHint:desc];
  return input;
}

- (AVMetadataItem *)createStillImageTimeMetadataItem {
  AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
  item.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
  item.key = @"com.apple.quicktime.still-image-time";
  item.value = @(-1);
  item.dataType = (NSString *)kCMMetadataBaseDataType_SInt8;
  return item;
}
- (NSString *)filePathFromDoc:(NSString *)filename {
  NSString *docPath = [NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
  NSString *filePath = [docPath stringByAppendingPathComponent:filename];
  return filePath;
}

- (void)deleteFile:(NSString *)file {
  NSFileManager *fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath:file]) {
    [fm removeItemAtPath:file error:nil];
  }
}

+ (void)downloadAllLivePhotos:(NSArray<NSDictionary *> *)livePhotos {
  if (livePhotos.count == 0) {
    return;
  }

  [self downloadAllLivePhotosWithProgress:livePhotos
                                 progress:nil
                               completion:^(NSInteger successCount,
                                            NSInteger totalCount) {
                                 [self showToast:
                                           [NSString
                                               stringWithFormat:
                                                   @"已儲存 %ld/%ld 個原況照片",
                                                   (long)successCount,
                                                   (long)totalCount]];
                               }];
}

+ (void)downloadAllLivePhotosWithProgress:(NSArray<NSDictionary *> *)livePhotos
                                 progress:
                                     (void (^)(NSInteger current,
                                               NSInteger total))progressBlock
                               completion:
                                   (void (^)(NSInteger successCount,
                                             NSInteger totalCount))completion {
  if (livePhotos.count == 0) {
    if (completion) {
      completion(0, 0);
    }
    return;
  }

  // 检查iOS版本
  BOOL supportsLivePhoto = NO;
  if (@available(iOS 15.0, *)) {
    supportsLivePhoto = YES;
  }

  if (!supportsLivePhoto) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [DYYYManager showToast:@"當前iOS版本不支援原況照片"];
    });
  }
  
   // 创建自定义批量下载进度条界面
  dispatch_async(dispatch_get_main_queue(), ^{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    DYYYDownloadProgressView *progressView =
        [[DYYYDownloadProgressView alloc] initWithFrame:screenBounds];
    progressView.progressLabel.text = @"準備下載原況照片...";
    [progressView show];

    NSString *batchID = [NSUUID UUID].UUIDString;

    // 设置取消按钮事件
    progressView.cancelBlock = ^{
      [DYYYManager cancelAllDownloads];
      if (completion) {
        completion(0, livePhotos.count);
      }
    };

    // 创建下载任务
    __block NSInteger completedCount = 0;
    __block NSInteger successCount = 0;
    NSInteger totalCount = livePhotos.count;

    // 为每个实况照片创建下载任务
    for (NSInteger index = 0; index < livePhotos.count; index++) {
      NSDictionary *livePhoto = livePhotos[index];
      NSURL *imageURL = [NSURL URLWithString:livePhoto[@"imageURL"]];
      NSURL *videoURL = [NSURL URLWithString:livePhoto[@"videoURL"]];

      if (!imageURL || !videoURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
          completedCount++;
          float progress = (float)completedCount / totalCount;
          [progressView setProgress:progress];
          progressView.progressLabel.text =
              [NSString stringWithFormat:@"進度: %ld/%ld", (long)completedCount,
                                         (long)totalCount];

          if (progressBlock) {
            progressBlock(completedCount, totalCount);
          }

          if (completedCount >= totalCount) {
            [progressView dismiss];
            if (completion) {
              completion(successCount, totalCount);
            }
          }
        });
        continue;
      }

      // 延迟启动每个下载，避免同时发起大量网络请求
      dispatch_after(
          dispatch_time(DISPATCH_TIME_NOW, index * 0.5 * NSEC_PER_SEC),
          dispatch_get_main_queue(), ^{
            [self
                downloadLivePhoto:imageURL
                         videoURL:videoURL
                       completion:^{
                         dispatch_async(dispatch_get_main_queue(), ^{
                           successCount++;
                           completedCount++;

                           float progress = (float)completedCount / totalCount;
                           [progressView setProgress:progress];
                           progressView.progressLabel.text =
                               [NSString stringWithFormat:@"進度: %ld/%ld",
                                                          (long)completedCount,
                                                          (long)totalCount];

                           if (progressBlock) {
                             progressBlock(completedCount, totalCount);
                           }

                           if (completedCount >= totalCount) {
                             [progressView dismiss];
                             if (completion) {
                               completion(successCount, totalCount);
                             }
                           }
                         });
                       }];
          });
    }
  });
}

+ (BOOL)isDarkMode {
  return [NSClassFromString(@"AWEUIThemeManager") isLightTheme] ? NO : YES;
}

+ (void)parseAndDownloadVideoWithShareLink:(NSString *)shareLink apiKey:(NSString *)apiKey {
    if (shareLink.length == 0 || apiKey.length == 0) {
        [self showToast:@"分享連結或API金鑰無效"];
        return;
    }

    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", apiKey, [shareLink stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    [self showToast:@"正在透過介面解析..."];

    NSURL *url = [NSURL URLWithString:apiUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];

    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                            if (error) {
                                [self showToast:[NSString stringWithFormat:@"介面請求失敗: %@", error.localizedDescription]];
                                return;
                            }

                            NSError *jsonError;
                            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                            if (jsonError) {
                                [self showToast:@"解析介面返回數據失敗"];
                                return;
                            }

                            NSInteger code = [json[@"code"] integerValue];
                            if (code != 0 && code != 200) {
                                [self showToast:[NSString stringWithFormat:@"介面返回錯誤: %@", json[@"msg"] ?: @"未知錯誤"]];
                                return;
                            }

                            NSDictionary *dataDict = json[@"data"];
                            if (!dataDict) {
                                [self showToast:@"介面返回數據為空"];
                                return;
                            }
                            NSArray *videos = dataDict[@"videos"];
                            NSArray *images = dataDict[@"images"];
                            NSArray *videoList = dataDict[@"video_list"];
                            BOOL hasVideos = [videos isKindOfClass:[NSArray class]] && videos.count > 0;
                            BOOL hasImages = [images isKindOfClass:[NSArray class]] && images.count > 0;
                            BOOL hasVideoList = [videoList isKindOfClass:[NSArray class]] && videoList.count > 0;
                            BOOL shouldShowQualityOptions = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYShowAllVideoQuality"];

                            // 如果启用了显示清晰度选项，并且存在 videoList，则弹出选择面板
                            if (shouldShowQualityOptions && hasVideoList) {
                                AWEUserActionSheetView *actionSheet = [[NSClassFromString(@"AWEUserActionSheetView") alloc] init];
                                NSMutableArray *actions = [NSMutableArray array];

                                for (NSDictionary *videoDict in videoList) {
                                    NSString *url = videoDict[@"url"];
                                    NSString *level = videoDict[@"level"];
                                    if (url.length > 0 && level.length > 0) {
                                        AWEUserSheetAction *qualityAction = [NSClassFromString(@"AWEUserSheetAction")
                                            actionWithTitle:level
                                                imgName:nil
                                                handler:^{
                                                  NSURL *videoDownloadUrl = [NSURL URLWithString:url];
                                                  [self downloadMedia:videoDownloadUrl
                                                    mediaType:MediaTypeVideo
                                                       completion:^{
                                                     [self showToast:[NSString stringWithFormat:@"影片已儲存到相簿 (%@)", level]];
                                                       }];
                                                }];
                                        [actions addObject:qualityAction];
                                    }
                                }

                                // 附加批量下载选项（如果开启清晰度选项 + 有视频/图片）
                                if (hasVideos || hasImages) {
                                    AWEUserSheetAction *batchDownloadAction = [NSClassFromString(@"AWEUserSheetAction")
                                        actionWithTitle:@"批次下載所有資源"
                                            imgName:nil
                                            handler:^{
                                              [self batchDownloadResources:videos images:images];
                                            }];
                                    [actions addObject:batchDownloadAction];
                                }

                                if (actions.count > 0) {
                                    [actionSheet setActions:actions];
                                    [actionSheet show];
                                    return;
                                }
                            }

                            // 如果未开启清晰度选项，但有 video_list，自动下载第一个清晰度
                            if (!shouldShowQualityOptions && hasVideoList) {
                                NSDictionary *firstVideo = videoList.firstObject;
                                NSString *url = firstVideo[@"url"];
                                NSString *level = firstVideo[@"level"] ?: @"預設解析度";

                                if (url.length > 0) {
                                    NSURL *videoDownloadUrl = [NSURL URLWithString:url];
                                    [self downloadMedia:videoDownloadUrl
                                          mediaType:MediaTypeVideo
                                         completion:^{
                                           [self showToast:[NSString stringWithFormat:@"影片已儲存到相簿 (%@)", level]];
                                         }];
                                    return;
                                }
                            }

                            // 如果没有视频或图片数组，但有单个视频URL
                            if (!hasVideos && !hasImages && !hasVideoList) {
                                NSString *videoUrl = dataDict[@"url"];
                                if (videoUrl.length > 0) {
                                    [self showToast:@"開始下載單一影片..."];
                                    NSURL *videoDownloadUrl = [NSURL URLWithString:videoUrl];
                                    [self downloadMedia:videoDownloadUrl
                                          mediaType:MediaTypeVideo
                                         completion:^{
                                           [self showToast:@"影片已儲存到相簿"];
                                         }];
                                } else {
                                    [self showToast:@"介面未返回有效的影片連結"];
                                }
                                return;
                            }

                            [self batchDownloadResources:videos images:images];
                              });
                            }];

    [dataTask resume];
}

+ (void)batchDownloadResources:(NSArray *)videos images:(NSArray *)images {
    BOOL hasVideos = [videos isKindOfClass:[NSArray class]] && videos.count > 0;
    BOOL hasImages = [images isKindOfClass:[NSArray class]] && images.count > 0;

    NSMutableArray<id> *videoFiles = [NSMutableArray arrayWithCapacity:videos.count];
    NSMutableArray<id> *imageFiles = [NSMutableArray arrayWithCapacity:images.count];
    for (NSInteger i = 0; i < videos.count; i++)
        [videoFiles addObject:[NSNull null]];
    for (NSInteger i = 0; i < images.count; i++)
        [imageFiles addObject:[NSNull null]];

    dispatch_group_t downloadGroup = dispatch_group_create();
    __block NSInteger totalDownloads = 0;
    __block NSInteger completedDownloads = 0;

    if (hasVideos) {
        totalDownloads += videos.count;
        for (NSInteger i = 0; i < videos.count; i++) {
            NSDictionary *videoDict = videos[i];
            NSString *videoUrl = videoDict[@"url"];
            if (videoUrl.length == 0) {
                completedDownloads++;
                continue;
            }
            dispatch_group_enter(downloadGroup);
            NSURL *videoDownloadUrl = [NSURL URLWithString:videoUrl];
            [self downloadMediaWithProgress:videoDownloadUrl
                          mediaType:MediaTypeVideo
                           progress:nil
                         completion:^(BOOL success, NSURL *fileURL) {
                           if (success && fileURL) {
                               @synchronized(videoFiles) {
                                   videoFiles[i] = fileURL;
                               }
                           }
                           completedDownloads++;
                           dispatch_group_leave(downloadGroup);
                         }];
        }
    }

    if (hasImages) {
        totalDownloads += images.count;
        for (NSInteger i = 0; i < images.count; i++) {
            NSString *imageUrl = images[i];
            if (imageUrl.length == 0) {
                completedDownloads++;
                continue;
            }
            dispatch_group_enter(downloadGroup);
            NSURL *imageDownloadUrl = [NSURL URLWithString:imageUrl];
            [self downloadMediaWithProgress:imageDownloadUrl
                          mediaType:MediaTypeImage
                           progress:nil
                         completion:^(BOOL success, NSURL *fileURL) {
                           if (success && fileURL) {
                               @synchronized(imageFiles) {
                                   imageFiles[i] = fileURL;
                               }
                           }
                           completedDownloads++;
                           dispatch_group_leave(downloadGroup);
                         }];
        }
    }

    dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
        if (completedDownloads < totalDownloads) {
            [self showToast:@"部分下載失敗"];
        }

      NSInteger videoSuccessCount = 0;
      for (id file in videoFiles) {
          if ([file isKindOfClass:[NSURL class]]) {
              [self saveMedia:(NSURL *)file mediaType:MediaTypeVideo completion:nil];
              videoSuccessCount++;
          }
      }

      NSInteger imageSuccessCount = 0;
      for (id file in imageFiles) {
          if ([file isKindOfClass:[NSURL class]]) {
              [self saveMedia:(NSURL *)file mediaType:MediaTypeImage completion:nil];
              imageSuccessCount++;
          }
      }

      NSString *toastMessage;
      if (hasVideos && hasImages) {
          toastMessage = [NSString stringWithFormat:@"已儲存 %ld/%ld 個影片和 %ld/%ld 張圖片", (long)videoSuccessCount, (long)videos.count, (long)imageSuccessCount, (long)images.count];
      } else if (hasVideos) {
          toastMessage = [NSString stringWithFormat:@"已儲存 %ld/%ld 個影片", (long)videoSuccessCount, (long)videos.count];
      } else if (hasImages) {
          toastMessage = [NSString stringWithFormat:@"已儲存 %ld/%ld 張圖片", (long)imageSuccessCount, (long)images.count];
      }
      [self showToast:toastMessage];
    });
}

@end