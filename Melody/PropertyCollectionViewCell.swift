//
//  PropertyCollectionViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 25/11/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PropertyCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var label: MELLabel!
    @IBOutlet var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var labelBottomConstraint: NSLayoutConstraint!
    
    override var isSelected: Bool {
        
        didSet {
            
            label.lightOverride = isSelected
        }
    }
    
    override var isHighlighted: Bool {
        
        didSet {
            
            label.lightOverride = isHighlighted
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        updateSpacing()
        
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
    }
    
    @objc func updateSpacing() {
        
        labelBottomConstraint.constant = {
            
            switch activeFont {
                
                case .avenirNext: return 3
                
                case .system: return 4
                
                case .myriadPro: return 5
            }
        }()
    }
}
