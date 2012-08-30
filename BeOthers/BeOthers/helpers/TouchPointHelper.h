//
//  TouchPositionHelper.h
//  MiKey
//
//  Created by Seng Hin Mak on 2/5/12.
//  Copyright (c) 2012 42games ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	kEdgeRight,
	kEdgeLeft
} EdgeDirection;

@interface TouchPointHelper : NSObject

/**
 * Determine if the given point is on the give edge (right, left)
 */
+ (BOOL)isTouchPoint:(CGPoint)point onEdge:(EdgeDirection)edge;

+ (BOOL)isTouchPoint:(CGPoint)point inRect:(CGRect)rect;


@end
