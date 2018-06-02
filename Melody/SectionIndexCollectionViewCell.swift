//
//  FilterPropertyCollectionViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 15/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SectionIndexCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var label: MELLabel!
    @IBOutlet weak var borderView: MELBorderView!
    @IBOutlet weak var borderViewProportionalWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var borderViewWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
    }
}
