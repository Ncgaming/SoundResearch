//
//  NetworkContents.h
//  MiKey
//
//  Created by Seng Hin Mak on 23/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkContents : NSObject


+ (void)checkNewZipFile;

+ (void)downloadZipFileFromPath:(NSString*)webPath;

+ (void)queryContentVersionCompleted:(void (^)(int version, NSString *zipPath))block;

@end
