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
    @IBOutlet var titleLabel: MELLabel!
    @IBOutlet var subtitleLabel: MELLabel!
    @IBOutlet var effectView: UIVisualEffectView!
    @IBOutlet var insets: [NSLayoutConstraint]!
    
    var inset: CGFloat = 10 {
        
        didSet {
            
            guard oldValue != inset else { return }
            
            insets.forEach({ $0.constant = inset })
        }
    }
    
    var useBorderView = true {
        
        didSet {
            
            guard oldValue != useBorderView else { return }
            
            selectedBackgroundView = useBorderView ? nil : MELBorderView(override: 0.03)
        }
    }
    
    var useEffectView = false {
        
        didSet {
            
            guard oldValue != useEffectView else { return }
            
            effectView.isHidden = useEffectView.inverted
            effectView.superview?.layer.cornerRadius = useEffectView ? 15 : 0
            effectView.superview?.clipsToBounds = useEffectView
            selectedBorderView.layer.cornerRadius = useEffectView ? 0 : 10
        }
    }
    
    override var isHighlighted: Bool {
        
        didSet {
            
            guard useBorderView else { return }
            
            selectedBorderView.isHidden = !self.isHighlighted
        }
    }
    
    override var isSelected: Bool {
        
        didSet {
            
            guard useBorderView else { return }
            
            selectedBorderView.isHidden = !self.isSelected
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
    }
    
    func prepare(with title: String?, subtitle: String? = nil, image: UIImage? = nil, style: TextStyle = .body) {
        
        titleLabel.text = title
        titleLabel.textStyle = style.rawValue
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        imageView.image = image
        imageView.superview?.isHidden = image == nil
    }
}
