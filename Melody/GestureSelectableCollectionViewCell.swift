//
//  GestureSelectableCollectionViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 24/11/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class GestureSelectableCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var selectedBorderView: MELBorderView!
    @IBOutlet var imageView: MELImageView!
    @IBOutlet var label: MELLabel!
    
    var useBorderView = true {
        
        didSet {
            
            guard oldValue != useBorderView else { return }
            
            selectedBackgroundView = useBorderView ? nil : MELBorderView()
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
    }
    
    func prepare(with text: String?, image: UIImage? = nil, style: TextStyle = .body) {
        
        label.text = text
        label.textStyle = style.rawValue
        imageView.image = image
        imageView.isHidden = image == nil
    }
}
