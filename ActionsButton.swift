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
        
        prepareImage()
        
        if useLargerImage {
            
            notifier.addObserver(self, selector: #selector(prepareImage), name: .showTabBarLabelsChanged, object: nil)
        }
    }
    
    @objc func prepareImage() {
        
        let image: UIImage = {
            
            if useLargerImage {
                
                return /*showTabBarLabels ? #imageLiteral(resourceName: "Actions20") : */#imageLiteral(resourceName: "Actions22")
                
            } else if useMiddleImage {
                
                return #imageLiteral(resourceName: "Actions18")
                
            } else if useSmallestImage {
                
                return #imageLiteral(resourceName: "Actions13")
                
            } else {
                
                return #imageLiteral(resourceName: "Actions15")
            }
        }()
        
        setImage(image, for: .normal)
    }
}
