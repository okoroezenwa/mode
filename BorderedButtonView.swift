//
//  BorderedButtonView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 18/08/2019.
//  Copyright © 2019 Ezenwa Okoro. All rights reserved.
//

import UIKit

class BorderedButtonViewContainer: UIView {
    
    lazy var borderedButtonView: BorderedButtonView = {
        
        let view = Bundle.main.loadNibNamed("BorderedButtonView", owner: nil, options: nil)?.first as! BorderedButtonView
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    var title: String? {
        
        didSet {
            
            borderedButtonView.label?.text = title
        }
    }
    var image: UIImage? {
        
        didSet {
            
            borderedButtonView.imageView?.image = image
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        fill(with: borderedButtonView)
    }
}

class BorderedButtonView: MELBorderView {
    
    @IBOutlet var label: MELLabel?
    @IBOutlet var imageView: MELImageView?
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var imageViewBottomConstraint: NSLayoutConstraint!
}
