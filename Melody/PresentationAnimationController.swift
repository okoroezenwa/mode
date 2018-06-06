//
//  PresentationAnimationController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 10/10/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PresentationAnimationController: NSObject, UIViewControllerAnimatedTransitioning {

    var direction: AnimationDirection = .forward
    @objc var interactor: InteractionController
    
    @objc init(interactor: InteractionController) {
        
        self.interactor = interactor
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
//        if #available(iOS 11, *) {

//            return 0.5
//        }
//        
        return /*interactor.interactionInProgress ? 0.3 :*/ 0.5
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
                
                subview.frame.origin.x += UIScreen.main.bounds.width
            }
        
        } else if direction == .reverse, let presentedVC = fromVC as? PresentedContainerViewController {
            
            presentedVC.transitionStart?()
        }
        
        containerView.addSubview(view)
        
        let animations: () -> () = { [weak self] in
            
            guard let weakSelf = self else { return }
            
            for subview in view.subviews {
                
                switch weakSelf.direction {
                    
                    case .forward:
                        
                        subview.frame.origin.x -= UIScreen.main.bounds.width
                    
                    case .reverse:
                        
                        subview.frame.origin.x += UIScreen.main.bounds.width
                    
                        if let presentedVC = fromVC as? PresentedContainerViewController {

                            presentedVC.transitionAnimation?()
                        }
                }
            }
        }
        
        if interactor.interactionInProgress {
            
            UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear], animations: animations, completion: { _ in
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                
                if self.direction == .forward {


                
                } else if !transitionContext.transitionWasCancelled {
                    
                    view.removeFromSuperview()
                
                } else if transitionContext.transitionWasCancelled, let presentedVC = fromVC as? PresentedContainerViewController {
                    
                    presentedVC.transitionCancellation?()
                }
            })
            
        } else {
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveLinear], animations: animations, completion: { _ in
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                
                if self.direction == .forward {

//                    view.frame = transitionContext.finalFrame(for: toVC)
                
                } else if !transitionContext.transitionWasCancelled {
                    
//                    if let vc = fromVC as? PresentedContainerViewController, vc.context == .queue { return }
                    
                    view.removeFromSuperview()
                }
            })
        }
    }
}

extension PresentationAnimationController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        direction = .forward
        
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        direction = .reverse
        
        return self
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        return interactor.interactionInProgress ? interactor : nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        // important this way as it solves issues with dismissing manually (freezes on screen otherwise)
        return interactor.interactionInProgress ? interactor : nil
    }
}
