//
//  MKPostAnnotation.m
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-27.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "MKPostAnnotation.h"

#import "Post.h"
#import "User.h"
#import "Image.h"
#import "UIImageManipulator.h"
#import "CGDataManager.h"

#define IMAGE_WIDTH 75.0
#define IMAGE_HEIGHT 75.0

@implementation MKPostAnnotation
@synthesize post = _post, image = _image, coordinate = _coordinate;

- (id) initWithPost:(Post*)post andCoordinate:(CLLocationCoordinate2D)coordinate {
    if ((self = [super init])) {
        _post = [post retain];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %@", @"thumbnail"];
        NSSet *set = [_post.images filteredSetUsingPredicate:predicate];
        
        Image *image = [set anyObject];
        
        // Format the image accordingly
        UIImage *photo = [CGDataManager getImage:image.path from:image.url];
        _image = [[UIImageManipulator drawImage:photo onBorderScaleToSize:CGSizeMake(IMAGE_WIDTH, IMAGE_HEIGHT)] retain];
        _coordinate = coordinate;
    }
    return self;
}

// No callout, so no info needed
- (NSString *)title {
    return nil;
}
// No callout, so no info needed
- (NSString *)subtitle {
    return nil;
}

- (void) dealloc {
    [_post release];
    [_image release];
    
    [super dealloc];
}

@end
