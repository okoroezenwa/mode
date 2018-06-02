//
//  ScrollHeaderSubview.swift
//  Melody
//
//  Created by Ezenwa Okoro on 01/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ScrollHeaderSubview: UIView {

    @IBOutlet weak var imageViewContainer: UIView!
    @IBOutlet weak var imageView: MELImageView!
    @IBOutlet weak var label: MELLabel!
    @IBOutlet weak var imageViewContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @objc var showImage = true {
        
        didSet {
            
            if !showImage {
                
                imageViewContainer.isHidden = true
            }
        }
    }
    
    @objc class func with(title: String?, image: UIImage?, useSmallerImage: Bool = false) -> ScrollHeaderSubview {
        
        let view = Bundle.main.loadNibNamed("ScrollHeaderSubview", owner: nil, options: nil)?.first as! ScrollHeaderSubview
        view.label.text = title
        view.imageView.image = image
        view.imageViewContainerWidthConstraint.constant = useSmallerImage ? 14 : 16
        
        return view
    }
    
    @objc class func forCell(title: String?, image: UIImage?, imageSize: CGFloat = 14, useSmallerDistance: Bool = true) -> ScrollHeaderSubview {
        
        let view = Bundle.main.loadNibNamed("ScrollHeaderSubview", owner: nil, options: nil)?.first as! ScrollHeaderSubview
        view.label.greyOverride = true
        view.topConstraint.constant = 0
        view.bottomConstraint.constant = 0
        view.imageViewTrailingConstraint.constant = useSmallerDistance ? 2 : 4
        view.label.text = title
        view.label.font = UIFont.myriadPro(ofWeight: .regular, size: 14)
        view.imageView.image = image
        view.imageViewContainerWidthConstraint.constant = imageSize
        
        return view
    }
}
