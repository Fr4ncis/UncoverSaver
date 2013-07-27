#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"
#import "NSButton+TextColor.h"
#import "UBButton.h"
#import "UBOptionButton.h"
#import "UBAnimatedImageView.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define SEARCH_INSET 17

#define POPUP_HEIGHT 400
#define PANEL_WIDTH 480
#define MENU_ANIMATION_DURATION .1

#pragma mark -

@implementation PanelController

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize breatheButton;
@synthesize flickerButton;
@synthesize screensaverButton;
@synthesize launchButton;
@synthesize arrowLayer;
@synthesize dialImageView;

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
}

#pragma mark -

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    // Customize buttons
    AppDelegate *delegate = (AppDelegate*)[NSApp delegate];
    BOOL breatheEffectOn = delegate.effect == kEffectBreathe;
    [breatheButton setSelected:breatheEffectOn];
    [flickerButton setSelected:!breatheEffectOn];

    
    arrowLayer = [CALayer layer];
    [dialImageView setWantsLayer:YES];
    arrowLayer.bounds = CGRectMake(0, 0, 9, 45);
    arrowLayer.position = CGPointMake(dialImageView.frame.size.width/2.0, dialImageView.frame.size.height/2.0-5.0);
    arrowLayer.contents = [NSImage imageNamed:@"Arrow.png"];
    [arrowLayer setAnchorPoint:CGPointMake(0.5, 0)];
    [dialImageView.layer addSublayer:arrowLayer];
    [dialImageView setNeedsDisplay];
    
    float cycleDuration = delegate.cycleDuration;
    float percentage = ((cycleDuration-1.0f)/9.0f);
    NSLog(@"cycle: %f percentage: %f", cycleDuration, percentage);
    float arrowRotation = - (percentage - 0.5f) * 2*M_PI_2;
    [arrowLayer setAffineTransform:CGAffineTransformMakeRotation(arrowRotation)];


    // Resize panel
    NSRect panelRect = [[self window] frame];
    panelRect.size.height = POPUP_HEIGHT;
    [[self window] setFrame:panelRect display:NO];
}

#pragma mark - Mouse events

- (BOOL) acceptsFirstMouse:(NSEvent *)e {
    return YES;
}

- (void)mouseDragged:(NSEvent *) e {
    if (e.locationInWindow.x < 187.0 || e.locationInWindow.x > 295.0)
        return;
    float percentage = (e.locationInWindow.x - 187.0) / 108.0;
    float arrowRotation = - (percentage - 0.5f) * 2*M_PI_2;
    
    float cycleDuration = (9.0f*percentage)+1.0f;
    [_computersImageView setFramesPerSecond:56.0/cycleDuration];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithFloat:cycleDuration] forKey:@"cycleDuration"];
    [defaults synchronize];
    
    [arrowLayer setAffineTransform:CGAffineTransformMakeRotation(arrowRotation)];
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        
        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    
    self.backgroundView.arrowX = panelX;
    
////    NSRect searchRect = [self.searchField frame];
//    searchRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
//    searchRect.origin.x = SEARCH_INSET;
//    searchRect.origin.y = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET - NSHeight(searchRect);
//    
//    if (NSIsEmptyRect(searchRect))
//    {
////        [self.searchField setHidden:YES];
//    }
//    else
//    {
////        [self.searchField setFrame:searchRect];
////        [self.searchField setHidden:NO];
//    }
    
//    NSRect textRect = [self.textField frame];
//    textRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
//    textRect.origin.x = SEARCH_INSET;
//    textRect.size.height = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET * 3 - NSHeight(searchRect);
//    textRect.origin.y = SEARCH_INSET;
//    
//    if (NSIsEmptyRect(textRect))
//    {
////        [self.textField setHidden:YES];
//    }
//    else
//    {
////        [self.textField setFrame:textRect];
////        [self.textField setHidden:NO];
//    }
}

- (IBAction)breatheButtonPressed:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithInteger:1] forKey:@"effect"];
    [defaults synchronize];
    
    [flickerButton setSelected:NO];
    [breatheButton setSelected:YES];
}

- (IBAction)flickerButtonPressed:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithInteger:2] forKey:@"effect"];
    [defaults synchronize];
    
    [flickerButton setSelected:YES];
    [breatheButton setSelected:NO];
}

- (IBAction)screensaverButtonPressed:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Breathe" ofType:@"saver"];
    [[NSWorkspace sharedWorkspace] openFile:path];
}

- (IBAction)launchButtonPressed:(id)sender {
    AppDelegate *delegate = (AppDelegate*)[NSApp delegate];
    [delegate startButtonPressed:sender];
}
#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    StatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];

    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    [panel setFrame:statusRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    
    NSTimeInterval openDuration = OPEN_DURATION;
    
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent type] == NSLeftMouseDown)
    {
        NSUInteger clearFlags = ([currentEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
        BOOL shiftPressed = (clearFlags == NSShiftKeyMask);
        BOOL shiftOptionPressed = (clearFlags == (NSShiftKeyMask | NSAlternateKeyMask));
        if (shiftPressed || shiftOptionPressed)
        {
            openDuration *= 10;
            
            if (shiftOptionPressed)
                NSLog(@"Icon is at %@\n\tMenu is on screen %@\n\tWill be animated to %@",
                      NSStringFromRect(statusRect), NSStringFromRect(screenRect), NSStringFromRect(panelRect));
        }
    }
    
    [panel setAlphaValue:0.0f];
    [panel setFrame:panelRect display:YES];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:openDuration];
    [[panel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];

    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        [_computersImageView startAnimation];
    });
//    [panel performSelector:@selector(makeFirstResponder:) withObject:self.searchField afterDelay:openDuration];
}

- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    

    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        [_computersImageView stopAnimation];
        
        [self.window orderOut:nil];
    });
}

#

@end
