//
//  PopoverDelegate.swift
//  Melody
//
//  Created by Ezenwa Okoro on 11/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PopoverDelegate: NSObject, UIPopoverPresentationControllerDelegate {
    
    @objc static let shared = PopoverDelegate()
    
    private override init() { }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        
        return .none
    }
    
    func prepare(vc: UIViewController, preferredSize size: CGSize?, sourceView view: UIView, sourceRect: CGRect, permittedDirections directions: UIPopoverArrowDirection) {
        
        if let size = size {
            
            vc.preferredContentSize = size
        }
        
        vc.view.backgroundColor = .clear//UIDevice.current.isBlurAvailable ? .clear : darkTheme ? UIColor.darkGray : .white
        
        if let popover = vc.popoverPresentationController {
            
            popover.delegate = self
            popover.sourceRect = sourceRect
            popover.sourceView = view
            popover.backgroundColor = darkTheme ? UIColor.darkGray.withAlphaComponent(UIDevice.current.isBlurAvailable ? 0.5 : 1) : UIColor.white.withAlphaComponent(UIDevice.current.isBlurAvailable ? 0.6 : 1)
            popover.permittedArrowDirections = directions
        }
    }
}
