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
        
        let gr = UIPanGestureRecognizer(target: self, action: #selector(handleGesture))
        
        if let grDelegate = vc as? UIGestureRecognizerDelegate {
            
            gr.delegate = grDelegate
        }
        
        viewController?.view.addGestureRecognizer(gr)
    }
    
    @objc func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        let translation = gestureRecognizer.translation(in: viewController?.view)
        let velocity = gestureRecognizer.velocity(in: viewController?.view)
        var progress = translation.y / UIScreen.main.bounds.height
        
        progress = min(max(progress, 0), 1)
        
        switch gestureRecognizer.state {
            
            case .began:
                
                // 2
                interactionInProgress = true
                    
                viewController?.dismiss(animated: true, completion: nil)
                
            case .changed:
                // 3
                shouldCompleteTransition = progress > 0.5 || velocity.y > 500
                update(progress)
                
            case .cancelled:
                // 4
                interactionInProgress = false
                cancel()
                
            case .ended:
                // 5
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
