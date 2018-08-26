//
//  InteractionController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 09/07/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class InteractionController: UIPercentDrivenInteractiveTransition {

    @objc var interactionInProgress = false
    fileprivate var shouldCompleteTransition = false
    fileprivate weak var viewController: UIViewController?
    @objc var presenting = false
    
    override var completionSpeed: CGFloat {
        
        get { return 1 }
        
        set { }
    }
    
    @objc func add(to vc: UIViewController?) {
        
        viewController = vc
        
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.edges = !(viewController is PresentedContainerViewController) && !(viewController is UINavigationController) ? .right : .left
//        presenting = !(viewController is PresentedContainerViewController) && !(viewController is UINavigationController)
        vc?.view.addGestureRecognizer(gesture)
    }
    
    @objc func add(to view: UIView, in vc: UIViewController?) {
        
        viewController = vc
        
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.edges = !(viewController is PresentedContainerViewController) && !(viewController is UINavigationController) ? .right : .left
        presenting = !(viewController is PresentedContainerViewController) && !(viewController is UINavigationController)
        view.addGestureRecognizer(gesture)
    }
    
    @objc func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        
        let isNavigationController = viewController is UINavigationController
        
        // 1
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view?.superview)
        var progress: CGFloat = {
            
            if presenting {
                
                return translation.x / -UIScreen.main.bounds.width
            }
            
            return translation.x / (isNavigationController ? 200 : UIScreen.main.bounds.width)
        }()
        
        progress = min(max(progress, 0), 1)
        
        switch gestureRecognizer.state {
            
            case .began:
                // 2
                interactionInProgress = true
                
                if let nVC = viewController as? UINavigationController {
                    
                    guard nVC.topViewController != nVC.viewControllers.first else {
                        
                        if let searchVC = nVC.topViewController as? SearchViewController {
                            
                            if searchVC.filtering {
                                
                                searchVC.dismissSearch()
                                
                            } else if searchVC.onlineOverride {
                                
                                searchVC.onlineOverride = false
//                                    searchVC.updateTempView(hidden: true)
                            }
                        }
                        
                        return
                    }
                    
                    nVC.popViewController(animated: true)
                    
                } else {
                    
                    if let viewController = viewController as? PresentedContainerViewController {
                        
                        viewController.altAnimator = viewController.animator
                    }
                    
                    viewController?.dismiss(animated: true, completion: nil)
                }
            
            case .changed:
                
                shouldCompleteTransition = progress > 0.5 || (translation.x > 0 && velocity.x > 500)
                update(progress)
                
            case .cancelled:
                
                interactionInProgress = false
                cancel()
                
            case .ended:
                
                interactionInProgress = false
                
                if !shouldCompleteTransition {
                    
                    cancel()
                    
                } else {
                    
                    finish()
                }
                
            default: print("Unsupported")
        }
    }
}
