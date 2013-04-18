//
//  CGPhotoMap.h
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-27.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class Post;
@class PBDetailView;

@interface CGPhotoMap : UIView <MKMapViewDelegate, CLLocationManagerDelegate> {
    // Map/location
    MKMapView *map;
    CLLocationManager *locationManager;
    NSMutableArray *annotations;
    
    // Detail view
    PBDetailView *detailView;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (void) fetchPosts;
- (void) createAnnotationWithPost:(Post*)postToCreate;

@end
