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
    @IBOutlet var switchContainer: MELSwitchContainer!
    @IBOutlet var edgeConstraints: [NSLayoutConstraint]!
    @IBOutlet var centreConstraints: [NSLayoutConstraint]!
    
    var inset: CGFloat = 10 {
        
        didSet {
            
            guard oldValue != inset else { return }
            
            insets.forEach({ $0.constant = inset })
        }
    }
    
    var useBorderView = true {
        
        didSet {
            
            guard oldValue != useBorderView else { return }
            
            selectedBackgroundView = useBorderView ? nil : MELBorderView(override: 0)
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
        
        selectedBorderView.layer.setRadiusTypeIfNeeded()
        selectedBorderView.layer.cornerRadius = 14
    }
    
    func update(for state: CellState) {
        
        if useBorderView {
            
            selectedBorderView.alphaOverride = state == .selected ? 1 : 0
            selectedBorderView.isHidden = state == .untouched
            
        } else {
            
//            selectedBorderView.isHidden = true
            
            if let borderView = selectedBackgroundView as? MELBorderView {
                
                borderView.alphaOverride = state == .selected ? 1 : 0
                borderView.isHidden = state == .untouched
            }
        }
        
        titleLabel.reversed = state == .selected
        titleLabel.changeThemeColor()
        subtitleLabel.reversed = state == .selected
        subtitleLabel.changeThemeColor()
        imageView.reversed = state == .selected
        imageView.changeThemeColor()
    }
    
    func prepare(with title: String?, subtitle: String? = nil, image: UIImage? = nil, style: TextStyle = .body, switchDetails: (isOn: Bool, action: () -> ())? = nil) {
        
        titleLabel.text = title
        titleLabel.textStyle = style.rawValue
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        imageView.image = image
        imageView.superview?.isHidden = image == nil
        switchContainer.isHidden = {
        
            if let details = switchDetails {
                
                switchContainer.setOn(details.isOn, animated: false)
                switchContainer.action = details.action
                
                return false
            }
            
            return true
        }()
        
        edgeConstraints.forEach({ $0.isActive = switchDetails != nil })
        centreConstraints.forEach({ $0.isActive = switchDetails == nil })
    }
}
