//
//  PropertyCollectionViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 25/11/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PropertyCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var label: MELLabel!
    @IBOutlet var imageView: MELImageView!
    
    override var isSelected: Bool {
        
        didSet {
            
            label.lightOverride = isSelected
            imageView.lightOverride = isSelected
        }
    }
    
    override var isHighlighted: Bool {
        
        didSet {
            
            label.lightOverride = isHighlighted
            imageView.lightOverride = isHighlighted
        }
    }
}
