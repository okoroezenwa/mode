//
//  MELVolumeView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 04/08/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELVolumeView: MPVolumeView {
    
    var volumeSlider: UISlider?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        setRouteButtonImage(#imageLiteral(resourceName: "Source17"), for: .normal)
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .MPVolumeViewWirelessRoutesAvailableDidChange, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        if showsVolumeSlider, let slider = volumeSlider {
            
            modify(slider)
            
        } else if showsRouteButton {
            
            modifyTint()
            
        } else {
            
            searchSubviews(in: self)
        }
    }
    
    @objc func searchSubviews(in view: UIView) {
        
        for subview in view.subviews {
            
            if showsVolumeSlider, let slider = subview as? UISlider {
                
                volumeSlider = slider
                modify(slider)
            
            } else if showsRouteButton, let button = subview as? UIButton {
                
                button.adjustsImageWhenHighlighted = true
                modifyTint()
                
            } else {
                
                searchSubviews(in: subview)
            }
        }
    }
    
    func modify(_ slider: UISlider) {
        
        let size: CGFloat = 11

        slider.tintColor = darkTheme ? .white : .black
        slider.minimumTrackTintColor = darkTheme ? .white : .black
        slider.maximumTrackTintColor = (darkTheme ? UIColor.white : UIColor.black).withAlphaComponent(0.1)
        slider.setThumbImage(UIImage.new(withColour: darkTheme ? .white : .black, size: .square(of: size * 2)).at(.square(of: size)).withCornerRadii(size / 2), for: .normal)
        
        if #available(iOS 11, *) {
            
            slider.minimumValueImage = #imageLiteral(resourceName: "VolumeOn")
            slider.maximumValueImage = nil
            
        } else {
            
            if areWirelessRoutesAvailable {
                
                slider.minimumValueImage = #imageLiteral(resourceName: "VolumeOn")
                slider.maximumValueImage = nil
                
            } else {
                
                slider.minimumValueImage = #imageLiteral(resourceName: "VolumeOff")
                slider.maximumValueImage = #imageLiteral(resourceName: "VolumeOn")
            }
        }
    }
    
    func modifyTint() {
        
        tintColor = darkTheme ? .white : .black
    }

    override func volumeSliderRect(forBounds bounds: CGRect) -> CGRect {
        
        return showsVolumeSlider ? bounds : .zero
    }
    
    override func routeButtonRect(forBounds bounds: CGRect) -> CGRect {
        
        return showsRouteButton ? bounds : .zero
    }
}
