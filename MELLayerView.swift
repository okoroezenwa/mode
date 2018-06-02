//
//  MELLayerView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/05/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELLayerView: UIView {
    
    @objc lazy var gradient: CAGradientLayer = {
        
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = [UIColor.clear.cgColor, (darkTheme ? UIColor.black : .white).withAlphaComponent(0.5).cgColor]
        gradient.startPoint = .init(x: 0, y: 0.5)
        gradient.endPoint = .init(x: 1, y: 0.5)
        
        return gradient
    }()

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        layer.insertSublayer(gradient, at: 0)
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        gradient.colors = [UIColor.clear.cgColor, (darkTheme ? UIColor.black : .white).withAlphaComponent(0.5).cgColor]
    }
}
