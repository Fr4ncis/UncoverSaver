//
//  UBAnimatedImageView.h
//  Breathe
//
//  Created by Francesco Mattia on 7/4/13.
//  Copyright (c) 2013 Uncover. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UBAnimatedImageView : NSImageView {
    NSMutableArray *images;
    NSMutableArray *introImages;
    int    introIndex;
    int    animationIndex;
}

@property (nonatomic, assign) float framesPerSecond;

-(void)startAnimation;
-(void)stopAnimation;

@end
