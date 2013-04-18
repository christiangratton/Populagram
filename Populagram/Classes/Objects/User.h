//
//  User.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-25.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Post;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSString * full_name;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) Post *post;

@end
