//
//  MELSearchBar.swift
//  Melody
//
//  Created by Ezenwa Okoro on 26/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELSearchBar: UISearchBar {
    
    @objc var textField: UITextField?
    @objc var capitalise = false
    
    override var inputView: UIView? {
        
        get { return textField?.inputView }
        
        set {
            
            updateKeyboard(with: newValue)
            
            textField?.inputView = newValue
        }
    }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        prepare(self, withPlaceholder: placeholder ?? "")
        changeThemeColor()
        autocapitalizationType = capitalise ? .words : .none
        returnKeyType = .done
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        setImage(#imageLiteral(resourceName: "SearchThick"), for: .search, state: .normal)
        
        tintColor = darkTheme ? .white : .black
        updateKeyboard(with: inputView)
        
        updateTextField(with: placeholder ?? "")
    }
    
    func updateKeyboard(with inputView: UIView?) {
        
        keyboardAppearance = {
            
            guard inputView == nil else { return .default }
            
            return darkTheme ? .dark : .light
        }()
    }
        
    private func prepare(_ view: UIView, withPlaceholder placeholder: String) {
        
        for subview in view.subviews {
            
            if let textField = subview as? UITextField {
                
                self.textField = textField
                textField.clearButtonMode = .never
                
                updateTextField(with: placeholder)
                
            } else {
                
                prepare(subview, withPlaceholder: placeholder)
            }
        }
    }
    
    @objc func updateTextField(with placeholder: String) {
        
        textField?.defaultTextAttributes = [
            
            NSAttributedStringKey.font.rawValue: UIFont.myriadPro(ofWeight: .regular, size: 17),
            NSAttributedStringKey.foregroundColor.rawValue: Themer.textColour(for: .title)
        ]
        
        textField?.attributedPlaceholder = NSAttributedString.init(string: placeholder, attributes: [
            
            .font: UIFont.myriadPro(ofWeight: .regular, size: 17),
            .foregroundColor: Themer.themeColour(alpha: 0.3)//textColour(for: .subtitle)
        ])
    }
}
