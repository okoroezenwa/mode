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
        
        if let vc = vc as? VerticalPresentationContainerViewController {
            
            vc.segments = [.init(title: "Ascending", image: #imageLiteral(resourceName: "Ascending17")), .init(title: "Descending", image: #imageLiteral(resourceName: "Descending17"))]
            vc.staticOptions = [.init(title: "Default"), .init(title: "Random")]
            vc.context = .sort
            vc.arrangeVC.sorter = sorter
            vc.requiresSegmentedControl = true
            vc.requiresStaticView = true
            vc.leftButtonAction = { button, _ in vc.arrangeVC.persist(button) }
            
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
    
    func showProperties(of entity: MPMediaEntity, entityType: Entity, title: String, from sender: UIViewController) {
        
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
        vc.subtitle = "Queue..."
        vc.alertVC.actions = [
            .init(info:
                .init(title: "Unshuffled",
                      accessoryType: .check({ vc.alertVC.queueInsertController?.activeShuffle == .some(.none) }),
                      inactive: { vc.alertVC.queueInsertController!.applicableShuffle.rawValue < ApplicableShuffle.songs.rawValue }),
                  context: .alert(.default),
                  handler: { vc.alertVC.queueInsertController?.activeShuffle = .none }),
            .init(info:
                .init(title: "Shuffled Songs",
                      accessoryType: .check({ vc.alertVC.queueInsertController?.activeShuffle == .songs }),
                      inactive: { vc.alertVC.queueInsertController!.applicableShuffle.rawValue < ApplicableShuffle.songs.rawValue }),
                  context: .alert(.default),
                  handler: { vc.alertVC.queueInsertController?.activeShuffle = .songs }),
            .init(info:
                .init(title: "Shuffled Albums",
                      accessoryType: .check({ vc.alertVC.queueInsertController?.activeShuffle == .albums }),
                      inactive: { vc.alertVC.queueInsertController!.applicableShuffle.rawValue < ApplicableShuffle.albums.rawValue }),
                  context: .alert(.default),
                  handler: { vc.alertVC.queueInsertController?.activeShuffle = .albums })
        ]
        vc.requiresSegmentedControl = false
        vc.requiresTopBorderView = true
        vc.staticOptions = [.init(title: "Next", image: #imageLiteral(resourceName: "PlayNext")), .init(title: "After...", image: #imageLiteral(resourceName: "PlayAfter")), .init(title: "Last", image: #imageLiteral(resourceName: "PlayLater"))]
        vc.requiresStaticView = true
        
        sender.present(vc, animated: true, completion: nil)
    }
    
    func showPropertySettings(from sender: UIViewController, with context: FilterViewContext) {
        
        guard let vc = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
        
        vc.context = .propertySettings
        vc.filterContext = context
        
        sender.present(vc, animated: true, completion: nil)
    }
    
    /// Array Version
    func showAlert(title: String?, subtitle: String? = nil, from sender: UIViewController?, context: AlertTableViewController.Context = .other, with actions: [AlertAction], segmentDetails: SegmentDetails = ([], nil), leftAction: AccessoryButtonAction? = nil, rightAction: AccessoryButtonAction? = nil, completion: (() -> ())? = nil) {
        
        guard let vc = popoverStoryboard.instantiateViewController(withIdentifier: String.init(describing: VerticalPresentationContainerViewController.self)) as? VerticalPresentationContainerViewController else { return }
        
        vc.context = .alert
        vc.alertVC.context = context
        vc.alertVC.actions = actions
        vc.alertVC.segmentAction = segmentDetails.action
        vc.leftButtonAction = leftAction
        vc.rightButtonAction = rightAction
        vc.title = title
        vc.subtitle = subtitle
        vc.segments = segmentDetails.array
        vc.requiresSegmentedControl = segmentDetails.array.isEmpty.inverted
        vc.requiresTopBorderView = true
        
        sender?.present(vc, animated: true, completion: completion)
    }
    
    /// Variadic Version
    func showAlert(title: String?, subtitle: String? = nil, from sender: UIViewController?, context: AlertTableViewController.Context = .other, with actions: AlertAction..., segmentDetails: SegmentDetails = ([], nil), leftAction: AccessoryButtonAction? = nil, rightAction: AccessoryButtonAction? = nil, completion: (() -> ())? = nil) {
        
        showAlert(title: title, subtitle: subtitle, from: sender, context: context, with: actions, segmentDetails: segmentDetails, leftAction: leftAction, rightAction: rightAction, completion: completion)
    }
}
