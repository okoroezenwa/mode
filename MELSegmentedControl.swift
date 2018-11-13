//
//  MELSegmentedControl.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELSegmentedControl: UISegmentedControl {

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        changeThemeColor()
        
        setTitleTextAttributes([NSAttributedString.Key.font: UIFont.font(ofWeight: .regular, size: 15)], for: .normal)
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        tintColor = darkTheme ? .white : .black
    }
}
