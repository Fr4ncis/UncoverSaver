//
//  UncoverSaverView.h
//  UncoverSaver
//
//  Created by Francesco Mattia on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import <QTKit/QTKit.h>

@interface UncoverSaverView : ScreenSaverView {
    NSDate *startTime;
    NSDate *lastChangeTime;
    float defaultBrightness;
    float normalizeOffset;
    
    int imageNum;
    int cycleDuration;
    
    float tempCycleDuration;
    
    IBOutlet NSSlider *breatheDurationSlider;
    IBOutlet NSWindow *configureSheet;
    QTMovie *movie;
    NSImageView *imageView;
}

- (void)setBrightness:(NSNumber*)brightness;
- (void)saveDefaultBrightness;
- (float)getBrightness;

@end
