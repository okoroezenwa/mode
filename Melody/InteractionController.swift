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
    var operation = UINavigationController.Operation.none
    weak var operatedObject: AnyObject?
    
    override var completionSpeed: CGFloat {
        
        get { return 1 }
        
        set { }
    }
    
    @objc func add(to vc: UIViewController?) {
        
        viewController = vc
        
        let leftGR = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        leftGR.edges = !(viewController is PresentedContainerViewController) && !(viewController is UINavigationController) ? .right : .left
//        presenting = !(viewController is PresentedContainerViewController) && !(viewController is UINavigationController)
        vc?.view.addGestureRecognizer(leftGR)
        
        let rightGR = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(handleGesture(_:)))
        rightGR.edges = .right
        vc?.view.addGestureRecognizer(rightGR)
    }
    
    @objc func add(to view: UIView, in vc: UIViewController?) {
        
        viewController = vc
        
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.edges = !(viewController is PresentedContainerViewController) && !(viewController is UINavigationController) ? .right : .left
        presenting = !(viewController is PresentedContainerViewController) && !(viewController is UINavigationController)
        view.addGestureRecognizer(gesture)
        
        let rightGR = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(handleGesture(_:)))
        rightGR.edges = .right
        view.addGestureRecognizer(rightGR)
    }
    
    @objc func handleGesture(_ gr: UIScreenEdgePanGestureRecognizer) {
        
        let isNavigationController = viewController is UINavigationController
        
        // 1
        let translation = gr.translation(in: gr.view)
        let velocity = gr.velocity(in: gr.view?.superview)
        var progress: CGFloat = {
            
            if presenting {
                
                return translation.x / -UIScreen.main.bounds.width
            }
            
            return translation.x / (isNavigationController ? (gr.edges == .left ? 200 : -200) : UIScreen.main.bounds.width)
        }()
        
        progress = min(max(progress, 0), 1)
        
        switch gr.state {
            
            case .began:
                // 2
                interactionInProgress = true
                
                if let nVC = viewController as? NavigationController {
                    
                    if gr.edges == .left {
                    
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
                        
                        nVC.interactive = true
                        operation = .pop
                        operatedObject = nVC.popViewController(animated: true)
                        
                    } else if gr.edges == .right, let vc = nVC.poppedViewControllers.last {
                        
                        nVC.interactive = true
                        operation = .push
                        operatedObject = vc
                        nVC.pushViewController(vc, animated: true)
                    }
                    
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
                    
                    switch operation {
                        
                        case .none: break
                            
                        case .push:
                            
                            if let nVC = viewController as? NavigationController {
                                
                                _ = nVC.poppedViewControllers.removeLast()
                            }
                            
                        case .pop:
                            
                            if let nVC = viewController as? NavigationController {
                                
                                if let vc = operatedObject as? UIViewController {
                                
                                    nVC.poppedViewControllers.append(vc)
                                
                                } else if let array = operatedObject as? [UIViewController] {
                                    
                                    nVC.poppedViewControllers += array.reversed()
                                }
                            }
                            
                        @unknown default: break
                    }
                }
                
                operation = .none
                operatedObject = nil
                (viewController as? NavigationController)?.interactive = false
                
            default: print("Unsupported")
        }
    }
}
