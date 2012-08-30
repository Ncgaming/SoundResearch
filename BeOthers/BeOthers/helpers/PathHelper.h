//
//  PathHelper.h
//  MiKey
//
//  Created by Seng Hin Mak on 23/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PathHelper : NSObject

+ (NSString *)documentsDirectory;

+ (NSString *)filenameFromPath:(NSString*)path;
@end
