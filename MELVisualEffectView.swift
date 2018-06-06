//
//  MELVisualEffectView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELVisualEffectView: UIVisualEffectView {
    
    @objc var alphaOverride: CGFloat = 0
    @objc var vibrant = false
    @objc var vibrantContaining = false
    @objc var light = false
    @objc var darkAlphaOverride: CGFloat = 0
    @objc var verticallyPresented = false

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    override init(effect: UIVisualEffect?) {
        
        super.init(effect: effect)
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    convenience init() {
        
        self.init(effect: UIBlurEffect.init(style: .light))
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    @objc func changeThemeColor() {
        
        if vibrant {
            
            if let _ = effect {
                
                effect = Themer.vibrancyEffect
            }
        
        } else if vibrantContaining {
            
            if let _ = effect {
                
                effect = Themer.vibrancyContainingEffect
                backgroundColor = Themer.vibrancyContainingBackground
            }
        
        } else {
            
            effect = Themer.vibrancyContainingEffect
            backgroundColor = .clear
            contentView.backgroundColor = darkTheme ? (light ? UIColor.white.withAlphaComponent(0.1) : UIColor.darkGray.withAlphaComponent(darkAlphaOverride)) : UIColor.white.withAlphaComponent((verticallyPresented ? 0.6 : 0.4) - alphaOverride)
        }
    }
}
