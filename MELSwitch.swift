//
//  Switch.swift
//  Music App
//
//  Created by Ezenwa Okoro on 05/01/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELSwitch: UIView {
    
    private let mainSwitch = Switch.instance
    var isOn = false
    var action: (() -> ())?
    @objc var leading: CGFloat = 10
    @objc var trailing: CGFloat = 10
    override var isUserInteractionEnabled: Bool {
        
        didSet {
            
            mainSwitch.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        addSubview(mainSwitch)
        centerYAnchor.constraint(equalTo: mainSwitch.centerYAnchor).isActive = true
        
        let leading = leadingAnchor.constraint(equalTo: mainSwitch.leadingAnchor)
        leading.constant = self.leading
        leading.isActive = true
        
        let trailing = trailingAnchor.constraint(equalTo: mainSwitch.trailingAnchor)
        trailing.constant = self.trailing
        trailing.isActive = true
        
        mainSwitch.isOn = isOn
        setOn(isOn, animated: false)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(changeValue(_:)))
        addGestureRecognizer(tap)
        
        let swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(swipe(_:)))
        swipeLeft.direction = .left
        addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer.init(target: self, action: #selector(swipe(_:)))
        swipeRight.direction = .right
        addGestureRecognizer(swipeRight)
    }
    
    func setOn(_ isOn: Bool, animated: Bool) {
        
        mainSwitch.knobLeadingConstraint.priority = UILayoutPriority.init(isOn ? 899 : 901)
        mainSwitch.isOn = isOn
        
        UIView.animate(withDuration: animated ? 0.7 : 0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            
            self.mainSwitch.changeThemeColor(self.mainSwitch)
            self.mainSwitch.layoutIfNeeded()
            
        }, completion: nil)
        
        self.isOn = isOn
    }
    
    @objc func changeValue(_ gr: UITapGestureRecognizer) {
        
        guard gr.state == .ended else { return }
        
        setOn(!isOn, animated: true)
        action?()
    }
    
    @objc func swipe(_ gr: UISwipeGestureRecognizer) {
        
        let goOn = gr.direction == .right
        
        guard isOn != goOn else { return }
        
        setOn(goOn, animated: true)
        action?()
    }
}

class Switch: UIView {

    @IBOutlet weak var knob: UIView!
    @IBOutlet weak var knobLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var knobTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var innerView: UIView!
    @IBOutlet var innerViewConstraints: [NSLayoutConstraint]!
    
    var isOn = false
    override var isUserInteractionEnabled: Bool {
        
        didSet {
            
            changeThemeColor(self)
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
//        if #available(iOS 11, *) {
//
//            let maskLayer = CAShapeLayer()
//            maskLayer.path = UIBezierPath.init(roundedRect: bounds, cornerRadius: 14).cgPath
//            layer.mask = maskLayer
//
//            innerViewConstraints.forEach({ $0.constant = 1.7 })
//
//            let otherMaskLayer = CAShapeLayer()
//            otherMaskLayer.path = UIBezierPath.init(roundedRect: bounds, cornerRadius: (28 - 1.7) / 2).cgPath
//            innerView.layer.mask = otherMaskLayer
//
//        } else {
            layer.setRadiusTypeIfNeeded()
            layer.cornerRadius = 14
            layer.borderWidth = 1.7
            
            innerView.isHidden = true
//        }
    
        changeThemeColor(knob)
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor(_ sender: Any) {
        
//        if #available(iOS 11, *) {
//
//            innerView.backgroundColor = isOn ? Themer.themeColour(alpha: isUserInteractionEnabled ? 1 : 0.2) : .clear
//            backgroundColor = isOn ? Themer.themeColour(alpha: isUserInteractionEnabled ? 1 : 0.2) : .clear
//
//        } else {
        
            animateBorderColor(sender is Switch)
            
            backgroundColor = isOn ? Themer.themeColour(alpha: isUserInteractionEnabled ? 1 : 0.2) : .clear
//        }
        
        knob.backgroundColor = Themer.themeColour(reversed: isOn, alpha: isUserInteractionEnabled ? 1 : 0.2)
    }
    
    @objc func animateBorderColor(_ animated: Bool) {

        let fromValue = layer.borderColor
        layer.borderColor = Themer.themeColour(alpha: isUserInteractionEnabled ? 1 : isOn ? 0 : 0.2).cgColor
        
        let color = CABasicAnimation.init(keyPath: "borderColor")
        color.fromValue = fromValue
        color.toValue = Themer.themeColour(alpha: isUserInteractionEnabled ? 1 : isOn ? 0 : 0.2).cgColor
        color.duration = animated ? 0.27 : 0
        color.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        layer.add(color, forKey: "borderColor")
    }
    
    class var instance: Switch { return Bundle.main.loadNibNamed("Switch", owner: nil, options: nil)?.first as! Switch }
}
