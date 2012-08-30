//
//  AdsViewController.h
//  MiKey
//
//  Created by Seng Hin Mak on 23/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AdsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)tappedClose:(id)sender;

- (id)initWithImagePath:(NSString *)imagePath;

@end
