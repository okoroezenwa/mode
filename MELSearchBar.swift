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
        
        prepare(self, withPlaceholder: placeholder ?? "")
        changeThemeColor()
        autocapitalizationType = capitalise ? .words : .none
        returnKeyType = .done
        
        if allowFontChange {
            
            changeFont()
            
            notifier.addObserver(self, selector: #selector(changeFont), name: .activeFontChanged, object: nil)
        }
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        setImage(#imageLiteral(resourceName: "Search13"), for: .search, state: .normal)
        
        tintColor = darkTheme ? .white : .black
        updateKeyboard(with: inputView)
        
        updateTextField(with: placeholder ?? "")
    }
    
    @objc func changeFont() {
        
        textField?.font = UIFont.font(ofWeight: FontWeight(rawValue: fontWeight) ?? .regular, size: (TextStyle(rawValue: textStyle) ?? .body).textSize())
        
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
                textField.clearButtonMode = .always//.never
                textField.delegate = self
                
                updateTextField(with: placeholder)
                
            } else {
                
                prepare(subview, withPlaceholder: placeholder)
            }
        }
    }
    
    @objc func updateTextField(with placeholder: String) {
        
        textField?.defaultTextAttributes = [
            
            NSAttributedString.Key.font: UIFont.font(ofWeight: .regular, size: 17),
            NSAttributedString.Key.foregroundColor: Themer.textColour(for: .title)
        ]
        
        textField?.attributedPlaceholder = NSAttributedString.init(string: placeholder, attributes: [
            
            .font: UIFont.font(ofWeight: .regular, size: 17),
            .foregroundColor: Themer.themeColour(alpha: 0.3)//textColour(for: .subtitle)
        ])
    }
}

extension MELSearchBar: UITextFieldDelegate {
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        text = nil
        delegate?.searchBar?(self, textDidChange: "")
        
        return false
    }
}
