//
//  Image.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-25.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Post;

@interface Image : NSManagedObject

@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) Post *post;

@end
