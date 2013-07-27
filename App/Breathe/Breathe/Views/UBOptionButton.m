//
//  UBOptionButton.m
//  Breathe
//
//  Created by Francesco Mattia on 6/29/13.
//  Copyright (c) 2013 Uncover. All rights reserved.
//

#import "UBOptionButton.h"
#import "NSButton+TextColor.h"
#import <QuartzCore/QuartzCore.h>

@implementation UBOptionButton
@synthesize selected;

- (void)awakeFromNib
{
    [self setWantsLayer:YES];
    [self setTextColor:[NSColor whiteColor]];
    [self setDefaultColor];
    
//    CIFilter *filter = [CIFilter filterWithName:@"CIFalseColor"];
//    [filter setDefaults];
//    [filter setValue:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0] forKey:@"inputColor0"];
//    [filter setValue:[CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forKey:@"inputColor1"];
//    [filter setName:@"pulseFilter"];
//    [[self layer] setFilters:[NSArray arrayWithObject:filter]];
//    
//    CABasicAnimation* pulseAnimation = [CABasicAnimation animation];
//    pulseAnimation.keyPath = @"filters.pulseFilter.inputColor1";
//    pulseAnimation.fromValue = [CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
//    pulseAnimation.toValue = [CIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0];
//    pulseAnimation.duration = 5;
//    pulseAnimation.repeatCount = 100;
//    pulseAnimation.autoreverses = YES;
//    
//    [[self layer] addAnimation:pulseAnimation forKey:@"pulseAnimation"];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    
    [[self cell] setBackgroundColor:NSColorFromRGB(0x025953)];
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
    [self setDefaultColor];
    [self.layer removeAnimationForKey:@"pulseAnimation"];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    [self setDefaultColor];
}

- (void)setDefaultColor
{
    if (selected)
        [[self cell] setBackgroundColor:NSColorFromRGB(0x01544e)];
    else
        [[self cell] setBackgroundColor:NSColorFromRGB(0x02736b)];
}

- (void)setSelected:(BOOL)_selected
{
    self->selected = _selected;
    [self setDefaultColor];
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
