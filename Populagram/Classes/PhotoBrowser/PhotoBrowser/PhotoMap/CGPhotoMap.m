//
//  CGPhotoMap.m
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-27.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "CGPhotoMap.h"
#import "MKPostAnnotation.h"
#import "PBDetailView.h"
#import "Post.h"
#import "Image.h"
#import "Location.h"

static UIEdgeInsets pinPadding = { 100.f, 100.f, 100.f, 100.f };

@implementation CGPhotoMap
@synthesize managedObjectContext;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Map
        map = [[MKMapView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        [map setDelegate:self];
        [map setZoomEnabled:YES];
        [map setScrollEnabled:YES];
        [self addSubview:map];
        
        // Location manager, to get user's location
        locationManager = [[CLLocationManager alloc] init];
        [locationManager setDelegate:self];
        [locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
        
        // Detail view
        detailView = [[PBDetailView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height)];
        
        // Stores map's annotations (for easy add and remove)
        annotations = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) fetchPosts {
    // Remove all annonations
    [annotations removeAllObjects];
    [map removeAnnotations:[map annotations]];
    
    // Fetch posts on our current context
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Creates the annotations
    NSArray * result = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
    for(id post in result) {
        [self createAnnotationWithPost:post];
    }
    
    // If we have any annotations, add them
    if([annotations count] > 0) {
        [locationManager startUpdatingLocation];
        [map addAnnotations:annotations];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"It would appear that no one has shared the location of their image. Bummer!" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    }
    
    [fetchRequest release];
}

- (void) createAnnotationWithPost:(Post*)postToCreate {
    Location *location = (Location*)postToCreate.location;
    // Only create if the post has a location
    if(location) {
        CLLocationCoordinate2D postLocation;
        postLocation.latitude = location.latitude.doubleValue;
        postLocation.longitude = location.longitude.doubleValue;
        
        MKPostAnnotation *annotation = [[MKPostAnnotation alloc] initWithPost:postToCreate andCoordinate:postLocation];
        [annotations addObject:annotation];
        [annotation release];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    static NSString *identifier = @"MKPostAnnotation";
    if ([annotation isKindOfClass:[MKPostAnnotation class]]) {
        
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [map dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier] autorelease];
        } else {
            annotationView.annotation = annotation;
        }
        
        annotationView.enabled = YES;
        annotationView.canShowCallout = NO;
        annotationView.image = ((MKPostAnnotation*)annotation).image;
        
        return annotationView;
    }
    
    return nil;
}

- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    // If the annotation is in fact of the kind that contains a post,
    // Display the image
    if ([view.annotation isKindOfClass:[MKPostAnnotation class]]) {
                
            [detailView setPost:((MKPostAnnotation*)view.annotation).post];
            [detailView showIn:self.superview.superview]; // Display view's superview
    }
}

#pragma mark - CoreLocation

// Triggered when location is found
- (void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    // Determine if the user is close to a post or if we display the most occupied area
    MKMapRect boundingRect = MKMapRectNull;
    NSUInteger i = 0;
    float distance = CGFLOAT_MAX; // Max distance (the earth is big)
    float maxDistance = 5000000.0; // Max distance that determines if the user is close enough
    CLLocationCoordinate2D focusLocation = kCLLocationCoordinate2DInvalid;
    for (MKPostAnnotation *point in annotations) {
                
        CLLocation *postLocation = [[CLLocation alloc] initWithLatitude:point.coordinate.latitude longitude:point.coordinate.longitude];
        
        // Try to determine the closest images to user based on distance if close enough
        if([newLocation distanceFromLocation:postLocation] < distance && [newLocation distanceFromLocation:postLocation] < maxDistance) {
            distance = [newLocation distanceFromLocation:postLocation];
            
            focusLocation.latitude = point.coordinate.latitude;
            focusLocation.longitude = point.coordinate.longitude;
        }
        
        // Calculate the display rect
        MKMapPoint mp = MKMapPointForCoordinate(point.coordinate);
        MKMapRect pRect = MKMapRectMake(mp.x, mp.y, 0, 0);
        if (i == 0) {
            boundingRect = pRect;
        } else {
            boundingRect = MKMapRectUnion(boundingRect, pRect);
        }
        i++;
        
        [postLocation release];
    }
    
    // If we did set a focus location, show
    if (CLLocationCoordinate2DIsValid(focusLocation)) {
                
        //Set region
        MKCoordinateRegion region;
        region.center = focusLocation;
        
        //Set zoom level using span
        MKCoordinateSpan span;
        span.latitudeDelta = 50;
        span.longitudeDelta = 50;
        region.span = span;
        
        //Set map to current position
        [map setRegion:region animated:YES];
    } else {
        [map setVisibleMapRect:boundingRect edgePadding:pinPadding animated:YES];
    }
    
    [locationManager stopUpdatingLocation];
}

- (void) dealloc
{
    [map release];
    [detailView release];
    [managedObjectContext release];
    [locationManager release];
    [annotations release];
    
    [super dealloc];
}

@end
