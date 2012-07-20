//
//  record_audio_testAppDelegate.h
//  record_audio_test
//
//  Created by jinhu zhang on 11-1-5.
//  Copyright 2011 no. All rights reserved.
//

#import <UIKit/UIKit.h>

@class record_audio_testViewController;

@interface record_audio_testAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    record_audio_testViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet record_audio_testViewController *viewController;

@end

