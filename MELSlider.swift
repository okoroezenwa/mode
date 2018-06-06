//
//  MELSlider.swift
//  Melody
//
//  Created by Ezenwa Okoro on 26/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELSlider: UISlider {
    
    @objc var border = false
    @objc var size: CGFloat = 8
    @objc var brightness = false

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        if #available(iOS 11, *) {
            
            accessibilityIgnoresInvertColors = false
        }
        
        maximumTrackTintColor = (darkTheme ? UIColor.white : UIColor.black).withAlphaComponent(border ? 0.05 : 0.1)
        minimumTrackTintColor = border ? (darkTheme ? UIColor.white.withAlphaComponent(0.5) : UIColor.black.withAlphaComponent(0.5)) : (darkTheme ? .white : .black)
        
        if border {
            
            thumbTintColor = .clear
            
        } else {
            
            setThumbImage(UIImage.new(withColour: darkTheme ? .white : .black, size: CGSize.init(width: size * 2, height: size * 2)).at(CGSize.init(width: size, height: size)).withCornerRadii(size / 2), for: .normal)
        }
        
        if brightness {
            
            minimumValueImage = #imageLiteral(resourceName: "MinBrightness12")
            maximumValueImage = #imageLiteral(resourceName: "MaxBrightness16")
        }
    }
}
