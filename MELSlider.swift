//
//  MELSlider.swift
//  Melody
//
//  Created by Ezenwa Okoro on 26/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELSlider: UISlider {
    
    @objc var border = false {
        
        didSet {
            
            guard oldValue != border else { return }
            
            changeThemeColor()
        }
    }
    @objc var size: CGFloat = 8
    @objc var brightness = false

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        maximumTrackTintColor = (darkTheme ? UIColor.white : UIColor.black).withAlphaComponent(border ? 0.05 : 0.1)
        minimumTrackTintColor = border ? (darkTheme ? UIColor.white.withAlphaComponent(0.5) : UIColor.black.withAlphaComponent(0.5)) : (darkTheme ? .white : .black)
            
        thumbTintColor = .clear
            
        [UIButton.State.normal, .application, .disabled, .focused, .highlighted, .reserved, .selected].forEach({ setThumbImage(UIImage.new(withColour: border ? .clear : Themer.themeColour(), size: .square(of: size * 2)).at(.square(of: size)).withCornerRadii(size / 2), for: $0) })
        
        if brightness {
            
            minimumValueImage = #imageLiteral(resourceName: "MinBrightness12")
            maximumValueImage = #imageLiteral(resourceName: "MaxBrightness16")
        }
    }
}
