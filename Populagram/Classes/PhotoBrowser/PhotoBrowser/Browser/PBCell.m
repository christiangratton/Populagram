//
//  PBCell.m
//  CGPhotoBrowser
//
//  Created by Christian Gratton on 2013-03-24.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "PBCell.h"
#import "PBView.h"

#import "Post.h"

@implementation PBCell
@synthesize photoBrowserView;

#define CONTAINER_LEFT_PADDING 10
#define CONTAINER_TOP_PADDING 10
#define CONTAINER_WIDTH 300
#define CONTAINER_HEIGHT 330

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Create a photo browser view and add it as a subview of self's contentView.
        CGRect pbvFrame = CGRectMake(CONTAINER_LEFT_PADDING, CONTAINER_TOP_PADDING, CONTAINER_WIDTH, CONTAINER_HEIGHT);
        photoBrowserView = [[PBView alloc] initWithFrame:pbvFrame];
        photoBrowserView.autoresizingMask = UIViewAutoresizingNone;
        [self.contentView addSubview:photoBrowserView];
        
        // Indicator to display when no image
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:indicator];
        indicator.center = photoBrowserView.center;
    }
    return self;
}

// Set post
- (void) setPost:(Post *)post { photoBrowserView.post = post; }

// Set post image
- (void) setPostImage:(UIImage*)image {
    
    photoBrowserView.photo = image;
    
    // If image, stop animating, if image is nil, animate
    if(image) {
        if(indicator.isAnimating) [indicator stopAnimating];
        
    } else {
        [indicator startAnimating];
    }
}

// Sets profile picture
- (void) setProfilePicture:(UIImage*)image { photoBrowserView.profile = image; }

// Redraw content
- (void) redisplay {
    [photoBrowserView setNeedsDisplay];
}

- (void) dealloc {
    [photoBrowserView release];
    [indicator release];
    [super dealloc];
}

@end
