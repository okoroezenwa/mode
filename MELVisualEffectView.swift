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
    @objc var darkPresentationAccomodation = false
    @objc var verticallyPresented = false
    @objc var floating = false {
        
        didSet {
            
            layer.borderWidth = floating ? 1.1 : 0
            updateEffectViewBorder()
        }
    }
    
    var shadowImageView: ShadowImageView?

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
        
        if floating {
        
            updateEffectViewBorder()
        }
        
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
            
            let dark: UIColor = {
                
                if light {
                    
                    return UIColor.white.withAlphaComponent(0.1)
                    
                } /*else if darkPresentationAccomodation {
                    
                    return UIColor.init(red: 100/255, green: 100/255, blue: 100/255, alpha: 0.3)
                }*/
                
                return UIColor.darkGray.withAlphaComponent(darkAlphaOverride)
            }()
            
            effect = Themer.vibrancyContainingEffect
            backgroundColor = darkTheme ? dark : UIColor.white.withAlphaComponent((verticallyPresented ? 0.6 : 0.4) - alphaOverride)
        }
    }
    
    func updateEffectViewBorder() {
        
        let value = 0.06 as CGFloat
        
        layer.borderColor = darkTheme ? Themer.themeColour().withAlphaComponent(value).cgColor : UIColor.clear.cgColor
    }
}
