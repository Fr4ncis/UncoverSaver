//
//  UncoverSaverView.h
//  UncoverSaver
//
//  Created by Francesco Mattia on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import <QTKit/QTKit.h>

@interface UncoverSaverView : ScreenSaverView {
    NSDate *startTime;
    float defaultBrightness;
    float normalizeOffset;
    BOOL upwards;
    
    QTMovie *movie;
}

- (void)setBrightness:(NSNumber*)brightness;
- (void)saveDefaultBrightness;
- (float)getBrightness;

@end
