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
    
    @discardableResult func transition(to entityType: EntityType,
                                       vc: UIViewController,
                                       from source: UIViewController?,
                                       sender: Any?,
                                       highlightedItem item: MPMediaItem? = nil,
                                       highlightedAlbum: MPMediaItemCollection? = nil,
                                       preview: Bool = false,
                                       titleOverride title: String? = nil,
                                       filter: Filterable? = nil) -> UIViewController? {
        
        guard let entityVC = vc as? EntityItemsViewController, let collection = sender as? MPMediaItemCollection else { return nil }
        
        entityVC.entityContainerType = entityType.containerType
        entityVC.backLabelText = title ?? (source as? Navigatable)?.preferredTitle
        entityVC.collection = collection
        entityVC.highlightedEntities = (item, highlightedAlbum)
        
        let rep = collection.representativeItem
        
        entityVC.title = {
            
            switch entityType {
                
                case .playlist: return (collection as? MPMediaPlaylist)?.validName
                
                case .album, .song: return rep?.validAlbum
                    
                case .artist: return rep?.validArtist
                    
                case .composer: return rep?.validComposer
                    
                case .genre: return rep?.validGenre
                    
                case .albumArtist: return rep?.validAlbumArtist
            }
        }()
        
        let id = collection.persistentID
        let query = MPMediaQuery.init(filterPredicates: [.for(entityType, using: id)]).cloud.grouped(by: entityType == .playlist ? .playlist : .album)
        
        entityVC.query = query
        
        switch entityType.containerType {
            
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
            
                entityVC.kind = entityType.albumBasedCollectionKind
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
    
    func transition(to entityType: EntityType, segue: UIStoryboardSegue, sender: Any?, highlightedItem item: MPMediaItem? = nil, highlightedAlbum: MPMediaItemCollection? = nil, preview: Bool = false) {
        
        transition(to: entityType, vc: segue.destination, from: segue.source, sender: sender, highlightedItem: item, highlightedAlbum: highlightedAlbum, preview: preview)
    }
    
    @discardableResult func transition(to vc: UIViewController, from sorter: Arrangeable, sourceRect: CGRect? = nil, sourceView: UIView? = nil) -> ArrangeViewController? {
        
        if let vc = vc as? VerticalPresentationContainerViewController {
            
            vc.title = "Sort Categories"
            vc.segments = [.init(title: "Ascending", image: #imageLiteral(resourceName: "Save22")), .init(title: "Descending", image: #imageLiteral(resourceName: "Upload22"))]
            vc.context = .sort
            vc.topHeaderMode = .themedImage(name: "Order17", height: 17)
            vc.arrangeVC.sorter = sorter
            vc.leftButtonAction = { button, vc in (vc as? VerticalPresentationContainerViewController)?.arrangeVC.persist(button) }
            
//            PopoverDelegate.shared.prepare(vc: verticalPresentedVC, preferredSize: .init(width: 350, height: 169), sourceView: sourceView ?? sorter.arrangeButton, sourceRect: sourceRect ?? sorter.arrangeButton.bounds.modifiedBy(width: 0, height: 5), permittedDirections: [.up, .down])
            
            return vc.arrangeVC
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
    
    func showProperties(of entity: MPMediaEntity, entityType: EntityType, title: String, from sender: UIViewController) {
        
        guard let vc = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
        
        vc.title = title
        vc.context = .properties
        vc.propertiesVC.entity = entity
        vc.propertiesVC.entityType = entityType
        
        sender.present(vc, animated: true, completion: nil)
    }
    
    func addToQueue(from sender: UIViewController, kind: MPMusicPlayerController.QueueKind, context: QueueInsertController.Context, index: CGFloat = -1, title: String? = nil) {
        
        guard let vc = popoverStoryboard.instantiateViewController(withIdentifier: String.init(describing: VerticalPresentationContainerViewController.self)) as? VerticalPresentationContainerViewController else { return }
            
        vc.context = .alert
        vc.alertVC.context = .queue(title: title, kind: kind, context: context)
        vc.topHeaderMode = .themedImage(name: "AddSong22", height: 22)
        vc.subtitle = "Queue"
        vc.alertVC.actions = {
            
            var array = [AlertAction]()
            
            if vc.alertVC.queueInsertController.applicableShuffle.rawValue > ApplicableShuffle.none.rawValue {
            
                array.append(contentsOf: [
                    .init(info:
                        .init(title: "Unshuffled",
                              accessoryType: .check({ vc.alertVC.queueInsertController.activeShuffle == .none })),
                          context: .alert(.default),
                          handler: { vc.alertVC.queueInsertController.activeShuffle = .none }),
                    .init(info:
                        .init(title: "Shuffled Songs",
                              accessoryType: .check({ vc.alertVC.queueInsertController.activeShuffle == .songs })),
                          context: .alert(.default),
                          handler: { vc.alertVC.queueInsertController.activeShuffle = .songs })
                ])
            }
            
            if vc.alertVC.queueInsertController.applicableShuffle == .albums {
                
                array.append(
                    .init(info:
                        .init(title: "Shuffled Albums",
                              accessoryType: .check({ vc.alertVC.queueInsertController.activeShuffle == .albums })),
                          context: .alert(.default),
                          handler: { vc.alertVC.queueInsertController.activeShuffle = .albums }
                    )
                )
            }
            
            return array
        }()
        vc.requiresTopBorderView = vc.alertVC.actions.isEmpty.inverted
        vc.segments = [.init(title: "Next", image: #imageLiteral(resourceName: "PlayNext")), .init(title: "After...", image: #imageLiteral(resourceName: "PlayAfter")), .init(title: "Last", image: #imageLiteral(resourceName: "PlayLater"))]
        
        sender.present(vc, animated: true, completion: nil)
    }
    
    func showPropertySettings(from sender: UIViewController, with context: FilterViewContext) {
        
        guard let vc = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
        
        vc.context = .propertySettings
        vc.filterContext = context
        
        sender.present(vc, animated: true, completion: nil)
    }
    
    func performDeepSelection(from sender: UIViewController?, title: String?) {
        
        guard let vc = popoverStoryboard.instantiateViewController(withIdentifier: String.init(describing: VerticalPresentationContainerViewController.self)) as? VerticalPresentationContainerViewController, isInDebugMode else { return }
        
        vc.context = .alert
        vc.alertVC.context = .select
        vc.alertVC.actions = [.init(title: "Invert", handler: nil), .init(title: "Select", handler: nil), .init(title: "Deselect", handler: nil)]
        vc.segments = [.init(title: "All"), .init(title: "Above"), .init(title: "Below")]
        vc.alertVC.segmentActions = [{ _ in }, { _ in }, { _ in }]
        vc.leftButtonAction = nil
        vc.rightButtonAction = nil
        vc.title = title
        vc.subtitle = nil
        vc.requiresTopBorderView = true
        
        sender?.present(vc, animated: true, completion: nil)
    }
}
