//
//  BorderedButtonContaining.swift
//  Mode
//
//  Created by Ezenwa Okoro on 18/08/2019.
//  Copyright © 2019 Ezenwa Okoro. All rights reserved.
//

import UIKit

protocol BorderedButtonContaining {
    
    var label: MELLabel? { get set }
    var imageView: MELImageView? { get set }
}

extension BorderedButtonContaining {
    
    func performTouchesBegan() {
        
        label?.lightOverride = true
        imageView?.lightOverride = true
    }
    
    func performTouchesEnded() {
        
        guard let label = label, let imageView = imageView else { return }
        
        UIView.transition(with: label, duration: 0.2, options: .transitionCrossDissolve, animations: { label.lightOverride = false }, completion: nil)
        
        UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve, animations: { imageView.lightOverride = false }, completion: nil)
    }
    
    func performTouchesCancelled() {
        
        guard let label = label, let imageView = imageView else { return }
        
        UIView.transition(with: label, duration: 0.2, options: .transitionCrossDissolve, animations: { self.label?.lightOverride = false }, completion: nil)
        
        UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve, animations: { self.imageView?.lightOverride = false }, completion: nil)
    }
}
