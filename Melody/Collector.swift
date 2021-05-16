//
//  Collector.swift
//  Mode
//
//  Created by Ezenwa Okoro on 25/02/2021.
//  Copyright © 2021 Ezenwa Okoro. All rights reserved.
//

import UIKit

class Collector {
    
    private init() { }
    
    static let shared = Collector.init()
    var items = [MPMediaItem]()
    var shuffled = false
    
    func getCollected() {
        
        guard let data = prefs.object(forKey: .collectedItems) as? Data, let items = NSKeyedUnarchiver.unarchiveObject(with: data) as? [MPMediaItem], !items.isEmpty else { return }
        
        self.items = items
//        modifyCollectedButton(forState: .invoked)
//        updateCollectedText(animated: false)
    }
    
    func saveCollected() {
        
        let savedData = NSKeyedArchiver.archivedData(withRootObject: items)
        prefs.set(savedData, forKey: .collectedItems)
    }
}
