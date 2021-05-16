//
//  NavigationController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 19/04/2021.
//  Copyright © 2021 Ezenwa Okoro. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    
    var poppedViewControllers = [UIViewController]()
    var interactive = false
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        super.pushViewController(viewController, animated: animated)
        
        guard interactive.inverted else { return }
        
        poppedViewControllers.removeAll()
    }
    
    @discardableResult override func popViewController(animated: Bool) -> UIViewController? {
        
        guard let vc = super.popViewController(animated: animated) else { return nil }
        
        guard interactive.inverted else { return vc }
        
        poppedViewControllers.append(vc)
        
        return vc
    }
    
    @discardableResult override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        
        let temp = Array(viewControllers.dropFirst())
        let array = super.popToRootViewController(animated: animated) ?? temp
        
        guard interactive.inverted else { return array }
        
        poppedViewControllers += array.reversed()
        
        return array
    }
    
    @discardableResult override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        
        guard let array = super.popToViewController(viewController, animated: animated) else { return nil }
        
        guard interactive.inverted else { return array }
        
        poppedViewControllers += array.reversed()
        
        return array
    }
}
