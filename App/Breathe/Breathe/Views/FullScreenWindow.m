//
//  FullScreenWindow.m
//  Breathe
//
//  Created by Francesco Mattia on 10/23/12.
//  Copyright (c) 2012 Uncover. All rights reserved.
//

#import "FullScreenWindow.h"
#import "LoggerClient.h"
#import "LoggerCommon.h"

@implementation FullScreenWindow

+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}

- (id)init
{
    NSRect mainDisplayRect = [[NSScreen mainScreen] frame];
    if (self = [self initWithContentRect:mainDisplayRect
                                styleMask:NSBorderlessWindowMask
                                  backing:NSBackingStoreBuffered
                                    defer:NO])
    {
        
    }
    return self;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])
    {
        [self setReleasedWhenClosed:NO];
        [self setOpaque:YES];
        [self setHidesOnDeactivate:NO];
        [self setLevel:NSMainMenuWindowLevel+1];
    }
    return self;
}

- (void)sendEvent:(NSEvent *)theEvent
{
    if (([theEvent type]==NSKeyDown) && ([theEvent keyCode] == 53))
    {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"closeFullScreenView"
         object:self];
        LogMessage(@"ESC",2,@"Escape pressed");
    }
    
    [super sendEvent:theEvent];
}

- (void)cancelOperation:(id)sender
{
    LogMessage(@"ESC",2,@"Escape pressed");
}

- (void)keyUp:(NSEvent *)theEvent
{
    LogMessage(@"ESC",2,@"Event: %@", theEvent);
}

- (void)keyDown:(NSEvent *)theEvent
{
    LogMessage(@"ESC",2,@"Event: %@", theEvent);
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

@end
