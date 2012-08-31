//
//  MainViewController.h
//  BeOthers
//
//  Created by Ncgaming on 30/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@class RootViewController;


@interface MainViewController : UIViewController<AVAudioRecorderDelegate>
@property(nonatomic, strong) RootViewController *rootViewController;
@property (retain, nonatomic) IBOutlet UIButton *playbtn;
@property (retain, nonatomic) IBOutlet UIButton *recordbtn;
- (IBAction)tappedPlay:(id)sender;
- (IBAction)tappedRecord:(id)sender;
@end
