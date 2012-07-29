//
//  DalekSingAlongAppDelegate.h
//
//  Created by Chris Adamson on 4/13/10.
//  Copyright Subsequently and Furthermore, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DalekSingAlongViewController;

@interface DalekSingAlongAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    DalekSingAlongViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet DalekSingAlongViewController *viewController;

@end

