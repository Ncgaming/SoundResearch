//
//  InAppPurchaseManager.h
//  MiKey
//
//  Created by Ncgaming on 22/8/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#define kInAppPurchaseManagerTransactionFailed @"kInAppPurchaseManagerTransactionFailed"

#define kInAppPurchaseManagerProductsFetchedNotification @"kInAppPurchaseManagerProductsFetchedNotification"
#define kInAppPurchaseManagerProductsFailedNotification @"kInAppPurchaseManagerProductsFailedNotification"
#define kInAppPurchaseManagerTransactionFailedNotification @"kInAppPurchaseManagerTransactionFailedNotification"
#define kInAppPurchaseManagerTransactionSucceededNotification @"kInAppPurchaseManagerTransactionSucceededNotification"


@interface InAppPurchaseManager : NSObject<SKProductsRequestDelegate,SKPaymentTransactionObserver>
{
    SKProduct *proUpgradeProduct;
    SKProductsRequest *productsRequest;
}

+(InAppPurchaseManager*)get;
// public methods
- (void)loadStore;
- (BOOL)canMakePurchases;
- (void)purchaseUkulele;
- (void)purchaseStarterPack;
@end
