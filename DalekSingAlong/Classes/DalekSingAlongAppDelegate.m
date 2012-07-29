//
//  DalekSingAlongAppDelegate.m
//
//  Created by Chris Adamson on 4/13/10.
//  Copyright Subsequently and Furthermore, Inc. 2010. All rights reserved.
//

#import "DalekSingAlongAppDelegate.h"
#import "DalekSingAlongViewController.h"

@implementation DalekSingAlongAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
