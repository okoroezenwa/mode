//
//  RecentSearchTableViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 28/02/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class RecentSearchTableViewCell: UITableViewCell {

    @IBOutlet var searchCategoryImageView: MELImageView!
    @IBOutlet var termLabel: MELLabel!
    @IBOutlet var criteriaLabel: MELLabel!
    @IBOutlet var borderView: MELBorderView!
    
    weak var delegate: (FilterContainer & UIViewController)?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        selectedBackgroundView = MELBorderView()
        
        preservesSuperviewLayoutMargins = false
        contentView.preservesSuperviewLayoutMargins = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        borderView.alphaOverride = selected ? 0.05 : 0
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
        super.setHighlighted(highlighted, animated: animated)
        
        borderView.alphaOverride = highlighted ? 0.05 : 0
    }

    @IBAction func deleteTerm() {
        
        delegate?.deleteRecentSearch(in: self)
    }
}
