//
//  WebViewController.h
//  MiKey
//
//  Created by Seng Hin Mak on 16/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webview;

- (id)initWithHTMLNamed:(NSString*)filename;

- (id)initWithWebURL:(NSURL*)url;

@end
