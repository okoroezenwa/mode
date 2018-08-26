//
//  MELGradientView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 26/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    var gradient = CAGradientLayer()
    @objc var horizontal = true
    @objc var midStart: Float = 0.06
    @objc var midEnd: Float = 0.94

    override func awakeFromNib() {
        
        if horizontal {
            
            gradient.startPoint = CGPoint.init(x: 0, y: 0.5)
            gradient.endPoint = CGPoint.init(x: 1, y: 0.5)
        }
        
        gradient.anchorPoint = .zero
        gradient.locations = [0, NSNumber.init(value: midStart), NSNumber.init(value: midEnd), 1]
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradient.shouldRasterize = true
        gradient.rasterizationScale = UIScreen.main.scale
        layer.mask = gradient 
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        updateGradient()
    }
    
    func updateGradient() {
        
        gradient.frame = bounds
    }
}
