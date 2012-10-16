//
//  UncoverSaverView.m
//  UncoverSaver
//
//  Created by Francesco Mattia on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UncoverSaverView.h"
#include <stdio.h>
#include <unistd.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#import "LoggerClient.h"
#import "LoggerCommon.h"
#import <QuartzCore/QuartzCore.h>
#include <ApplicationServices/ApplicationServices.h>

const int kVersion = 39;
const int kCycleDuration = 5;
const int kPreviewInterval = 10;
const int kMaxDisplays = 16;
const float kSteps = 1/8.0;
const CFStringRef kDisplayBrightness = CFSTR(kIODisplayBrightnessKey);
const char *APP_NAME;

@implementation UncoverSaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    if (self = [super initWithFrame:frame isPreview:isPreview]) {
        imageNum = 0;
        firstIteration = YES;
        __isPreview = isPreview;
        LogMessage(@"", 4, @"%@", [NSString stringWithFormat:@"(VER %d) InitWithFrame PREVIEW: %d", kVersion, isPreview]);
        if (__isPreview) {
            LogMessage(@"Mode", 4, @"SMALL PREVIEW");
            [self setAnimationTimeInterval:kPreviewInterval];
            [self setupMovie];
        }
        else {
            LogMessage(@"Mode", 4, @"FULL SCREEN");
            [self setAnimationTimeInterval:kSteps];
            [self changeImage];
        }
        QTMovieView *movieView = [[QTMovieView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        [movieView setControllerVisible:NO];
        [movieView setMovie:movie];
        [movie autoplay];
        [self addSubview:movieView];
    }
    return self;
}

- (void)setupMovie
{
    NSError *error = nil;
    NSBundle *bundle = [NSBundle bundleForClass: [self class]];
    NSString *filePath = [bundle pathForResource: @"littleMovie"  ofType: @"mov"];
    LogMessage(@"", 4, @"%@", [NSString stringWithFormat:@"FilePath: %@", filePath]);
    movie = [[QTMovie alloc] initWithFile:filePath error:&error];
    [movie setAttribute:[NSNumber numberWithBool:YES] forKey: @"QTMovieLoopsAttribute"];
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(playAgain:)
                               name:QTMovieDidEndNotification
                             object:self];
}

- (void)changeImage
{
    firstIteration = NO;
    NSError *error = nil;
    NSBundle *bundle = [NSBundle bundleForClass: [self class]];
    imageNum++;
    (imageNum>3)?imageNum=1:imageNum;
    NSString *filePath = [bundle pathForResource: [NSString stringWithFormat:@"image%d", imageNum]  ofType: @"jpg"];
    LogMessage(@"Image", 4, @"%@", [NSString stringWithFormat:@"FilePath: %@", filePath]);
    if (imageView) {
        [imageView removeFromSuperview];
        imageView = nil;
    }
    imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height)];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePath];
    [imageView setImage:image];
    [imageView setImageScaling:NSScaleToFit];
    [self addSubview:imageView];
}

- (void)startAnimation
{
    [super startAnimation];
    startTime = [[NSDate alloc] init];
    LogMessage(@"", 4, @"startAnimation");
    if (![self isPreview]) {
        [self saveDefaultBrightness];
    }
}

- (BOOL)enoughTimeFromLastChange
{
    if (!lastChangeTime) {
        lastChangeTime = [[NSDate alloc] init];
        return YES;
    } else {
        float secStarted = [lastChangeTime timeIntervalSinceNow]*-1;
        if (secStarted > (kCycleDuration / 10.0)) {
            lastChangeTime = [[NSDate alloc] init];
            return YES;
        } else {
            return NO;
        }
    }
}

- (void)brightnessCycle
{
    float secStarted = [startTime timeIntervalSinceNow]*-1;
    float brightness = (sin(secStarted*MATH_PI/kCycleDuration)+1.1)/2.1;
    float derivative = (cos(secStarted*MATH_PI/kCycleDuration));
    if (brightness < 0.5 && derivative > 0 && derivative < 0.1 && [self enoughTimeFromLastChange]) {
        [self changeImage];
    }
    LogMessage(@"Started", 3, @"%@",[NSString stringWithFormat:@"Started: %f Bright: %f Deriv: %f", secStarted, brightness, derivative]);
    [self setBrightness:[NSNumber numberWithFloat:brightness]];
}

- (void)stopAnimation
{
    LogMessage(@"", 4, @"stopAnimation");
    [super stopAnimation];
    if (![self isPreview])
        [self setBrightness:[NSNumber numberWithFloat:defaultBrightness]];
}

- (float)getBrightness
{
    float myBrightness;
    CGDisplayErr err;
    CGDisplayCount numDisplays;
    CGDirectDisplayID display[kMaxDisplays];
    err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
    CGDirectDisplayID dspy = display[0];
    io_service_t service = CGDisplayIOServicePort(dspy);
    IODisplayGetFloatParameter(service, kNilOptions, kDisplayBrightness, &myBrightness);
    return myBrightness;
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    LogMessage(@"", 5, @"Size: %f %f", rect.size.width, rect.size.height);
    LogMessage(@"", 5, @"drawRect");
}

- (void)animateOneFrame
{
    if (__isPreview) {
        //LogMessage(@"", 5, @"animateOneFrame (SmallPreview)");
    } else {
        //LogMessage(@"", 5, @"animateOneFrame (FullScreen) (brightness: %f)", [self getBrightness]);
        [self brightnessCycle];
        if (firstIteration) {
            LogMessage(@"FirstIteration", 5, @"First Iteration");
            [self changeImage];
        }
    }
    return;
}

- (BOOL)hasConfigureSheet
{
    LogMessage(@"", 5, @"hasConfigureSheet");
    return YES;
}

- (NSWindow*)configureSheet
{
    LogMessage(@"", 5, @"configureSheet");
    return nil;
}

- (void)setBrightness:(NSNumber*)brightness
{
    float brightnessFloat = [brightness floatValue];
    CGDirectDisplayID display[kMaxDisplays];
    CGDisplayCount numDisplays;
    CGDisplayErr err;
    err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
    
    //CFWriteStreamRef stdoutStream = NULL;								  
    
    for (CGDisplayCount i = 0; i < numDisplays; ++i) {
        CGDirectDisplayID dspy = display[i];
        //CFDictionaryRef originalMode = CGDisplayCurrentMode(dspy);
        //        if (originalMode == NULL)
        //            continue;
        
        io_service_t service = CGDisplayIOServicePort(dspy);
        //        IODisplayGetFloatParameter(service, kNilOptions, kDisplayBrightness, &brightness);
        err = IODisplaySetFloatParameter(service, kNilOptions, kDisplayBrightness, brightnessFloat);
        if (err != kIOReturnSuccess) {
            NSLog(@"Error setting display brightness");
        }
    }

}

- (void)saveDefaultBrightness
{
    defaultBrightness = [self getBrightness];
    LogMessage(@"Brightness", 3, @"Default brightness: %f", defaultBrightness);
    //    CGDisplayErr err;
    //    CGDisplayCount numDisplays;
    //    CGDirectDisplayID display[kMaxDisplays];
    //    err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
    //    CGDirectDisplayID dspy = display[0];
    //    io_service_t service = CGDisplayIOServicePort(dspy);
    //    IODisplayGetFloatParameter(service, kNilOptions, kDisplayBrightness, &defaultBrightness);
}

- (void)playAgain:(NSNotification*)note
{
    [movie play];
}

@end
