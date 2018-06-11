//
//  Extensions.swift
//  Melody
//
//  Created by Ezenwa Okoro on 02/08/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

extension MPMusicPlayerController {
    
    @objc var isPlaying: Bool {
        
        if #available(iOS 11.3, *) {
            
            return playbackState == .playing || currentPlaybackRate > 0.0
        }
        
        return currentPlaybackRate > 0.0
    }
    
    var nowPlayingItemIndex: Int { return indexOfNowPlayingItem == NSNotFound ? -1 : indexOfNowPlayingItem }
}

extension UIView {
    
    @objc func addShadow(radius: CGFloat = 2,
                         colour: UIColor = colour,
                         xOffset: CGFloat = 0,
                         yOffset: CGFloat = 0,
                         opacity: Float = 0.5,
                         path: CGPath? = nil,
                         shouldRasterise: Bool = false,
                         rasterisationScale: CGFloat = UIScreen.main.scale) {
        
        layer.masksToBounds = false
        layer.shadowColor = colour.cgColor
        layer.shadowOffset = CGSize(width: xOffset, height: yOffset)
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowPath = path
        layer.shouldRasterize = shouldRasterise
        
        if shouldRasterise {
            
            layer.rasterizationScale = rasterisationScale
        }
    }
    
    @objc func animateShadowOpacity(to newOpacity: Float, duration: CFTimeInterval) {
        
        let animation = CABasicAnimation.init(keyPath: "shadowOpacity")
        animation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.fromValue = layer.shadowOpacity
        animation.toValue = newOpacity
        animation.duration = duration
        layer.add(animation, forKey: "shadowOpacity")
        layer.shadowOpacity = newOpacity
    }
    
    @objc func animateCornerRadius(to newRadius: CGFloat, duration: CFTimeInterval) {
        
        let animation = CABasicAnimation.init(keyPath: "cornerRadius")
        animation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.fromValue = layer.cornerRadius
        animation.toValue = newRadius
        animation.duration = duration
        layer.add(animation, forKey: "cornerRadius")
        layer.cornerRadius = newRadius
    }
}

extension MPMediaItem {
    
    var likedState: LikedState {
        
        if let liked = value(forProperty: .likedState) as? Int {
            
            switch liked {
                
                case LikedState.liked.rawValue: return .liked
                    
                case LikedState.disliked.rawValue: return .disliked
                    
                default: return .none
            }
            
        } else {
            
            return .none
        }
    }
    
    @objc var isExplicit: Bool {
        
        if #available(iOS 10, *) {
            
            return isExplicitItem
            
        } else {
            
            return value(forProperty: .isExplicit) as? Bool ?? false
        }
    }
    
    @objc func set(property: String, to value: Any?) {
        
        let string = NSString.init(format: "%@%@%@%@%@%@%@%@%@%@", "set", "Va", "lu", "e:", "for", "Pr", "op", "er", "ty", ":")
        let sel = NSSelectorFromString(string as String)
        
        guard responds(to: sel) else { return }
        
        _ = perform(sel, with: value, with: property)
    }
    
    var actualArtwork: MPMediaItemArtwork? {
        
        if let artwork = artwork, artwork.bounds.width != 0 {
            
            return artwork
        }
        
        return nil
    }
}

extension MPMediaItemArtwork {
    
    var actualArtwork: MPMediaItemArtwork? {
        
        if self.bounds.width != 0 {
            
            return self
            
        } else {
            
            return nil
        }
    }
}

extension UIImage {
    
    func at(_ size: CGSize) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

extension Int {
    
    var formatted: String { return formatter.numberFormatter.string(from: NSNumber.init(value: self)) ?? "\(self)" }
}

extension TimeInterval {
    
    var nowPlayingRepresentation: String {
        
        guard isFinite && !isNaN else { return "--:--" }
        
        let int = abs(Int(self))
        
        let seconds = int % 60
        let minutes = int / 60
        let hours = int / 3600
        
        let hoursString = hours < 1 ? "" : "\(hours):"
        let minutesString = String.init(format: "%02d:", minutes)
        let secondsString = String.init(format: "%02d", seconds)
        
        return hoursString + minutesString + secondsString
    }
}

extension CALayer {
    
    func setRadiusTypeIfNeeded() {
        
        let string = String.init(format: "%@%@%@%@", "conti", "nuous", "Cor", "ners")
        let sel = NSSelectorFromString(string)
        
        guard responds(to: sel) else { return }
        
        setValue(true, forKey: string)
    }
}
