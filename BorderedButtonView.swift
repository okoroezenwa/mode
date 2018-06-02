//
//  BorderedButtonView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 11/01/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class BorderedButtonView: UIView {

    @IBOutlet weak var button: MELButton!
    @IBOutlet weak var borderView: MELBorderView!
    @IBOutlet weak var borderViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var borderViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var borderViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var borderViewTopConstraint: NSLayoutConstraint!
    
    enum Position { case leading, middle, trailing }
    
    var position = Position.middle {
        
        didSet {
            
            switch position {
                
                case .leading:
                
                    borderViewLeadingConstraint.constant = 10
                    borderViewTrailingConstraint.constant = 6
                
                case .middle: break
                
                case .trailing: break
            }
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        UniversalMethods.setRadiusType(for: borderView.layer)
        borderView.layer.cornerRadius = 19
    }
    
    func updateCornerRadius() {
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath.init(roundedRect: borderView.bounds, cornerRadius: 19).cgPath
        borderView.layer.mask = maskLayer
    }
    
    class func with(title: String, image: UIImage, action: Selector?, target: Any?) -> BorderedButtonView {
        
        let view = Bundle.main.loadNibNamed("BorderedButtonView", owner: nil, options: nil)?.first as! BorderedButtonView
        
        view.button.setImage(image, for: .normal)
        view.button.setTitle(title, for: .normal)
        
        if let action = action {
            
            view.button.addTarget(target, action: action, for: .touchUpInside)
        }
        
        return view
    }
}
