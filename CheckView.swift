//
//  CheckView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 25/11/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class CheckView: UIView {

    @IBOutlet weak var borderView: MELBorderView!
    @IBOutlet weak var button: UIButton!
    
    var checked = true
    
    class func with(image: UIImage, radius: CGFloat) -> CheckView {
        
        let view = Bundle.main.loadNibNamed("CheckView", owner: nil, options: nil)?.first as! CheckView
        
        view.button.setImage(image, for: .normal)
        view.layer.cornerRadius = radius
        
        return view
    }
    
    @objc func changeState() {
        
        checked = !checked
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.button.alpha = self.checked ? 1 : 0
        })
    }
}

class CheckViewContainer: UIView {
    
    var image = #imageLiteral(resourceName: "Check")
    @objc var radius: CGFloat = 15
    lazy var checkView: CheckView = { return CheckView.with(image: image, radius: radius) }()
    override var intrinsicContentSize: CGSize { return .init(width: radius * 2, height: radius * 2) }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        fill(with: checkView)
        backgroundColor = .clear
        
        UniversalMethods.addShadow(to: self, shouldRasterise: true)
        invalidateIntrinsicContentSize()
    }
}
