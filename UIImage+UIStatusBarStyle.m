//
//  UIImage+UIStatusBarStyle.m
//  Melody
//
//  Created by Ezenwa Okoro on 06/08/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

#import "UIImage+UIStatusBarStyle.h"

@implementation UIImage (UIStatusBarStyle)

- (UIStatusBarStyle)statusBarStyle {
    UIGraphicsBeginImageContextWithOptions((CGSize){1, 1}, NO, 0.0);
    [self drawInRect:(CGRect){0, 0, 1, 1}];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    BOOL imageIsLight = NO;
    
    CGImageRef imageRef = [img CGImage];
    CGDataProviderRef dataProviderRef = CGImageGetDataProvider(imageRef);
    NSData *pixelData = (__bridge_transfer NSData *)CGDataProviderCopyData(dataProviderRef);
    
    if ([pixelData length] > 0) {
        const UInt8 *pixelBytes = [pixelData bytes];
        
        // Whether or not the image format is opaque, the first byte is always the alpha component, followed by RGB.
        uint8_t pixelR = pixelBytes[1];
        uint8_t pixelG = pixelBytes[2];
        uint8_t pixelB = pixelBytes[3];
        
        // Calculate the perceived luminance of the pixel; the human eye favors green, followed by red, then blue.
        double percievedLuminance = 1 - (((0.299 * pixelR) + (0.587 * pixelG) + (0.114 * pixelB)) / 255);
        
        imageIsLight = percievedLuminance < 0.5;
    }
    
    return imageIsLight ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}

@end
