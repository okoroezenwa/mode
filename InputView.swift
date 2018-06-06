//
//  InputView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 08/11/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class InputView: UIView {

    @IBOutlet weak var pickerView: UIPickerView!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        resetColour()
        
        notifier.addObserver(self, selector: #selector(resetColour), name: .themeChanged, object: nil)
    }
    
    @objc func resetColour() {
        
        backgroundColor = darkTheme ? UIColor.init(red: 0.12, green: 0.12, blue: 0.12, alpha: 1) : UIColor.init(red: 0.97, green: 0.97, blue: 0.96, alpha: 1)
    }
}
