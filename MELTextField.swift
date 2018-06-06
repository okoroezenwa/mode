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
    @objc var fontSize: CGFloat = 15

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        changeThemeColor()
        returnKeyType = .done
        
        font = .myriadPro(ofWeight: .regular, size: fontSize)
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        tintColor = darkTheme ? .white : .black
        keyboardAppearance = darkTheme ? .dark : .light
        textColor = Themer.textColour(for: .title)
        
        if bordered {
            
            backgroundColor = darkTheme ? UIColor.black.withAlphaComponent(0.1) : UIColor.white.withAlphaComponent(0.1)
        }
        
        guard let placeholder = placeholder else { return }
        
        attributedPlaceholder = NSAttributedString.init(string: placeholder, attributes: [
            
            .font: UIFont.myriadPro(ofWeight: .regular, size: fontSize),
            .foregroundColor: Themer.themeColour(alpha: 0.3)//textColour(for: .subtitle)
        ])
    }
}
