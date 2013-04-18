//
//  CGImageView.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-26.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CGImageView : UIScrollView <UIScrollViewDelegate> {
    BOOL isZoomed;
    BOOL isStatusBarVisible;
    
    UIImageView *imageToBeFramed;
}

@property (readonly, nonatomic, retain) UIImageView *imageToBeFramed;

-(id)initWithFrame:(CGRect)frame;

- (void) toggle;

- (CGRect)zoomRectForScrollView:(UIScrollView *)scrollView withScale:(float)scale withCenter:(CGPoint)center;

@end
