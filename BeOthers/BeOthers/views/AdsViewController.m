//
//  AdsViewController.m
//  MiKey
//
//  Created by Seng Hin Mak on 23/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import "AdsViewController.h"
#import "UIImageView+AFNetworking.h"
#import "marcoHelper.h"
#import "NetworkConfiguration.h"

@interface AdsViewController ()
@property (nonatomic, strong) NSString *imagePath;
@end

@implementation AdsViewController
@synthesize imageView;
@synthesize imagePath = _imagePath;

- (id)initWithImagePath:(NSString *)imagePath
{
    self = [self initWithNibName:@"AdsViewController" bundle:nil];
    if (self) {
        self.imagePath = imagePath;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (self.imagePath != nil)
    {
        DLog(@"showing image ads from %@.", self.imagePath);
        [imageView setImageWithURL:[NSURL URLWithString:self.imagePath]];
    }
    
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)tappedClose:(id)sender {
    [self dismissModalViewControllerAnimated:NO];
}
@end
