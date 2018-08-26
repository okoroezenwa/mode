//
//  NowPlayingAnimationController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 29/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class NowPlayingAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    var direction: AnimationDirection = .forward
    @objc var interactor: NowPlayingInteractionController
    
    @objc init(interactor: NowPlayingInteractionController) {
        
        self.interactor = interactor
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        switch direction {
            
            case .forward: return fasterNowPlayingStartup ? 0.15 : 0.3
            
            case .reverse: return useAlternateAnimation ? 0.25 : fasterNowPlayingStartup ? 0.15 : 0.3
        }
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        modalIndex = 0
        
        switch direction {
            
            case .forward:
            
                guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? ContainerViewController, let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? NowPlayingViewController else { return }
                
                let containerView = transitionContext.containerView
                
                fromVC.view.frame = containerView.bounds
                toVC.view.frame = .init(x: 50, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                toVC.view.alpha = 0
                containerView.addSubview(fromVC.view)
                containerView.addSubview(toVC.view)
            
                let duration = transitionDuration(using: transitionContext)
                
                UIView.animateKeyframes(withDuration: duration, delay: 0, options: [.calculationModeCubic], animations: {
                    
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 2.6/5, animations: {
                        
                        fromVC.contentView.alpha = 0
                        fromVC.contentView.transform = .init(translationX: -50, y: 0)
                        
                        let inset = (fromVC.activeViewController?.topViewController as? Navigatable)?.inset ?? (10 + 34 + 10)
                        fromVC.visualEffectNavigationBar.transform = .init(translationX: 0, y: -(inset + (UIApplication.shared.statusBarFrame.height == 40 ? 0 : UIApplication.shared.statusBarFrame.height)))
                        fromVC.bottomEffectView.transform = .init(translationX: 0, y: fromVC.inset)
                    })
                    
                    UIView.addKeyframe(withRelativeStartTime: 2.4/5, relativeDuration: 2.6/5, animations: {
                        
                        toVC.view.frame = .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - UIApplication.shared.statusBarFrame.height + 20)
                        toVC.view.alpha = 1
                    })
                    
                }, completion: { _ in
                    
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    toVC.view.frame = transitionContext.finalFrame(for: toVC)
                        
//                    fromVC.bottomEffectView.transform = .identity
//                    fromVC.visualEffectNavigationBar.transform = .identity
                    fromVC.contentView.alpha = 0
                    fromVC.contentView.transform = .identity
                })
            
            case .reverse:
            
                guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? NowPlayingViewController, let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? ContainerViewController else { return }
            
                let containerView = transitionContext.containerView
                
                if useAlternateAnimation {
                    
                    toVC.visualEffectNavigationBar.alpha = 0
                    toVC.bottomEffectView.alpha = 0

                    toVC.visualEffectNavigationBar.transform = .identity
                    toVC.bottomEffectView.transform = .identity
                    toVC.contentView.alpha = 0
                    
                } else {
                    
                    toVC.contentView.alpha = 0
                    toVC.contentView.transform = .init(translationX: -50, y: 0)
                    toVC.bottomEffectView.transform = .init(translationX: 0, y: toVC.inset)
                    
                    let inset = (toVC.activeViewController?.topViewController as? Navigatable)?.inset ?? (10 + 34 + 10)
                    toVC.visualEffectNavigationBar.transform = .init(translationX: 0, y: -(inset + (UIApplication.shared.statusBarFrame.height == 40 ? 0 : UIApplication.shared.statusBarFrame.height)))
                }
                
                containerView.addSubview(toVC.view)
                containerView.addSubview(fromVC.view)
                
                let duration = transitionDuration(using: transitionContext)
                
                let completion: (Bool) -> Void = { _ in
                    
                    if !transitionContext.transitionWasCancelled {

                        fromVC.view.removeFromSuperview()
                        
                        if let keyWindow = UIApplication.shared.keyWindow, !keyWindow.subviews.contains(toVC.view) {
                            
                            UIApplication.shared.keyWindow?.addSubview(toVC.view)
                            toVC.view.frame = keyWindow.frame.modifiedBy(width: 0, height: isiPhoneX ? 0 : -(UIApplication.shared.statusBarFrame.height - 20)).modifiedBy(x: 0, y: isiPhoneX ? 0 : UIApplication.shared.statusBarFrame.height - 20)
                        }
                        
                        toVC.bottomEffectView.transform = .identity
                        toVC.visualEffectNavigationBar.transform = .identity
                        toVC.contentView.alpha = 1
                    }
                    
                    toVC.contentView.transform = .identity
                    
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
                
                if useAlternateAnimation {
                    
                    UIView.animateKeyframes(withDuration: duration, delay: 0, options: .calculationModeCubic, animations: {
                        
                        UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 4/5, animations: {
                            
                            fromVC.view.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
                            fromVC.view.alpha = 0
                        })
                        
                        UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                            
                            toVC.visualEffectNavigationBar.alpha = 1
                            toVC.bottomEffectView.alpha = 1
                        })
                        
                        UIView.addKeyframe(withRelativeStartTime: 1/5, relativeDuration: 4/5, animations: {
                            
                            toVC.contentView.alpha = 1
                        })
                        
                    }, completion: completion)
                    
                } else {
                    
                    UIView.animateKeyframes(withDuration: duration, delay: 0, options: .calculationModeCubic, animations: {
                        
                        UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 2.6/5, animations: {
                            
                            fromVC.view.alpha = 0
                            fromVC.view.frame = .init(x: 50, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - UIApplication.shared.statusBarFrame.height + 20)
                        })
                        
                        UIView.addKeyframe(withRelativeStartTime: 2.4/5, relativeDuration: 2.6/5, animations: {
                            
                            toVC.contentView.alpha = 1
                            toVC.contentView.transform = .identity
                            
                            toVC.visualEffectNavigationBar.transform = .identity
                            toVC.bottomEffectView.transform = .identity
                        })
                        
                    }, completion: completion)
                }
        }
    }
}

extension NowPlayingAnimationController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        direction = .forward
        
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        direction = .reverse
        
        return self
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        // important this way as it solves issues with dismissing manually (freezes on screen otherwise)
        return interactor.interactionInProgress ? interactor : nil
    }
}
