//
//  CGActivityView.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-26.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface CGActivityView : UIView

@property (nonatomic, retain) UIView *originalView;
@property (nonatomic, retain) UIView *borderView;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicatorView;

+ (CGActivityView*) activityViewFor:(UIView*)addToView;

- (id) initForView:(UIView*)addToView;
- (void) makeBackground;
- (UIView*) makeBorderView;
- (UIActivityIndicatorView*) makeActivityIndicatorView;

- (void) show;
- (void) hide;
+ (void) remove;

@end
