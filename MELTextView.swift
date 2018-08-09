//
//  MELTextView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 26/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELTextView: UITextView {

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        textColor = darkTheme ? .white : .black
        tintColor = darkTheme ? .white : .black
        keyboardAppearance = darkTheme ? .dark : .light
        indicatorStyle = darkTheme ? .white : .black
    }
}
