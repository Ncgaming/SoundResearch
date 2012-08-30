//
//  SKProduct+LocalizedPrice.h
//  MiKey
//
//  Created by Ncgaming on 22/8/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SKProduct (LocalizedPrice)

@property (nonatomic, readonly) NSString *localizedPrice;

@end
