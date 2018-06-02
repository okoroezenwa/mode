//
//  MELCollectionView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 19/05/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELCollectionView: UICollectionView {
    
    @objc var horizontal = true {
        
        didSet {
            
            panGestureRecognizer.delegate = horizontal ? self : nil
        }
    }
    
    @objc var shouldDismiss = true

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        keyboardDismissMode = shouldDismiss ? .onDrag : .none
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        tintColor = darkTheme ? .white : .black
        indicatorStyle = darkTheme ? .white : .black
    }
}

extension MELCollectionView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}
