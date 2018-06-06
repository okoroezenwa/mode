//
//  MELLabel.swift
//  Melody
//
//  Created by Ezenwa Okoro on 26/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELLabel: UILabel {
    
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
    
    var attributes: [Attributes]? {
        
        didSet {
            
            guard updateTheme else { return }
            
            changeThemeColor()
        }
    }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        alpha = 1
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        alpha = 1
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    convenience init(fontWeight weight: UIFont.FontWeight, fontSize size: CGFloat, alignment: NSTextAlignment) {
        
        self.init(frame: .zero)
        
        font = .myriadPro(ofWeight: weight, size: size)
        textAlignment = alignment
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    @objc func changeThemeColor() {
        
        let colour = lightOverride ? Themer.tempInactiveColours : Themer.textColour(for: greyOverride ? .subtitle : .title)
        textColor = colour
        
        if let attributes = attributes, let text = text {
            
            let attributed = NSMutableAttributedString.init(string: text)
            
            attributed.addAttribute(.foregroundColor, value: colour, range: text.nsRange())
            attributes.forEach({ attributed.addAttribute($0.name, value: $0.trueValue, range: $0.range) })
            
            attributedText = attributed
        }
    }
}
