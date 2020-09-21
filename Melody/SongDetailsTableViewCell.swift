//
//  SongDetailsTableViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 05/05/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SongDetailsTableViewCell: UITableViewCell {
    
    @IBOutlet var typeImageView: MELImageView!
    @IBOutlet var label: MELLabel!
    @IBOutlet var checkImageView: MELImageView!

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        selectedBackgroundView = MELBorderView.init()
        
        preservesSuperviewLayoutMargins = false
        contentView.preservesSuperviewLayoutMargins = false
    }

    func prepare(for detail: SecondaryCategory, visible: Bool) {
        
        label.text = detail.title
        typeImageView.image = detail.largeImage
        
        checkImageView.isHidden = !visible
    }
}
