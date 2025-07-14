#import <UIKit/UIKit.h>

@interface FloatingSpeedButton : UIButton
@property(nonatomic, assign) CGPoint lastLocation;
@property(nonatomic, weak) id interactionController;
@property(nonatomic, assign) BOOL isLocked;
@property(nonatomic, assign) BOOL justToggledLock;
@property(nonatomic, assign) BOOL originalLockState;
@property(nonatomic, assign) BOOL isResponding;
@property(nonatomic, strong) NSTimer *statusCheckTimer;
@property(nonatomic, strong) NSTimer *fadeTimer;
@property(nonatomic, assign) CGFloat originalAlpha;
- (void)saveButtonPosition;
- (void)loadSavedPosition;
- (void)resetButtonState;
- (void)toggleLockState;
- (void)resetFadeTimer;
@end

extern FloatingSpeedButton *getSpeedButton(void);
extern void showSpeedButton(void);
extern void hideSpeedButton(void);
extern void toggleSpeedButtonVisibility(void);
extern BOOL isFloatSpeedButtonEnabled;
extern BOOL isCommentViewVisible;
extern BOOL isInteractionViewVisible;
extern BOOL isForceHidden;
extern BOOL showSpeedX;
extern CGFloat speedButtonSize;
extern FloatingSpeedButton *speedButton;
extern void updateSpeedButtonVisibility(void);
extern void updateSpeedButtonUI(void);