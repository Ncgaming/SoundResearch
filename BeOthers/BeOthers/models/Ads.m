//
//  Ads.m
//  MiKey
//
//  Created by Seng Hin Mak on 23/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import "Ads.h"
#import "AFHTTPClient.h"
#import "NSString+SBJSON.h"
#import "AdsViewController.h"
#import "NetworkConfiguration.h"
#import "marcoHelper.h"

#define requestCountKey @"requestCount"

@implementation Ads 

+ (void)requestToShowAds
{
    int requestCount = [[NSUserDefaults standardUserDefaults] integerForKey:requestCountKey];
    
    DLog(@"request count: %d", requestCount);

    [[NSUserDefaults standardUserDefaults] setInteger:requestCount+1 forKey:requestCountKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // we do not request and show ads on first few times.
    if (requestCount < 4) return;
    

    
    [self queryAdsVersionCompleted:^(int version, NSString *imagePath) {
        DLog(@"latest ads version: %d", version);
        int lastShownVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastShownVersion"];
        DLog(@"saved ads version: %d", lastShownVersion);
        if (version > lastShownVersion)
        {
            DLog(@"Please query the ads and show.");
            
            DLog(@"image path? %@", imagePath);
            
            AdsViewController *adsVC = [[AdsViewController alloc] initWithImagePath:imagePath];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:adsVC animated:NO];
            
            
            [[NSUserDefaults standardUserDefaults] setInteger:version forKey:@"lastShownVersion"];
			[[NSUserDefaults standardUserDefaults] synchronize];
        }
    }];
}

+ (void)queryAdsVersionCompleted:(void (^)(int version, NSString *imagePath))block
{
    NSURL *baseURL = [NSURL URLWithString:BASE_URL];
    
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:baseURL];
    [client getPath:ADS_VERSION parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *responseStr = [NSString stringWithUTF8String:[responseObject bytes]];
        DLog(@"%@", responseStr);
        NSDictionary *response = [responseStr JSONValue];
        DLog(@"%@", response);
        DLog(@"%@", [response objectForKey:@"image_url"]);
        block([[response objectForKey:@"version"] intValue], [response objectForKey:@"image_url"]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"Error fetching ad information. Error: %@", error);
    }];    
}



@end
