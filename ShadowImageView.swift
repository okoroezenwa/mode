//
//  ShadowView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 27/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ShadowImageView: UIImageView {
    
    @objc var radius: CGFloat = 0
    @objc var blur: CGFloat = 15
    @objc var length: CGFloat = 5
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        image = .resizableShadowImage(withSideLength: length, cornerRadius: radius, shadow: Shadow(offset: .zero, blur: blur, color: darkTheme ? .gray : .darkGray))
    }
}
