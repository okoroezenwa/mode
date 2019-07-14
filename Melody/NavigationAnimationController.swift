//
//  NavigationAnimationController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class NavigationAnimationController: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    var direction: AnimationDirection
    @objc var interactor: InteractionController

    override init() {
        
        direction = .forward
        interactor = InteractionController()
        
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        modalIndex = 0
        
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else { return }
        
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        toVC.view.frame.origin.x += direction == .forward ? 40 : -40
        toVC.view.alpha = 0
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        
        var needsToUpdateBottomBar = false
        
        toVC.view.layoutIfNeeded()
        
        if let first = fromVC as? Navigatable, let second = toVC as? Navigatable, let container = appDelegate.window?.rootViewController as? ContainerViewController {
            
            container.view.layoutIfNeeded()
            container.visualEffectNavigationBar.animateViews(direction: direction, section: .preparation, with: first, and: second)
        }
        
        if let container = appDelegate.window?.rootViewController as? ContainerViewController, container.activeViewController == container.searchNavigationController {
            
            needsToUpdateBottomBar = container.filterViewContainer.filterView.withinSearchTerm != (toVC != container.searchNavigationController?.viewControllers.first)
            
            if needsToUpdateBottomBar {
                
                container.filterViewContainer.filterView.withinSearchTerm = !container.filterViewContainer.filterView.withinSearchTerm
            }
        }
        
        if let container = appDelegate.window?.rootViewController as? ContainerViewController, let final = toVC as? ArtworkModifying {
            
            container.altImageView.image = container.imageView.image
            container.altImageView.alpha = 1
            container.imageView.alpha = 0
            container.imageView.image = final.artworkType.image
        }
        
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: .calculationModeCubic, animations: {
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 3/5, animations: {
            
                fromVC.view.frame.origin.x += (self.direction == .forward ? -40 : 40)
                fromVC.view.alpha = 0
                
                if let first = fromVC as? Navigatable, let second = toVC as? Navigatable, let container = appDelegate.window?.rootViewController as? ContainerViewController {
                    
                    container.visualEffectNavigationBar.animateViews(direction: self.direction, section: .firstHalf, with: first, and: second)
                }
            })
            
            UIView.addKeyframe(withRelativeStartTime: 2.8/5, relativeDuration: 2.2/5, animations: {
            
                toVC.view.frame.origin.x += (self.direction == .forward ? -40 : 40)
                
                if let first = fromVC as? Navigatable, let second = toVC as? Navigatable, let container = appDelegate.window?.rootViewController as? ContainerViewController {
                    
                    container.visualEffectNavigationBar.animateViews(direction: self.direction, section: .secondHalf, with: first, and: second)
                }
                
                if self.direction == .forward, fromVC.view.frame.origin.x < 0 {
                    
                    fromVC.view.frame.origin.x = 0
                }
                
                toVC.view.alpha = 1
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                
                if let container = appDelegate.window?.rootViewController as? ContainerViewController {
                    
                    container.imageView.alpha = 1
                    container.altImageView.alpha = 0
                    container.view.layoutIfNeeded()
                }
            })
            
            if needsToUpdateBottomBar, let container = appDelegate.window?.rootViewController as? ContainerViewController, let filterView = container.filterViewContainer?.filterView {
                
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/2, animations: {
                    
                    filterView.filterTestButton.alpha = 0
                })
                
                UIView.addKeyframe(withRelativeStartTime: 1/2, relativeDuration: 1/2, animations: {
                    
                    filterView.filterTestButton.alpha = 1
                })
                
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                    
                    filterView.filterInputView.alpha = filterView.context == .library || filterView.withinSearchTerm ? 0 : 1
                    container.view.layoutIfNeeded()
                })
            }
            
        }, completion: { [weak self] _ in
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
            if let weakSelf = self, let first = fromVC as? Navigatable, let second = toVC as? Navigatable, let container = appDelegate.window?.rootViewController as? ContainerViewController {
                
                container.visualEffectNavigationBar.animateViews(direction: weakSelf.direction, section: .end(completed: !transitionContext.transitionWasCancelled), with: first, and: second)
            }
            
            if let container = appDelegate.window?.rootViewController as? ContainerViewController, let initial = fromVC as? ArtworkModifying, let final = toVC as? ArtworkModifying {
                
                container.altImageView.alpha = 0
                container.imageView.alpha = 1
                container.imageView.image = transitionContext.transitionWasCancelled.inverted ? final.artworkType.image : initial.artworkType.image
            }
            
            if !transitionContext.transitionWasCancelled {
                
                if self?.direction == .reverse {
                    
                    fromVC.view.removeFromSuperview()
                }
                
                if needsToUpdateBottomBar {
                    
                    notifier.post(name: .resetInsets, object: nil)
                }
                
                toVC.view.alpha = 1
                
            } else {
                
                if needsToUpdateBottomBar, let container = appDelegate.window?.rootViewController as? ContainerViewController, let filterView = container.filterViewContainer?.filterView {
                    
                    filterView.withinSearchTerm = !filterView.withinSearchTerm
                }
                
                fromVC.view.alpha = 1
            }
        })
    }
}

extension NavigationAnimationController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        return interactor.interactionInProgress ? interactor : nil
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        switch operation {
            
            case .pop:
            
                direction = .reverse
                return self
            
            case .push:
            
                direction = .forward
                return self
            
            case .none: return nil
            
            @unknown default: return nil
        }
    }
}
