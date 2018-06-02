//
//  NoAccessView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 01/01/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class NoAccessView: UIView {

    @IBAction func openSettings() {
    
        if let appSettings = URL.init(string: UIApplicationOpenSettingsURLString) {
            
            UIApplication.shared.openURL(appSettings)
        }
    }
}
