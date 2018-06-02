//
//  TableFooterView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 21/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TableFooterView: UITableViewHeaderFooterView {

    @IBOutlet weak var label: MELLabel! {
        
        didSet {
            
            textLabel?.text = nil
        }
    }
}
