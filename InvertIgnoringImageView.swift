//
//  InvertIgnoringImageView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 23/08/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class InvertIgnoringImageView: UIImageView, EntityArtworkDisplaying {
    
    weak var provider: ThemeStatusProvider?
    
    var artworkType = EntityArtworkType.image(nil) {
        
        didSet {
            
            guard let provider = provider else { return }
            
            image = artworkType.artwork(darkTheme: provider.isDarkTheme)
        }
    }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        layer.setRadiusTypeIfNeeded()
        
        if #available(iOS 11, *) {
            
            accessibilityIgnoresInvertColors = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateImage), name: .themeChanged, object: nil)
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        translatesAutoresizingMaskIntoConstraints = false
        layer.setRadiusTypeIfNeeded()
        
        if #available(iOS 11, *) {
            
            accessibilityIgnoresInvertColors = true
        }
    }
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
    }
    
    @objc func updateImage() {
        
        guard case .empty = artworkType, let provider = provider else { return }
        
        image = artworkType.artwork(darkTheme: provider.isDarkTheme)
    }
}

protocol ThemeStatusProvider: class {
    
    var isDarkTheme: Bool { get }
}
