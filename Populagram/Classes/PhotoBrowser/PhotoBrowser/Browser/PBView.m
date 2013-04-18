//
//  PBView.m
//  CGPhotoBrowser
//
//  Created by Christian Gratton on 2013-03-24.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "PBView.h"
#import "UIImageManipulator.h"
#import "CGDataManager.h"

#import "Post.h"
#import "User.h"

#define SHADOW_OPACITY 0.45
#define SHADOW_RADIUS 3.5

#define BANNER_WIDTH 300
#define BANNER_HEIGHT 75

#define LIKE_BUTTON_WIDTH 40
#define LIKE_BUTTON_HEIGHT 40

#define PHOTO_WIDTH 290
#define PHOTO_HEIGHT 290
#define PHOTO_LEFT_OFFSET 5
#define PHOTO_TOP_OFFSET 5

#define INTERACTIONS_LEFT_OFFSET 5
#define INTERACTIONS_TOP_OFFSET 300
#define INTERACTIONS_BOTTOM_OFFSET 5
#define INTERACTIONS_RIGHT_OFFSET 5

@implementation PBView
@synthesize delegate, post, photo, profile;

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setOpaque:YES];
        [self setBackgroundColor:[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0]];
        
        // Shadow
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOpacity = SHADOW_OPACITY;
        self.layer.shadowRadius = SHADOW_RADIUS;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
                
        // Interactions
        interactions = [UIButton buttonWithType:UIButtonTypeCustom];
        [interactions setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [interactions setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [interactions.titleLabel setFont:[UIFont boldSystemFontOfSize:12.0]];
        [interactions addTarget:self action:@selector(showInteractions) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:interactions];
        
        // Share
        // Share is added in init because it always does the same action
        // We get the loaded post when pressed
        UIButton *share = [UIButton buttonWithType:UIButtonTypeCustom];
        [share setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [share setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [share.titleLabel setFont:[UIFont boldSystemFontOfSize:12.0]];
        [share setTitle:@"share" forState:UIControlStateNormal];
        [share addTarget:self action:@selector(showShareOptions) forControlEvents:UIControlEventTouchUpInside];
        float width = [share.titleLabel.text sizeWithFont:interactions.titleLabel.font constrainedToSize:CGSizeMake(CGFLOAT_MAX, 20.0) lineBreakMode:NSLineBreakByTruncatingTail].width + 7.5;
        [share setFrame:CGRectMake(self.frame.size.width - (INTERACTIONS_RIGHT_OFFSET + width), INTERACTIONS_TOP_OFFSET, width, self.frame.size.height - (INTERACTIONS_TOP_OFFSET + INTERACTIONS_BOTTOM_OFFSET))];
        [self addSubview:share];
        
        background = [[UIImageManipulator imageWithImage:[UIImage imageNamed:@"banner.png"] scaledToSize:CGSizeMake(BANNER_WIDTH, BANNER_HEIGHT)] retain];
        noLike = [[UIImageManipulator imageWithImage:[UIImage imageNamed:@"noLike.png"] scaledToSize:CGSizeMake(LIKE_BUTTON_WIDTH, LIKE_BUTTON_HEIGHT)] retain];
        like = [[UIImageManipulator imageWithImage:[UIImage imageNamed:@"like.png"] scaledToSize:CGSizeMake(LIKE_BUTTON_WIDTH, LIKE_BUTTON_HEIGHT)] retain];
    }
    return self;
}

// Shows comments/likes (not implemented)
- (void) showInteractions {
    [delegate showInteractionsForPost:post];
}

// Shows share options (not implemented)
- (void) showShareOptions {
    [delegate showShareOptionsForPost:post];
}

// Shows details
- (void) showDetails {
    [delegate showImageForPost:post];
}

// Post is now favorite, save context and redraw for icon
- (void) setAsFavorite {
    
    BOOL isFavorite = [post.favorite boolValue];
    [post setValue:[NSNumber numberWithBool:!isFavorite] forKey:@"favorite"];
    [[CGDataManager defaultManager] saveContext:nil];
    [self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect {
    
#define BANNER_LEFT_OFFSET 0
#define BANNER_TOP_OFFSET 10
    
#define PROFILE_LEFT_OFFSET 22.5
#define PROGILE_TOP_OFFSET 8.75
    
#define LIKE_LEFT_OFFSET 245
#define LIKE_TOP_OFFSET 245
    
#define TEXT_LEFT_OFFSET 90
#define TEXT_TOP_OFFSET 22.5
#define TEXT_WIDTH 200
    
#define NAME_FONT_SIZE 14
#define MIN_NAME_FONT_SIZE 12
#define USERNAME_FONT_SIZE 12
#define MIN_USERNAME_FONT_SIZE 10
        
    // Font for name (i.e. Christian Gratton)
    UIFont *nameFont = [UIFont boldSystemFontOfSize:NAME_FONT_SIZE];
    
    // Font for username (i.e. @christiangratton)
    UIFont *usernameFont = [UIFont systemFontOfSize:USERNAME_FONT_SIZE];
    
    // Text color
    UIColor *color = [UIColor whiteColor];
    
    // Positioning
    CGRect contentRect = self.bounds;
    
    CGFloat boundsX = contentRect.origin.x;
    CGPoint point;
    
    CGFloat actualFontSize;
    CGSize size;
    
    // Set main color
    [color set];
        
    // Photo
    point = CGPointMake(boundsX + PHOTO_LEFT_OFFSET, PHOTO_TOP_OFFSET);
    [photo drawAtPoint:point];
    
    // Favorite
    point = CGPointMake(boundsX + LIKE_LEFT_OFFSET, LIKE_TOP_OFFSET);
    if([post.favorite boolValue]) [like drawAtPoint:point];
    else [noLike drawAtPoint:point];
    
    // Banner
    point = CGPointMake(boundsX + BANNER_LEFT_OFFSET, BANNER_TOP_OFFSET);
    [background drawAtPoint:point];
    
    // Profile picture
    point = CGPointMake(boundsX + PROFILE_LEFT_OFFSET, BANNER_TOP_OFFSET + PROGILE_TOP_OFFSET);
    [profile drawAtPoint:point];
    
    // Draw name
    User *user = (User*)post.user;
    point = CGPointMake(boundsX + TEXT_LEFT_OFFSET, TEXT_TOP_OFFSET + BANNER_TOP_OFFSET);
    size = [user.full_name sizeWithFont:nameFont minFontSize:MIN_NAME_FONT_SIZE actualFontSize:&actualFontSize forWidth:TEXT_WIDTH lineBreakMode:NSLineBreakByTruncatingTail];
    [user.full_name drawAtPoint:point forWidth:TEXT_WIDTH withFont:nameFont minFontSize:MIN_NAME_FONT_SIZE actualFontSize:NULL lineBreakMode:NSLineBreakByTruncatingTail baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
    
    // Draw username
    point = CGPointMake(boundsX + TEXT_LEFT_OFFSET, BANNER_TOP_OFFSET + TEXT_TOP_OFFSET + size.height);
    [user.username drawAtPoint:point forWidth:TEXT_WIDTH withFont:usernameFont minFontSize:MIN_USERNAME_FONT_SIZE actualFontSize:NULL lineBreakMode:NSLineBreakByTruncatingTail baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
}

- (void) setPost:(Post *)newPost {    
    if(post != newPost) {
        
        [post release];
        post = [newPost retain];
        
        int likes = [post.likeCount intValue];
        int comments = [post.commentCount intValue];
                
        [interactions setTitle:[NSString stringWithFormat:@"%i likes & %i comments", likes, comments] forState:UIControlStateNormal];
        float width = [interactions.titleLabel.text sizeWithFont:interactions.titleLabel.font constrainedToSize:CGSizeMake(CGFLOAT_MAX, 20.0) lineBreakMode:NSLineBreakByTruncatingTail].width + 7.5;
        [interactions setFrame:CGRectMake(INTERACTIONS_LEFT_OFFSET, INTERACTIONS_TOP_OFFSET, width, self.frame.size.height - (INTERACTIONS_TOP_OFFSET + INTERACTIONS_BOTTOM_OFFSET))];
    }
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self
                                             selector: @selector(showDetails)
                                               object: nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([touch tapCount] == 1) {
        [self performSelector: @selector(showDetails)
                   withObject: nil
                   afterDelay: 0.25];
    }
    else if ([touch tapCount] == 2) {
        [self setAsFavorite];
    }
}

- (void) dealloc {
    [post release];
    [photo release];
    [profile release];
    [background release];
    [noLike release];
    [like release];
    
    [super dealloc];
}

@end
