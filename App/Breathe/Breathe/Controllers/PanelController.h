#import "BackgroundView.h"
#import "StatusItemView.h"

@class PanelController;
@class UBButton;
@class UBOptionButton;
@class UBAnimatedImageView;

@protocol PanelControllerDelegate <NSObject>

@optional

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;

@end

#pragma mark -

@interface PanelController : NSWindowController <NSWindowDelegate>
{
    BOOL _hasActivePanel;
    __unsafe_unretained BackgroundView *_backgroundView;
    __unsafe_unretained id<PanelControllerDelegate> _delegate;
    
    int pictureNumber;
}
@property (strong) IBOutlet NSView *buttonPanel;
@property (nonatomic, unsafe_unretained) IBOutlet BackgroundView *backgroundView;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, unsafe_unretained, readonly) id<PanelControllerDelegate> delegate;

@property (strong) IBOutlet UBOptionButton *breatheButton;
@property (strong) IBOutlet UBOptionButton *flickerButton;
@property (strong) IBOutlet NSButton *launchButton;
@property (strong) IBOutlet NSButton *screensaverButton;
@property (strong) CALayer *arrowLayer;
@property (strong) IBOutlet NSImageView *dialImageView;
@property (strong) IBOutlet UBAnimatedImageView *computersImageView;


- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;

@end
