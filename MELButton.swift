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
    
    @objc var allowFontChange = true
    @objc var scaleFactor: CGFloat = 1
    
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
    
    private var inputReplacement: UIView?
    override var inputView: UIView? {
        
        get { return inputReplacement }
        
        set { inputReplacement = newValue }
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.frame = frame
        
        prepare()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    func prepare() {
        
        guard !ignoreTheme else { return }
        
        changeThemeColor()
        
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = scaleFactor
        
        if allowFontChange {
            
            changeFont()
            
            notifier.addObserver(self, selector: #selector(changeFont), name: .activeFontChanged, object: nil)
        }
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        prepare()
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
    
    @objc func changeFont() {
        
        titleLabel?.font = UIFont.font(ofWeight: FontWeight(rawValue: fontWeight) ?? .regular, size: (TextStyle(rawValue: textStyle) ?? .body).textSize())
    }
}
