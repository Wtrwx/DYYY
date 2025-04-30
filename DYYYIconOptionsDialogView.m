#import "DYYYIconOptionsDialogView.h"

@implementation DYYYIconOptionsDialogView

- (instancetype)initWithTitle:(NSString *)title previewImage:(UIImage *)image {
    if (self = [super initWithFrame:UIScreen.mainScreen.bounds]) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        
        // 創建模糊效果視圖
        self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        self.blurView.frame = self.bounds;
        self.blurView.alpha = 0.2;
        [self addSubview:self.blurView];
        
        // 創建內容視圖 - 使用純白背景
        CGFloat contentHeight = image ? 300 : 200; // 如果有圖片預覽則增加高度
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, contentHeight)];
        self.contentView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.layer.cornerRadius = 12;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [self addSubview:self.contentView];
        
        // 標題 - 顏色使用 #2d2f38
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 260, 24)];
        self.titleLabel.text = title;
        self.titleLabel.textColor = [UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0]; // #2d2f38
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
        [self.contentView addSubview:self.titleLabel];
        
        // 如果有圖片，添加預覽
        CGFloat buttonStartY = 54;
        if (image) {
            CGFloat imageViewSize = 120;
            self.previewImageView = [[UIImageView alloc] initWithFrame:CGRectMake((300 - imageViewSize) / 2, 54, imageViewSize, imageViewSize)];
            self.previewImageView.contentMode = UIViewContentModeScaleAspectFit;
            self.previewImageView.image = image;
            self.previewImageView.layer.cornerRadius = 8;
            self.previewImageView.layer.borderColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0].CGColor;
            self.previewImageView.layer.borderWidth = 0.5;
            self.previewImageView.clipsToBounds = YES;
            [self.contentView addSubview:self.previewImageView];
            buttonStartY = 184; // 調整按鈕位置
        }
        
        // 添加內容和按鈕之間的分割線
        UIView *contentButtonSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, contentHeight - 55.5, 300, 0.5)];
        contentButtonSeparator.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        [self.contentView addSubview:contentButtonSeparator];
        
        // 按鈕容器
        UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, contentHeight - 55, 300, 55)];
        [self.contentView addSubview:buttonContainer];
        
        // 清除按鈕 - 顏色使用 #7c7c82
        self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.clearButton.frame = CGRectMake(0, 0, 149.5, 55);
        self.clearButton.backgroundColor = [UIColor clearColor];
        [self.clearButton setTitle:@"清除" forState:UIControlStateNormal];
        [self.clearButton setTitleColor:[UIColor colorWithRed:124/255.0 green:124/255.0 blue:130/255.0 alpha:1.0] forState:UIControlStateNormal]; // #7c7c82
        [self.clearButton addTarget:self action:@selector(clearButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:self.clearButton];
        
        // 按鈕之間的分割線
        UIView *buttonSeparator = [[UIView alloc] initWithFrame:CGRectMake(149.5, 0, 0.5, 55)];
        buttonSeparator.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        [buttonContainer addSubview:buttonSeparator];
        
        // 選擇按鈕 - 顏色使用 #2d2f38
        self.selectButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.selectButton.frame = CGRectMake(150, 0, 150, 55);
        self.selectButton.backgroundColor = [UIColor clearColor];
        [self.selectButton setTitle:@"選擇" forState:UIControlStateNormal];
        [self.selectButton setTitleColor:[UIColor colorWithRed:45/255.0 green:47/255.0 blue:56/255.0 alpha:1.0] forState:UIControlStateNormal]; // #2d2f38
        [self.selectButton addTarget:self action:@selector(selectButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:self.selectButton];
        
        // 添加點擊空白處關閉的手勢
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTap:)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

// 處理背景點擊事件
- (void)handleBackgroundTap:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self];
    if (!CGRectContainsPoint(self.contentView.frame, location)) {
        [self dismiss];
    }
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    
    [UIView animateWithDuration:0.12 animations:^{
        self.contentView.alpha = 1.0;
        self.contentView.transform = CGAffineTransformIdentity;
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.1 animations:^{
        self.contentView.alpha = 0;
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        self.blurView.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)clearButtonTapped {
    if (self.onClear) {
        self.onClear();
    }
    [self dismiss];
}

- (void)selectButtonTapped {
    if (self.onSelect) {
        self.onSelect();
    }
    [self dismiss];
}

@end
