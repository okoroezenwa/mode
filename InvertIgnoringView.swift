//
//  InvertIgnoringView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 23/08/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class InvertIgnoringView: UIView {

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        if #available(iOS 11, *) {
            
            accessibilityIgnoresInvertColors = true
        }
    }
}
