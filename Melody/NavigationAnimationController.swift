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
    var animationInProgress: Bool
    var disregardViewLayoutDuringKeyboardPresentation = false

    override init() {
        
        direction = .forward
        interactor = InteractionController()
        animationInProgress = false
        
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        animationInProgress = true
        modalIndex = 0
        
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let container = appDelegate.window?.rootViewController as? ContainerViewController else { return }
        
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        let keyboardWasActive = container.filterViewContainer.filterView.searchBar.isFirstResponder
        
        var centreViewSnapshot: UIView?
        var requiresCentreView = false
        
        UIView.setAnimationsEnabled(false)
        
        toVC.view.frame.origin.x += direction == .forward ? 40 : -40
        toVC.view.alpha = 0
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        
        toVC.view.layoutIfNeeded()
        
        if let first = fromVC as? CentreViewDisplaying, let second = toVC as? CentreViewDisplaying {
                    
            if first.currentCentreView == .none { } else if let snapshot = container.centreView.snapshotView(afterScreenUpdates: false) {
                
                centreViewSnapshot = snapshot
                container.view.addSubview(snapshot)
                centreViewSnapshot?.frame = container.centreView.frame
            }
              
            requiresCentreView = second.centreView != .none
            
            container.centreView.alpha = 0
            second.updateViews(to: second.currentCentreView, alternateCentreView: container.centreView)
            container.centreView.updateCurrentView(to: second.currentCentreView, animated: false, setAlpha: false)
            container.centreView.transform = .init(translationX: direction == .forward ? 40 : -40, y: 0)
        }
        
        if let first = fromVC as? Navigatable, let second = toVC as? Navigatable {
            
            container.visualEffectNavigationBar.animateViews(direction: direction, section: .preparation, with: first, and: second)
        }
        
        let needsToUpdateBottomBar: Bool = {
            
            let requiresSearchBar: (UIViewController) -> Bool = { $0 is FilterContainer }
            
            return (requiresSearchBar(toVC) && requiresSearchBar(fromVC).inverted) || (requiresSearchBar(fromVC) && requiresSearchBar(toVC).inverted)
        }()
        
        if needsToUpdateBottomBar {
            
            container.filterViewContainer.filterView.requiresSearchBar = !container.filterViewContainer.filterView.requiresSearchBar
        }
        
        if let final = toVC as? ArtworkModifying {
            
            container.altImageView.image = container.imageView.image
            container.altImageView.alpha = 1
            container.imageView.alpha = 0
            container.imageView.image = final.artworkType.image
        }
        
        UIView.setAnimationsEnabled(true)
        
        if keyboardWasActive {

            container.filterViewContainer.filterView.filterInputViewBottomConstraint.constant = -53
            container.filterViewContainer.filterView.searchBar.delegate?.searchBarTextDidEndEditing?(container.filterViewContainer.filterView.searchBar)
        }
        
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: .calculationModeCubic, animations: {
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 3/5, animations: {
            
                fromVC.view.frame.origin.x += (self.direction == .forward ? -40 : 40)
                fromVC.view.alpha = 0
                
                if let first = fromVC as? Navigatable, let second = toVC as? Navigatable {
                    
                    container.visualEffectNavigationBar.animateViews(direction: self.direction, section: .firstHalf, with: first, and: second)
                }
                
                if let snapshot = centreViewSnapshot {
                    
                    snapshot.frame.origin.x += (self.direction == .forward ? -40 : 40)
                    snapshot.alpha = 0
                }
            })
            
            UIView.addKeyframe(withRelativeStartTime: 2.8/5, relativeDuration: 2.2/5, animations: {
            
                toVC.view.frame.origin.x += (self.direction == .forward ? -40 : 40)
                
                if let first = fromVC as? Navigatable, let second = toVC as? Navigatable {
                    
                    container.visualEffectNavigationBar.animateViews(direction: self.direction, section: .secondHalf, with: first, and: second)
                }
                
                if self.direction == .forward, fromVC.view.frame.origin.x < 0 {
                    
                    fromVC.view.frame.origin.x = 0
                }
                
                if requiresCentreView {
                    
                    container.centreView.transform = .identity
                    container.centreView.alpha = 1
                }
                
                toVC.view.alpha = 1
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                    
                container.imageView.alpha = 1
                container.altImageView.alpha = 0
                container.tabBarPassthroughView.layoutIfNeeded()
                
                if needsToUpdateBottomBar || keyboardWasActive, let filterView = container.filterViewContainer?.filterView {
                
                    filterView.alpha = filterView.requiresSearchBar ? 1 : 0
                }
            })
            
        }, completion: { [weak self] _ in
            
            let completed = transitionContext.transitionWasCancelled.inverted
            transitionContext.completeTransition(completed)
            
            self?.animationInProgress = false
            
            if let weakSelf = self, let first = fromVC as? Navigatable, let second = toVC as? Navigatable {

                container.visualEffectNavigationBar.animateViews(direction: weakSelf.direction, section: .end(completed: completed), with: first, and: second)
            }
            
            if let initial = fromVC as? ArtworkModifying, let final = toVC as? ArtworkModifying {
                
                container.altImageView.alpha = 0
                container.imageView.alpha = 1
                container.imageView.image = completed ? final.artworkType.image : initial.artworkType.image
            }
            
            if completed {
                
                if needsToUpdateBottomBar {
                    
                    notifier.post(name: .resetInsets, object: nil)
                }
                
                toVC.view.alpha = 1
                
                if self?.direction == .reverse {
                    
                    fromVC.view.removeFromSuperview()
                }
                
                if let filterVC = toVC as? FilterViewController, filterVC.searchBar.text?.isEmpty == true {

                    filterVC.searchBar.becomeFirstResponder()
                }
                
                if let second = toVC as? CentreViewDisplaying {

                    if second.centreView != .none {

                        second.updateViews(to: second.currentCentreView, alternateCentreView: container.centreView)
                        container.centreView.updateCurrentView(to: second.currentCentreView, animated: true)

                    } else {

                        container.centreView.alpha = 0
                        container.centreView.isUserInteractionEnabled = false
                    }
                    
                    container.centreView.transform = .identity
                }
                
            } else {
                
                self?.disregardViewLayoutDuringKeyboardPresentation = true
                UIView.setAnimationsEnabled(false)
                
                if needsToUpdateBottomBar, let filterView = container.filterViewContainer?.filterView {
                    
                    filterView.requiresSearchBar = !filterView.requiresSearchBar
                    filterView.alpha = filterView.requiresSearchBar ? 1 : 0
                }
                
                if keyboardWasActive {

                    container.filterViewContainer.filterView.searchBar.becomeFirstResponder()
                }
                
                fromVC.view.alpha = 1
                
                if let first = fromVC as? CentreViewDisplaying {

                    if first.centreView != .none {

                        first.updateViews(to: first.currentCentreView, alternateCentreView: container.centreView)
                        container.centreView.updateCurrentView(to: first.currentCentreView, animated: false)

                    } else {

                        container.centreView.alpha = 0
                        container.centreView.isUserInteractionEnabled = false
                    }
                    
                    container.centreView.transform = .identity
                }
                
                self?.disregardViewLayoutDuringKeyboardPresentation = false
                UIView.setAnimationsEnabled(true)
            }
            
            centreViewSnapshot?.removeFromSuperview()
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
