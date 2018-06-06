//
//  ActionsButton.swift
//  Mode
//
//  Created by Ezenwa Okoro on 03/02/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ActionsButton: MELButton {
    
    @objc var useLargerImage = false
    @objc var useMiddleImage = false
    @objc var useSmallestImage = false
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        setImage(useLargerImage ? #imageLiteral(resourceName: "Actions22") : useMiddleImage ? #imageLiteral(resourceName: "Actions18") : useSmallestImage ? #imageLiteral(resourceName: "Actions13") : #imageLiteral(resourceName: "Actions15"), for: .normal)
    }
}
