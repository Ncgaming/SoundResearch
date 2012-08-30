//
//  AppSettings.h
//  MiKey
//
//  Created by Seng Hin Mak on 18/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


#define PhoneColorKey @"PhoneColorKey"
#define GuitarHandKey @"GuitarHandKey"
#define BackgroundFilenameKey @"BackgroundFilenameKey"
#define RingFilenameKey @"RingFilenameKey"
#define HasShownHelpPage @"HasShownHelpPage"
#define HasPurchasedStarterPack @"HasPurchasedStarterPack"
#define HasPurchasedUkulele @"HasPurchasedUkulele"

typedef enum {
	kPhoneWhite,
	kPhoneBlack
} PhoneColor;

typedef enum {
	kGuitarLeftHand,
	kGuitarRightHand
} GuitarHand;

@interface AppSettings : NSObject

@property (nonatomic) BOOL isLightOption1;

@property (nonatomic) PhoneColor phoneColor;

@property (nonatomic) GuitarHand guitarHand;

@property (nonatomic, strong) NSString *backgroundFileName;

@property (nonatomic) BOOL hasShownHelpPage; 

@property (nonatomic) BOOL hasPurchasedStarterPack;

@property (nonatomic) BOOL hasPurchasedUkulele;


// shorthand of sharedAppSetting singleton instance
+(AppSettings*)get;

@end
