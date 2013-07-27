//
//  AppDelegate.h
//  Breathe
//
//  Created by Francesco Mattia on 10/22/12.
//  Copyright (c) 2012 Uncover. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <WebKit/WebKit.h>
#import "MenubarController.h"
#import "PanelController.h"

@class FullScreenWindow;

typedef enum {
    kEffectBreathe = 1,
    kEffectFlicker = 2,
    kEffectFlickerBreathe = 3,
    kEffectSpaceInvaders = 4
} kEffect;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSURLConnectionDelegate, PanelControllerDelegate> {
    NSDate *startTime;
    NSDate *lastChangeTime;
    float defaultBrightness;
    float normalizeOffset;
    
    int imageNum;
    float cycleDuration;
    
    kEffect effect;
    
    NSMutableData *receivedData;
    
    IBOutlet NSSlider *breatheDurationSlider;
    
    NSImageView *imageView;
    WebView     *webView;
    FullScreenWindow    *fullScreenWindow;
    
    // Effects button cells outlets
    IBOutlet NSButtonCell   *breatheCell;
    IBOutlet NSButtonCell   *flickerBreatheCell;
    IBOutlet NSButtonCell   *flickerCell;
    IBOutlet NSButtonCell   *spaceInvadersCell;
    IBOutlet NSTextField    *cycleDurationTextField;
    
    // Images button cells outlets
    IBOutlet NSButtonCell   *imagesUncoverCell;
    IBOutlet NSButtonCell   *imagesFolderCell;
    IBOutlet NSTextField    *imagesNumberTextField;
    __weak NSMatrix *_imageSourceMatrix;
    
    NSString    *imagesFolderPath;
    NSMutableArray     *imagesArray;
    NSMutableArray     *remoteImagesArray;
    
    // Loading elements
    
    __weak NSTextField *_loadingTextField;
    __weak NSProgressIndicator *_activityIndicator;
    __weak NSButton *_startButton;
}

- (void)setBrightness:(NSNumber*)brightness;
- (void)saveDefaultBrightness;
- (float)getBrightness;
- (void)startFullScreenAnimation;
- (IBAction)startButtonPressed:(id)sender;
- (float)cycleDuration;
- (kEffect)effect;

@property (assign) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSMatrix *imageSourceMatrix;
@property (weak) IBOutlet NSButton *startButton;
@property (weak) IBOutlet NSProgressIndicator *activityIndicator;
@property (weak) IBOutlet NSTextField *loadingTextField;

@property (nonatomic, strong) MenubarController *menubarController;
@property (nonatomic, strong, readonly) PanelController *panelController;

@end
