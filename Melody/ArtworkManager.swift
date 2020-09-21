//
//  ArtworkManager.swift
//  Mode
//
//  Created by Ezenwa Okoro on 01/09/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ArtworkManager: NSObject { // Handles adaptive artwork

    @objc static let shared = ArtworkManager()
    
    private override init() {
        
        super.init()
        
        [Notification.Name.themeChanged, .backgroundArtworkAdaptivityChanged, .nowPlayingItemChanged, Notification.Name.init("updateSection")].forEach({ notifier.addObserver(self, selector: #selector(updateArtwork), name: $0, object: nil) })
    }
    
    weak var container: ArtworkModifierContaining?
    weak var nowPlayingVC: ArtworkModifierContaining?
    weak var currentlyPeeking: Peekable?
    
    var activeContainer: ArtworkModifierContaining? { return ((nowPlayingVC as? NowPlayingViewController)?.activeItem == nil ? nil : nowPlayingVC) ?? container } // fixes the issue where stopping a song from the nowPlayingVC causes the artwork to change to a basic colour even when an entity is in front.
    
    @objc func updateArtwork(_ notification: Notification) {
        
        if notification.name == .themeChanged, let modifier = activeContainer?.modifier, case .image(_) = modifier.artworkType { return }
        
        if notification.name == .nowPlayingItemChanged, backgroundArtworkAdaptivity != .nowPlayingAdaptive { return }
        
        guard let containerVC = appDelegate.window?.rootViewController as? ContainerViewController else { return }
        
        UIView.transition(with: containerVC.imageView, duration: 0.5, options: .transitionCrossDissolve, animations: { containerVC.imageView.image = self.activeContainer?.modifier?.artworkType.image }, completion: nil)
    }
}
