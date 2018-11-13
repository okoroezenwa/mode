//
//  ScrollHeaderSubview.swift
//  Melody
//
//  Created by Ezenwa Okoro on 01/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ScrollHeaderSubview: UIView {

    @IBOutlet var imageViewContainer: UIView!
    @IBOutlet var imageView: MELImageView!
    @IBOutlet var label: MELLabel!
    @IBOutlet var imageViewContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var labelBottomConstraint: NSLayoutConstraint!
    
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
        view.label.textStyle = TextStyle.body.rawValue
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
        view.label.textStyle = TextStyle.secondary.rawValue
        view.imageView.image = image
        view.imageViewContainerWidthConstraint.constant = imageSize
        
        return view
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        updateSpacing()
        
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
    }
    
    @objc func updateSpacing() {
        
        labelBottomConstraint.constant = abs(2 - FontManager.shared.buttonInset)
    }
}
