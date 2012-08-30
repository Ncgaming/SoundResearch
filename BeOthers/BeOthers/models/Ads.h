//
//  Ads.h
//  MiKey
//
//  Created by Seng Hin Mak on 23/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Ads : NSObject

+ (void)requestToShowAds;

+ (void)queryAdsVersionCompleted:(void (^)(int version, NSString *imagePath))block;

@end
