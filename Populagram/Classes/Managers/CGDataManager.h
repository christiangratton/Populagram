//
//  CGDataManager.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-25.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;
@class Location;
@class Link;
@class Like;
@class Image;
@class Comment;
@class Caption;

@interface CGDataManager : NSObject

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSManagedObjectContext *backgroundManagedObjectContext;
@property (nonatomic, retain) NSOperationQueue *imageDownloadQ;

+ (CGDataManager*) defaultManager;

+ (void) requestForURL:(NSString*)url;

+ (BOOL) canReadReceivedResponse:(NSDictionary*)response;

- (void) receivedResponseWithData:(NSDictionary*)response;

- (void) backgroundMOCDidSave:(NSNotification*)notification;

- (void) saveContext:(NSNotification*)notification;

+ (void) deleteExistingEntities;

// order key

+ (NSUInteger) startIndex;

// types

+ (User*) userWithDictionary:(NSDictionary*)dictionary forContext:(NSManagedObjectContext*)context;

+ (Location*) locationWithDictionary:(NSDictionary*)dictionary forContext:(NSManagedObjectContext*)context;

+ (Link*) linkWithValue:(NSString*)value forContext:(NSManagedObjectContext*)context;

+ (Image*) imageWithDictionary:(NSDictionary*)dictionary forType:(NSString*)type andContext:(NSManagedObjectContext*)context;

+ (Caption*) captionWithDictionary:(NSDictionary*)dictionary forContext:(NSManagedObjectContext*)context;

// Cache

+ (NSString*) cachePath;

+ (NSString*) pathForImage:(NSString*)url;

+ (void) cacheImage:(NSString*)url atPath:(NSString*)path;

+ (UIImage*) getImage:(NSString*)path from:(NSString*)url;

@end
