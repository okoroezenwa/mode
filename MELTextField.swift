//
//  MELTextField.swift
//  Melody
//
//  Created by Ezenwa Okoro on 11/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELTextField: UITextField {
    
    @objc var bordered = false
    @objc var allowFontChange = true
    
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
    
    override var placeholder: String? {
        
        didSet {
            
            preparePlaceholder()
        }
    }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        changeThemeColor()
        returnKeyType = .done
        
        if allowFontChange {
            
            changeFont()
            
            notifier.addObserver(self, selector: #selector(changeFont), name: .activeFontChanged, object: nil)
        }
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        tintColor = darkTheme ? .white : .black
        keyboardAppearance = darkTheme ? .dark : .light
        textColor = Themer.textColour(for: .title)
        
        if bordered {
            
            backgroundColor = UIColor.black.withAlphaComponent(darkTheme ? 0.2 : 0.05)// darkTheme ? UIColor.black.withAlphaComponent(0.1) : UIColor.white.withAlphaComponent(0.1)
        }
        
        preparePlaceholder()
    }
    
    @objc func changeFont() {
        
        font = UIFont.font(ofWeight: FontWeight(rawValue: fontWeight) ?? .regular, size: (TextStyle(rawValue: textStyle) ?? .body).textSize())
        
        preparePlaceholder()
    }
    
    func preparePlaceholder() {
        
        guard let placeholder = placeholder else { return }
        
        attributedPlaceholder = NSAttributedString.init(string: placeholder, attributes: [
            
            .font: UIFont.font(ofWeight: FontWeight(rawValue: fontWeight) ?? .regular, size: (TextStyle(rawValue: textStyle) ?? .body).textSize()),
            .foregroundColor: Themer.themeColour(alpha: 0.3)
        ])
    }
}
