//
//  AUPassThroughWithDalekEffectAppDelegate.h
//
//  Created by Chris Adamson on 3/21/10.
//  Copyright Subsequently and Furthermore, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AUPassThroughWithDalekEffectViewController;

@interface AUPassThroughWithDalekEffectAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    AUPassThroughWithDalekEffectViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet AUPassThroughWithDalekEffectViewController *viewController;

@end

