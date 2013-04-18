//
//  CGImageView.m
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-26.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "CGImageView.h"
#import "PBDetailView.h"

@implementation CGImageView
@synthesize imageToBeFramed;

-(UIImageView *)imageToBeFramed {
    return [self.subviews objectAtIndex:0];
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.minimumZoomScale = 1.00;
        self.maximumZoomScale = 3.50;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizesSubviews = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.backgroundColor = [UIColor blackColor];
        self.clipsToBounds = NO;
        self.delegate = self;
    }
    return self;
}

// Position
- (void)layoutSubviews {
    [super layoutSubviews];
    
    // center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.imageToBeFramed.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.imageToBeFramed.frame = frameToCenter;
}


// Show/hide details
- (void) toggle {
    [((PBDetailView*)self.superview) toggleDetails];
}

// Get the view to scale
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // return the first subview of the scroll view
    return self.imageToBeFramed;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // Cancels if double tap (or else single + double captured)
    [NSObject cancelPreviousPerformRequestsWithTarget: self
                                             selector: @selector(toggle)
                                               object: nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([touch tapCount] == 1) { // Toggle
        [self performSelector: @selector(toggle)
                   withObject: nil
                   afterDelay: 0.25];
    }
    else if ([touch tapCount] == 2) { // Zoom in/out
        if(isZoomed){
            CGRect rect = [self.imageToBeFramed bounds];
            [self zoomToRect:rect animated:YES];
            isZoomed = NO;
        }else {
            UITouch *touch = [[event allTouches] anyObject];
            CGPoint touchPoint = [touch locationInView:self.imageToBeFramed];
            CGRect zrect = [self zoomRectForScrollView:self withScale:2 withCenter:touchPoint];
            [self zoomToRect:zrect animated:YES];
            isZoomed = YES;
        }
    }
}

- (CGRect)zoomRectForScrollView:(UIScrollView *)scrollView withScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // The zoom rect is in the content view's coordinates.
    // At a zoom scale of 1.0, it would be the size of the
    // imageScrollView's bounds.
    // As the zoom scale decreases, so more content is visible,
    // the size of the rect grows.
    zoomRect.size.height = scrollView.frame.size.height / scale;
    zoomRect.size.width  = scrollView.frame.size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

// Hide while zooming
- (void) scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    [((PBDetailView*)self.superview) hideDetails];
}

// Show when done
- (void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    if(scale <= 1.0) [((PBDetailView*)self.superview) showDetails];
    else if(scale > 1.0) isZoomed = YES;
}

-(void)dealloc {
    [imageToBeFramed release];
    [super dealloc];
}

@end
