//
//  SwiperTableViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 20/07/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SwiperTableViewCell: UITableViewCell {
    
    var leftSwipeView: MELBorderView!
    var leftSwipeViewLeadingConstraint: NSLayoutConstraint?
    var mainViewTrailingConstraint: NSLayoutConstraint?
    var mainViewLeadingConstraint: NSLayoutConstraint?
    var leftSwipeLabelLeadingConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)
    }

}
