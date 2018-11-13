//
//  FilterPropertyCollectionViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 15/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SectionIndexCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var label: MELLabel!
    @IBOutlet var borderView: MELBorderView!
    @IBOutlet var borderViewProportionalWidthConstraint: NSLayoutConstraint!
    @IBOutlet var borderViewWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
    }
}
