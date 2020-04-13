//
//  SearchLeftView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 22/03/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SearchLeftView: UIView {

    @IBOutlet var propertyButton: MELButton!
    @IBOutlet var testButton: MELButton!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
    }
    
    class var instance: SearchLeftView {
            
        let view = Bundle.main.loadNibNamed("SearchLeftView", owner: nil, options: nil)?.first as! SearchLeftView
        
        return view
    }
}
