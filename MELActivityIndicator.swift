//
//  MELActivityIndicator.swift
//  Melody
//
//  Created by Ezenwa Okoro on 26/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELActivityIndicatorView: UIActivityIndicatorView {

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    init() {
        
        super.init(frame: .zero)
        
        changeThemeColor()
        translatesAutoresizingMaskIntoConstraints = false
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    required init(coder: NSCoder) {
        
        super.init(coder: coder)
    }
    
    @objc func changeThemeColor() {
        
        color = darkTheme ? .white : .black
    }
}
