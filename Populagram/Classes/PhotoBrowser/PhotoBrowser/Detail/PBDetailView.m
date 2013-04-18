//
//  PBDetailView.m
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-26.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "PBDetailView.h"
#import "Post.h"
#import "Image.h"
#import "Caption.h"
#import "CGDataManager.h"
#import "CGImageView.h"

#define MIN_ZOOM_SCALE 1.0
#define MAX_ZOOM_SCALE 3.5
#define IMAGE_HEIGHT 306
#define IMAGE_WIDTH 306

// Category to prevent controls of appearing on the text view
@implementation UITextView (DisableCopyPaste)

- (BOOL)canBecomeFirstResponder
{
    return NO;
}

@end

@implementation PBDetailView
@synthesize post;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.9]];
        [self setUserInteractionEnabled:YES];
        
        // Custom scroll view that handles zoom, pan and displays the image
        cgImageView = [[CGImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, IMAGE_WIDTH, IMAGE_HEIGHT)];
        
        // This is the image container we are going to display inside the scroll view
        imageToBeFramed = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, IMAGE_WIDTH, IMAGE_HEIGHT)];
        [imageToBeFramed setContentMode:UIViewContentModeScaleToFill];
        [imageToBeFramed setBackgroundColor:[UIColor clearColor]];
        [cgImageView addSubview:imageToBeFramed];

        [self addSubview:cgImageView];
        
        // Caption
        textView = [[UITextView alloc] initWithFrame:CGRectZero];
        [textView setBackgroundColor:[UIColor clearColor]];
        [textView setTextColor:[UIColor whiteColor]];
        [textView setShowsHorizontalScrollIndicator:NO];
        [textView setShowsVerticalScrollIndicator:NO];
        [textView setFont:[UIFont systemFontOfSize:14.0]];
        [textView setEditable:NO];
        [textView setDelegate:self];
        [self addSubview:textView];
        
        // Close button
        close = [UIButton buttonWithType:UIButtonTypeCustom];
        [close setImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
        [close addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [close setFrame:CGRectMake(self.frame.size.width - 60, 5, 50, 50)];
        [self addSubview:close];
    }
    return self;
}

- (void) setPost:(Post *)newPost {
    // Sets/releases a new post
    [post release];
    post = [newPost retain];
    
    // Get the highest res image
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %@", @"standard_resolution"];
    NSSet *set = [post.images filteredSetUsingPredicate:predicate];
    
    // Format
    Image *image = [set anyObject];
    [imageToBeFramed setImage:[CGDataManager getImage:image.path from:image.url]];
    
    // Add caption
    Caption *caption = (Caption*)post.caption;
    [textView setText:caption.text];
    // Format content size in case the text is longer than the area
    CGSize contentSize = [textView.text sizeWithFont:textView.font constrainedToSize:CGSizeMake(CGFLOAT_MAX, 20.0) lineBreakMode:NSLineBreakByWordWrapping];
    [textView setContentSize:contentSize];
}

// Animate show in
- (void) showIn:(UIView*)viewToShowIn {
    self.alpha = 0.0;
    self.transform = CGAffineTransformMakeScale(0.0, 0.0);
    [viewToShowIn addSubview:self];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [UIView beginAnimations:@"DetailViewShow" context:nil];
    [UIView animateWithDuration:0.75f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.transform = CGAffineTransformIdentity;
                         self.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                     }];
    [UIView commitAnimations];
}

// Animate hide
- (void) hide {
    self.alpha = 1.0;
    self.transform = CGAffineTransformIdentity;
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    [UIView beginAnimations:@"DetailViewHide" context:nil];
    [UIView animateWithDuration:0.75f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.transform = CGAffineTransformMakeScale(0.0, 0.0);
                         self.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         [self removeFromSuperview];
                     }];
    [UIView commitAnimations];
}

// Helper to toggle details (button, caption)
- (void) toggleDetails {
    if(textView.alpha == 0.0) [self showDetails];
    else [self hideDetails];
}

// Animate hide details
- (void) hideDetails {
    [UIView beginAnimations:@"DetailViewHideDetails" context:nil];
    [UIView animateWithDuration:0.25f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [textView setAlpha:0.0];
                         [close setAlpha:0.0];
                     }
                     completion:^(BOOL finished){
                     }];
    [UIView commitAnimations];
}

// Animate show details
- (void) showDetails
{
    [UIView beginAnimations:@"DetailViewShowDetails" context:nil];
    [UIView animateWithDuration:0.25f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [textView setAlpha:1.0];
                         [close setAlpha:1.0];
                     }
                     completion:^(BOOL finished){
                     }];
    [UIView commitAnimations];
}

// Display items at right place
- (void) layoutSubviews
{
    [super layoutSubviews];

    if (!CGAffineTransformIsIdentity(self.transform))
        return;
    
    // center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = cgImageView.frame;
    
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
    
    cgImageView.frame = frameToCenter;
    
    float y = cgImageView.frame.origin.y + cgImageView.frame.size.height + 5.0;
    textView.frame = CGRectMake(0.0, y, self.frame.size.width, self.frame.size.height - y);
}

// Toggles the details
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if ([touch tapCount] == 1)
    {
        [self toggleDetails];
    }
}


-(void)dealloc {
    [cgImageView release];
    [imageToBeFramed release];
    [textView release];
    
    [super dealloc];
}

@end
