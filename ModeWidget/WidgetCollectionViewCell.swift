//
//  WidgetCollectionViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 02/08/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class WidgetCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var artworkContainer: UIView!
    @IBOutlet var selectedView: UIView!
    @IBOutlet var artworkContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var artworkContainerTrailingConstraint: NSLayoutConstraint!
    
    lazy var artworkImageView = InvertIgnoringImageView.init(frame: .zero)
    
    override var isSelected: Bool {
        
        didSet {
            
            selectedView.isHidden = !self.isSelected
        }
    }
    
    override var isHighlighted: Bool {
        
        didSet {
            
            selectedView.isHidden = !self.isHighlighted
        }
    }
    
    var isUpdated = false {
        
        didSet {
            
            guard isUpdated != oldValue else { return }
            
            layoutIfNeeded()
            
            updateCornersAndShadows()
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        artworkImageView.clipsToBounds = true
        artworkContainer.addSubview(artworkImageView)
        
        contentView.layoutMargins = .zero
        
        NSLayoutConstraint.activate([
        
            artworkImageView.topAnchor.constraint(equalTo: artworkContainer.topAnchor),
            artworkImageView.leadingAnchor.constraint(equalTo: artworkContainer.leadingAnchor),
            artworkImageView.trailingAnchor.constraint(equalTo: artworkContainer.trailingAnchor),
            artworkImageView.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor),
        ])
        
        artworkContainer.bringSubviewToFront(selectedView)
        
        updateCornersAndShadows()
    }
    
    @objc func updateCornersAndShadows() {
        
        [artworkImageView, selectedView].forEach({
            
            let cornerRadius = CornerRadius(rawValue: sharedCornerRadius) ?? .large
            
            (CornerRadius(rawValue: sharedWidgetCornerRadius) ?? cornerRadius).updateCornerRadius(on: $0?.layer, using: artworkImageView.bounds.width, globalRadiusType: cornerRadius)
        })
        
        artworkContainer.addShadow(radius: 4, opacity: 0.3, shouldRasterise: true)
    }
    
    func prepare(with item: MPMediaItem?, index: Int) {
        
        // x = max spacing, i = index, and n = number of cells in a row
        
        // formula for leading is ((no - index) / no) * max
        // formula for trailing is max * (1 - ((no - (index + 1)) / no))
        
        let i = CGFloat(index)
        let x: CGFloat = 10
        let n: CGFloat = 5
        
        let leading = ((n - i) / n) * x
        let trailing = (1 - ((n - (i + 1)) / n)) * x
        
        artworkContainerLeadingConstraint.constant = leading// - 8
        artworkContainerTrailingConstraint.constant = trailing// - 8
        
        artworkImageView.image = item?.artwork?.image(at: artworkContainer.frame.size) ?? #imageLiteral(resourceName: "NoSong75")
        
        isUpdated = true
    }
}
