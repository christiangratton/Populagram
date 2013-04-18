//
//  PBCell.h
//  CGPhotoBrowser
//
//  Created by Christian Gratton on 2013-03-24.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PBView;
@class Post;

@interface PBCell : UITableViewCell {
    PBView *photoBrowserView;
    UIActivityIndicatorView *indicator;
}

@property (nonatomic, retain) PBView *photoBrowserView;

- (void) setPost:(Post *)post;
- (void) setPostImage:(UIImage*)image;
- (void) setProfilePicture:(UIImage*)image;

- (void) redisplay;

@end
