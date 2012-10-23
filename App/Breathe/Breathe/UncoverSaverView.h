//
//  UncoverSaverView.h
//  UncoverSaver
//
//  Created by Francesco Mattia on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import <QTKit/QTKit.h>
#import <WebKit/WebKit.h>

typedef enum {
    kEffectBreathe = 1,
    kEffectFlicker = 2,
    kEffectFlickerBreathe = 3,
    kEffectSpaceInvaders = 4
} kEffect;

@interface UncoverSaverView : ScreenSaverView {
    NSDate *startTime;
    NSDate *lastChangeTime;
    float defaultBrightness;
    float normalizeOffset;
    
    int imageNum;
    int cycleDuration;
    
    kEffect effect;
    
    float tempCycleDuration;
    
    IBOutlet NSSlider *breatheDurationSlider;
    IBOutlet id configureSheet;
    QTMovie *movie;
    
    NSImageView *imageView;
    WebView     *webView;
    
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
    
    NSString    *imagesFolderPath;
    NSMutableArray     *imagesArray;
}

- (void)setBrightness:(NSNumber*)brightness;
- (void)saveDefaultBrightness;
- (float)getBrightness;

@end
