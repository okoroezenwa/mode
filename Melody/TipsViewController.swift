//
//  TipsViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 28/10/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TipsViewController: UIViewController {

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        dismiss(animated: true, completion: nil)
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "TVC going away...").show(for: 0.3)
        }
    }
}
