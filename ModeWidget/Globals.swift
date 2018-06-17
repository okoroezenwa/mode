//
//  Globals.swift
//  Melody
//
//  Created by Ezenwa Okoro on 02/08/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

let musicPlayer: MPMusicPlayerController = {
    
    if #available(iOS 10.3, *), !sharedUseSystemPlayer {
        
        return .applicationQueuePlayer

    } else {
    
        return .systemMusicPlayer
    }
}()

let formatter = Formatter.shared

let colour: UIColor = {
    
    if #available(iOS 10, *) {
        
        return .black
        
    } else {
        
        return .white
    }
}()

let alphaColour: UIColor = {
    
    if #available(iOS 10, *) {
        
        return UIColor.black.withAlphaComponent(sharedUseLighterBorders ? 0.05 : 0.08)
        
    } else {
        
        return UIColor.white.withAlphaComponent(sharedUseLighterBorders ? 0.05 : 0.08)
    }
}()

//let itemWidth: CGFloat = {
//    
//    if #available(iOS 10, *) {
//        
//        return (UIScreen.main.bounds.width - 20) / 5
//    }
//    
//    return UIScreen.main.bounds.width / 5
//}()
//
//let itemSize: CGSize = {
//    
//    let width: CGFloat = {
//        
//        if #available(iOS 10, *) {
//            
//            return (UIScreen.main.bounds.width - 20) / 5
//        }
//        
//        return UIScreen.main.bounds.width / 5
//    }()
//    
//    return CGSize.init(width: width, height: width + (18 - (40/3)))
//}()

func getItemWidth(from view: UIView) -> CGFloat {
    
    if #available(iOS 10, *) {
        
        return (view.frame.width - 20) / 5
    }
    
    return view.frame.width / 5
}

func getItemSize(from view: UIView) -> CGSize {
    
    let width: CGFloat = {
        
        if #available(iOS 10, *) {
            
            return (view.frame.width - 20) / 5
        }
        
        return view.frame.width / 5
    }()
    
    return CGSize.init(width: width, height: width + (18 - (40/3)))
}

enum LikedState: Int { case none, liked = 2, disliked = 3 }
enum Position { case leading, middle, trailing }

enum CornerRadius: Int {
    
    case automatic, square, small, large, rounded
    
    func radius(width: CGFloat) -> CGFloat {
        
        switch self {
            
            case .automatic: return CornerRadius.small.radius(width: width)
            
            case .square: return 0
            
            case .small: return ceil((4/66) * width)
            
            case .large: return ceil((14/54) * width)
            
            case .rounded: return width / 2
        }
    }
    
    func updateCornerRadius(on layer: CALayer?, using width: CGFloat, globalRadiusType: CornerRadius) {
        
        let details: RadiusDetails = {
            
            switch globalRadiusType {
                
                case .automatic: return (self.radius(width: width), self != .rounded)
                
                default: return (globalRadiusType.radius(width: width), globalRadiusType != .rounded)
            }
        }()
        
        layer?.setRadiusTypeIfNeeded(to: details.useSmoothCorners)
        layer?.cornerRadius = details.radius
    }
}
