//
//  PBOptionsProtocol.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-27.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PBOptionsProtocol <NSObject>

@required
- (void) selectedOptionIndex:(int)index;

@end
