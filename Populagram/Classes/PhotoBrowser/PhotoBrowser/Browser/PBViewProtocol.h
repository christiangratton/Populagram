//
//  PBViewProtocol.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-25.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Post;

@protocol PBViewProtocol <NSObject>

@required
- (void) showInteractionsForPost:(Post*)aPost;
- (void) showShareOptionsForPost:(Post*)aPost;
- (void) showImageForPost:(Post*)aPost;

@end
