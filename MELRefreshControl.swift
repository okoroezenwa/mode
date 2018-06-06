//
//  MELRefreshControl.swift
//  Melody
//
//  Created by Ezenwa Okoro on 16/06/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELRefreshControl: UIRefreshControl {

    override init() {
        
        super.init(frame: .zero)
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    @objc func changeThemeColor() {
        
        tintColor = Themer.textColour(for: .subtitle)
    }
}
