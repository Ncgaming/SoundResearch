//
//  AppSettings.m
//  MiKey
//
//  Created by Seng Hin Mak on 18/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import "AppSettings.h"

#import "SynthesizeSingleton.h"

#define kIsLightOption1 @"isLightOption1"


@implementation AppSettings
@synthesize isLightOption1;
@synthesize phoneColor;
@synthesize guitarHand;
@synthesize backgroundFileName = _backgroundFileName;
@synthesize hasShownHelpPage;
@synthesize hasPurchasedStarterPack;
@synthesize hasPurchasedUkulele;

SYNTHESIZE_SINGLETON_FOR_CLASS(AppSettings)

+(AppSettings*)get 
{
    return [AppSettings sharedAppSettings];
}

- (id)init
{
    self = [super init];
    if (self) {
        
        [self addObserver:self 
               forKeyPath:@"isLightOption1" 
                  options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld 
                  context:nil];
        
        [self addObserver:self forKeyPath:@"guitarHand" options:NSKeyValueObservingOptionNew context:nil];
        
         [self addObserver:self forKeyPath:@"hasShownHelpPage" options:NSKeyValueObservingOptionNew context:nil];
        
        [self addObserver:self forKeyPath:@"hasPurchasedStarterPack" options:NSKeyValueObservingOptionNew context:nil];
        
        [self addObserver:self forKeyPath:@"hasPurchasedUkulele" options:NSKeyValueObservingOptionNew context:nil];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasPurchasedDefault"];
        [[NSUserDefaults standardUserDefaults] synchronize];
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HasPurchasedStarterPack];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HasPurchasedUkulele];
//        [[NSUserDefaults standardUserDefaults] synchronize];
        hasPurchasedStarterPack = NO;
        id hasPurchasedStarterPack1 = [[NSUserDefaults standardUserDefaults] objectForKey:HasPurchasedStarterPack];
        if (hasPurchasedStarterPack1 != nil)
        {
            hasPurchasedStarterPack = [[NSUserDefaults standardUserDefaults] boolForKey:HasPurchasedStarterPack];
        }
        
        hasPurchasedUkulele = NO;
        id hasPurchasedUkulele1 = [[NSUserDefaults standardUserDefaults] objectForKey:HasPurchasedUkulele];
        if (hasPurchasedUkulele1 != nil)
        {
            hasPurchasedUkulele = [[NSUserDefaults standardUserDefaults] boolForKey:HasPurchasedUkulele];
        }


        
        hasShownHelpPage = NO;
        id hasShownHelpPage1 = [[NSUserDefaults standardUserDefaults] objectForKey:HasShownHelpPage];
        if (hasShownHelpPage1 != nil)
        {
            hasShownHelpPage = [[NSUserDefaults standardUserDefaults] boolForKey:HasShownHelpPage];
        }
        
        isLightOption1 = YES;
        
        id savedLightOption1 = [[NSUserDefaults standardUserDefaults] objectForKey:kIsLightOption1];
        if (savedLightOption1 != nil)
        {
            isLightOption1 = [[NSUserDefaults standardUserDefaults] boolForKey:kIsLightOption1];
        }
        
        phoneColor = kPhoneBlack;
        id savedPhoneColor = [[NSUserDefaults standardUserDefaults] objectForKey:PhoneColorKey];
        if (savedPhoneColor != nil)
        {
            phoneColor = [[NSUserDefaults standardUserDefaults] integerForKey:PhoneColorKey];
        }
        
        
        guitarHand = kGuitarRightHand;
        id savedGuitarHand = [[NSUserDefaults standardUserDefaults] objectForKey:GuitarHandKey];
        if (savedGuitarHand != nil)
        {
            guitarHand = [[NSUserDefaults standardUserDefaults] integerForKey:GuitarHandKey];
        }
        
        
        
        
        id savedBackgroundFileName = [[NSUserDefaults standardUserDefaults] objectForKey:BackgroundFilenameKey];
        if (savedBackgroundFileName != nil)
        {
            self.backgroundFileName = [[NSUserDefaults standardUserDefaults] objectForKey:BackgroundFilenameKey];
        }
        else {
            self.backgroundFileName = [NSString stringWithFormat:@"new_bg.jpg"];
        }
        
        
        
        
    }
    return self;
}

- (void)setBackgroundFileName:(NSString *)backgroundFileName
{
    _backgroundFileName = backgroundFileName;
    
    [[NSUserDefaults standardUserDefaults] setObject:backgroundFileName forKey:BackgroundFilenameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // change background
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BackgroundOptionChanged" object:nil];
}



- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:@"isLightOption1"]) 
    {
        [[NSUserDefaults standardUserDefaults] setBool:isLightOption1 forKey:kIsLightOption1];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"lightOptionChanged" object:nil];
    }
    else if ([keyPath isEqual:@"guitarHand"])
    {
        [[NSUserDefaults standardUserDefaults] setInteger:guitarHand forKey:GuitarHandKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GuitarHandChanged" object:nil];
    }
    else if ([keyPath isEqual:@"hasShownHelpPage"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:hasShownHelpPage forKey:HasShownHelpPage];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HasShownHelpPage" object:nil];
    }
    else if ([keyPath isEqual:@"hasPurchasedUkulele"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:hasPurchasedUkulele forKey:HasPurchasedUkulele];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HasPurchasedUkulele" object:nil];
    }
    else if ([keyPath isEqual:@"hasPurchasedStarterPack"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:hasPurchasedStarterPack forKey:HasPurchasedStarterPack];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HasPurchasedStarterPack" object:nil];
    }
}




@end
