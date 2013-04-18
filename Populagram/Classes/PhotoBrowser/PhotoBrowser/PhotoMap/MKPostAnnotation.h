//
//  MKPostAnnotation.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-27.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class Post;

@interface MKPostAnnotation : NSObject <MKAnnotation>

- (id) initWithPost:(Post*)post andCoordinate:(CLLocationCoordinate2D)coordinate;

@property (nonatomic, retain) Post *post;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end
