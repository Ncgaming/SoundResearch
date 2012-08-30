//
//  TouchPositionHelper.m
//  MiKey
//
//  Created by Seng Hin Mak on 2/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import "TouchPointHelper.h"

@implementation TouchPointHelper

+ (BOOL)isTouchPoint:(CGPoint)point onEdge:(EdgeDirection)edge
{
    int margin = 30;
    int rightEdge = 320;
    int leftEdge = 0;
    
    if (edge == kEdgeRight)
    {
        return (point.x > rightEdge-margin);
    }
    if (edge == kEdgeLeft)
    {
        return (point.x < leftEdge+margin);
    }
    
    return NO;
}

+ (BOOL)isTouchPoint:(CGPoint)point inRect:(CGRect)rect
{
	return CGRectContainsPoint(rect, point);
}

@end
