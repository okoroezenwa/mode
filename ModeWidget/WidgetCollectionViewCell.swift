//
//  WidgetCollectionViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 02/08/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class WidgetCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var artworkContainer: UIView!
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var artworkImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var artworkImageViewTrailingConstraint: NSLayoutConstraint!
    
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
        
        updateCornersAndShadows()
    }
    
    @objc func updateCornersAndShadows() {
        
        [artworkImageView, selectedView].forEach({
            
            let cornerRadius = CornerRadius(rawValue: sharedCornerRadius) ?? .large
            
            (CornerRadius(rawValue: sharedWidgetCornerRadius) ?? cornerRadius).updateCornerRadius(on: $0?.layer, using: artworkImageView.bounds.width, globalRadiusType: cornerRadius)
            
//            let details: (radius: CGFloat, useSmoothCorners: Bool) = {
//
//                let cornerRadius = CornerRadius(rawValue: sharedCornerRadius) ?? .small
//
//                switch cornerRadius {
//
//                    case .automatic: return ((CornerRadius(rawValue: sharedWidgetCornerRadius) ?? cornerRadius).radius(width: artworkImageView.bounds.width), (CornerRadius(rawValue: sharedWidgetCornerRadius) ?? cornerRadius) != .rounded)
//
//                    default: return (cornerRadius.radius(width: artworkImageView.bounds.width), cornerRadius != .rounded)
//                }
//            }()
//
//            $0?.layer.setRadiusTypeIfNeeded(to: details.useSmoothCorners)
//            $0?.layer.cornerRadius = details.radius
            
//            $0?.layer.cornerRadius = {
//                
//                let cornerRadius = CornerRadius(rawValue: sharedCornerRadius) ?? .small
//                
//                switch cornerRadius {
//                    
//                    case .automatic: return  (CornerRadius(rawValue: sharedWidgetCornerRadius) ?? cornerRadius).radius(width: artworkImageView.bounds.width)
//                    
//                    default: return cornerRadius.radius(width: artworkImageView.bounds.width)
//                }
//            }()
        })
        
        artworkContainer.addShadow(radius: 4, opacity: 0.3, shouldRasterise: true)
    }
    
    func prepare(with item: MPMediaItem?, position: Position = .leading) {
     
        let insets: UIEdgeInsets = {
            
            let expression: CGFloat = (20/3) - 8
            
            switch position {
                
                case .leading: return .init(top: 0, left: 10 - 8, bottom: 10, right: (10/3) - 8)
                    
                case .middle: return .init(top: 0, left: expression, bottom: 10, right: expression)
                    
                case .trailing: return .init(top: 0, left: (10/3) - 8, bottom: 10, right: 10 - 8)
            }
        }()
        
        artworkImageViewLeadingConstraint.constant = insets.left
        artworkImageViewTrailingConstraint.constant = insets.right
        
        artworkImageView.image = item?.actualArtwork?.image(at: artworkContainer.frame.size) ?? #imageLiteral(resourceName: "NoSong75")
        
        isUpdated = true
    }
}
