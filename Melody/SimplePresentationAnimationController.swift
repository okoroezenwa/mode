//
//  VerticalPresentationAnimationController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 31/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SimplePresentationAnimationController: NSObject, UIViewControllerAnimatedTransitioning {

    var direction: AnimationDirection = .forward
    var orientation: AnimationOrientation
    
    init(orientation: AnimationOrientation) {
        
        self.orientation = orientation
        
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        switch orientation {
            
            case .horizontal: return 0.4
            
            case .vertical: return direction == .forward ? 0.5 : 0.4
        }
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else { return }
        
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        let view: UIView = {
            
            switch direction {
                
                case .forward: return toVC.view
                
                case .reverse: return fromVC.view
            }
        }()
        
        if direction == .forward {
            
            if UIApplication.shared.statusBarFrame.height.truncatingRemainder(dividingBy: 20) == 0 {
                
                view.frame = .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - UIApplication.shared.statusBarFrame.height + 20)
            }
            
            for subview in view.subviews {
                
                switch orientation {
                    
                    case .horizontal: subview.frame.origin.x += subview.frame.width
                    
                    case .vertical: subview.frame.origin.y += (subview.frame.height/* + 30*/)
                }
            }
        }
        
        containerView.addSubview(view)
        
        let animations: () -> () = { [weak self] in
            
            guard let weakSelf = self else { return }
                
            switch weakSelf.direction {
                
                case .forward:
                    
                    view.subviews.forEach({
                        
                        switch weakSelf.orientation {
                    
                            case .horizontal: $0.frame.origin.x -= $0.frame.width
                            
                            case .vertical: $0.frame.origin.y -= ($0.frame.height/* - 30*/)
                        }
                    })
                    
                    view.backgroundColor = darkTheme ? UIColor.white.withAlphaComponent(0.05) : UIColor.black.withAlphaComponent(weakSelf.orientation == .horizontal ? 0.2 : 0.3)
                
                case .reverse:
                    
                    view.subviews.forEach({
                        
                        switch weakSelf.orientation {
                    
                            case .horizontal: $0.frame.origin.x += $0.frame.width
                            
                            case .vertical: $0.frame.origin.y += ($0.frame.height/* + 30*/)
                        }
                    })
                    
                    view.backgroundColor = .clear
            }
        }
        
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: orientation == .vertical ? 1 : 0.8, initialSpringVelocity: 0, options: [.curveLinear, .allowUserInteraction], animations: animations, completion: { _ in
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
            if !transitionContext.transitionWasCancelled, self.direction == .reverse {
                
                view.removeFromSuperview()
            }
        })
    }
}

extension SimplePresentationAnimationController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        direction = .forward
        
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        direction = .reverse
        
        return self
    }
}
