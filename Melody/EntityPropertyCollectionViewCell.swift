//
//  EntityPropertyCollectionViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 14/09/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class EntityPropertyCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: MELImageView!
    @IBOutlet var label: MELLabel!
    @IBOutlet var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var imageContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var stackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var stackViewBottomConstraint: NSLayoutConstraint!
    
    enum EntityPropertyContext { case header, cell }
    
    var context = EntityPropertyContext.cell {
        
        didSet {
            
            guard oldValue != context, let _ = label, let _ = stackViewTopConstraint, let _ = stackViewBottomConstraint else { return }
            
            prepareConstraints()
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        prepareConstraints()
    }
    
    func prepareConstraints() {
        
        label.textStyle = {
            
            switch context {
                
                case .cell: return TextStyle.secondary.rawValue
                
                case .header: return TextStyle.body.rawValue
            }
        }()
        
        stackViewTopConstraint.constant = {
            
            switch context {
                
                case .cell: return 0
                
                case .header: return 17
            }
        }()
        
        stackViewBottomConstraint.constant = {
            
            switch context {
                
                case .cell: return 0
                
                case .header: return 7
            }
        }()
    }
    
    func prepare(with image: UIImage?, text: String?, property: SecondaryCategory) {
        
        imageView.image = image
        label.text = text
        
        let details = property.imageProperties
        imageViewTrailingConstraint.constant = (text == nil || image == nil) ? 0 : context == .cell ? details.spacing : 4
        imageContainerWidthConstraint.constant = image == nil ? 0 : context == .cell ? details.size : property.largeSize
    }
}
