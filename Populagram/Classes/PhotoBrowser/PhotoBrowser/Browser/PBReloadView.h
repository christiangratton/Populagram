//
//  PBReloadView.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-26.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "PBReloadViewProtocol.h"

@interface PBReloadView : UIView
{
    UIButton *download;
    UIActivityIndicatorView *indicator;
}

@property (nonatomic, assign, setter = setDelegate:) id<PBReloadViewProtocol> delegate;

- (void) loadMore;
- (void) reset;

@end
