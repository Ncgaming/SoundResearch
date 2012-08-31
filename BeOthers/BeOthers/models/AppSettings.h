//
//  AppSettings.h
//  MiKey
//
//  Created by Seng Hin Mak on 18/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <Foundation/Foundation.h>






@interface AppSettings : NSObject
@property (nonatomic) int totalFileNum;
// shorthand of sharedAppSetting singleton instance
+(AppSettings*)get;

@end
