//
//  File.swift
//  Mode
//
//  Created by Ezenwa Okoro on 21/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

extension UIImage {
    
    func at(_ size: CGSize) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func crop(within rect: CGRect) -> UIImage? {
        
        guard let cgImage = self.cgImage, let imageRef = cgImage.cropping(to: rect) else { return nil }
        
        return UIImage.init(cgImage: imageRef)
    }
    
    class func new(withColour colour: UIColor, size: CGSize?) -> UIImage {
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size ?? CGSize(width: 5, height: 5))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(colour.cgColor);
        context?.fill(rect);
        
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image!;
    }
    
    static func gradientImage(in bounds: CGRect, colors: [UIColor]) -> UIImage {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map({ $0.cgColor })
        
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    static func gradientImage(in bounds: CGRect, colors: UIColor...) -> UIImage {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map({ $0.cgColor })
        
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    class func from(_ view: UIView?) -> UIImage? {
        
        guard let view = view else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
    
    func withCornerRadii(_ cornerRadius: CGFloat) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        self.draw(in: rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    func tint(_ tintColor: UIColor) -> UIImage {
        
        return UIImageEffects.imageByApplyingTintEffect(with: tintColor, to: self)
    }
    
    func blur(with effect: UIBlurEffect.Style) -> UIImage {
        
        switch effect {
            
            case .dark: return UIImageEffects.imageByApplyingDarkEffect(to: self)
            
            case .light: return UIImageEffects.imageByApplyingLightEffect(to: self)
            
            case .extraLight: return UIImageEffects.imageByApplyingExtraLightEffect(to: self)
            
            default: return self
        }
    }
    
    fileprivate func modifiedImage(_ draw: (CGContext, CGRect) -> ()) -> UIImage {
        
        // using scale correctly preserves retina images
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context: CGContext! = UIGraphicsGetCurrentContext()
        assert(context != nil)
        
        // correctly rotate image
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        
        draw(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func translucentImage(withAlpha alpha: CGFloat, colour: UIColor) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        colour.setFill()
        draw(in: bounds, blendMode: CGBlendMode.screen, alpha: alpha)
        
        let translucentImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return translucentImage!
    }
    
    class func collage(ofSize size: CGSize, withImages images: [UIImage]) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        for image in images.enumerated() {
            
            if image.offset == 0 {
                
                image.element.draw(in: CGRect.init(x: 0, y: 0, width: size.width / 2, height: size.height / 2))
                
            } else if image.offset == 1 {
                
                image.element.draw(in: CGRect.init(x: size.width / 2, y: 0, width: size.width / 2, height: size.height / 2))
                
            } else if image.offset == 2 {
                
                image.element.draw(in: CGRect.init(x: 0, y: size.height / 2, width: size.width / 2, height: size.height / 2))
                
            } else {
                
                image.element.draw(in: CGRect.init(x: size.width / 2, y: size.height / 2, width: size.width / 2, height: size.height / 2))
            }
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    var greyscale: UIImage? {
        
        let context = CIContext.init(options: nil)
        
        if let currentFilter: CIFilter = {
            
            let filter = CIFilter(name: "CIPhotoEffectNoir")
            filter?.setValue(CIImage(image: self), forKey: kCIInputImageKey)
            
            return filter
            }(),
            let output = currentFilter.outputImage,
            let cgimg = context.createCGImage(output,from: output.extent) {
            
            return UIImage(cgImage: cgimg)
        }
        
        return nil
    }
    
    class var inactiveEditImage: UIImage { #imageLiteral(resourceName: "EditNoBorder15") }//Edit") }
    class var inactiveEditBorderlessImage: UIImage { #imageLiteral(resourceName: "EditNoBorder13") }
    class var moreEditImage: UIImage { #imageLiteral(resourceName: "MoreBordered13") }
    class var doneImage: UIImage { #imageLiteral(resourceName: "CheckBordered13") }
    class var doneBorderlessImage: UIImage { #imageLiteral(resourceName: "Check13") }
    
    func masked(with mask: UIImage) -> UIImage? {
        
        guard let maskRef = mask.cgImage, let provider = maskRef.dataProvider, let mask = CGImage(
            maskWidth: maskRef.width,
            height: maskRef.height,
            bitsPerComponent: maskRef.bitsPerComponent,
            bitsPerPixel: maskRef.bitsPerPixel,
            bytesPerRow: maskRef.bytesPerRow,
            provider: provider,
            decode: nil,
            shouldInterpolate: true), let masked = cgImage?.masking(mask) else { return nil }
        
        return UIImage(cgImage: masked)
    }
    
    func scaled(to size: CGSize, by multiplier: CGFloat) -> UIImage {
        
        guard size.width * multiplier < self.size.width else { return self }
        
        return self.at(.init(width: size.width * multiplier, height: size.height * multiplier))
    }
    
    func scaled(proportionalTo size: CGSize, by scale: CGFloat) -> UIImage {
        
        let widthRatio = size.width / self.size.width
        let heightRatio = size.height / self.size.height
        
        if widthRatio > heightRatio {
            
            return self.at(.init(width: self.size.width * heightRatio * scale, height: self.size.height * heightRatio * scale))
            
        } else {
            
            return self.at(.init(width: self.size.width * widthRatio * scale, height: self.size.height * widthRatio * scale))
        }
    }
    
    func draw(in rect: CGRect, at index: Int, within array: [UIImage]) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        var imageArray = array
        imageArray.insert(self, at: index)
        
        for image in imageArray {
            
            image.draw(in: rect)
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    static func resizableShadowImage(withSideLength sideLength: CGFloat, cornerRadius: CGFloat, shadow: Shadow) -> UIImage {
        // The image is a square, which makes it easier to set up the cap insets.
        //
        // Note: this implementation assumes an offset of CGSize(0, 0)
        
        let lengthAdjustment = sideLength + (shadow.blur * 2.0)
        let graphicContextSize = CGSize(width: lengthAdjustment, height: lengthAdjustment)
        
        // Note: the image is transparent
        UIGraphicsBeginImageContextWithOptions(graphicContextSize, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()!
        defer {
            UIGraphicsEndImageContext()
        }
        
        let roundedRect = CGRect(x: shadow.blur, y: shadow.blur, width: sideLength, height: sideLength)
        let shadowPath = UIBezierPath(roundedRect: roundedRect, cornerRadius: cornerRadius)
        let color = shadow.color.cgColor
        
        // Cut out the middle
        context.addRect(context.boundingBoxOfClipPath)
        context.addPath(shadowPath.cgPath)
        context.clip(using: .evenOdd)
        
        context.setStrokeColor(color)
        context.addPath(shadowPath.cgPath)
        context.setShadow(offset: shadow.offset, blur: shadow.blur, color: color)
        context.fillPath()
        
        let capInset = cornerRadius + shadow.blur
        let edgeInsets = UIEdgeInsets(top: capInset, left: capInset, bottom: capInset, right: capInset)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        
        return image.resizableImage(withCapInsets: edgeInsets, resizingMode: .tile)
    }
}

struct Shadow {
    
    let offset: CGSize
    let blur: CGFloat
    let color: UIColor
}
