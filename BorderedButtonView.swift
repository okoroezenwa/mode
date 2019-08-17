//
//  BorderedButtonView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 11/01/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias GestureRecogniserAction = (UIGestureRecognizer) -> ()

class BorderedButtonView: UIView {

    @IBOutlet var button: MELButton!
    @IBOutlet var borderView: MELBorderView!
    @IBOutlet var borderViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var borderViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var borderViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var borderViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var label: MELLabel!
    @IBOutlet var imageView: MELImageView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var imageViewBottomConstraint: NSLayoutConstraint!
    
    var tapAction: BorderedButtonActionDetails? {
        
        didSet {
            
            guard let tapAction = tapAction else { return }
            
            let tap = UITapGestureRecognizer.init(target: tapAction.target, action: tapAction.action)
            addGestureRecognizer(tap)
        }
    }
    
    var longPressAction: BorderedButtonActionDetails? {
        
        didSet {
            
            guard let longPressAction = longPressAction else { return }
            
            let hold = UILongPressGestureRecognizer.init(target: longPressAction.target, action: longPressAction.action)
            hold.minimumPressDuration = longPressDuration
            addGestureRecognizer(hold)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        }
    }
    
    var tapClosure: GestureRecogniserAction? {
        
        didSet {
            
            guard let tapClosure = tapClosure else { return }
            
            let tap = UITapGestureRecognizer.new(tapClosure)
            addGestureRecognizer(tap)
        }
    }
    
    var longPressClosure: GestureRecogniserAction? {
        
        didSet {
            
            guard let longPressClosure = longPressClosure else { return }
            
            let hold = UILongPressGestureRecognizer.new(longPressClosure)
            hold.minimumPressDuration = longPressDuration
            addGestureRecognizer(hold)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        }
    }
    
    var stackViewSnapshot: UIView? {
        
        didSet {
            
            oldValue?.removeFromSuperview()
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        borderView.layer.setRadiusTypeIfNeeded()
        borderView.layer.cornerRadius = 19
        button.isHidden = true
        button.setTitle(nil, for: .normal)
        button.setImage(nil, for: .normal)
        
        updateSpacing()
        
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
    }
    
    @objc func updateSpacing() {
        
        imageViewBottomConstraint.constant = FontManager.shared.buttonInset
        button.imageEdgeInsets.bottom = FontManager.shared.buttonInset
    }
    
    func animateChange(title: String?, image: UIImage?) {
        
        guard let snapshot = stackView.snapshotView(afterScreenUpdates: false) else { return }
        
        borderView.addSubview(snapshot)
        snapshot.frame = stackView.frame
        stackView.alpha = 0
        stackView.transform = .init(scaleX: 0.2, y: 0.2)
        
        if let title = title {
            
            label.text = title
        }
        
        if let image = image {
            
            imageView.image = image
        }
        
        UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: .calculationModeCubic, animations: {
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/2, animations: {
                
                snapshot.transform = .init(scaleX: 0.2, y: 0.2)
                snapshot.alpha = 0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 1/2, relativeDuration: 1/2, animations: {
                
                self.stackView.transform = .identity
                self.stackView.alpha = 1
            })
            
        }, completion: { _ in
            
            self.stackView.transform = .identity
            self.stackView.alpha = 1
            snapshot.removeFromSuperview()
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        super.touchesBegan(touches, with: event)
        
        label.lightOverride = true
        imageView.lightOverride = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        super.touchesEnded(touches, with: event)
        
        UIView.transition(with: label, duration: 0.2, options: .transitionCrossDissolve, animations: { self.label.lightOverride = false }, completion: nil)
        
        UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve, animations: { self.imageView.lightOverride = false }, completion: nil)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {

        super.touchesCancelled(touches, with: event)

        UIView.transition(with: label, duration: 0.2, options: .transitionCrossDissolve, animations: { self.label.lightOverride = false }, completion: nil)
        
        UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve, animations: { self.imageView.lightOverride = false }, completion: nil)
    }
    
    func updateCornerRadius() {
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath.init(roundedRect: borderView.bounds, cornerRadius: 19).cgPath
        borderView.layer.mask = maskLayer
    }
    
    class func with(title: String, image: UIImage, tapAction: BorderedButtonActionDetails?, longPressAction: BorderedButtonActionDetails? = nil) -> BorderedButtonView {
        
        let view = Bundle.main.loadNibNamed("BorderedButtonView", owner: nil, options: nil)?.first as! BorderedButtonView
        
        view.imageView.image = image
        view.label.text = title
        view.tapAction = tapAction
        view.longPressAction = longPressAction
        
        return view
    }
    
    class func with(title: String, image: UIImage, tapClosure: GestureRecogniserAction?, longPressClosure: GestureRecogniserAction? = nil) -> BorderedButtonView {
        
        let view = Bundle.main.loadNibNamed("BorderedButtonView", owner: nil, options: nil)?.first as! BorderedButtonView
        
        view.imageView.image = image
        view.label.text = title
        view.tapClosure = tapClosure
        view.longPressClosure = longPressClosure
        
        return view
    }
}

class BorderedButtonActionDetails {
    
    weak var target: AnyObject?
    var action: Selector?
    
    init(action: Selector?, target: AnyObject?) {
        
        self.target = target
        self.action = action
    }
}
