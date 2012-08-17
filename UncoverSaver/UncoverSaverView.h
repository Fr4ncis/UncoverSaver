//
//  UncoverSaverView.h
//  UncoverSaver
//
//  Created by Francesco Mattia on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>

@interface UncoverSaverView : ScreenSaverView {
    float defaultBrightness;
    BOOL upwards;
}

- (void)setBrightness:(NSNumber*)brightness;
- (void)saveDefaultBrightness;
- (float)getBrightness;

@end
