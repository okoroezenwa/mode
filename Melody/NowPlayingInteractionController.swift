//
//  NowPlayingInteractionController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 28/07/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class NowPlayingInteractionController: UIPercentDrivenInteractiveTransition {

    @objc var interactionInProgress = false
    fileprivate var shouldCompleteTransition = false
    fileprivate weak var viewController: UIViewController?
    
    override var completionSpeed: CGFloat {
        
        get { return 1 }
        
        set { }
    }
    
    @objc func addToVC(_ vc: UIViewController) {
        
        viewController = vc
        
        let gr = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture))
        gr.edges = .left
        
        viewController?.view.addGestureRecognizer(gr)
    }
    
    @objc func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view?.superview)
        var progress = translation.x / ((200 / 375) * UIScreen.main.bounds.width)
        
        progress = min(max(progress, 0), 1)
        
        switch gestureRecognizer.state {
            
            case .began:
                
                interactionInProgress = true
                viewController?.dismiss(animated: true, completion: nil)
                
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
