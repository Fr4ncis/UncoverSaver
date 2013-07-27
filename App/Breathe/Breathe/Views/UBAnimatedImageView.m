//
//  UBAnimatedImageView.m
//  Breathe
//
//  Created by Francesco Mattia on 7/4/13.
//  Copyright (c) 2013 Uncover. All rights reserved.
//

#import "UBAnimatedImageView.h"

@implementation UBAnimatedImageView
@synthesize framesPerSecond;

-(void)awakeFromNib
{
    [super awakeFromNib];
    introImages = [[NSMutableArray alloc] initWithCapacity:83];
    images = [[NSMutableArray alloc] initWithCapacity:388];
    framesPerSecond = 20.0;
    for (int i = 0; i < 83; i++)
    {
        [introImages addObject:[NSString stringWithFormat:@"uncover_intro%04d",i]];
    }
    for (int i = 0; i < 388; i++)
    {
        [images addObject:[NSString stringWithFormat:@"uncoverfade%04d",i]];
    }
    [self setWantsLayer:YES];
}

-(void)startAnimation
{
    self.layer.contents = [NSImage imageNamed:[introImages objectAtIndex:0]];
    [self performSelector:@selector(nextImage:) withObject:nil afterDelay:1/20.0];
    animationIndex = 0;
    introIndex = 0;
}

-(void)stopAnimation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.layer.contents = [NSImage imageNamed:@"uncover_intro0000"];
}

-(void)nextImage:(id)sender
{
    if (introIndex < [introImages count]-1)
    {
        introIndex++;
        self.layer.contents = [NSImage imageNamed:[introImages objectAtIndex:introIndex]];
        [self setNeedsDisplay:YES];
        [self performSelector:@selector(nextImage:) withObject:nil afterDelay:1/20.0];
    }
    else
    {
        if (animationIndex < [images count]-2)
            animationIndex++;
        else
            animationIndex = 0;
        self.layer.contents = [NSImage imageNamed:[images objectAtIndex:animationIndex]];
        [self setNeedsDisplay:YES];
        [self performSelector:@selector(nextImage:) withObject:nil afterDelay:1/framesPerSecond];
    }
}

@end
