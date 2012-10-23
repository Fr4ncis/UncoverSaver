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
