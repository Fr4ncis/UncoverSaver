//
//  AppDelegate.m
//  Breathe
//
//  Created by Francesco Mattia on 10/22/12.
//  Copyright (c) 2012 Uncover. All rights reserved.
//

#import "AppDelegate.h"
#import "FullScreenWindow.h"
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

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self loadConfiguration];
    [self saveDefaultBrightness];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullscreenWindowClosed) name:@"closeFullScreenView" object:nil];
    [NSApp setDelegate:self];
}

- (void)loadEffectFromDefaults:(NSUserDefaults *)defaults
{
    NSNumber *defaultEffect = [defaults valueForKey:@"effect"];
    if (!defaultEffect)
    {
        [defaults setValue:[NSNumber numberWithInt:kEffectBreathe] forKey:@"effect"];
        effect = kEffectBreathe;
        [defaults synchronize];
    } else
        effect = [defaultEffect intValue];
    LogMessage(@"Effect:", 3, @"Effect: %d", effect);
    
    // Sets the button cells on the configuration sheet
    LogMessage(@"parameter", 5, @"Effect: %d", effect);
    [breatheCell setState:0];
    [flickerBreatheCell setState:0];
    [flickerCell setState:0];
    [spaceInvadersCell setState:0];
    switch (effect) {
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
}

- (void)loadImageFromDefaults:(NSUserDefaults *)defaults
{
    imagesFolderPath = [defaults valueForKey:@"imagesFolder"];
    LogMessage(@"imagesFolder", 3, @"Image Folder: %@", imagesFolderPath);
    if (imagesFolderPath)
        [self importImagesForFolder:imagesFolderPath];
    
    // Images configuresheet parameters
    [imagesNumberTextField setTitleWithMnemonic:[NSString stringWithFormat:@"%ld items", [imagesArray count]]];
    [imagesUncoverCell setState:([imagesArray count]>0?0:1)];
    [imagesFolderCell setState:([imagesArray count]>0?1:0)];
}

- (void)loadCycleDurationFromDefaults:(NSUserDefaults *)defaults
{
    // cycleDuration
    
    NSNumber *numCycleDuration = [defaults valueForKey:@"cycleDuration"];
    if (numCycleDuration)
        cycleDuration = [numCycleDuration floatValue];
    else
    {
        cycleDuration = kDefaultCycleDuration;
        [defaults setValue:[NSNumber numberWithInt:cycleDuration] forKey:@"cycleDuration"];
        [defaults synchronize];
    }
    
    // Sets the slider on the configure sheet
    [cycleDurationTextField setTitleWithMnemonic:[NSString stringWithFormat:@"%.0f sec", cycleDuration]];
    [breatheDurationSlider setFloatValue:cycleDuration];
    [breatheDurationSlider setNeedsDisplay:YES];
    LogMessage(@"parameter", 5, @"durationSlider: %f", breatheDurationSlider.floatValue);
}

- (void)loadConfiguration
{
    imageNum = 0;
    
    // Load defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [self loadEffectFromDefaults:defaults];
    [self loadImageFromDefaults:defaults];
    [self loadCycleDurationFromDefaults:defaults];
}

- (void)changeImage
{
    if (effect == kEffectSpaceInvaders)
        return;
    NSError *error = nil;
    NSBundle *bundle = [NSBundle bundleForClass: [self class]];
    imageNum++;
    if (!imageView) {
        NSRect mainDisplayRect = [[NSScreen mainScreen] frame];
        imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, mainDisplayRect.size.width, mainDisplayRect.size.height)];
        NSView *blackView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, mainDisplayRect.size.width, mainDisplayRect.size.height)];
        CALayer *viewLayer = [CALayer layer];
        [viewLayer setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0)]; //RGB plus Alpha Channel
        [blackView setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
        [blackView setLayer:viewLayer];
        [blackView addSubview:imageView];
        [fullScreenWindow setContentView:blackView];
        [fullScreenWindow makeKeyAndOrderFront:self];
    }
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
        //LogMessage(@"Image", 4, @"%@", [NSString stringWithFormat:@"FilePath: %@", filePath]);
    }
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePath];
    [imageView setAlphaValue:0.0];
    [imageView setImage:image];
    [imageView setImageScaling:NSScaleToFit];
    [imageView setWantsLayer:YES];
    [imageView setNeedsDisplay:YES];
}

- (void)startAnimation
{
    startTime = [[NSDate alloc] init];
    LogMessage(@"", 4, @"startAnimation");
    [self saveDefaultBrightness];
    [self changeImage];
    if (effect == kEffectSpaceInvaders) {
        LogMessage(@"Load", 4, @"Loading space invaders");
        NSRect mainDisplayRect = [[NSScreen mainScreen] frame];
        NSView *blackView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, mainDisplayRect.size.width, mainDisplayRect.size.height)];
        CALayer *viewLayer = [CALayer layer];
        [viewLayer setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0)]; //RGB plus Alpha Channel
        [blackView setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
        [blackView setLayer:viewLayer];
        webView = [[WebView alloc] initWithFrame:CGRectMake(0, 0, mainDisplayRect.size.width, mainDisplayRect.size.height) frameName:nil groupName:nil];
        [[webView preferences] setPlugInsEnabled:YES];
        [webView setDrawsBackground:NO];
        [blackView addSubview:webView];
        NSURL *url = [NSURL URLWithString:@"http://www.commodore.ca/arcade/spaceinvaders.swf"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [fullScreenWindow setContentView:blackView];
        [fullScreenWindow makeKeyAndOrderFront:nil];
        [[webView mainFrame] loadRequest:request];
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
    //LogMessage(@"Started", 3, @"%@",[NSString stringWithFormat:@"Started: %f Bright: %f Deriv: %f", secStarted, brightness, derivative]);
    if (brightness < 0.5 && derivative > 0 && derivative < 0.1 && [self enoughTimeFromLastChange]) {
        [self changeImage];
    } else {
        if (imageView)
            [imageView setAlphaValue:(brightness)];
        if (webView)
            [webView setAlphaValue:(brightness)];
        if (brightness < 0.1) {
            //LogMessage(@"Alpha", 3, @"Setting alpha: %f",brightness);
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
            return (sin(secStarted*M_PI/cycleDuration)+1)/2;
            //return ((sin(secStarted*MATH_PI/cycleDuration+asin(defaultBrightness*2-1)))+1)/2;
        }
        case kEffectSpaceInvaders:
        {
            return (sin(secStarted*M_PI/cycleDuration)+1)/2;
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
                return (cos((secStarted-kStopSolid)*M_PI/cycleDuration)+1)/2;
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
            return (-cos(secStarted*M_PI/cycleDuration));
            //return (cos(secStarted*MATH_PI/cycleDuration)-asin(1-2*defaultBrightness));
        }
        case kEffectSpaceInvaders:
        {
            return (-cos(secStarted*M_PI/cycleDuration));
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
                return (-sin((secStarted-kStopSolid)*M_PI/cycleDuration));
        }
        default:
            break;
    }
}

- (void)stopAnimation
{
    LogMessage(@"", 4, @"stopAnimation");
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
    [self brightnessCycle];
    if ([fullScreenWindow isVisible]) {
        [self performSelector:@selector(animateOneFrame) withObject:nil afterDelay:kSteps];
    } else {
        [self stopAnimation];
    }
}

- (BOOL)hasConfigureSheet
{
    LogMessage(@"", 5, @"hasConfigureSheet");
    return YES;
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

#pragma mark - Actions from the configureSheet

- (IBAction)startButtonPressed:(id)sender {
    
    NSRect mainDisplayRect = [[NSScreen mainScreen] frame];
    [self loadConfiguration];
    
    LogMessage(@"fullScreenWindow", 3, @"%@", fullScreenWindow);
    if (!fullScreenWindow) {
        fullScreenWindow = [[FullScreenWindow alloc] initWithContentRect:mainDisplayRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        
        [fullScreenWindow setLevel:NSMainMenuWindowLevel+1];
        [fullScreenWindow setReleasedWhenClosed:NO];
        [fullScreenWindow setOpaque:YES];
        [fullScreenWindow setHidesOnDeactivate:YES];
        [fullScreenWindow makeFirstResponder:nil];
    } else {
        [fullScreenWindow makeKeyAndOrderFront:nil];
        [fullScreenWindow makeFirstResponder:nil];
    }
    
    LogMessage(@"Effect", 3, @"Effect: %d", effect);
    LogMessage(@"Folder", 3, @"Folder: %@", imagesFolderPath);
    
    [self startAnimation];
    
    [self performSelector:@selector(animateOneFrame) withObject:nil afterDelay:kSteps];
}

// Any of the parameters changed

- (IBAction)breatheDurationCycleParameterChanged:(id)sender
{
    cycleDuration = ((NSSlider*)sender).floatValue;
    [cycleDurationTextField setTitleWithMnemonic:[NSString stringWithFormat:@"%.0f sec", cycleDuration]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setValue:[NSNumber numberWithFloat:cycleDuration] forKey:@"cycleDuration"];

    [defaults synchronize];
}

- (IBAction)effectParameterChanged:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSUInteger chosenEffect = (((NSMatrix*)sender).selectedRow)+1;
    //effect = (kEffect)chosenEffect;
    [defaults setValue:[NSNumber numberWithInteger:chosenEffect] forKey:@"effect"];

    [defaults synchronize];
    
    LogMessage(@"effect", 2, @"%@", [defaults valueForKey:@"effect"]);
}

- (IBAction)imageSourceParameterChanged:(id)sender
{
    if (!sender)
        sender = _imageSourceMatrix;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSUInteger chosenCell = (((NSMatrix*)sender).selectedRow);
    LogMessage(@"Cell", 3, @"%d", _imageSourceMatrix.selectedRow);

    [self importImagesForFolder:imagesFolderPath];
    
    // Images source param
    if (chosenCell == 0) {
        [imagesArray removeAllObjects];
        LogMessage(@"imagesFolder", 3, @"Removed");
        [defaults removeObjectForKey:@"imagesFolder"];
    }
    else if (chosenCell == 1 && [imagesArray count] > 0) {
        LogMessage(@"imagesFolder", 3, @"%@", imagesFolderPath);
        [defaults setValue:imagesFolderPath forKey:@"imagesFolder"];
    }
    else {
        [imagesArray removeAllObjects];
        LogMessage(@"imagesFolder", 3, @"Removed");
        [defaults removeObjectForKey:@"imagesFolder"];
    }
    
    [defaults synchronize];
}

- (IBAction)chooseImagesFolderButtonPressed:(id)sender {
    NSURL *pickedFolder = [self getFolder];
    LogMessage(@"Picked Folder", 3, @"File: %@", [pickedFolder path]);
    [self importImagesForFolder:[pickedFolder path]];
    [self imageSourceParameterChanged:nil];
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

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self setBrightness:[NSNumber numberWithFloat:defaultBrightness]];
}

- (void)fullscreenWindowClosed
{
    [fullScreenWindow close];
    //fullScreenWindow = nil;
}

@end