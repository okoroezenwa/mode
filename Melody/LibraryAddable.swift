//
//  LibraryAddable.swift
//  Mode
//
//  Created by Ezenwa Okoro on 16/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

@objc protocol EntityVerifiable {
    
    @objc optional var updateableView: UIView? { get }
    @objc optional var addButtonLeadingConstraint: NSLayoutConstraint? { get set }
    //    @objc optional var titleButton: MELButton? { get }
    @objc optional var albumButton: MELButton! { get }
    @objc optional var artistButton: MELButton! { get }
    @objc optional var genreButton: MELButton! { get }
    @objc optional var composerButton: MELButton! { get }
    @objc optional var albumArtistButton: MELButton! { get }
    @objc optional var divider: MELLabel! { get }
}

extension EntityVerifiable {
    
    @discardableResult func verifyLibraryStatus(of item: MPMediaItem?, itemProperty property: EntityType, animated: Bool = true, updateButton: Bool = true) -> ItemStatus {
        
        switch property {
            
            case .song:
                
                if let persistentID = item?.persistentID, let query: MPMediaQuery = {
                    
                    let query: MPMediaQuery? = MPMediaQuery.init(filterPredicates: [.for(.song, using: persistentID)])
                    return query
                    
                }(), let items = query.items, !items.isEmpty {
                    
                    updateAddButton(hidden: true, animated: animated)
                    return .present
                    
                } else {
                    
                    let bool: Bool = {
                        
                        if appDelegate.appleMusicStatus == .appleMusic(libraryAccess: true) {
                            
                            return false
                            
                        } else {
                            
                            return true
                        }
                    }()
                    
                    updateAddButton(hidden: bool, animated: animated)
                    return .absent
                }
                
            case .artist:
                
                if let persistentID = item?.artistPersistentID, let query: MPMediaQuery = {
                    
                    let query: MPMediaQuery? = MPMediaQuery.init(filterPredicates: [.for(.artist, using: persistentID)]).cloud.grouped(by: .artist)
                    return query
                    
                    }(), let collections = query.collections, !collections.isEmpty {
                    
                    if let vc = self as? ArtistTransitionable {
                        
                        vc.artistQuery = query
                        vc.currentItem = item
                        vc.currentAlbum = {
                            
                            guard let id = item?.albumPersistentID else { return nil }
                            
                            return MPMediaQuery.init(filterPredicates: [.for(.album, using: id)]).cloud.grouped(by: .album).collections?.first
                        }()
                    }
                    
                    if updateButton {
                        
                        artistButton??.greyOverride = false
                        divider??.greyOverride = false
                    }
                    
                    return .present
                    
                } else {
                    
                    if let vc = self as? ArtistTransitionable {
                        
                        vc.artistQuery = nil
                        vc.currentAlbum = nil
                        vc.currentItem = nil
                    }
                    
                    if updateButton {
                        
                        artistButton??.greyOverride = true
                        divider??.greyOverride = true
                    }
                    
                    return .absent
                }
                
            case .album:
                
                if let persistentID = item?.albumPersistentID, let query: MPMediaQuery = {
                    
                    let query: MPMediaQuery? = MPMediaQuery.init(filterPredicates: [.for(.album, using: persistentID)]).cloud.grouped(by: .album)
                    return query
                    
                    }(), let collections = query.collections, !collections.isEmpty {
                    
                    if let vc = self as? AlbumTransitionable {
                        
                        vc.albumQuery = query
                        vc.currentItem = item
                    }
                    
                    if updateButton {
                        
                        albumButton??.greyOverride = false
                    }
                    
                    return .present
                    
                } else {
                    
                    if let vc = self as? AlbumTransitionable {
                        
                        vc.albumQuery = nil
                        vc.currentItem = nil
                    }
                    
                    if updateButton {
                        
                        albumButton??.greyOverride = true
                    }
                    
                    return .absent
                }
                
            case .genre:
                
                if let persistentID = item?.genrePersistentID, let query: MPMediaQuery = {
                    
                    let query: MPMediaQuery? = MPMediaQuery.init(filterPredicates: [.for(.genre, using: persistentID)]).cloud.grouped(by: .genre)
                    return query
                    
                }(), let collections = query.collections, !collections.isEmpty {
                    
                    if let vc = self as? GenreTransitionable {
                        
                        vc.genreQuery = query
                        vc.currentItem = item
                        vc.currentAlbum = {
                            
                            guard let id = item?.albumPersistentID else { return nil }
                            
                            return MPMediaQuery.init(filterPredicates: [.for(.album, using: id)]).cloud.grouped(by: .album).collections?.first
                        }()
                    }
                    
                    if updateButton {
                        
                        genreButton??.greyOverride = false
                    }
                    
                    return .present
                    
                } else {
                    
                    if let vc = self as? GenreTransitionable {
                        
                        vc.genreQuery = nil
                        vc.currentAlbum = nil
                        vc.currentItem = nil
                    }
                    
                    if updateButton {
                        
                        genreButton??.greyOverride = true
                    }
                    
                    return .absent
                }
                
            case .playlist: return .present
                
            case .composer:
                
                if let persistentID = item?.composerPersistentID, let query: MPMediaQuery = {
                    
                    let query: MPMediaQuery? = MPMediaQuery.init(filterPredicates: [.for(.composer, using: persistentID)]).cloud.grouped(by: .composer)
                    return query
                    
                    }(), let collections = query.collections, !collections.isEmpty {
                    
                    if let vc = self as? ComposerTransitionable {
                        
                        vc.composerQuery = query
                        vc.currentItem = item
                        vc.currentAlbum = {
                            
                            guard let id = item?.albumPersistentID else { return nil }
                            
                            return MPMediaQuery.init(filterPredicates: [.for(.album, using: id)]).cloud.grouped(by: .album).collections?.first
                        }()
                    }
                    
                    if updateButton {
                        
                        composerButton??.greyOverride = false
                    }
                    
                    return .present
                    
                } else {
                    
                    if let vc = self as? ComposerTransitionable {
                        
                        vc.composerQuery = nil
                        vc.currentAlbum = nil
                        vc.currentItem = nil
                    }
                    
                    if updateButton {
                        
                        composerButton??.greyOverride = true
                    }
                    
                    return .absent
                }
                
            case .albumArtist:
                
                if let persistentID = item?.albumArtistPersistentID, let query: MPMediaQuery = {
                    
                    let query: MPMediaQuery? = MPMediaQuery.init(filterPredicates: [.for(.albumArtist, using: persistentID)]).cloud.grouped(by: .albumArtist)
                    return query
                    
                    }(), let collections = query.collections, !collections.isEmpty {
                    
                    if let vc = self as? AlbumArtistTransitionable {
                        
                        vc.albumArtistQuery = query
                        vc.currentItem = item
                        vc.currentAlbum = {
                            
                            guard let id = item?.albumPersistentID else { return nil }
                            
                            return MPMediaQuery.init(filterPredicates: [.for(.album, using: id)]).cloud.grouped(by: .album).collections?.first
                        }()
                    }
                    
                    if updateButton {
                        
                        albumArtistButton??.greyOverride = false
                        divider??.greyOverride = false
                    }
                    
                    return .present
                    
                } else {
                    
                    if let vc = self as? AlbumArtistTransitionable {
                        
                        vc.albumArtistQuery = nil
                        vc.currentAlbum = nil
                        vc.currentItem = nil
                    }
                    
                    if updateButton {
                        
                        albumArtistButton??.greyOverride = true
                        divider??.greyOverride = true
                    }
                    
                    return .absent
                }
        }
    }
    
    func updateAddButton(hidden: Bool, animated: Bool) {
        
        addButtonLeadingConstraint??.constant = hidden ? -44 : 0
        
        if animated {
            
            UIView.animate(withDuration: 0.3, animations: { self.updateableView??.layoutIfNeeded() })
        }
    }
    
    func performUnwindSegue(with entityType: EntityType, isEntityAvailable check: Bool, title: String, completion: (() -> Void)? = nil) {
        
        guard let vc = self as? UIViewController else { return }
        
        if check.inverted {
            
            let newBanner = Banner.init(title: showiCloudItems ? "This \(title) is not in your library" : "This \(title) is not available offline", subtitle: nil, image: nil, backgroundColor: .black, didTapBlock: nil)
            newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
            newBanner.show(duration: 1)
            
            completion?()
            
            return
        }
        
        useAlternateAnimation = true
        
        if let containerVC = vc as? ContainerViewController {
            
            switch entityType {
            
                case .album: containerVC.unwindToAlbum(from: containerVC)
                
                case .artist: containerVC.unwindToArtist(with: containerVC.artistQuery, item: containerVC.currentItem, album: containerVC.currentAlbum, kind: .artist)
                
                case .albumArtist: containerVC.unwindToArtist(with: containerVC.albumArtistQuery, item: containerVC.currentItem, album: containerVC.currentAlbum, kind: .albumArtist)
                
                case .genre: containerVC.unwindToArtist(with: containerVC.genreQuery, item: containerVC.currentItem, album: containerVC.currentAlbum, kind: .genre)
                
                case .composer: containerVC.unwindToArtist(with: containerVC.composerQuery, item: containerVC.currentItem, album: containerVC.currentAlbum, kind: .composer)
                
                default: break
            }
            
            return
        }
        
        switch entityType {
            
            case .album where self is AlbumTransitionable: vc.performSegue(withIdentifier: .albumUnwind, sender: nil)
            
            case .artist where self is ArtistTransitionable: vc.performSegue(withIdentifier: .artistUnwind, sender: nil)
            
            case .albumArtist where self is AlbumArtistTransitionable: vc.performSegue(withIdentifier: .albumArtistUnwind, sender: nil)
            
            case .genre where self is GenreTransitionable: vc.performSegue(withIdentifier: .genreUnwind, sender: nil)
            
            case .composer where self is ComposerTransitionable: vc.performSegue(withIdentifier: .composerUnwind, sender: nil)
            
            case .playlist where self is PlaylistTransitionable: vc.performSegue(withIdentifier: .playlistUnwind, sender: nil)
            
            default: break
        }
        
        completion?()
    }
    
    func showInLibrary(entity: MPMediaEntity, type: EntityType, unwinder: UIViewController?) {
        
        guard let container = appDelegate.window?.rootViewController as? ContainerViewController/*, (albumArtistsAvailable && type != .artist) || (albumArtistsAvailable.inverted && type != .albumArtist)*/ else { return }
        
        let currentSection = prefs.integer(forKey: .lastUsedLibrarySection)
        let section = type.librarySection(from: entity)
        
        let setHighlightedEntity: () -> () = { [weak container] in
            
            let libraryVC = container?.libraryNavigationController?.viewControllers.first as? LibraryViewController ?? container?.libraryNavigationController?.topViewController as? LibraryViewController
            
            switch section {
                
                case .songs: libraryVC?.highlightedEntities = (entity as? MPMediaItem, nil)
                
                default: libraryVC?.highlightedEntities = (nil, entity as? MPMediaItemCollection)
            }
        }
        
        let scrollToRow: () -> () = { [weak container] in
            
            if let tableContainer = (container?.libraryNavigationController?.viewControllers.first as? LibraryViewController ?? container?.libraryNavigationController?.topViewController as? LibraryViewController)?.activeChildViewController as? TableViewContainer {
                
                tableContainer.setHighlightedIndex(of: entity)
                tableContainer.scrollToHighlightedRow()
            }
        }
        
        useAlternateAnimation = true
        shouldReturnToContainer = true
        
        unwinder?.performSegue(withIdentifier: "unwind", sender: nil)
        
        if container.isLibraryNavigationControllerInitialised.inverted {
            
            prefs.set(section.rawValue, forKey: .lastUsedLibrarySection)
            setHighlightedEntity()
            container.switchViewController(container.libraryButton)
        
        } else {
            
            guard let details: (libraryVC: LibraryViewController?, needsToReturnToRoot: Bool) = {
                
                if let libraryVC = container.libraryNavigationController?.topViewController as? LibraryViewController {
                    
                    return (libraryVC, false)
                
                } else if let libraryVC = container.libraryNavigationController?.viewControllers.first as? LibraryViewController {
                    
                    return (libraryVC, true)
                }
                
                return nil
            
            }() else { return }
            
            let libraryNVCIsTopVC = container.activeViewController == container.libraryNavigationController
            
            if section.rawValue == currentSection {
                
                if libraryNVCIsTopVC.inverted {
                    
                    if details.needsToReturnToRoot {
                        
                        details.libraryVC?.navigationController?.popToRootViewController(animated: false)
                        container.switchViewController(container.libraryButton)
                        details.libraryVC?.view.alpha = 1
                        
                    } else {
                    
                        container.switchViewController(container.libraryButton)
                        details.libraryVC?.view.alpha = 1
                    }
                
                } else {
                    
                    details.libraryVC?.navigationController?.popToRootViewController(animated: true)
                }
                
                setHighlightedEntity()
                scrollToRow()
                
            } else if let libraryVC = details.libraryVC {
                
                let oldChild = libraryVC.activeChildViewController
                
//                if let details = container.filterViewContainer.filterView.locationDetails(for: section) {
//                    
//                    container.filterViewContainer.filterView.selectCell(at: details.indexPath, usingOtherArray: details.fromOtherArray, arrayIndex: details.index, performTransitions: false)
//                    container.filterViewContainer.filterView.collectionView.scrollToItem(at: details.indexPath, at: .centeredHorizontally, animated: true)
//                }
                
                prefs.set(section.rawValue, forKey: .lastUsedLibrarySection)
                
                if libraryVC.isViewControllerInitialised(for: section).inverted {
                    
                    setHighlightedEntity()
                    
                    if details.needsToReturnToRoot {
                    
                        libraryVC.shouldSetTitles = false
                    }
                    
                    libraryVC.changeActiveVC = false
                    libraryVC.activeChildViewController = libraryVC.viewControllerForCurrentSection()
                    libraryVC.changeActiveVC = true
                    libraryVC.changeActiveViewControllerFrom(oldChild, animated: libraryNVCIsTopVC, completion: {
                        
                        if details.needsToReturnToRoot {
                        
                            libraryVC.navigationController?.popToRootViewController(animated: libraryNVCIsTopVC)
                        }
                        
                        if libraryNVCIsTopVC.inverted {
                        
                            container.switchViewController(container.libraryButton)
                            details.libraryVC?.view.alpha = 1
                        }
                        
                        libraryVC.shouldSetTitles = true
                    })
                
                } else {
                    
                    setHighlightedEntity()
                    libraryVC.changeActiveVC = false
                    libraryVC.activeChildViewController = libraryVC.viewControllerForCurrentSection()
                    libraryVC.changeActiveVC = true
                    libraryVC.changeActiveViewControllerFrom(oldChild, animated: libraryNVCIsTopVC, completion: {
                        
                        if details.needsToReturnToRoot {
                        
                            libraryVC.navigationController?.popToRootViewController(animated: libraryNVCIsTopVC)
                        }
                        
                        if libraryNVCIsTopVC.inverted {
                        
                            container.switchViewController(container.libraryButton)
                            details.libraryVC?.view.alpha = 1
                        }
                    })
                    scrollToRow()
                }
            }
        }
    }
}
