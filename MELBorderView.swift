//
//  MELBorderView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELBorderView: UIView {
    
    @objc var white = false
    @objc var alphaOverride: CGFloat = 0 {
        
        didSet {
            
            changeThemeColor()
        }
    }
    @objc var temp = false
    @objc var greyOverride = false {
        
        didSet {
            
            changeThemeColor()
        }
    }
    @objc var reversed = false
    @objc var clear = false {
        
        didSet {
            
            changeThemeColor()
        }
    }
    @objc var bordered = false {
        
        didSet {
            
            changeThemeColor()
        }
    }
    
    @objc var desiredAlpha: CGFloat = 1

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        alpha = desiredAlpha
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .lighterBordersChanged, object: nil)
    }
    
    @objc init(override: CGFloat = 0) {
        
        alphaOverride = override
        
        super.init(frame: .zero)
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .lighterBordersChanged, object: nil)
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .lighterBordersChanged, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    @objc func changeThemeColor() {
        
        guard !temp else {
            
            layer.borderColor = (greyOverride ? Themer.borderViewColor(withAlphaOverride: alphaOverride) : Themer.tempActiveColours).cgColor
            
            return
        }
        
        layer.borderColor = bordered ? Themer.borderViewColor(withAlphaOverride: alphaOverride).cgColor : nil
        
        backgroundColor = {
            
            if white {
                
                return .white
                
            } else {
                
                return clear ? .clear : reversed ? Themer.reversedBorderViewColor(withAlphaOverride: alphaOverride) : Themer.borderViewColor(withAlphaOverride: alphaOverride)
            }
        }()
    }
}
