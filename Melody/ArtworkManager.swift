//
//  ArtworkManager.swift
//  Mode
//
//  Created by Ezenwa Okoro on 01/09/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ArtworkManager: NSObject {

    @objc static let shared = ArtworkManager()
    
    private override init() {
        
        super.init()
        
        [Notification.Name.themeChanged, .backgroundArtworkAdaptivityChanged, .nowPlayingItemChanged].forEach({ notifier.addObserver(self, selector: #selector(updateArtwork), name: $0, object: nil) })
    }
    
    weak var container: ArtworkModifierContaining?
    weak var nowPlayingVC: ArtworkModifierContaining?
    
    var activeContainer: ArtworkModifierContaining? { return nowPlayingVC ?? container }
    
    @objc func updateArtwork(_ notification: Notification) {
        
        if notification.name == .themeChanged, let modifier = activeContainer?.modifier, case .image(_) = modifier.artworkType { return }
        
        if notification.name == .nowPlayingItemChanged, backgroundArtworkAdaptivity != .nowPlayingAdaptive { return }
        
        guard let containerVC = appDelegate.window?.rootViewController as? ContainerViewController else { return }
        
        UIView.transition(with: containerVC.imageView, duration: 0.5, options: .transitionCrossDissolve, animations: { containerVC.imageView.image = self.activeContainer?.modifier?.artworkType.image }, completion: nil)
    }
}
