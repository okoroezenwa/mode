//
//  InvertIgnoringImageView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 23/08/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class InvertIgnoringImageView: UIImageView {

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        layer.setRadiusTypeIfNeeded()
        
        if #available(iOS 11, *) {
            
            accessibilityIgnoresInvertColors = true
        }
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        translatesAutoresizingMaskIntoConstraints = false
        layer.setRadiusTypeIfNeeded()
        
        if #available(iOS 11, *) {
            
            accessibilityIgnoresInvertColors = true
        }
    }
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
    }
}
