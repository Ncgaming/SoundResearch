//
//  Document.m
//  MiKey
//
//  Created by Seng Hin Mak on 23/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import "Document.h"
#import "PathHelper.h"

@implementation Document

+ (NSString *)documentsDirectory 
{
    return [PathHelper documentsDirectory];
}


@end
