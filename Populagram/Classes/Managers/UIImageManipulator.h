//
//  UIImageManipulator.h
//  CGPhotoBrowser
//
//  Created by Christian Gratton on 2013-03-24.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImageManipulator : NSObject

+ (UIImage*) imageWithImage:(UIImage*)image scaledToSize:(CGSize)size;

+ (UIImage*) drawImage:(UIImage*)image onBorderScaleToSize:(CGSize)size;

+ (UIImage*) border;

+ (UIImage*) drawImage:(UIImage*)topImage onImage:(UIImage*)bottomImage scaledToSize:(CGSize)size;

@end
