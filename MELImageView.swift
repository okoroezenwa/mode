//
//  MELImageView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 26/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELImageView: UIImageView {
    
    @objc var greyOverride = false {
        
        didSet {
            
            changeThemeColor()
        }
    }
    
    @objc var lightOverride = false {
        
        didSet {
            
            changeThemeColor()
        }
    }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        alpha = 1
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    override init(image: UIImage?) {
        
        super.init(image: image)
        
        self.contentMode = .scaleAspectFit
        
        alpha = 1
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    @objc func changeThemeColor() {
        
        tintColor = lightOverride ? Themer.tempInactiveColours : Themer.textColour(for: greyOverride ? .subtitle : .title)
    }
}
