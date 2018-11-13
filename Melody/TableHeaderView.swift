//
//  TableHeaderView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 07/11/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TableHeaderView: UITableViewHeaderFooterView {

    @IBOutlet var label: MELLabel! {
        
        didSet {
            
            textLabel?.text = nil
        }
    }
    @IBOutlet var button: MELButton!
    @IBOutlet var altButton: UIButton!
    @IBOutlet var labelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var rightButton: UIButton!
    @IBOutlet var rightButtonViewConstraint: NSLayoutConstraint!
    @IBOutlet var leftButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet var leftButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet var leftButtonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var leftButtonBorderView: MELBorderView!
    @IBOutlet var leftButtonBorderViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var labelBottomConstraint: NSLayoutConstraint!
    
    weak var attributor: Attributor? {
        
        didSet {
            
            if let _ = attributor {
                
                notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
                
            } else {
                
                notifier.removeObserver(self)
            }
        }
    }
    
    var buttons: [UIButton?] { return [button, altButton] }
    
    @objc var showButton = false {
        
        didSet {
            
            button.superview?.isHidden = !showButton
        }
    }
    
    var isRecentsButton = false {
        
        didSet {
            
            leftButtonWidthConstraint.constant = isRecentsButton ? 17 : 24
            leftButtonBottomConstraint.constant = isRecentsButton ? 7 : 4
            leftButtonLeadingConstraint.constant = isRecentsButton ? 14 : 17
            leftButtonBorderViewTrailingConstraint.constant = isRecentsButton ? 0 : 10
//            button.contentEdgeInsets.bottom = isRecentsButton ? 11 : 12
            button.contentEdgeInsets.right = isRecentsButton ? 5 : 15
            button.setImage(isRecentsButton ? #imageLiteral(resourceName: "BackArrow9") : #imageLiteral(resourceName: "AddNoBorderSmall"), for: .normal)
            leftButtonBorderView.layer.cornerRadius = isRecentsButton ? 8.5 : 12
        }
    }
    
    @objc var canShowRightButton = false
    @objc var canShowLeftButton = false
    
    @objc var section = 0
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        updateSpacing()
        
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
    }
    
    @objc func updateSpacing() {
        
        labelBottomConstraint.constant = activeFont == .avenirNext ? 2 : 4
    }
    
    @objc func changeThemeColor() {

        attributor?.updateAttributedText(for: self, inSection: section)
    }
    
    @objc func updateLabelConstraint(showButton: Bool) {
        
        labelLeadingConstraint.constant = showButton ? (isRecentsButton ? 4 : 0) : 10
    }
    
    @objc class func with(leftButtonVisible: Bool) -> TableHeaderView {
        
        let view = Bundle.main.loadNibNamed("TableHeaderView", owner: nil, options: nil)?.first as! TableHeaderView
        view.showButton = leftButtonVisible
        view.isRecentsButton = leftButtonVisible
        view.updateLabelConstraint(showButton: leftButtonVisible)
        
        return view
    }
}
