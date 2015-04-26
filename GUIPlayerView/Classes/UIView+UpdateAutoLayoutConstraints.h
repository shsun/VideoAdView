//
//  UIView+UpdateAutoLayoutConstant.h
//  XAdSDK
//
//  Created by shsun on 4/26/15
//
//

#import <UIKit/UIKit.h>

@interface UIView (UpdateAutoLayoutConstraints)


- (BOOL) setConstraintConstant:(CGFloat)constant forAttribute:(NSLayoutAttribute)attribute;

- (CGFloat) constraintConstantforAttribute:(NSLayoutAttribute)attribute;
- (NSLayoutConstraint*) constraintForAttribute:(NSLayoutAttribute)attribute;

- (void)hideView:(BOOL)hidden byAttribute:(NSLayoutAttribute)attribute;
- (void)hideByHeight:(BOOL)hidden;
- (void)hideByWidth:(BOOL)hidden;

- (CGSize) getSize;

- (void)sizeToSubviews;

@end