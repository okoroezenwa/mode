//
//  TextFieldsTableViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 10/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TextFieldsTableViewCell: UITableViewCell {

    @IBOutlet var itemImageView: MELImageView!
    @IBOutlet var textField: MELTextField!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)
    }

}
