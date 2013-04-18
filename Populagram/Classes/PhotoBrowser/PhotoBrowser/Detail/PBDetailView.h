//
//  PBDetailView.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-26.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Post;
@class CGImageView;

@interface PBDetailView : UIView <UIScrollViewDelegate, UITextViewDelegate> {
    CGImageView *cgImageView;
    UIImageView *imageToBeFramed;
    
    UITextView *textView;
    UIButton *close;
}

@property (nonatomic, retain) Post *post;

- (void) showIn:(UIView*)viewToShowIn;
- (void) hide;

- (void) toggleDetails;
- (void) hideDetails;
- (void) showDetails;

@end
