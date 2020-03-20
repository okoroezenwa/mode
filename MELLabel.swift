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
    
    @objc var reversed = false
    @objc var allowFontChange = true
    @objc var scaleFactor: CGFloat = 1
    var colorOverride: UIColor? {
        
        didSet {
            
            guard updateTheme else { return }
            
            changeThemeColor()
        }
    }
    
    @objc var fontWeight = FontWeight.regular.rawValue {
        
        didSet {
            
            changeFont()
        }
    }
    
    @objc var textStyle = TextStyle.body.rawValue {
        
        didSet {
            
            changeFont()
        }
    }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        prepare()
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        prepare()
    }
    
    func prepare() {
        
        alpha = 1
        
        adjustsFontSizeToFitWidth = true
        minimumScaleFactor = scaleFactor
        
        changeThemeColor()
        
        if allowFontChange {
            
            changeFont()
            
            notifier.addObserver(self, selector: #selector(changeFont), name: .activeFontChanged, object: nil)
        }
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    convenience init(fontWeight weight: FontWeight, textStyle style: TextStyle, alignment: NSTextAlignment) {
        
        self.init(frame: .zero)
        self.fontWeight = weight.rawValue
        self.textStyle = style.rawValue
        
        textAlignment = alignment
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    @objc func changeThemeColor() {
        
        let colour = colorOverride ?? (reversed ? (lightOverride ? Themer.reversedTempInactiveColours : Themer.reversedTextColour(for: greyOverride ? .subtitle : .title)) : (lightOverride ? Themer.tempInactiveColours : Themer.textColour(for: greyOverride ? .subtitle : .title)))
        textColor = colour
        
        if let attributes = attributes, let text = text {
            
            let attributed = NSMutableAttributedString.init(string: text)
            
            attributed.addAttribute(.foregroundColor, value: colour, range: text.nsRange())
            attributes.forEach({ attributed.addAttribute($0.name, value: $0.trueValue, range: $0.range) })
            
            attributedText = attributed
        }
    }
    
    @objc func changeFont() {
        
        guard allowFontChange else { return }
        
        font = UIFont.font(ofWeight: FontWeight(rawValue: fontWeight) ?? .regular, size: (TextStyle(rawValue: textStyle) ?? .body).textSize())
    }
}
