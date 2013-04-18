//
//  CGActivityView.m
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-26.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "CGActivityView.h"

@implementation CGActivityView
@synthesize originalView, borderView, activityIndicatorView;

static CGActivityView *activityView = nil;

+ (CGActivityView*) activityViewFor:(UIView*)addToView {
    if(activityView) {
        [activityView removeFromSuperview];
        [activityView release];
    }
    
    activityView = [[self alloc] initForView:addToView];
    
    return activityView;
}


- (id) initForView:(UIView*)addToView {
    if (!(self = [super initWithFrame:CGRectZero]))
		return nil;
    
    // Creates a singleton activity view that is displayed on top of view
    self.originalView = addToView;
    
    [self setAlpha:0.0];
    [self makeBackground];
    self.borderView = [self makeBorderView];
    self.activityIndicatorView = [self makeActivityIndicatorView];
    
    [self.borderView addSubview:self.activityIndicatorView];
    [self addSubview:self.borderView];
    
    [addToView addSubview:self];
    
    [self show];
    
    return self;
}

- (void) makeBackground {
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65];
    self.opaque = NO;
    
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (UIView*) makeBorderView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    
    view.opaque = NO;
    view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65];
    view.layer.cornerRadius = 10.0;
    
    return view;
}

- (UIActivityIndicatorView*) makeActivityIndicatorView {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    [indicator startAnimating];
    
    return indicator;
}

- (void) layoutSubviews {
    if (!CGAffineTransformIsIdentity(self.borderView.transform))
        return;
    
    self.frame = self.superview.bounds;
    
    // Calculate the size and position for the border view: with the indicator to the left of the label, and centered in the receiver:
	CGRect borderFrame = CGRectZero;
    borderFrame.size.width = self.activityIndicatorView.frame.size.width + 50.0;
    borderFrame.size.height = self.activityIndicatorView.frame.size.height + 50.0;
    borderFrame.origin.x = floor(0.5 * (self.frame.size.width - borderFrame.size.width));
    borderFrame.origin.y = floor(0.5 * (self.frame.size.height - borderFrame.size.height - 20.0));
    self.borderView.frame = borderFrame;
    
    CGPoint center = CGPointMake(self.borderView.frame.size.width/2.0, self.borderView.frame.size.height/2.0);
    self.activityIndicatorView.center = center;
}

- (void) show {
    
    self.alpha = 0.0;
    self.borderView.transform = CGAffineTransformMakeScale(3.0, 3.0);
    
    [UIView beginAnimations:@"ShowActivityView" context:nil];
    [UIView animateWithDuration:0.25f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.borderView.transform = CGAffineTransformIdentity;
                         self.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                     }];
    [UIView commitAnimations];
}

- (void) hide {
    
    self.alpha = 1.0;
    self.borderView.transform = CGAffineTransformIdentity;
    
    [UIView beginAnimations:@"HideActivityView" context:nil];
    [UIView animateWithDuration:0.25f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.borderView.transform = CGAffineTransformMakeScale(0.5, 0.5);
                         self.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         [activityView removeFromSuperview];
                         [activityView release];
                     }];
    [UIView commitAnimations];
}

+ (void) remove {
    
    if (!activityView) return;
    
    [activityView hide];
}

- (void) dealloc {
    activityView = nil;
    [originalView release];
    [borderView release];
    [activityIndicatorView release];
    
    [super dealloc];
}

@end
