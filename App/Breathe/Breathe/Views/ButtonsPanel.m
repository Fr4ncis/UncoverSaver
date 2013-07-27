//
//  ButtonsPanel.m
//  Breathe
//
//  Created by Francesco Mattia on 4/23/13.
//  Copyright (c) 2013 Uncover. All rights reserved.
//

#import "ButtonsPanel.h"

@implementation ButtonsPanel

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    [NSColorFromRGB(0x3f8981) setFill];
    NSRectFill(dirtyRect);
}

@end
