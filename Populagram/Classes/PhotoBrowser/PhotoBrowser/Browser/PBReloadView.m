//
//  PBReloadView.m
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-26.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "PBReloadView.h"

@implementation PBReloadView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setOpaque:YES];
        
        // Instead of having an infinite scroll/load, user must accept to load more posts        
        download = [UIButton buttonWithType:UIButtonTypeCustom];
        [download setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [download setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [download.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
        [download setTitle:@"Load more" forState:UIControlStateNormal];
        [download addTarget:self action:@selector(loadMore) forControlEvents:UIControlEventTouchUpInside];
        [download setFrame:frame];
        [self addSubview:download];
        
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.center = self.center;
        [self addSubview:indicator];
    }
    return self;
}

// Button was pressed, load more
- (void) loadMore {
    [download setHidden:YES];
    [indicator startAnimating];
    
    [delegate loadMorePosts];
}

// Helper to hide button
- (void) reset {
    [download setHidden:NO];
    [indicator stopAnimating];
}

- (void) dealloc
{
    [indicator release];
    
    [super dealloc];
}

@end
