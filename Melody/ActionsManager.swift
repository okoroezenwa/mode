//
//  ActionsManager.swift
//  Mode
//
//  Created by Ezenwa Okoro on 17/05/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ActionsManager: NSObject {

    @objc static let shared = ActionsManager()
    
    enum Sender {
        
        case indexPath(IndexPath, within: [MPMediaEntity])
        case entity(MPMediaEntity, ofType: Entity)
    }
    
    enum AddLocation { case library, newPlaylist, existingPlaylist }
    
    private override init() { }
    
    func getInfo(_ sender: Sender, completion: (() -> Void)? = nil) {
        
        
    }
    
    func goTo(_ sender: Sender, completion: (() -> Void)? = nil) {
        
        
    }
    
    func queue(_ sender: Sender, completion: (() -> Void)? = nil) {
        
        
    }
    
    func addTo(_ location: AddLocation, sender: Sender, completion: (() -> Void)? = nil) {
        
        
    }
}
