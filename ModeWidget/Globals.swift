//
//  Globals.swift
//  Melody
//
//  Created by Ezenwa Okoro on 02/08/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

var musicPlayer: MPMusicPlayerController {
    
    if #available(iOS 10.3, *), !sharedUseSystemPlayer {
        
        return applicationPlayer

    } else {
    
        return systemPlayer
    }
}

let systemPlayer = MPMusicPlayerController.systemMusicPlayer
let applicationPlayer: MPMusicPlayerController = {
    
    if #available(iOS 10.3, *) {
        
        return .applicationQueuePlayer

    } else {
    
        return .applicationMusicPlayer
    }
}()

let formatter = Formatter.shared

func getItemWidth(from view: UIView) -> CGFloat { view.frame.width / 5 }

func getItemSize(from view: UIView) -> CGSize {
    
    let width = getItemWidth(from: view)
    
    return CGSize.init(width: width, height: width + 10 - 12) // to keep the 1:1 ratio the difference between the left/right and top/bottom constraints are then added.
}

enum LikedState: Int { case none, liked = 2, disliked = 3 }

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
        
        layer?.setRadiusTypeIfNeeded(to: details.useContinuousCorners)
        layer?.cornerRadius = details.radius
    }
}
