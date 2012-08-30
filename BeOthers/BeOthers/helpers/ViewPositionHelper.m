//
//  Created by makzan on 2/5/12.
//
//


#import "ViewPositionHelper.h"


@implementation ViewPositionHelper {

}

+ (void)setX:(CGFloat)x ofView:(UIView *)view {
	CGRect frame = view.frame;
	frame.origin.x = x;
	view.frame = frame;
}

+ (void)setY:(CGFloat)y ofView:(UIView *)view {
	CGRect frame = view.frame;
	frame.origin.y = y;
	view.frame = frame;
}

+ (void)setPosition:(CGPoint)pos ofView:(UIView *)view {
	[ViewPositionHelper setX:pos.x ofView:view];
	[ViewPositionHelper setY:pos.y ofView:view];
}

+ (void)setXBy:(CGFloat)x ofView:(UIView *)view {
	[ViewPositionHelper setX:view.frame.origin.x+x ofView:view];

}

+ (void)setYBy:(CGFloat)y ofView:(UIView *)view {
	[ViewPositionHelper setY:view.frame.origin.y+y ofView:view];
}




@end
