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
    
    var location: Location {
        
        switch self {
            
            case let x where x is PlaylistItemsViewController: return .playlist
            
            case let x where x is AlbumItemsViewController: return .album
            
            case let x where x is ArtistSongsViewController: return .artist(point: .songs)
            
            case let x where x is ArtistAlbumsViewController: return .artist(point: .albums)
            
            case let x where x is SongsViewController: return .songs
            
            case let x where x is CollectionsViewController: return .collections(kind: (x as! CollectionsViewController).collectionKind)
            
            case let x where x is NowPlayingViewController: return .fullPlayer
            
            case let x where x is ContainerViewController: return .miniPlayer
            
            case let x where x is CollectorViewController: return .collector
            
            case let x where x is QueueViewController: return .queue
            
            case let x where x is SearchViewController: return .search
            
            case let x where x is InfoViewController: return .info
            
            case let x where x is NewPlaylistViewController: return .newPlaylist
            
            case let x where x is FilterViewController: return .filter
            
            default: return .unknown
        }
    }
}
