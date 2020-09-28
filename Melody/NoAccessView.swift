//
//  NoAccessView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 01/01/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class NoAccessView: UIView, ThemeStatusProvider {
    
    @IBOutlet var imageView: InvertIgnoringImageView!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        updateArtwork()
        
        notifier.addObserver(self, selector: #selector(updateArtwork), name: .themeChanged, object: nil)
    }
    
    @objc func updateArtwork() {
        
        let prefix = "NoArtwork"
        let suffix = "20"
        let infix = darkTheme ? "Dark" : "Light"
        
        imageView.image = #imageLiteral(resourceName: prefix + infix + suffix)
    }

    @IBAction func openSettings() {
    
        if let appSettings = URL.init(string: UIApplication.openSettingsURLString) {
            
            UIApplication.shared.openURL(appSettings)
        }
    }
}
