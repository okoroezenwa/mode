//
//  Switch.swift
//  Music App
//
//  Created by Ezenwa Okoro on 05/01/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELSwitchContainer: UIView {
    
    enum SwitchType { case system, custom }
    
    private let customSwitch = Switch.instance
    private let systemSwitch = MELSwitch.init(frame: .zero)
    var isOn = false
    var action: (() -> ())?
    @objc var leading: CGFloat = 10
    @objc var trailing: CGFloat = 10
    var customConstraints = Set<NSLayoutConstraint>()
    var systemConstraints = Set<NSLayoutConstraint>()
    override var isUserInteractionEnabled: Bool {
        
        didSet {
            
            customSwitch.isUserInteractionEnabled = isUserInteractionEnabled
            systemSwitch.isEnabled = isUserInteractionEnabled
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        customSwitch.isHidden = useSystemSwitch
        systemSwitch.isHidden = useSystemSwitch.inverted
        
        prepareConstraints(for: .system)
        prepareConstraints(for: .custom)
        
        systemSwitch.isOn = isOn
        customSwitch.isOn = isOn
        setOn(isOn, animated: false)
        
        systemSwitch.addTarget(self, action: #selector(changeValue(_:)), for: .valueChanged)
        notifier.addObserver(self, selector: #selector(updateSwitch), name: .useSystemSwitchChanged, object: nil)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(changeValue(_:)))
        tap.delegate = self
        addGestureRecognizer(tap)
        
        let swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(swipe(_:)))
        swipeLeft.direction = .left
        swipeLeft.delegate = self
        addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer.init(target: self, action: #selector(swipe(_:)))
        swipeRight.direction = .right
        swipeRight.delegate = self
        addGestureRecognizer(swipeRight)
    }
    
    func prepareConstraints(for type: SwitchType) {
        
        let relevantSwitch: UIView = type == .system ? systemSwitch : customSwitch
        let makeActive: Bool = {
            
            switch type {
                
                case .custom: return useSystemSwitch.inverted
                
                case .system: return useSystemSwitch
            }
        }()
        
        let append: (NSLayoutConstraint) -> Void = {
            
            switch type {
                
                case .system: self.systemConstraints.insert($0)
                
                case .custom: self.customConstraints.insert($0)
            }
        }
        
        addSubview(relevantSwitch)
        let centre = centerYAnchor.constraint(equalTo: relevantSwitch.centerYAnchor)
        centre.isActive = makeActive
        append(centre)
        
        let leading = leadingAnchor.constraint(equalTo: relevantSwitch.leadingAnchor)
        leading.constant = -self.leading
        leading.isActive = makeActive
        append(leading)
        
        let trailing = trailingAnchor.constraint(equalTo: relevantSwitch.trailingAnchor)
        trailing.constant = self.trailing
        trailing.isActive = makeActive
        append(trailing)
    }
    
    @objc func updateSwitch() {
        
        customConstraints.forEach({ $0.isActive = useSystemSwitch.inverted })
        systemConstraints.forEach({ $0.isActive = useSystemSwitch })
        systemSwitch.isHidden = useSystemSwitch.inverted
        customSwitch.isHidden = useSystemSwitch
    }
    
    func setOn(_ isOn: Bool, animated: Bool) {
        
        customSwitch.knobLeadingConstraint.priority = UILayoutPriority.init(isOn ? 899 : 901)
        customSwitch.isOn = isOn
        systemSwitch.isOn = isOn
        
        UIView.animate(withDuration: animated ? 0.7 : 0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            
            self.customSwitch.changeThemeColor(animated)
            self.customSwitch.layoutIfNeeded()
            
        }, completion: nil)
        
        self.isOn = isOn
    }
    
    @objc func changeValue(_ sender: Any) {
        
        if let gr = sender as? UITapGestureRecognizer, gr.state != .ended { return }
        
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

extension MELSwitchContainer: UIGestureRecognizerDelegate {
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return useSystemSwitch.inverted
    }
}

class MELSwitch: UISwitch {
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    @objc func changeThemeColor() {
        
        thumbTintColor = Themer.themeColour()
        onTintColor = Themer.borderViewColor(withAlphaOverride: 0.1)
        tintColor = Themer.borderViewColor(withAlphaOverride: 0.1)//darkTheme ? .white : .black
    }
}

class Switch: UIView {

    @IBOutlet var knob: UIView!
    @IBOutlet var knobLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var knobTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var innerView: UIView!
    @IBOutlet var innerViewConstraints: [NSLayoutConstraint]!
    
    var isOn = false
    override var isUserInteractionEnabled: Bool {
        
        didSet {
            
            changeThemeColor(false)
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        layer.setRadiusTypeIfNeeded()
        layer.cornerRadius = 14
        layer.borderWidth = 1.7
        
        innerView.isHidden = true
    
        changeThemeColor(false)
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor(_ animated: Bool) {
        
        if animated {
            
            animateBorderColor()
            
        } else {
            
            layer.borderColor = Themer.themeColour(alpha: isUserInteractionEnabled ? 1 : isOn ? 0 : 0.2).cgColor
        }
        
        backgroundColor = isOn ? Themer.themeColour(alpha: isUserInteractionEnabled ? 1 : 0.2) : .clear
        
        knob.backgroundColor = Themer.themeColour(reversed: isOn, alpha: isUserInteractionEnabled ? 1 : 0.2)
    }
    
    @objc func animateBorderColor() {

        let fromValue = layer.borderColor
        layer.borderColor = Themer.themeColour(alpha: isUserInteractionEnabled ? 1 : isOn ? 0 : 0.2).cgColor
        
        let color = CABasicAnimation.init(keyPath: "borderColor")
        color.fromValue = fromValue
        color.toValue = Themer.themeColour(alpha: isUserInteractionEnabled ? 1 : isOn ? 0 : 0.2).cgColor
        color.duration = 0.27
        color.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        layer.add(color, forKey: "borderColor")
    }
    
    class var instance: Switch { return Bundle.main.loadNibNamed("Switch", owner: nil, options: nil)?.first as! Switch }
}
