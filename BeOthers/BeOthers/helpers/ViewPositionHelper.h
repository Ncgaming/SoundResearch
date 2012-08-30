//
//  Created by makzan on 2/5/12.
//
//


#import <Foundation/Foundation.h>


@interface ViewPositionHelper : NSObject

+ (void)setX:(CGFloat)x ofView:(UIView *)view;

+ (void)setY:(CGFloat)y ofView:(UIView *)view;

+ (void)setPosition:(CGPoint)pos ofView:(UIView *)view;

+ (void)setXBy:(CGFloat)x ofView:(UIView *)view;
+ (void)setYBy:(CGFloat)y ofView:(UIView *)view;


@end
