//
//  LongPressManager.swift
//  Melody
//
//  Created by Ezenwa Okoro on 18/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class LongPressManager: NSObject {

    var gestureRecognisers = [Weak<UILongPressGestureRecognizer>]()
    var count = 20
    
    @objc static let shared = LongPressManager()
    
    private override init() {
        
        super.init()
    
        notifier.addObserver(self, selector: #selector(updateGestureTimes), name: .longPressDurationChanged, object: nil)
        
        notifier.addObserver(self, selector: #selector(reap), name: NSNotification.Name(rawValue: "reap"), object: nil)
    }
    
    @objc func updateGestureTimes() {
        
        for gesture in gestureRecognisers.compactMap({ $0.value }) {
            
            gesture.minimumPressDuration = longPressDuration
        }
    }
    
    @objc func reap() {
        
        if count > 0 {
            
            count -= 1
            
        } else {
            
            gestureRecognisers = gestureRecognisers.filter({ $0.value != nil })
            
            count = 20
        }
    }
}

class Weak<Element: NSObject> {
    
    weak var value: Element?
    
    init(value: Element) {
        
        self.value = value
        
        notifier.post(name: NSNotification.Name(rawValue: "reap"), object: nil)
    }
    
//    static func ==(lhs: Weak, rhs: Weak) -> Bool {
//        
//        return lhs.value == rhs.value
//    }
//    
//    var hashValue: Int { return value?.hashValue ?? 0 }
}
