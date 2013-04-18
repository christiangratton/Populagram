//
//  UIImageManipulator.m
//  CGPhotoBrowser
//
//  Created by Christian Gratton on 2013-03-24.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "UIImageManipulator.h"

#define BORDER_SCALAR 0.25

@implementation UIImageManipulator

+ (UIImage*) imageWithImage:(UIImage*)image scaledToSize:(CGSize)size {
    // The bitsPerComponent and bitmapInfo values are hard-coded to prevent an "unsupported parameter combination" error
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                size.width,
                                                size.height,
                                                8,
                                                0,
                                                CGImageGetColorSpace(image.CGImage),
                                                CGImageGetBitmapInfo(image.CGImage));
    
    CGContextDrawImage(bitmap, CGRectMake(0, 0, size.width, size.height), image.CGImage);
    CGImageRef imageRef = CGBitmapContextCreateImage(bitmap);
    
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(imageRef);
        
    return newImage;
}

+ (UIImage*) drawImage:(UIImage*)image onBorderScaleToSize:(CGSize)size {
    UIImage *border = [UIImageManipulator border];
    CGFloat borderWidth = size.width * BORDER_SCALAR;
    CGFloat borderPadding = borderWidth/2.0;
    
    // The bitsPerComponent and bitmapInfo values are hard-coded to prevent an "unsupported parameter combination" error
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                size.width,
                                                size.height,
                                                8,
                                                0,
                                                CGImageGetColorSpace(border.CGImage),
                                                CGImageGetBitmapInfo(border.CGImage));
    
    CGContextDrawImage(bitmap, CGRectMake(0, 0, size.width, size.height), border.CGImage);
    CGContextDrawImage(bitmap, CGRectMake(borderPadding, borderPadding, size.width - borderWidth, size.height - borderWidth), image.CGImage);
    CGImageRef overlayedImageRef = CGBitmapContextCreateImage(bitmap);
    
    UIImage *overlayedImage = [UIImage imageWithCGImage:overlayedImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(overlayedImageRef);
    
    return overlayedImage;
}

+ (UIImage*) border {
    return [UIImage imageNamed:@"border.png"];
}

+ (UIImage*) drawImage:(UIImage*)topImage onImage:(UIImage*)bottomImage scaledToSize:(CGSize)size {
    CGFloat borderWidth = size.width * BORDER_SCALAR;
    CGFloat borderPadding = borderWidth/2.0;
    
    // The bitsPerComponent and bitmapInfo values are hard-coded to prevent an "unsupported parameter combination" error
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                size.width,
                                                size.height,
                                                8,
                                                0,
                                                CGImageGetColorSpace(topImage.CGImage),
                                                CGImageGetBitmapInfo(topImage.CGImage));
    
    CGContextDrawImage(bitmap, CGRectMake(0, 0, size.width, size.height), bottomImage.CGImage);
    CGContextDrawImage(bitmap, CGRectMake(borderPadding, borderPadding, size.width - borderWidth, size.height - borderWidth), topImage.CGImage);
    CGImageRef overlayedImageRef = CGBitmapContextCreateImage(bitmap);
    
    UIImage *overlayedImage = [UIImage imageWithCGImage:overlayedImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(overlayedImageRef);
    
    return overlayedImage;
}

@end
