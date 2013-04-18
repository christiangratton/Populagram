//
//  PBOptions.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-27.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBOptionsProtocol.h"

@interface PBOptions : UIView

@property (nonatomic, retain, setter = setDelegate:) id<PBOptionsProtocol> delegate;

- (void) didSelectOption:(id)sender;

@end
