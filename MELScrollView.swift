//
//  MELScrollView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 18/04/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELScrollView: UIScrollView {
    
    @objc var horizontal = true {
        
        didSet {
            
            panGestureRecognizer.delegate = horizontal ? self : nil
        }
    }
    
    @objc var rightSide = false

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
//        keyboardDismissMode = .onDrag//interactive
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        tintColor = darkTheme ? .white : .black
        indicatorStyle = darkTheme ? .white : .black
    }
}

extension MELScrollView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}
