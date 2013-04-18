//
//  CGDataManager.m
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-25.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "CGDataManager.h"

#import "Post.h"
#import "User.h"
#import "Location.h"
#import "Link.h"
#import "Image.h"
#import "Caption.h"

static CGDataManager *defaultManager;

@implementation CGDataManager
@synthesize managedObjectContext, backgroundManagedObjectContext, imageDownloadQ;

+ (CGDataManager*) defaultManager {
    @synchronized(self) {
        if(defaultManager == nil) {
            defaultManager = [[CGDataManager alloc] init];
            defaultManager.imageDownloadQ = [[NSOperationQueue alloc] init]; // Image download queue that is used as part of the shared instance. Images will be downloaded in order of process (+ 5 concurrent operations)
            [defaultManager.imageDownloadQ setMaxConcurrentOperationCount:5];
            [defaultManager.imageDownloadQ setName:@"Image Download Queue"];
        }
    }
    return defaultManager;
}

+ (void) requestForURL:(NSString*)url {
    // Add the activity indicator as we will fetch some data
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if([data length] > 0 && error == nil)
         {
             NSError *JSONError = nil;
             // Post dictionary
             NSDictionary *rData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&JSONError];
             
             // If we didn't receive an error, process...
             if([CGDataManager canReadReceivedResponse:rData]) {
                 
                 //Do dispatch queue to read response
                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                     [[CGDataManager defaultManager] receivedResponseWithData:rData];
                 });
                 
             } else {
                 // Warn the user the data couldn't be loaded
                 dispatch_async(dispatch_get_main_queue(), ^{
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There's was an error with the connection." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
                     [alert show];
                     [alert release];
                 });
             }
        }
        else if([data length] == 0 || error != nil)
        {
             // Warn the user the data couldn't be loaded
             dispatch_async(dispatch_get_main_queue(), ^{
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There's was an error with the connection." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
                 [alert show];
                 [alert release];
             });
        }
     }];
}

+ (BOOL) canReadReceivedResponse:(NSDictionary*)response {
    
    // Check if we did receive something (all json from instagram should containt meta)
    if([response objectForKey:@"meta"] == [NSNull null]) return NO;
    
    NSDictionary *meta = [response objectForKey:@"meta"];
    int code = [[meta objectForKey:@"code"] intValue];
    
    // If we didn't get code 200 we have an error
    return code == 200;
}

- (void) receivedResponseWithData:(NSDictionary*)data {
    // Get the main context and create a background context to update the data
    NSManagedObjectContext *defaultContext = [[CGDataManager defaultManager] managedObjectContext];
    NSManagedObjectContext *context = [[CGDataManager defaultManager] backgroundManagedObjectContext];
    
    // We are already updating
    if(context != nil) return;
    
    // Set the store to context
    context = [[[NSManagedObjectContext alloc] init] autorelease];
    [context setPersistentStoreCoordinator:[defaultContext persistentStoreCoordinator]];
    
    // Add observers to merge context after load
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundMOCDidSave:) name:NSManagedObjectContextDidSaveNotification object:context];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveContext:) name:@"UpdateComplete" object:nil];
    
    // Get starting index (for ordering)
    NSUInteger order = [CGDataManager startIndex];
    
    // Go through data
    for(NSDictionary *post in [data objectForKey:@"data"])
    {
        // Get the id to see if the post already exists
        NSString *postId = [post objectForKey:@"id"];
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
        request.predicate = [NSPredicate predicateWithFormat:@"postId = %@", postId];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"postId" ascending:YES];
        request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        
        NSError *error = nil;
        NSArray *matches = [context executeFetchRequest:request error:&error];
                
        // Check if post exists already
        Post *nPost;

        if([matches count] > 0) {
            nPost = [matches objectAtIndex:0]; // The post already exists so we'll update the information instead of creating a new
        } else {
            // New post, set id and order key
            nPost = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:context];
            [nPost setValue:postId forKey:@"postId"];
            [nPost setValue:[NSNumber numberWithInteger:order] forKey:@"order"];
        }
        
        // Create user
        if([post objectForKey:@"user"] != [NSNull null]) {
            NSDictionary *dictionary = [post objectForKey:@"user"];
            User *user = [CGDataManager userWithDictionary:dictionary forContext:context];
            [user setValue:nPost forKey:@"post"];
        }
        
        // Create caption
        if([post objectForKey:@"caption"] != [NSNull null]) {
            NSDictionary *dictionary = [post objectForKey:@"caption"];
            Caption *caption = [CGDataManager captionWithDictionary:dictionary forContext:context];
            [caption setValue:nPost forKey:@"post"];
        }

        // Link
        if([post objectForKey:@"link"] != [NSNull null]) {
            Link *link = [CGDataManager linkWithValue:[post objectForKey:@"link"] forContext:context];
            [link setValue:nPost forKey:@"post"];
        }

        // Location
        if([post objectForKey:@"location"] != [NSNull null]) {
            NSDictionary *dictionary = [post objectForKey:@"location"];
            Location *location = [CGDataManager locationWithDictionary:dictionary forContext:context];
            [location setValue:nPost forKey:@"post"];
        }

        // Images
        if([post objectForKey:@"images"] != [NSNull null]) {
            NSDictionary *dictionary = [post objectForKey:@"images"];
            
            for(NSString *type in [dictionary allKeys])
            {
                Image *image = [CGDataManager imageWithDictionary:[dictionary objectForKey:type]  forType:type andContext:context];
                [image setValue:nPost forKey:@"post"];
            }
        }

        // Likes
        if([post objectForKey:@"likes"] != [NSNull null]) {
            NSDictionary *dictionary = [post objectForKey:@"likes"];
            
            id count = [dictionary objectForKey:@"count"];
            if(count != nil) [nPost setValue:[NSNumber numberWithInt:[count integerValue]] forKey:@"likeCount"];
        }

        // Comments
        if([post objectForKey:@"comments"] != [NSNull null]) {
            NSDictionary *dictionary = [post objectForKey:@"comments"];
            
            id count = [dictionary objectForKey:@"count"];
            if(count != nil) [nPost setValue:[NSNumber numberWithInt:[count integerValue]] forKey:@"commentCount"];
        }
        
        // Increment order key
        order++;
        
        // Save context to trigger backgroundMOCDidSave
        // We do not really save it, we just post the event for merging
        [context save:nil];
    }
    
    // Remove notification for context saved
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:context];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateComplete" object:nil];
    
    // Reset background context
    [context reset];
    context = nil;
    
    // We are done loading, remove activity indicator
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)backgroundMOCDidSave:(NSNotification*)notification
{
    // Merge on main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        NSManagedObjectContext *context = [[CGDataManager defaultManager] managedObjectContext];  
        [context mergeChangesFromContextDidSaveNotification:notification];
    });
}

- (void) saveContext:(NSNotification*)notification
{
    // Save context on main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        NSManagedObjectContext *context = [[CGDataManager defaultManager] managedObjectContext];  
        // Save the context
        NSError *error;
        if(![context save:&error])
        {
            NSLog(@"Error: could not save context (%@)", [error localizedDescription]);
        } else
            NSLog(@"context saved");
    });
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpdateComplete" object:nil];
}

+ (void) deleteExistingEntities
{
    // This method is never used (was a helper while debugging)
    // It delete all exisint posts. It could be used in an instance where we wanted to remove everything
    // instead of keep all the posts in memory
    NSManagedObjectContext *defaultContext = [[CGDataManager defaultManager] managedObjectContext];
    NSManagedObjectContext *context = [[CGDataManager defaultManager] backgroundManagedObjectContext];
    
    // We are already updating
    if(context != nil) return;
    
    context = [[[NSManagedObjectContext alloc] init] autorelease];
    [context setPersistentStoreCoordinator:[defaultContext persistentStoreCoordinator]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundMOCDidSave:) name:NSManagedObjectContextDidSaveNotification object:context];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveContext:) name:@"UpdateComplete" object:nil];
        
    // Delete existing
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    NSArray * result = [context executeFetchRequest:fetchRequest error:nil];
    for (id post in result)
        [context deleteObject:post];
    
    [fetchRequest release];
    
    // Save context to trigger backgroundMOCDidSave
    [context save:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:context];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateComplete" object:nil];
    
    [context reset];
    context = nil;
}

+ (NSUInteger) startIndex
{
    // This is just to help for ordering. Returns the count which is refered to as the last id.
    NSManagedObjectContext *context = [[CGDataManager defaultManager] managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Post" inManagedObjectContext: context]];
    
    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest:request error: &error];
    
    [request release];
    
    return count;
}

// Types

+ (User*) userWithDictionary:(NSDictionary*)dictionary forContext:(NSManagedObjectContext*)context {
    
    // Create a new user
    User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
    
    // Fetch existing users to check if user exists already.
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    request.predicate = [NSPredicate predicateWithFormat:@"userId = %i", [[dictionary objectForKey:@"id"] integerValue]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"userId" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
        
    // Match found, return match
    if([matches count] > 0) {
       return [matches objectAtIndex:0]; // User already exists, update info...
    }
    else { // No match found, create new
        id userId = [dictionary objectForKey:@"userId"];
        if(userId != nil) [user setValue:[NSNumber numberWithInt:[userId integerValue]] forKey:@"userId"];
        
        id fullName = [dictionary objectForKey:@"full_name"];
        if(fullName != nil) [user setValue:fullName forKey:@"full_name"];
        
        id profilePicture = [dictionary objectForKey:@"profile_picture"];
        if(profilePicture != nil) {
            [user setValue:profilePicture forKey:@"url"];
            
            // Set path
            [user setValue:[CGDataManager pathForImage:user.url] forKey:@"path"];
                        
            // Download profile image to cache
            [CGDataManager cacheImage:user.url atPath:user.path];
        }
        
        id username = [dictionary objectForKey:@"username"];
        if(username != nil) [user setValue:[NSString stringWithFormat:@"@%@", username] forKey:@"username"];
    }
    
    return user;
}

+ (Location*) locationWithDictionary:(NSDictionary*)dictionary forContext:(NSManagedObjectContext*)context {
    // Create new location object
    Location *location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:context];
    
    id longitude = [dictionary objectForKey:@"longitude"];
    if(longitude != nil) [location setValue:longitude forKey:@"longitude"];
    
    id latitude = [dictionary objectForKey:@"latitude"];
    if(latitude != nil) [location setValue:latitude forKey:@"latitude"];
    
    return location;
}

+ (Link*) linkWithValue:(NSString*)value forContext:(NSManagedObjectContext*)context {
    // Create the link (to share)
    Link *link = [NSEntityDescription insertNewObjectForEntityForName:@"Link" inManagedObjectContext:context];
    
    if(value != nil) [link setValue:value forKey:@"url"];
    
    return link;
}

+ (Image*) imageWithDictionary:(NSDictionary*)dictionary forType:(NSString*)type andContext:(NSManagedObjectContext*)context {
    // Create the images
    Image *image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:context];
    
    [image setValue:type forKey:@"type"];
    
    id height = [dictionary objectForKey:@"height"];
    if(height != nil) [image setValue:height forKey:@"height"];
    
    id width = [dictionary objectForKey:@"width"];
    if(width != nil) [image setValue:width forKey:@"width"];
    
    id url = [dictionary objectForKey:@"url"];
    if(url != nil) {
        [image setValue:url forKey:@"url"];
        
        // Set path
        [image setValue:[CGDataManager pathForImage:image.url] forKey:@"path"];
        
        // Only cache high res because it's the main one we use
        // If we need other sizes, we can download and cache later
        if([type isEqualToString:@"standard_resolution"]) {
            // Download image in background
            [CGDataManager cacheImage:image.url atPath:image.path];
        }
    }
    
    return image;
    
}

+ (Caption*) captionWithDictionary:(NSDictionary*)dictionary forContext:(NSManagedObjectContext*)context {
    
    // Create caption object
    Caption *caption = [NSEntityDescription insertNewObjectForEntityForName:@"Caption" inManagedObjectContext:context];
    
    
    id createdTime = [dictionary objectForKey:@"created_time"];
    if(createdTime != nil) {
        
        NSTimeInterval interval = [createdTime doubleValue] - 3600;
        [caption setValue:[NSDate dateWithTimeIntervalSince1970:interval] forKey:@"created_time"];
    
        /*
         // Formatting to string
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"MM/dd/yyyy HH:mm:ss aaa"];
        NSLog(@"result: %@", [dateFormatter stringFromDate:online]);
         */
        
    }
    
    id text = [dictionary objectForKey:@"text"];
    if(text != nil) [caption setValue:text forKey:@"text"];
    
    return caption;
}

// Cache
// Path to cache
+ (NSString*) cachePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

// Method to format the path of a given image (we use the same name as instagram, simpler and unique)
+ (NSString*) pathForImage:(NSString*)url { return [[CGDataManager cachePath] stringByAppendingPathComponent:[[url pathComponents] lastObject]]; }

+ (void) cacheImage:(NSString*)url atPath:(NSString*)path {
    // Before trying to cache the image, make sure it doesn't exists
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        // Add image download to queue
        [[[CGDataManager defaultManager] imageDownloadQ] addOperationWithBlock:^{
            
            // Start activity indicator
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            UIImage *image = [UIImage imageWithData:data];
            
            // Save the file in the right format
            if([path rangeOfString:@".png" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
            }
            else if ([path rangeOfString: @".jpg" options: NSCaseInsensitiveSearch].location != NSNotFound ||
                     [path rangeOfString: @".jpeg" options: NSCaseInsensitiveSearch].location != NSNotFound) {
                [UIImageJPEGRepresentation(image, 100) writeToFile:path atomically:YES];
            }
            // Stop the acitivity indicator
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }];
    }
}

+ (UIImage*) getImage:(NSString*)path from:(NSString*)url {
    UIImage *image;
    // Get the image
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        image = [UIImage imageWithData:data];
    } else {
        // The image should have downloaded,
        // it is possible that it isn't done or that the download was interupted
        // We will go a head a try to download it again
        [CGDataManager cacheImage:url atPath:path];
        
        // Sends back an image for the time being
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        image = [UIImage imageWithData:data];
    }
    
    return image;
}











@end





















