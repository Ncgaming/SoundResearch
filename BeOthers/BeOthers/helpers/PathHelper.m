//
//  PathHelper.m
//  MiKey
//
//  Created by Seng Hin Mak on 23/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import "PathHelper.h"

@implementation PathHelper

+ (NSString *)documentsDirectory 
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString *)filenameFromPath:(NSString*)path
{
    NSArray *parts = [path componentsSeparatedByString:@"/"];
    return [parts objectAtIndex:[parts count]-1];
}

@end
