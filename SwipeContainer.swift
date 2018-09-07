//
//  SwiperTableViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 20/07/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias SwipeContainerAction = (title: String?, image: UIImage?, handler: (() -> ())?)

protocol SwipeActionsDelegate: class {
    
    var leftSwipeActions: [SwipeContainerAction] { get }
    var rightSwipeActions: [SwipeContainerAction] { get }
}

protocol Swipable: class {
    
    var trailingConstraint: NSLayoutConstraint! { get set }
    var leadingConstraint: NSLayoutConstraint! { get set }
    var leftSwipeView: SwipeView { get }
    var rightSwipeView: SwipeView { get }
    var swipeDelegate: SwipeActionsDelegate? { get set }
    var radius: CGFloat { get set }
    var totalInset: CGFloat { get set }
    var leftAttachedView: UIView { get }
    var rightAttachedView: UIView { get }
}

extension Swipable where Self: UIView {
    
    func prepareViews() {
        
        [leftSwipeView, rightSwipeView].forEach({ addSubview($0) })
        
        let leftViewConstraint = leftSwipeView.leadingAnchor.constraint(equalTo: leadingAnchor)
        leftViewConstraint.priority = .init(900)
        leftViewConstraint.isActive = true
        
        leftSwipeView.trailingAnchor.constraint(equalTo: leftAttachedView.leadingAnchor).isActive = true
        leftSwipeView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftSwipeView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        let rightViewConstraint = rightSwipeView.trailingAnchor.constraint(equalTo: leadingAnchor)
        rightViewConstraint.priority = .init(900)
        rightViewConstraint.isActive = true
        
        rightSwipeView.leadingAnchor.constraint(equalTo: rightAttachedView.trailingAnchor).isActive = true
        rightSwipeView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightSwipeView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    func updateRadiusIfNecessary(_ radius: CGFloat = 44) {
        
        self.radius = radius
        leftSwipeView.leadingConstraint.constant = -(radius / 2)
        layer.cornerRadius = radius / 2
        leftSwipeView.leadingConstraint.constant = leftSwipeView.constant
    }
    
    func revealSwipeActions(_ sender: UIPanGestureRecognizer) {
        
        switch sender.state {
            
            case .changed:
                
                let translation = sender.translation(in: self)
                
                leadingConstraint.constant = translation.x
                trailingConstraint.constant = -translation.x
                
                let value = min(leftSwipeView.constant + translation.x, 16 + (radius / 2))
                leftSwipeView.leadingConstraint.constant = value
                
                leftSwipeView.leftThreshold = threshold(for: .left)
                leftSwipeView.stackView.alpha = min(1, translation.x/(UIScreen.main.bounds.width / 6))
            
            case .ended, .cancelled:
                
                leadingConstraint.constant = 0
                trailingConstraint.constant = 0
                leftSwipeView.leadingConstraint.constant = leftSwipeView.constant
                
                performAction(for: leftSwipeView.leftThreshold, going: .left)
                
                UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: { self.layoutIfNeeded() }, completion: { _ in
                    
                    self.leftSwipeView.leftThreshold = .none
                    self.updateRadiusIfNecessary(self.radius)
                })
            
            default: break
        }
    }
    
    func performAction(for threshold: Threshold, going orientation: SwipeActionsOrientation) {
        
        guard threshold > .none else { return }
        
        switch orientation {
            
            case .left: swipeDelegate?.leftSwipeActions.value(at: threshold.index)?.handler?()
            
            case .right: swipeDelegate?.rightSwipeActions.value(at: threshold.index)?.handler?()
        }
    }
    
    func threshold(for direction: SwipeActionsOrientation) -> Threshold {
        
        switch direction {
            
            case .left:
                
                if leadingConstraint.constant > (UIScreen.main.bounds.width / 6) {
                    
                    switch leadingConstraint.constant {
                        
                        case let x where ((UIScreen.main.bounds.width / 6)..<(UIScreen.main.bounds.width / 3)).contains(x): return .first
                        
                        case let x where ((UIScreen.main.bounds.width / 3)..<(UIScreen.main.bounds.width / 2)).contains(x): return .second
                        
                        default: return .third
                    }
                }
                
                return .none
            
            case .right:
                
                if leadingConstraint.constant < -(UIScreen.main.bounds.width / 6) {
                    
                    switch abs(leadingConstraint.constant) {
                        
                        case let x where ((UIScreen.main.bounds.width / 6)..<(UIScreen.main.bounds.width / 3)).contains(x): return .first
                        
                        case let x where ((UIScreen.main.bounds.width / 3)..<(UIScreen.main.bounds.width / 2)).contains(x): return .second
                        
                        default: return .third
                    }
                }
                
                return .none
        }
    }
}
