//
//  UncoverSaverView.m
//  UncoverSaver
//
//  Created by Francesco Mattia on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UncoverSaverView.h"
#include <stdio.h>
#include <math.h>
#include <unistd.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#import "LoggerClient.h"
#import "LoggerCommon.h"
#import <QuartzCore/QuartzCore.h>
#include <ApplicationServices/ApplicationServices.h>
#import <WebKit/WebKit.h>

const int kVersion = 89;
const int kDefaultCycleDuration = 5;
const int kPreviewInterval = 10;
const int kMaxDisplays = 16;

int kStopFlickering = 3;
int kStopSolid = 5;
int kFlickerCycle = 7;

const float kSteps = 1/20.0;
const CFStringRef kDisplayBrightness = CFSTR(kIODisplayBrightnessKey);
const char *APP_NAME;

static NSString * const moduleName = @"com.uncover.breathe";



@implementation UncoverSaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    if (self = [super initWithFrame:frame isPreview:isPreview]) {
        imageNum = 0;
        
        // Load defaults
        ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:moduleName];
        
        NSNumber *defaultEffect = [defaults valueForKey:@"effect"];
        if (!defaultEffect)
        {
            [defaults setValue:[NSNumber numberWithInt:kEffectBreathe] forKey:@"effect"];
            effect = kEffectBreathe;
            [defaults synchronize];
        } else
            effect = [defaultEffect intValue];
        
        imagesFolderPath = [defaults valueForKey:@"imagesFolder"];
        LogMessage(@"imagesFolder", 3, @"Image Folder: %@", imagesFolderPath);
        if (imagesFolderPath)
            [self importImagesForFolder:imagesFolderPath];

        NSNumber *numCycleDuration = [defaults valueForKey:@"cycleDuration"];
        if (numCycleDuration)
            cycleDuration = [numCycleDuration intValue];
        else
        {
            cycleDuration = kDefaultCycleDuration;
            [defaults setValue:[NSNumber numberWithInt:cycleDuration] forKey:@"cycleDuration"];
            [defaults synchronize];
        }
        
        LogMessage(@"", 4, @"%@", [NSString stringWithFormat:@"(VER %d) InitWithFrame PREVIEW: %d", kVersion, isPreview]);
        if (isPreview) {
            LogMessage(@"Mode", 4, @"SMALL PREVIEW");
            [self setAnimationTimeInterval:kPreviewInterval];
            [self setupMovie];
        }
        else {
            LogMessage(@"Mode", 4, @"FULL SCREEN");
            [self setAnimationTimeInterval:kSteps];
            [self changeImage];
        }
        [self setWantsLayer:YES];
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
    if (effect == kEffectSpaceInvaders)
        return;
    NSError *error = nil;
    NSBundle *bundle = [NSBundle bundleForClass: [self class]];
    imageNum++;
    if (!imageView)
        imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height)];
    NSString *filePath;
    if ([imagesArray count] > 0)
    {
        // Images from user folder
        (imageNum>=[imagesArray count])?imageNum=0:imageNum;
        filePath = [imagesArray objectAtIndex:imageNum];
    }
    else
    {
        // Local images
        (imageNum>3)?imageNum=1:imageNum;
        filePath = [bundle pathForResource:[NSString stringWithFormat:@"image%d", imageNum]  ofType: @"jpg"];
        LogMessage(@"Image", 4, @"%@", [NSString stringWithFormat:@"FilePath: %@", filePath]);
    }
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePath];
    [imageView setAlphaValue:0.0];
    [imageView setImage:image];
    [imageView setImageScaling:NSScaleToFit];
    [self addSubview:imageView];
    [imageView setWantsLayer:YES];
}

- (void)startAnimation
{
    [super startAnimation];
    startTime = [[NSDate alloc] init];
    LogMessage(@"", 4, @"startAnimation");
    if (![self isPreview]) {
        [self saveDefaultBrightness];
        [self changeImage];
        if (effect == kEffectSpaceInvaders) {
            LogMessage(@"Load", 4, @"Loading space invaders");
            webView = [[WebView alloc] initWithFrame:self.frame frameName:nil groupName:nil];
            [[webView preferences] setPlugInsEnabled:YES];
            [webView setDrawsBackground:NO];
            NSURL *url = [NSURL URLWithString:@"http://www.commodore.ca/arcade/spaceinvaders.swf"];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [self addSubview:webView];
            [[webView mainFrame] loadRequest:request];
        }
    }
}

- (BOOL)enoughTimeFromLastChange
{
    if (!lastChangeTime) {
        lastChangeTime = [[NSDate alloc] init];
        return YES;
    } else {
        float secStarted = [lastChangeTime timeIntervalSinceNow]*-1;
        if (secStarted > (cycleDuration / 10.0)) {
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
    float brightness = [self brightnessForX:secStarted];
    float derivative = [self derivativeForX:secStarted];
    LogMessage(@"Started", 3, @"%@",[NSString stringWithFormat:@"Started: %f Bright: %f Deriv: %f", secStarted, brightness, derivative]);
    if (brightness < 0.5 && derivative > 0 && derivative < 0.1 && [self enoughTimeFromLastChange]) {
        [self changeImage];
    } else {
        if (imageView)
            [imageView setAlphaValue:(brightness)];
        if (webView)
            [webView setAlphaValue:(brightness)];
        if (brightness < 0.1) {
            LogMessage(@"Alpha", 3, @"Setting alpha: %f",brightness);
        } else {
            [self setBrightness:[NSNumber numberWithFloat:brightness]];
        }
    }
}

#pragma mark - Methods to calculate brightness and derivative (given time)

- (float)brightnessForX:(float)secStarted
{
    switch (effect) {
        case kEffectBreathe:
        {
            return (sin(secStarted*MATH_PI/cycleDuration)+1)/2;
            //return ((sin(secStarted*MATH_PI/cycleDuration+asin(defaultBrightness*2-1)))+1)/2;
        }
        case kEffectSpaceInvaders:
        {
            return (sin(secStarted*MATH_PI/cycleDuration)+1)/2;
        }
        case kEffectFlicker:
        {
            if (((int)floor(secStarted) % kFlickerCycle) < kStopFlickering)
                return (arc4random() % 100)/100.0;
            else
                return 1;
        }
        case kEffectFlickerBreathe:
        {
            if (secStarted < kStopFlickering)
                return (arc4random() % 100)/100.0;
            else if (secStarted > kStopFlickering && secStarted < kStopSolid)
                return 1;
            else
                return (cos((secStarted-kStopSolid)*MATH_PI/cycleDuration)+1)/2;
        }
        default:
            break;
    }
}

- (float)derivativeForX:(float)secStarted
{
    switch (effect) {
        case kEffectBreathe:
        {
            return (-cos(secStarted*MATH_PI/cycleDuration));
            //return (cos(secStarted*MATH_PI/cycleDuration)-asin(1-2*defaultBrightness));
        }
        case kEffectSpaceInvaders:
        {
            return (-cos(secStarted*MATH_PI/cycleDuration));
        }
        case kEffectFlicker:
        {
            return 1;
        }
        case kEffectFlickerBreathe:
        {
            if (secStarted < kStopSolid)
                return 1;
            else
                return (-sin((secStarted-kStopSolid)*MATH_PI/cycleDuration));
        }
        default:
            break;
    }
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

- (void)animateOneFrame
{
    if ([self isPreview]) {
        // do nothing
    } else {
        [self brightnessCycle];
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
    LogMessage(@"load", 5, @"configureSheet %@", configureSheet);
    
    if (configureSheet == nil) {
        if ([NSBundle loadNibNamed:@"ConfigureSheet" owner:self])
            LogMessage(@"load", 5, @"nib loaded");

    }
    
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:moduleName];

    // Sets the slider on the configure sheet
    NSNumber *numCycleDuration = [defaults valueForKey:@"cycleDuration"];
    tempCycleDuration = [numCycleDuration floatValue];
    [cycleDurationTextField setTitleWithMnemonic:[NSString stringWithFormat:@"%.0f sec", tempCycleDuration]];
    [breatheDurationSlider setFloatValue:tempCycleDuration];
    [breatheDurationSlider setNeedsDisplay:YES];
    LogMessage(@"parameter", 5, @"durationSlider: %f", breatheDurationSlider.floatValue);
    
    // Images configuresheet parameters
    [imagesNumberTextField setTitleWithMnemonic:[NSString stringWithFormat:@"%d items", [imagesArray count]]];
    [imagesUncoverCell setState:([imagesArray count]>0?0:1)];
    [imagesFolderCell setState:([imagesArray count]>0?1:0)];
    LogMessage(@"imagesFolder", 3, @"Image Folder: %@", imagesFolderPath);
    
    // Sets the button cells on the configuration sheet
    NSNumber *effect = [defaults valueForKey:@"effect"];
    LogMessage(@"parameter", 5, @"Effect: %d", [effect intValue]);
    [breatheCell setState:0];
    [flickerBreatheCell setState:0];
    [flickerCell setState:0];
    [spaceInvadersCell setState:0];
    switch ([effect intValue]) {
        case kEffectBreathe:
            [breatheCell setState:1];
            break;
        case kEffectFlickerBreathe:
            [flickerBreatheCell setState:1];
            break;
        case kEffectFlicker:
            [flickerCell setState:1];
            break;
        case kEffectSpaceInvaders:
            [spaceInvadersCell setState:1];
            break;
        default:
            break;
    }

    return configureSheet;
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
}

- (void)playAgain:(NSNotification*)note
{
    [movie play];
}

#pragma mark - Actions from the configureSheet

// OK button pressed, does save the temporary parameters

- (IBAction)okButtonPressed:(id)sender {
    
    // Saves parameters
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:moduleName];
    [defaults setValue:[NSNumber numberWithFloat:tempCycleDuration] forKey:@"cycleDuration"];
    
    // Effect param
    if ([breatheCell state] == 1)
        [defaults setValue:[NSNumber numberWithInt:kEffectBreathe] forKey:@"effect"];
    else if ([flickerBreatheCell state] == 1)
        [defaults setValue:[NSNumber numberWithInt:kEffectFlickerBreathe] forKey:@"effect"];
    else if ([flickerCell state] == 1)
        [defaults setValue:[NSNumber numberWithInt:kEffectFlicker] forKey:@"effect"];
    else if ([spaceInvadersCell state] == 1)
        [defaults setValue:[NSNumber numberWithInt:kEffectSpaceInvaders] forKey:@"effect"];
    
    // Images source param
    if ([imagesUncoverCell state] == 1) {
        [imagesArray removeAllObjects];
        LogMessage(@"imagesFolder", 3, @"REMOVED");
        [defaults removeObjectForKey:@"imagesFolder"];
    }
    else if ([imagesFolderCell state] == 1 && [imagesArray count] > 0) {
        LogMessage(@"imagesFolder", 3, @"%@", imagesFolderPath);
        [defaults setValue:imagesFolderPath forKey:@"imagesFolder"];
    }
    else {
        [imagesArray removeAllObjects];
        LogMessage(@"imagesFolder", 3, @"REMOVED");
        [defaults removeObjectForKey:@"imagesFolder"];
    }
    
    [defaults synchronize];
    LogMessage(@"Parameter", 3, @"Effect: %d", [[defaults valueForKey:@"effect"] intValue]);
    LogMessage(@"ImageFolder", 3, @"Folder: %@", [defaults valueForKey:@"imagesFolder"]);
    LogMessage(@"Parameter", 3, @"Default cycle duration: %f", tempCycleDuration);
    
    // Close the configureSheet
    [NSApp endSheet:configureSheet];
    configureSheet = nil;
}

// Cancel button pressed, does not save temporary parameters

- (IBAction)cancelButtonPressed:(id)sender {
    [NSApp endSheet:configureSheet];
    configureSheet = nil;
}

// Breathe slider value changed

- (IBAction)breathDurationValueChanged:(id)sender {
    tempCycleDuration = ((NSSlider*)sender).floatValue;
    [cycleDurationTextField setTitleWithMnemonic:[NSString stringWithFormat:@"%.0f sec", tempCycleDuration]];
}

- (IBAction)chooseImagesFolderButtonPressed:(id)sender {
    NSURL *pickedFolder = [self getFolder];
    LogMessage(@"Picked Folder", 3, @"File: %@", [pickedFolder path]);
    [self importImagesForFolder:[pickedFolder path]];
}

# pragma mark - Choose images folder

-(NSURL *)getFolder {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    if ([panel runModal] != NSFileHandlingPanelOKButton) return nil;
    return [[panel URLs] lastObject];
}

- (void)importImagesForFolder:(NSString*)folderPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *direnum = [fileManager enumeratorAtPath:folderPath];
    NSString *tString;

    imagesFolderPath = [folderPath copy];
    imagesArray = [[NSMutableArray alloc] initWithCapacity:1];
    while ((tString = [direnum nextObject] ))
    {
        if ([tString hasSuffix:@".jpg"] || [tString hasSuffix:@".png"] || [tString hasSuffix:@".jpeg"])
        {
            NSString *fileAbsPath = [NSString stringWithFormat:@"%@/%@",folderPath,tString];
            //LogMessage(@"Image", 3, @"File: %@", fileAbsPath);
            [imagesArray addObject:fileAbsPath];
            
        }
    }
    
    // Set radio buttons based on image numbers
    [imagesNumberTextField setTitleWithMnemonic:[NSString stringWithFormat:@"%d items", [imagesArray count]]];
    [imagesUncoverCell setState:([imagesArray count]>0?0:1)];
    [imagesFolderCell setState:([imagesArray count]>0?1:0)];
}

@end
