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
#include <ApplicationServices/ApplicationServices.h>

const int kMaxDisplays = 16;
const CFStringRef kDisplayBrightness = CFSTR(kIODisplayBrightnessKey);
const char *APP_NAME;

@implementation UncoverSaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"This is being called" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:nil];
        [alert runModal];
        [self setAnimationTimeInterval:1/30.0];
    }
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
    if (![self isPreview]) {
        [self saveDefaultBrightness];
        upwards = TRUE;
        [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(brightnessCycle) userInfo:nil repeats:YES];
    }
}

- (void)brightnessCycle
{
    if ([self getBrightness] >= 1)
        upwards = NO;
    else if ([self getBrightness] <= 0)
        upwards = YES;
    [self setBrightness:[NSNumber numberWithFloat:upwards?[self getBrightness]+0.01:[self getBrightness]-0.01]];
}

- (void)stopAnimation
{
    [super stopAnimation];
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
}

- (void)animateOneFrame
{
    return;
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow*)configureSheet
{
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
    CGDisplayErr err;
    CGDisplayCount numDisplays;
    CGDirectDisplayID display[kMaxDisplays];
    err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
    CGDirectDisplayID dspy = display[0];
    io_service_t service = CGDisplayIOServicePort(dspy);
    IODisplayGetFloatParameter(service, kNilOptions, kDisplayBrightness, &defaultBrightness);
}

@end
