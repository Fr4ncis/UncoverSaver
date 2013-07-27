//
//  UBButton.m
//  Breathe
//
//  Created by Francesco Mattia on 6/26/13.
//  Copyright (c) 2013 Uncover. All rights reserved.
//

#import "UBButton.h"
#import "NSButton+TextColor.h"
#import <QuartzCore/QuartzCore.h>


@implementation UBButton

- (void)awakeFromNib
{
    [self setWantsLayer:YES];
    [self setTextColor:[NSColor whiteColor]];
    [[self cell] setBackgroundColor:NSColorFromRGB(0x02736b)];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [[[self animator] cell] setBackgroundColor:NSColorFromRGB(0x01544e)];
    CABasicAnimation* pulseAnimation = [CABasicAnimation animation];
    pulseAnimation.keyPath = @"opacity";
    pulseAnimation.fromValue = @1.0f;
    pulseAnimation.toValue = @0.5f;
    pulseAnimation.duration = 1.0f;
    pulseAnimation.repeatCount = 100;
    pulseAnimation.autoreverses = YES;
    [self.layer addAnimation:pulseAnimation forKey:@"pulseAnimation"];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [[self cell] setBackgroundColor:NSColorFromRGB(0x02736b)];
    [self.layer removeAnimationForKey:@"pulseAnimation"];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [[self cell] setBackgroundColor:NSColorFromRGB(0x03ab9f)];
    [super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [[[self animator] cell] setBackgroundColor:NSColorFromRGB(0x02736b)];
    [super mouseUp:theEvent];
}

-(void)updateTrackingAreas
{
    if ([self.trackingAreas count] == 0)
    {
        int options = (NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways);
        NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                            options:options
                                                              owner:self
                                                           userInfo:nil];
        [self addTrackingArea:area];
    }
}

@end
