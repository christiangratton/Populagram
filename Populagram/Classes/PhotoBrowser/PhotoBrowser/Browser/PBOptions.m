//
//  PBOptions.m
//  CGInstagramBrowser
//
//  Created by Christian Gratton on 2013-03-27.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "PBOptions.h"

#define LEFT_PADDING 10
#define TOP_PADDING 10

@implementation PBOptions
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.85]];
        self.alpha = 0.0;
        
        UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[@"Popular", @"Photo Map", @"Favorites"]];
        segment.frame = CGRectMake(LEFT_PADDING, TOP_PADDING, frame.size.width - (LEFT_PADDING*2.0), frame.size.height - (TOP_PADDING*2.0));
        [segment addTarget:self action:@selector(didSelectOption:) forControlEvents:UIControlEventValueChanged];
        [segment setSegmentedControlStyle:UISegmentedControlStyleBar];
        
        UIFont *boldFont = [UIFont boldSystemFontOfSize:13.0f];
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:boldFont, UITextAttributeFont, [UIColor darkGrayColor], UITextAttributeTextColor, nil];
        [segment setTitleTextAttributes:attributes forState:UIControlStateNormal];
        
        [segment setTintColor:[UIColor whiteColor]];
        [segment setSelectedSegmentIndex:0];
        
        [self addSubview:segment];
        [segment release];
    }
    return self;
}

// Tell delegate which options was picked
- (void) didSelectOption:(id)sender {
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    
    [delegate selectedOptionIndex:segment.selectedSegmentIndex];
}

@end
