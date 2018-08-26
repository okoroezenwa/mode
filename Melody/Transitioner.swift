//
//  Transitioner.swift
//  Melody
//
//  Created by Ezenwa Okoro on 17/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class Transitioner: NSObject {

    @objc static let shared = Transitioner()
    
    private override init() { }
    
    @discardableResult func transition(to entity: Entity,
                                       vc: UIViewController,
                                       from source: UIViewController?,
                                       sender: Any?,
                                       highlightedItem item: MPMediaItem? = nil,
                                       highlightedAlbum: MPMediaItemCollection? = nil,
                                       preview: Bool = false,
                                       titleOverride title: String? = nil,
                                       filter: Filterable? = nil) -> UIViewController? {
        
        guard let entityVC = vc as? EntityItemsViewController, let collection = sender as? MPMediaItemCollection else { return nil }
        
        entityVC.entityContainerType = entity.containerType
        entityVC.backLabelText = title ?? (source as? Navigatable)?.preferredTitle
        entityVC.collection = collection
        entityVC.highlightedEntities = (item, highlightedAlbum)
        
        let rep = collection.representativeItem
        
        entityVC.title = {
            
            switch entity {
                
                case .playlist: return (collection as? MPMediaPlaylist)?.validName
                
                case .album, .song: return rep?.validAlbum
                    
                case .artist: return rep?.validArtist
                    
                case .composer: return rep?.validComposer
                    
                case .genre: return rep?.validGenre
                    
                case .albumArtist: return rep?.validAlbumArtist
            }
        }()
        
        let id = collection.persistentID
        let query = MPMediaQuery.init(filterPredicates: [.for(entity, using: id)]).cloud.grouped(by: entity == .playlist ? .playlist : .album)
        
        entityVC.query = query
        
        switch entity.containerType {
            
            case .playlist:
            
                if let sortable = UniversalMethods.sortableItem(forPersistentID: collection.persistentID, kind: .playlist) {
                    
                    entityVC.sortCriteria = SortCriteria(rawValue: Int(sortable.sort)) ?? .standard
                    entityVC.ascending = sortable.order
                }
            
            case .album:
            
                if let sortable = UniversalMethods.sortableItem(forPersistentID: collection.persistentID, kind: .album) {
                    
                    entityVC.ascending = sortable.order
                    entityVC.sortCriteria = SortCriteria(rawValue: Int(sortable.sort)) ?? .standard
                }
            
            case .collection:
            
                if let sortable = UniversalMethods.sortableItem(forPersistentID: collection.persistentID, kind: .artistSongs) {
                    
                    entityVC.ascending = sortable.order
                    entityVC.sortCriteria = SortCriteria(rawValue: Int(sortable.sort)) ?? .standard
                }
                
                if let sortable = UniversalMethods.sortableItem(forPersistentID: collection.persistentID, kind: .artistAlbums) {
                    
                    entityVC.albumAscending = sortable.order
                    entityVC.albumSortCriteria = SortCriteria(rawValue: Int(sortable.sort)) ?? .standard
                }
            
                entityVC.kind = entity.albumBasedCollectionKind
        }
        
        if preview {
            
            entityVC.peeker = source
            entityVC.modifyBackgroundView(forState: .visible)
        }
        
        if let searchVC = source as? SearchViewController, searchVC.searchBar.isFirstResponder {
            
            searchVC.searchBar.resignFirstResponder()
            searchVC.wasFiltering = true
        }
        
        return entityVC
    }
    
    func transition(to entity: Entity, segue: UIStoryboardSegue, sender: Any?, highlightedItem item: MPMediaItem? = nil, highlightedAlbum: MPMediaItemCollection? = nil, preview: Bool = false) {
        
        transition(to: entity, vc: segue.destination, from: segue.source, sender: sender, highlightedItem: item, highlightedAlbum: highlightedAlbum, preview: preview)
    }
    
    @discardableResult func transition(to vc: UIViewController, from sorter: Arrangeable, sourceRect: CGRect? = nil, sourceView: UIView? = nil) -> ArrangeViewController? {
        
        if let verticalPresentedVC = vc as? VerticalPresentationContainerViewController {
            
            verticalPresentedVC.context = .sort
            verticalPresentedVC.arrangeVC.sorter = sorter
//            PopoverDelegate.shared.prepare(vc: verticalPresentedVC, preferredSize: .init(width: 350, height: 169), sourceView: sourceView ?? sorter.arrangeButton, sourceRect: sourceRect ?? sorter.arrangeButton.bounds.modifiedBy(width: 0, height: 5), permittedDirections: [.up, .down])
            
            return verticalPresentedVC.arrangeVC
        }
        
        return nil
    }
    
    private func offSet(for configuration: ActionsViewController.Configuration) -> CGSize {
        
        return .zero
    }
    
    private func origin(for configuration: ActionsViewController.Configuration) -> CGPoint {
        
        switch configuration {
            
            case .collection, .library, .search, .info, .collected, .queue: return .init(x: 0, y: -5)
            
            default: return .zero
        }
    }
    
    @discardableResult func transition(to vc: UIViewController,
                    using options: LibraryOptions,
                    sourceView: UIView) -> UIViewController? {
        
        if let actionsVC = vc as? ActionsViewController {
            
            if options.count > 0 {
                
                actionsVC.count = options.count
            }
            
            actionsVC.sender = options.fromVC
            
            if let context = options.context {
                
                actionsVC.context = context
            }
            
            PopoverDelegate.shared.prepare(vc: actionsVC, preferredSize: nil, sourceView: sourceView, sourceRect: sourceView.bounds.modifiedBy(newOrigin: origin(for: options.configuration), size: offSet(for: options.configuration)), permittedDirections: .down)
            
            actionsVC.configuration = options.configuration
            
            return actionsVC
        }
        
        return nil
    }
    
    func showInfo(from sender: UIViewController, with context: InfoViewController.Context, completion: (() -> ())? = nil) {
        
        guard let vc = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
        
        vc.optionsContext = context
        vc.context = .info
        
        vc.newOptionsVC.filterContainer = (sender as? FilterContaining)?.filterContainer ?? sender as? FilterViewController
        
        sender.present(vc, animated: true, completion: completion)
    }
    
    func showProperties(of entity: MPMediaEntity, entityType: Entity, title: String, from sender: UIViewController) {
        
        guard let vc = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
        
        vc.title = title
        vc.context = .properties
        vc.propertiesVC.entity = entity
        vc.propertiesVC.entityType = entityType
        
        sender.present(vc, animated: true, completion: nil)
    }
    
    func addToQueue(from sender: UIViewController, kind: MPMusicPlayerController.QueueKind, context: QueueInsertViewController.Context, index: CGFloat = -1, title: String? = nil) {
        
        if let vc = popoverStoryboard.instantiateViewController(withIdentifier: String.init(describing: VerticalPresentationContainerViewController.self)) as? VerticalPresentationContainerViewController {
            
            vc.context = .insert
            vc.insertVC.kind = kind
            vc.insertVC.title = title
            vc.insertVC.context = context
            
            sender.present(vc, animated: true, completion: nil)
        }
    }
}
