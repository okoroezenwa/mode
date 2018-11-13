//
//  UIViewController + Extensions.swift
//  Melody
//
//  Created by Ezenwa Okoro on 09/10/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

extension UIViewController {
    
    class var storyboardName: String {
        
        return String.init(describing: type(of: self))
    }
    
    func guardQueue(using alertController: UIAlertController, onCondition condition: Bool, fallBack: () -> ()) {
        
        if condition {
            
            present(alertController, animated: true, completion: nil)
            
        } else {
            
            fallBack()
        }
    }
    
    @objc func showSettings(with sender: Any) {
        
        if let sender = sender as? UILongPressGestureRecognizer {
            
            guard sender.state == .began else { return }
        }
        
        guard let vc = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
        
        vc.context = .settings
        
        present(vc, animated: true, completion: nil)
    }
    
    static var fromStoryboard: UIViewController {
        
        return UIStoryboard.init(name: self.storyboardName, bundle: nil).instantiateViewController(withIdentifier: self.storyboardName)
    }
}
