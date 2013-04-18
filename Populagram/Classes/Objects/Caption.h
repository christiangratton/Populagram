//
//  Caption.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-25.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Post;

@interface Caption : NSManagedObject

@property (nonatomic, retain) NSDate * created_time;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) Post *post;

@end
