//
//  CustomizeViewHelper.h
//  MiKey
//
//  Created by Ncgaming on 30/7/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomizeViewHelper : NSObject

//left for back
+(UIButton*)backButton:(UIViewController*)root imageName:(NSString*)img pressedImageName:(NSString*)img_p;

//
+(UIButton*)closeButton:(UIViewController*)root imageName:(NSString*)img pressedImageName:(NSString*)img_p;

+(UILabel*)titleLabel:(NSString*)text color:(UIColor*)textColor fontName:(NSString*)fontName fontSize:(int)fontSize backgroundColor:(UIColor*)bgColor;

+(void)setBackground:(UIViewController*)root bgImageName:(NSString*)bgImageName barImageName:(NSString*)barImageName;
@end
