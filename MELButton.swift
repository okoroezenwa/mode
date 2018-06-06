//
//  MELButton.swift
//  Melody
//
//  Created by Ezenwa Okoro on 26/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELButton: UIButton {
    
    @objc var greyOverride = false {
        
        didSet {
            
            guard updateTheme else { return }
            
            changeThemeColor()
        }
    }
    
    @objc var lightOverride = false {
        
        didSet {
            
            guard updateTheme else { return }
            
            changeThemeColor()
        }
    }
    
    var updateTheme = true {
        
        didSet {
            
            if updateTheme { changeThemeColor() }
        }
    }
    
    @objc var temp = false
    @objc var ignoreTheme = false
    
    var attributes: [Attributes]? {
        
        didSet {
            
            guard updateTheme else { return }
            
            changeThemeColor()
        }
    }
    
    private var inputReplacement: UIView?
    override var inputView: UIView? {
        
        get { return inputReplacement }
        
        set { inputReplacement = newValue }
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.frame = frame
        
        guard !ignoreTheme else {
            
            if #available(iOS 11, *) {
                
                accessibilityIgnoresInvertColors = true
            }
            
            return
        }
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        guard !ignoreTheme else {
            
            if #available(iOS 11, *) {
                
                accessibilityIgnoresInvertColors = true
            }
            
            return
        }
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        let colour = lightOverride ? Themer.tempInactiveColours : Themer.textColour(for: greyOverride ? .subtitle : .title)
        tintColor = colour
        setTitleColor(colour, for: .normal)
        
        if let attributes = attributes, let text = title(for: .normal) {
            
            let attributed = NSMutableAttributedString.init(string: text)
            
            attributed.addAttribute(.foregroundColor, value: colour, range: text.nsRange())
            attributes.forEach({ attributed.addAttribute($0.name, value: $0.trueValue, range: $0.range) })
            
            setAttributedTitle(attributed, for: .normal)
        }
    }
}
