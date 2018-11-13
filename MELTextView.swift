//
//  MELTextView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 26/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELTextView: UITextView {
    
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

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        changeThemeColor()
        
        if allowFontChange {
            
            changeFont()
            
            notifier.addObserver(self, selector: #selector(changeFont), name: .activeFontChanged, object: nil)
        }
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        textColor = darkTheme ? .white : .black
        tintColor = darkTheme ? .white : .black
        keyboardAppearance = darkTheme ? .dark : .light
        indicatorStyle = darkTheme ? .white : .black
    }
    
    @objc func changeFont() {
        
        font = UIFont.font(ofWeight: FontWeight(rawValue: fontWeight) ?? .regular, size: (TextStyle(rawValue: textStyle) ?? .body).textSize())
    }
}
