//
//  HeaderButtonsCollectionViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 19/09/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class HeaderButtonsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: MELImageView!
    @IBOutlet var activityIndicator: MELActivityIndicatorView!
    @IBOutlet var label: MELLabel!
    @IBOutlet var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var borderViewLeadingConstraint: NSLayoutConstraint!
    
    override var isHighlighted: Bool {
        
        didSet {
            
            update(for: isSelected ? .selected : isHighlighted ? .highlighted : .untouched)
        }
    }
    
    override var isSelected: Bool {
        
        didSet {
            
            update(for: isSelected ? .selected : isHighlighted ? .highlighted : .untouched)
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
    }
    
    func prepare(with image: UIImage?, text: String?, index: Int) {
        
        imageView.image = image
        label.text = text
        
        borderViewLeadingConstraint.constant = index == 0 ? 16 : 4
        imageViewTrailingConstraint.constant = text?.isEmpty == false ? 4 : 0
    }
    
    func update(for state: CellState) {
        
        UIView.transition(with: label, duration: 0.1, options: [.transitionCrossDissolve, .allowUserInteraction], animations: { self.label.lightOverride = state == .highlighted }, completion: nil)
        
        UIView.transition(with: imageView, duration: 0.1, options: [.transitionCrossDissolve, .allowUserInteraction], animations: { self.imageView.lightOverride = state == .highlighted }, completion: nil)
    }
}
