//
//  WebViewController.m
//  MiKey
//
//  Created by Seng Hin Mak on 16/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import "WebViewController.h"
#import "Document.h"
#import "PathHelper.h"
#import "ColorHelper.h"
#import "CustomizeViewHelper.h"
#import "marcoHelper.h"

@interface WebViewController ()
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSURL *webURL;
@end

@implementation WebViewController
@synthesize webview;
@synthesize filename = _filename;
@synthesize webURL = _webURL;

- (id)initWithHTMLNamed:(NSString*)filename
{
    self = [self initWithNibName:@"WebViewController" bundle:nil];
    if (self) {
        // Custom initialization      
        
        // if the filename contains .html, we want to remove it for consistence
        filename = [filename stringByReplacingOccurrencesOfString:@".html" withString:@""];
        
        self.filename = filename;
        if([filename isEqualToString:@"disclaimer"])
        {
            //title - label
//            [self.navigationItem setTitleView:[CustomizeViewHelper titleLabel:@"Disclaimer" color:[ColorHelper colorWithHexString:@"efe3d9"] fontName:@"Berthold Akzidenz Grotesk BE" fontSize:22 backgroundColor:[UIColor clearColor]]];
        }
        
        DLog(@"[WebViewController] filename %@",filename);
    }
    return self;
}

- (id)initWithWebURL:(NSURL*)url
{
    self = [self initWithNibName:@"WebViewController" bundle:nil];
    if (self) {
        // Custom initialization        
        self.webURL = url;
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
    self.webview.backgroundColor = [UIColor clearColor];
    [self.webview setOpaque:NO];
    
    
    // Do any additional setup after loading the view from its nib.
    
    //customize right button
//    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:[CustomizeViewHelper closeButton:self imageName:@"close-button" pressedImageName:nil]];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(close)];
    self.navigationItem.rightBarButtonItem = rightButton;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
    
    
    //left button
//    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithCustomView:[CustomizeViewHelper backButton:self imageName:@"back-back.png" pressedImageName:nil]];    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(back)];

    self.navigationItem.backBarButtonItem = leftButton;
    self.navigationItem.backBarButtonItem.tintColor = [UIColor blackColor];
        
    // remove the shadow
    for(UIView *wview in [[[webview subviews] objectAtIndex:0] subviews]) { 
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; } 
    }
    
    
    NSString *downloadedFilePath = [[Document documentsDirectory]
                         stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.html", self.filename]];
    
    // this class may load web URL or local html file. But not both.
    if (self.webURL == nil)
    {
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:downloadedFilePath];
        if (fileExists)
        {
            DLog(@"downloaded file exists. loading: %@", downloadedFilePath);
            [webview loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:downloadedFilePath]]];
        }
        else {
            DLog(@"loading default %@.html", self.filename);
            [webview loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:self.filename ofType:@"html"] 
                                                                         isDirectory:NO]]];
        }
    }
    else
    {
        [webview loadRequest:[NSURLRequest requestWithURL:self.webURL]];
    }
    
        
}

- (void)close 
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];  
}

- (void)viewDidUnload
{
    [self setWebview:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark -
#pragma mark WebView Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    
    NSString *requestFilename = [PathHelper filenameFromPath:request.URL.absoluteString];
    
    NSString *selfFilenameFull = [NSString stringWithFormat:@"%@.html", self.filename];
    
    // Determine if we want the system to handle it.
    NSURL *url = request.URL;
    
    // if it is self loading, pass it.
    if ([url.absoluteString isEqualToString:self.webURL.absoluteString])
    {
        DLog(@"%@ self loading web URL: %@", self, url);
        return YES;
    }
    
    // if it is self loading, pass it.
    if ([requestFilename isEqualToString:selfFilenameFull])
    {
        DLog(@"%@ self loading file: %@", self, selfFilenameFull);
        return YES;
    }    
    
    if ([url.scheme isEqual:@"http"] || [url.scheme isEqual:@"https"]) {
        DLog(@"YES, it is a url. load it. %@", url);
        WebViewController *webVC = [[WebViewController alloc] initWithWebURL:url];
        [self.navigationController pushViewController:webVC animated:YES];
        
        // don't know why return NO does not stop current webview loading it. so need manually stop.
        [webView stopLoading];
        
        return NO;
    }
    else if ([url.scheme isEqual:@"file"])
    {
        DLog(@"Yes, it is a file. load it: %@", requestFilename);
        WebViewController *webVC = [[WebViewController alloc] initWithHTMLNamed:requestFilename];
        [self.navigationController pushViewController:webVC animated:YES];
        
        // don't know why return NO does not stop current webview loading it. so need manually stop.
        [webView stopLoading];
        
        return NO;
    }
    else
    {
        DLog(@"Yes, it is something else, just load it.");
        if ([[UIApplication sharedApplication]canOpenURL:url]) {
            [[UIApplication sharedApplication]openURL:url];
            
            // don't know why return NO does not stop current webview loading it. so need manually stop.
            [webView stopLoading];
            
            return NO;
        }
    }
    
    DLog(@"%@ here?", self);
    return YES;
}


@end
