//
//  CustomizeViewHelper.m
//  MiKey
//
//  Created by Ncgaming on 30/7/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import "CustomizeViewHelper.h"

@implementation CustomizeViewHelper

+(UIButton*)backButton:(UIViewController*)root imageName:(NSString *)img pressedImageName:(NSString *)img_p
{
    
    UIButton *b2 = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 26)];
    [b2 setImage:[UIImage imageNamed:img] forState:UIControlStateNormal];
    if(img_p != nil)
    {
        [b2 setImage:[UIImage imageNamed:img_p] forState:UIControlStateHighlighted];

    }
    [b2 addTarget:root action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    return b2;
    
}

+(UIButton*)closeButton:(UIViewController*)root imageName:(NSString *)img pressedImageName:(NSString *)img_p
{
    
    UIButton *b2 = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 26)];
    [b2 setImage:[UIImage imageNamed:img] forState:UIControlStateNormal];
    if(img_p != nil)
    {
        [b2 setImage:[UIImage imageNamed:img_p] forState:UIControlStateHighlighted];
        
    }
    [b2 addTarget:root action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    return b2;
    
}

+(UILabel*)titleLabel:(NSString*)text color:(UIColor*)textColor fontName:(NSString*)fontName fontSize:(int)fontSize backgroundColor:(UIColor*)bgColor
{
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 44)];
    [titleLabel setTextColor: textColor];
    [titleLabel setFont:[UIFont fontWithName:fontName size:fontSize]];
    [titleLabel setBackgroundColor:bgColor];
    [titleLabel setText:text];
    [titleLabel setTextAlignment:UITextAlignmentCenter];
    
    return titleLabel;
}

+(void)setBackground:(UIViewController *)root bgImageName:(NSString *)bgImageName barImageName:(NSString *)barImageName
{
    //view background
    UIImageView * background =[[UIImageView alloc]initWithFrame:root.view.frame];
    [background setImage:[UIImage imageNamed:bgImageName]];
    [root.view addSubview:background];
    [root.view sendSubviewToBack:background];
    
    
    //Nav bar background
    UIView * v = [[root.navigationController.navigationBar subviews]objectAtIndex:0];
    v.hidden = YES;
    root.navigationController.navigationBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:barImageName]];
  
}




@end
