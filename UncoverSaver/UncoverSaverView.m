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

const int kVersion = 21;
const int kCycleDuration = 5;
const int kPreviewInterval = 10;
const int kMaxDisplays = 16;
const float kSteps = 1/30.0;
const CFStringRef kDisplayBrightness = CFSTR(kIODisplayBrightnessKey);
const char *APP_NAME;

@implementation UncoverSaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    if (self = [super initWithFrame:frame isPreview:isPreview]) {
        LogMessage(@"", 4, [NSString stringWithFormat:@"(VER %d) InitWithFrame PREVIEW: %d", kVersion, isPreview]);
        if (isPreview) {
            [self setAnimationTimeInterval:kPreviewInterval];
            //NSView *movieView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
            [self setupMovie];
            
            //CALayer *viewLayer = [CALayer layer];
            //[viewLayer setBackgroundColor:CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0)]; //RGB plus Alpha Channel
            //[movieView setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
            
            //QTMovieLayer *movieLayer = [QTMovieLayer layerWithMovie:movie];
            //QTMovieView *movieView = [[QTMovieView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height+20)];
            //[movieView setMovie:movie];
            //[movieView setLayer:viewLayer];
            //[viewLayer addSublayer:movieLayer];
            //[self addSubview:movieView];
        }
        else {
            [self setAnimationTimeInterval:kSteps];
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
    LogMessage(@"", 4, [NSString stringWithFormat:@"FilePath: %@", filePath]);
    movie = [[QTMovie alloc] initWithFile:filePath error:&error];
    [movie setAttribute:[NSNumber numberWithBool:YES] forKey: @"QTMovieLoopsAttribute"];
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(playAgain:)
                               name:QTMovieDidEndNotification
                             object:self];
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

- (void)brightnessCycle
{
    float secStarted = [startTime timeIntervalSinceNow]*-1;
    float brightness = (sin(secStarted*MATH_PI/kCycleDuration)+1.1)/2.1;
    LogMessage(@"Started", 3, [NSString stringWithFormat:@"Started: %f Bright: %f", secStarted, brightness]);
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
    LogMessage(@"", 5, [NSString stringWithFormat:@"Size: %f %f", rect.size.width, rect.size.height]);
    LogMessage(@"", 5, @"drawRect");
}

- (void)animateOneFrame
{
    if (![self isPreview]) {
        LogMessage(@"", 5, [NSString stringWithFormat:@"animateOneFrame (Preview:NO) (brightness: %f)", [self getBrightness]]);
        [self brightnessCycle];
    } else {
        LogMessage(@"", 5, @"animateOneFrame (Preview:YES)");
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
