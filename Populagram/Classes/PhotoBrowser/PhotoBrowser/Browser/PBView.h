//
//  PBView.h
//  CGPhotoBrowser
//
//  Created by Christian Gratton on 2013-03-24.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "PBViewProtocol.h"

@class Post;

@interface PBView : UIView {
    UIImage *photo;
    UIImage *background;
    UIImage *noLike;
    UIImage *like;
    UIImage *profile;
    UIButton *interactions;
}

@property (nonatomic, assign, setter = setDelegate:) id<PBViewProtocol> delegate;

@property (nonatomic, retain) Post *post;
@property (nonatomic, retain) UIImage *photo;
@property (nonatomic, retain) UIImage *profile;

- (void) showInteractions;
- (void) showShareOptions;
- (void) showDetails;
- (void) setAsFavorite;

@end
