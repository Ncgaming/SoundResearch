//
//  Document.h
//  MiKey
//
//  Created by Seng Hin Mak on 23/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Document : NSObject


// going to be removed and please use [PathHelper documentsDirectory] instead.
// @deprecated
+ (NSString *)documentsDirectory;

@end
