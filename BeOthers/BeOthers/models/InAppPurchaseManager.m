//
//  InAppPurchaseManager.m
//  MiKey
//
//  Created by Ncgaming on 22/8/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import "InAppPurchaseManager.h"
#import "SynthesizeSingleton.h"
#import "AppSettings.h"
#import "marcoHelper.h"

#define kInAppPurchaseUkulele @"jamnukulele"
#define kInAppPurchaseStarterPack @"jamnstarterpack"

@implementation InAppPurchaseManager

SYNTHESIZE_SINGLETON_FOR_CLASS(InAppPurchaseManager)

+(InAppPurchaseManager*)get 
{
return [InAppPurchaseManager sharedInAppPurchaseManager];
}

- (void)requestUkuleleProductData
{
    NSSet *productIdentifiers = [NSSet setWithObject:@"jamnukulele" ];
    productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
    
    // we will release the request object in the delegate callback
}

-(void)requestStarterPackProductData
{
    NSSet *productIdentifiers = [NSSet setWithObject:@"jamnstarterpack" ];
    productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
}

//
// call this method once on startup
//
- (void)loadStore
{
    // restarts any purchases if they were interrupted last time the app was open
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    // get the product description (defined in early sections)
    [self requestUkuleleProductData];
    [self requestStarterPackProductData];
}

//
// call this before making a purchase
//
- (BOOL)canMakePurchases
{
    return [SKPaymentQueue canMakePayments];
}

//
// kick off the upgrade transaction
//
- (void)purchaseUkulele
{    
    // get the product description (defined in early sections)
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:kInAppPurchaseUkulele];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)purchaseStarterPack
{
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:kInAppPurchaseStarterPack];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma -
#pragma Purchase helpers

//
// saves a record of the transaction by storing the receipt to disk
//
- (void)recordTransaction:(SKPaymentTransaction *)transaction
{
    if ([transaction.payment.productIdentifier isEqualToString:kInAppPurchaseUkulele])
    {
        // save the transaction receipt to disk
        [[NSUserDefaults standardUserDefaults] setValue:transaction.transactionReceipt forKey:@"ukuleleTransactionReceipt" ];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if ([transaction.payment.productIdentifier isEqualToString:kInAppPurchaseStarterPack])
    {
        // save the transaction receipt to disk
        [[NSUserDefaults standardUserDefaults] setValue:transaction.transactionReceipt forKey:@"starterPackTransactionReceipt" ];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

}

//
// enable pro features
//
- (void)provideContent:(NSString *)productId
{
    if ([productId isEqualToString:kInAppPurchaseUkulele])
    {
        [AppSettings get].hasPurchasedUkulele = YES;
    }
    else if ([productId isEqualToString:kInAppPurchaseStarterPack])
    {
        [AppSettings get].hasPurchasedStarterPack = YES;
    }
}

//
// removes the transaction from the queue and posts a notification with the transaction result
//
- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful
{

    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
    if (wasSuccessful)
    {
        // send out a notification that we’ve finished the transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionSucceededNotification object:self userInfo:userInfo];

    }
    else
    {
        // send out a notification for the failed transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionFailedNotification object:self userInfo:userInfo];

    }
}

//
// called when the transaction was successful
//
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{

    [self recordTransaction:transaction];
    [self provideContent:transaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
}

//
// called when a transaction has been restored and and successfully completed
//
- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{

    [self recordTransaction:transaction.originalTransaction];
    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
}

//
// called when a transaction has failed
//
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // error!
        [self finishTransaction:transaction wasSuccessful:NO];
    }
    else
    {
        // this is fine, the user just cancelled, so don’t notify
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

#pragma mark -
#pragma mark SKPaymentTransactionObserver methods

//
// called when the transaction status is updated
//
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionFailed object:self userInfo:nil];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

#pragma mark -
#pragma mark SKProductsRequestDelegate methods
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *products = response.products;
    proUpgradeProduct = [products count] == 1 ? [products objectAtIndex:0]: nil;
    if (proUpgradeProduct)
    {
        DLog(@"Product title: %@" , proUpgradeProduct.localizedTitle);
        DLog(@"Product description: %@" , proUpgradeProduct.localizedDescription);
        DLog(@"Product price: %@" , proUpgradeProduct.price);
        DLog(@"Product id: %@" , proUpgradeProduct.productIdentifier);
    }
    
    for (NSString *invalidProductId in response.invalidProductIdentifiers)
    {
        DLog(@"Invalid product id: %@" , invalidProductId);
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerProductsFailedNotification object:self userInfo:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerProductsFetchedNotification object:self userInfo:nil];
}
@end
