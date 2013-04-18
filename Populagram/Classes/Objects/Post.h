//
//  Post.h
//  Populagram
//
//  Created by Christian Gratton on 2013-03-27.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Post : NSManagedObject

@property (nonatomic, retain) NSNumber * commentCount;
@property (nonatomic, retain) NSNumber * favorite;
@property (nonatomic, retain) NSNumber * likeCount;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSString * postId;
@property (nonatomic, retain) NSManagedObject *caption;
@property (nonatomic, retain) NSSet *images;
@property (nonatomic, retain) NSManagedObject *link;
@property (nonatomic, retain) NSManagedObject *location;
@property (nonatomic, retain) NSManagedObject *user;
@end

@interface Post (CoreDataGeneratedAccessors)

- (void)addImagesObject:(NSManagedObject *)value;
- (void)removeImagesObject:(NSManagedObject *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@end
