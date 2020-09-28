//
//  Protocols.swift
//  Melody
//
//  Created by Ezenwa Okoro on 02/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

// MARK: - BackgroundHideable
protocol BackgroundHideable {

    var temporaryImageView: UIImageView { get set }
    var temporaryEffectView: MELVisualEffectView { get set }
    var view: UIView! { get set }
}

extension BackgroundHideable {
    
    func modifyBackgroundView(forState state: BackgroundViewState) {
        
        switch state {
            
            case .visible:
                
                let views: [UIView] = [temporaryEffectView, temporaryImageView]
                
                for subview in views {
                    
                    view.addSubview(subview)
                    view.sendSubviewToBack(subview)
                    subview.translatesAutoresizingMaskIntoConstraints = false
                    
                    view.addConstraints([NSLayoutConstraint.init(item: view as Any, attribute: .bottom, relatedBy: .equal, toItem: subview, attribute: .bottom, multiplier: 1, constant: 0), NSLayoutConstraint.init(item: view as Any, attribute: .top, relatedBy: .equal, toItem: subview, attribute: .top, multiplier: 1, constant: 0), NSLayoutConstraint.init(item: view as Any, attribute: .leading, relatedBy: .equal, toItem: subview, attribute: .leading, multiplier: 1, constant: 0), NSLayoutConstraint.init(item: view as Any, attribute: .trailing, relatedBy: .equal, toItem: subview, attribute: .trailing, multiplier: 1, constant: 0)])
                }
            
            case .removed:
                
                temporaryEffectView.frame = .zero
                temporaryImageView.frame = .zero
                temporaryImageView.image = nil
                temporaryEffectView.effect = nil
                temporaryImageView.isHidden = true
                temporaryEffectView.isHidden = true
                temporaryImageView.removeFromSuperview()
                temporaryEffectView.removeFromSuperview()
        }
    }
}

// MARK: - QueueManager
protocol QueueManager: class {
    
    var queue: [MPMediaItem] { get set }
    var shuffled: Bool { get set }
    var reverseShuffle: Bool { get set }
}

// MARK: - DynamicSections
protocol DynamicSections { }

extension DynamicSections where Self: UIViewController {
    
    func getSectionDetails(from arrays: SectionDetails...) -> [SectionDetails] {
        
        var tupleArray = [SectionDetails]()
        
        for array in arrays where array.count > 0 {
            
            tupleArray.append(array)
        }
        
        return tupleArray
    }
}

// MARK: - Contained
protocol Contained { }

extension Contained where Self: UIViewController {
    
    weak var container: ContainerViewController? { return navigationController?.parent as? ContainerViewController }
}

// MARK: - ArtworkContainingCell
protocol ArtworkContainingCell: class {
    
    var artworkImageView: (EntityArtworkDisplaying & UIImageView)! { get set }
}

protocol ArtistTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var currentAlbum: MPMediaItemCollection? { get set }
    var artistQuery: MPMediaQuery? { get set }
}

protocol AlbumTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var albumQuery: MPMediaQuery? { get set }
}

protocol PlaylistTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var playlistQuery: MPMediaQuery? { get set }
}

protocol PreviewTransitionable: class {
    
    var isCurrentlyTopViewController: Bool { get set }
    var viewController: UIViewController? { get set }
}

protocol GenreTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var currentAlbum: MPMediaItemCollection? { get set }
    var genreQuery: MPMediaQuery? { get set }
}

protocol ComposerTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var currentAlbum: MPMediaItemCollection? { get set }
    var composerQuery: MPMediaQuery? { get set }
}

protocol AlbumArtistTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var currentAlbum: MPMediaItemCollection? { get set }
    var albumArtistQuery: MPMediaQuery? { get set }
}

protocol ArtworkModifying: class {
    
    var artwork: UIImage? { get set }
}

extension ArtworkModifying {
    
    var artworkType: ArtworkType {
        
        switch backgroundArtworkAdaptivity {
            
            case .none: return .colour(.noArtwork)
            
            case .nowPlayingAdaptive:
            
                if let artwork = musicPlayer.nowPlayingItem?.actualArtwork?.image(at: .artworkSize) {
                    
                    return .image(artwork)
                }
                
                return .colour(.noArtwork)
            
            case .sectionAdaptive:
            
                if let artwork = artwork {
                    
                    return .image(artwork)
                }
                
                return .colour(.noArtwork)
        }
    }
}

protocol ArtworkModifierContaining: class {
    
    var modifier: ArtworkModifying? { get }
}

protocol Peekable: class {
    
    var peeker: UIViewController? { get set }
    var oldArtwork: UIImage? { get set }
}

protocol InteractivePresenter {
    
    var presenter: PresentationAnimationController { get }
}

protocol PropertyStripPresented {
    
    var title: String { get }
    var propertyImage: UIImage? { get }
}

extension PropertyStripPresented {
    
    func perform(_ operation: FilterViewContext.Operation, context: FilterViewContext) {
        
        switch operation {
            
            case .group(index: let index):
            
                switch context {
                    
                    case .filter:
                    
                        guard let property = self as? Property, let arrayIndex = filterProperties.firstIndex(of: property), Set(otherFilterProperties).contains(property).inverted else { return }
                    
                        prefs.set(filterProperties.removing(from: arrayIndex).map({ $0.oldRawValue }), forKey: .filterProperties)
                        prefs.set(otherFilterProperties.inserting(property, at: index ?? otherFilterProperties.endIndex).map({ $0.oldRawValue }), forKey: .otherFilterProperties)
                    
                    case .library:
                    
                        guard let section = self as? LibrarySection, let arrayIndex = librarySections.firstIndex(of: section), Set(otherLibrarySections).contains(section).inverted else { return }
                        
                        prefs.set(librarySections.removing(from: arrayIndex).map({ $0.rawValue }), forKey: .librarySections)
                        prefs.set(otherLibrarySections.inserting(section, at: index ?? otherLibrarySections.endIndex).map({ $0.rawValue }), forKey: .otherLibrarySections)
                }
            
            case .ungroup(index: let index):
            
                switch context {
                    
                    case .filter:
                        
                        guard let property = self as? Property, let arrayIndex = otherFilterProperties.firstIndex(of: property), Set(filterProperties).contains(property).inverted else { return }
                        
                        prefs.set(otherFilterProperties.removing(from: arrayIndex).map({ $0.oldRawValue }), forKey: .otherFilterProperties)
                        prefs.set(filterProperties.inserting(property, at: index ?? filterProperties.endIndex).map({ $0.oldRawValue }), forKey: .filterProperties)
                    
                    case .library:
                        
                        guard let section = self as? LibrarySection, let arrayIndex = otherLibrarySections.firstIndex(of: section), Set(librarySections).contains(section).inverted else { return }
                        
                        prefs.set(otherLibrarySections.removing(from: arrayIndex).map({ $0.rawValue }), forKey: .otherLibrarySections)
                        prefs.set(librarySections.inserting(section, at: index ?? librarySections.endIndex).map({ $0.rawValue }), forKey: .librarySections)
                }
            
            case .hide:
            
                switch context {
                    
                    case .filter:
                    
                        guard let property = self as? Property, Set(hiddenFilterProperties).contains(property).inverted else { return }
                    
                        prefs.set(hiddenFilterProperties.appending(property).map({ $0.oldRawValue }), forKey: .hiddenFilterProperties)
                    
                    case .library:
                    
                        guard let section = self as? LibrarySection, Set(hiddenLibrarySections).contains(section).inverted else { return }
                        
                        prefs.set(hiddenLibrarySections.appending(section).map({ $0.rawValue }), forKey: .hiddenLibrarySections)
                }
            
            case .unhide:
            
                switch context {
                    
                    case .filter:
                    
                        guard let property = self as? Property, let index = hiddenFilterProperties.firstIndex(of: property) else { return }
                    
                        prefs.set(hiddenFilterProperties.removing(from: index).map({ $0.oldRawValue }), forKey: .hiddenFilterProperties)
                    
                    case .library:
                    
                        guard let section = self as? LibrarySection, let index = hiddenLibrarySections.firstIndex(of: section) else { return }
                        
                        prefs.set(hiddenLibrarySections.removing(from: index).map({ $0.rawValue }), forKey: .hiddenLibrarySections)
                }
        }
        
        notifier.post(name: .propertiesUpdated, object: nil, userInfo: [String.filterViewContext: context])
    }
}

protocol EntityContainer: UITableViewDelegate, TableViewContaining {
    
    func handleLeftSwipe(_ sender: Any)
    func handleRightSwipe(_ sender: Any)
}

protocol TableViewContainer: FullySortable, InfoLoading, Filterable, SingleItemActionable {
    
    var tableDelegate: TableDelegate { get set }
    var collectionView: UICollectionView? { get set }
    var entities: [MPMediaEntity] { get set }
    var query: MPMediaQuery? { get }
    var filteredEntities: [MPMediaEntity] { get set }
    var highlightedEntity: MPMediaEntity? { get }
    
    func selectCell(in tableView: UITableView, at indexPath: IndexPath, filtering: Bool)
    func getEntity(at indexPath: IndexPath, filtering: Bool) -> MPMediaEntity
}

extension TableViewContainer {
    
    func setHighlightedIndex(of entity: MPMediaEntity) {
        
        highlightedIndex = entities.firstIndex(of: entity)
    }
    
    func sortAllItems() {
        
        headerView.updateSortActivityIndicator(to: .visible)
        
        let mainBlock: ([MPMediaEntity], [MPMediaPlaylist], [SortSectionDetails], [PlaylistContainer]) -> () = { [weak self] array, recentsArray, details, playlistContainers in
            
            guard let weakSelf = self, weakSelf.operation?.isCancelled == false else {
                
                self?.headerView.updateSortActivityIndicator(to: .hidden)
                
                return
            }
            
            weakSelf.entities = array
            
            if let collectionsVC = weakSelf as? CollectionsViewController, collectionsVC.collectionKind == .playlist {
                
                collectionsVC.headerView.playlists = recentsArray
                collectionsVC.playlistsLoaded = true
                collectionsVC.libraryVC?.setCurrentOptions()
                
                if showPlaylistFolders {
                    
                    collectionsVC.tableDelegate.playlistContainers = playlistContainers
                }
            }
            
            weakSelf.sections = details
            weakSelf.headerView.updateSortActivityIndicator(to: .hidden)
            
            guard weakSelf.operation?.isCancelled == false else { return }
            
            if let container = weakSelf as? LibrarySectionContainer {
                
                container.updateTopLabels(setTitle: container.libraryVC?.container?.activeViewController?.topViewController == container.libraryVC)
            }
            
            if let playlistItemsVC = weakSelf as? PlaylistItemsViewController {
                
                playlistItemsVC.updateEmptyLabel(withCount: array.count)
            }

            weakSelf.updateHeaderView(withCount: array.count)
            weakSelf.prepareSupplementaryInfo(animated: true)
            
            if let container = weakSelf as? LibrarySectionContainer {
                
                var text: String {
                    
                    if let collectionsVC = weakSelf as? CollectionsViewController {
                    
                        guard collectionsVC.collectionKind != .playlist else {
                            
                            return "Create a new playlist or use iTunes to create other types of playlists"
                        }
                        
                        return showiCloudItems ? "There are no \(collectionsVC.collectionKind.title.lowercased()) in your library" : "There are no offline \(collectionsVC.collectionKind.title.lowercased()) in your library"
                    
                    } else {
                        
                        return showiCloudItems ? "There are no songs in your library" : "There are no offline songs in your library"
                    }
                }
                
                container.libraryVC?.updateEmptyLabel(withCount: array.count, text: text)
            }
            
            if weakSelf.filtering, let filterContainer = weakSelf.filterContainer, let text = filterContainer.searchBar?.text {
                
                filterContainer.searchBar?(filterContainer.searchBar, textDidChange: text)
                
            } else {
                
                if let container = weakSelf as? LibrarySectionContainer {
                    
                    if let _ = container as? SongsViewController {
                        
                        weakSelf.headerView.showRecents = showRecentSongs && weakSelf.sortCriteria != .dateAdded
                    
                    } else if let collectionsVC = container as? CollectionsViewController {
                        
                        weakSelf.headerView.showRecents = collectionsVC.showRecents && weakSelf.sortCriteria != .dateAdded
                    }
                    
                    weakSelf.updateHeaderView(withCount: array.count)
                }
                
                weakSelf.tableView.reloadData()
                
                if let collectionsVC = weakSelf as? CollectionsViewController, collectionsVC.collectionKind == .playlist {
                    
                    collectionsVC.collectionView?.isHidden = true
                }
                
                if let animator = weakSelf as? CellAnimatable {
                    
                    if let vc = weakSelf as? UIViewController, let peekable = vc.parent as? Peekable, peekable.peeker != nil { } else {
                        
                        animator.animateCells(direction: .vertical, alphaOnly: weakSelf.highlightedIndex != nil)
                    }
                }
                
                if let collectionsVC = weakSelf as? CollectionsViewController, collectionsVC.collectionKind == .playlist && weakSelf.sortCriteria != .dateAdded {
                    
                    collectionsVC.collectionView?.reloadData()
                    UniversalMethods.performOnMainThread({ collectionsVC.animateCollectionCells() }, afterDelay: 0.1)
                }
                
                weakSelf.scrollToHighlightedRow()
            }
        }
        
        let parent = (self as? UIViewController)?.parent
        let items = expectedEntities
        
        operation?.cancel()
        operation = BlockOperation()
        operation?.addExecutionBlock({ [weak operation, weak self, weak parent] in
            
            guard let weakSelf = self as? TableViewContainer & UIViewController, let weakOperation = operation, !weakOperation.isCancelled, let items = items/*query?.items*/, !items.isEmpty else {
                
                OperationQueue.main.addOperation {
                    
                    self?.headerView.updateSortActivityIndicator(to: .hidden)
                    
                    if self?.query?.items?.isEmpty == true {
                        
//                        self?.updateEmptyLabel(withCount: 0)
                        self?.entities = []
                        self?.tableView.reloadData()
                        self?.updateHeaderView(withCount: 0)
                    }
                }
                
                return
            }
            
            // for artistSongsVC
            let isAlternateAlbumArrangement = Set([SortCriteria.albumName, .albumYear]).contains(weakSelf.sortCriteria)
            let other = isAlternateAlbumArrangement ? (weakSelf as? ArtistSongsViewController)?.altSections(by: weakSelf.sortCriteria == .albumName ? .name : .year) : nil
            
            let array = weakSelf.sortedArray(from: items, alternateArray: other?.items)
            let recentArray: [MPMediaPlaylist] = {
                
                guard let collectionsVC = weakSelf as? CollectionsViewController, collectionsVC.collectionKind == .playlist else { return [] }
                
                return collectionsVC.recentPlaylists(from: array.entities as? [MPMediaItemCollection] ?? [])
            }()
            
            if let highlighter = parent as? HighlightedEntityContaining {
                
                switch weakSelf.location {
                    
                    case .album, .playlist, .songs, .collection(kind: _, point: .songs):
                        
                        if let song = highlighter.highlightedEntities?.song {
                        
                            weakSelf.highlightedIndex = array.entities.firstIndex(of: song)
                        }
                    
                    case .collections, .collection:
                        
                        if let collection = highlighter.highlightedEntities?.collection {
                        
                            weakSelf.highlightedIndex = array.entities.firstIndex(of: collection)
                        }
                    
                    default: break
                }
            }
            
            guard !weakOperation.isCancelled else {
                
                UniversalMethods.performInMain {
                    
                    self?.headerView.updateSortActivityIndicator(to: .hidden)
                }
                
                return
            }
            
            let details = weakSelf.sortedSections(from: array.entities, alternateSections: other?.details)
            
            OperationQueue.main.addOperation({ mainBlock(array.entities, recentArray, details, array.containers) })
        })
        
        sortOperationQueue.addOperation(operation!)
        
        if let collectionsVC = self as? CollectionsViewController, collectionsVC.collectionKind == .playlist { return }
        
        if let actionable = self as? CollectionActionable {
            
            actionable.getActionableSongs()
        }
        
        if let container = self as? LibrarySectionContainer {
            
            container.getRecents()
        }
    }
    
    var expectedEntities: [MPMediaEntity]? {
        
        switch sortLocation {
            
            case .album, .playlist, .songs: return query?.items
            
            case .playlistList, .collections: return query?.collections
        }
    }
    
    func sortedSections(from entities: [MPMediaEntity], alternateSections: [SortSectionDetails]?) -> [SortSectionDetails] {
        
        guard let vc = self as? UIViewController else { return [] }
        
        if let sections = alternateSections {
            
            return sections
        }
        
        switch vc.location {
            
            case .album, .playlist, .songs, .collection(kind: _, point: .songs): return prepareSections(from: entities as! [MPMediaItem])
            
            case .collections(kind: let collectionKind):
                
                switch collectionKind {
                
                    case .playlist: return prepareSections(from: entities as! [MPMediaPlaylist])
                    
                    default: return prepareSections(from: entities as! [MPMediaItemCollection])
                }
            
            case .collection(kind: _, point: .albums): return prepareSections(from: entities as! [MPMediaItemCollection])
            
            default: return []
        }
    }
    
    func sortedArray(from entities: [MPMediaEntity], alternateArray: [MPMediaEntity]?) -> (entities: [MPMediaEntity], containers: [PlaylistContainer]) {
        
        switch sortCriteria {
            
            case .random:
                
                if let collectionsVC = self as? CollectionsViewController, collectionsVC.collectionKind == .playlist {
                    
                    let playlists = collectionsVC.getPlaylists(from: entities as! [MPMediaPlaylist]).filter({ collectionsVC.condition(for: $0) }).shuffled()
                    
                    if showPlaylistFolders {
                        
                        let reduced = playlists.foldersConsidered.map({ $0.reduced })
                        let containers = reduced.reduce([], { $0 + $1.containers })
                        
                        return (reduced.reduce([], { $0 + $1.dataSource }), containers)
                    }
                    
                    return (playlists, [])
                }
                
                return (entities.shuffled(), [])
    
            case .standard:
                
                if let collectionsVC = self as? CollectionsViewController, collectionsVC.collectionKind == .playlist {
                    
                    let playlists = collectionsVC.standardPlaylists(from: entities as! [MPMediaPlaylist]).filter({ collectionsVC.condition(for: $0) })
                    
                    if showPlaylistFolders {
                        
                        let reduced = playlists.foldersConsidered.map({ $0.reduced })
                        let containers = reduced.reduce([], { $0 + $1.containers })
                        
                        return (reduced.reduce([], { $0 + $1.dataSource }), containers)
                    }
                    
                    return (playlists, [])
                }
                
                return (ascending ? entities : entities.reversed(), [])
            
            case .dateAdded where (self as? CollectionsViewController)?.collectionKind == .playlist:
                
                guard let collectionsVC = self as? CollectionsViewController else { return (entities, []) }
            
                if let recentsQuery = collectionsVC.recentsQuery {
                    
                    let array = collectionsVC.getPlaylists(from: recentsQuery.collections as? [MPMediaPlaylist] ?? []).filter({ collectionsVC.condition(for: $0) })
                    
                    let playlists = collectionsVC.ascending ? array.reversed() : array
                    
                    if showPlaylistFolders {
                        
                        let reduced = playlists.foldersConsidered.map({ $0.reduced })
                        let containers = reduced.reduce([], { $0 + $1.containers })
                        
                        return (reduced.reduce([], { $0 + $1.dataSource }), containers)
                    }
                    
                    return (playlists, [])
                }
                
                return ((collectionsVC.getPlaylists(from: entities as! [MPMediaPlaylist]).filter({ collectionsVC.condition(for: $0) }) as NSArray).sortedArray(using: collectionsVC.sortDescriptors) as! [MPMediaPlaylist], [])
    
            default:
                
                if let collectionsVC = self as? CollectionsViewController, collectionsVC.collectionKind == .playlist {
                    
                    let playlists = (collectionsVC.getPlaylists(from: entities as! [MPMediaPlaylist]).filter({ collectionsVC.condition(for: $0) }) as NSArray).sortedArray(using: collectionsVC.sortDescriptors) as! [MPMediaPlaylist]
                    
                    if showPlaylistFolders {
                        
                        let reduced = playlists.foldersConsidered.map({ $0.reduced })
                        let containers = reduced.reduce([], { $0 + $1.containers })
                        
                        return (reduced.reduce([], { $0 + $1.dataSource }), containers)
                    }
                    
                    return (playlists, [])
                }
                
                return (alternateArray ?? (entities as NSArray).sortedArray(using: sortDescriptors) as! [MPMediaEntity], [])
        }
    }
}

protocol HighlightedEntityContaining: class {
    
    var highlightedEntities: (song: MPMediaItem?, collection: MPMediaItemCollection?)? { get set }
}

protocol FilterContaining: class {
    
    var filterContainer: (FilterContainer & UIViewController)? { get set }
}

protocol Dismissable {
    
    var needsDismissal: Bool { get set }
    var navigationController: UINavigationController? { get }
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

protocol QueryUpdateable {
    
    func updateWithQuery()
}

protocol Attributor: class {
    
    func updateAttributedText(for view: TableHeaderView?, inSection section: Int)
}

protocol CellAnimatable: TableViewContaining { }

extension CellAnimatable {
    
    func animateCells(direction: AnimationOrientation = .horizontal, alphaOnly: Bool = false) {
        
        let cells = tableView.visibleCells
        
        for cell in cells {
            
            cell.alpha = 0
            
            if alphaOnly.inverted {
            
                cell.transform = .init(translationX: direction == .horizontal ? tableView.bounds.size.width : 0, y: direction == .horizontal ? 0 : 40)
            }
        }
        
        for cell in cells.enumerated() {
            
            UIView.animate(withDuration: 0.8, delay: 0.02 * Double(cell.offset), usingSpringWithDamping: 0.8, initialSpringVelocity: direction == .horizontal ? 0 : 20, options: [.curveLinear, .allowUserInteraction], animations: {
                
                cell.element.alpha = 1
                
                if alphaOnly.inverted {
                
                    cell.element.transform = .identity
                }
                
            }, completion: nil)
        }
    }
}

@objc protocol OnlineOverridable {
    
    var onlineOverride: Bool { get set }
    func performOnlineOverride()
    @objc optional var tempViewLeadingConstraint: NSLayoutConstraint! { get set }
    @objc optional var topView: UIView! { get set }
    func updateOfflineFilterPredicates(onCondition condition: Bool)
}

extension OnlineOverridable {
    
//    func updateTempView(hidden: Bool) {
//
//        tempViewLeadingConstraint?.priority = UILayoutPriority(rawValue: hidden ? 899 : 901)
//
//        UIView.animate(withDuration: 0.3, animations: { self.topView?.layoutIfNeeded() })
//    }
}

protocol TextContaining: class {
    
    var actualFont: UIFont? { get set }
}

protocol Boldable {
    
    var boldableLabels: [TextContaining?] { get }
}

extension Boldable {
    
    func changeSize(to weight: FontWeight) {
        
        for container in boldableLabels {
            
            guard let size = container?.actualFont?.pointSize else { return }
            
            container?.actualFont = UIFont.font(ofWeight: weight, size: size)
        }
    }
}

protocol Settable: NSObjectProtocol {

    var likedState: LikedState { get }
    var persistentID: MPMediaEntityPersistentID { get }
}

extension Settable {
    
    func set(property: String, to value: Any?) {
        
        let string = NSString.init(format: "%@%@%@%@%@%@%@%@%@%@", "set", "Va", "lu", "e:", "for", "Pr", "op", "er", "ty", ":")
        let sel = NSSelectorFromString(string as String)
        
        guard self.responds(to: sel) else { return }
        
        _ = perform(sel, with: value, with: property)
    }
}

protocol PillButtonContaining {
    
    var borderedButtons: [PillButtonView?] { get set }
}

extension PillButtonContaining {
    
    func updateButtons() {
        
        let edgeConstraint: CGFloat = 10.0/3.0
        let middleConstraint: CGFloat = 20.0/3.0
        
        for view in borderedButtons {
            
            guard let view = view ?? nil, let first = borderedButtons.first ?? nil, let last = borderedButtons.last ?? nil else { return }
            
            let position: Position = {
                
                switch (first, last) {
                    
                    case (view, let z) where z != view: return .leading
                    
                    case (view, view): return .middle(single: true)
                    
                    case (let y, let z) where y != view && z != view: return .middle(single: false)
                    
                    case (let y, view) where y != view: return .trailing
                    
                    default:
                        
                        print("couldn't find button position")
                        
                        return .leading
                }
            }()
            
            switch position {
                
                case .leading:
                
                    view.borderViewContainerLeadingConstraint.constant = 10
                    view.borderViewContainerTrailingConstraint.constant = borderedButtons.count < 3 ? 5 : edgeConstraint
                
                case .middle(single: let single):
                
                    view.borderViewContainerLeadingConstraint.constant = single ? 10 : middleConstraint
                    view.borderViewContainerTrailingConstraint.constant = single ? 10 : middleConstraint
                
                case .trailing:
                
                    view.borderViewContainerLeadingConstraint.constant = borderedButtons.count < 3 ? 5 : edgeConstraint
                    view.borderViewContainerTrailingConstraint.constant = 10
            }
        }
    }
}

protocol OptionsContaining {
    
    var options: LibraryOptions { get }
}

protocol TableViewContaining: class {
    
    var tableView: MELTableView! { get set }
}

protocol TopScrollable: IndexContaining { }

extension TopScrollable {
    
    func scrollToTop() {
        
        tableView.setContentOffset(.init(x: 0, y: -(navigatable?.inset ?? 0)), animated: true)
    }
}

protocol Detailing {
    
    func goToDetails(basedOn entityType: EntityType) -> (entities: [EntityType], albumArtOverride: Bool)
}

extension Detailing {
    
    func getActionDetails(from action: SongAction, indexPath: IndexPath, actionable: SingleItemActionable?, vc: UIViewController?, entityType: EntityType, entity: MPMediaEntity, useAlternateTitle alternateTitle: Bool = false) -> ActionDetails? {
        
        guard let actionable = actionable, let vc = vc else { return nil }
        
        return actionable.singleItemActionDetails(for: action, entityType: entityType, using: entity, from: vc, useAlternateTitle: alternateTitle)
    }
}

protocol LocationBroadcastable { }

extension LocationBroadcastable {
    
    var location: Location {
        
        if let _ = self as? PlaylistItemsViewController {
            
            return .playlist
            
        } else if let _ = self as? AlbumItemsViewController {
            
            return .album
            
        } else if let vc = self as? ArtistSongsViewController, let entityVC = vc.entityVC {
            
            return .collection(kind: entityVC.kind, point: .songs)
            
        } else if let vc = self as? ArtistAlbumsViewController, let entityVC = vc.entityVC {
            
            return .collection(kind: entityVC.kind, point: .albums)
            
        } else if let _ = self as? SongsViewController {
            
            return .songs
            
        } else if let vc = self as? CollectionsViewController {
            
            return .collections(kind: vc.collectionKind)
            
        } else if let _ = self as? CollectorViewController {
            
            return .collector
            
        } else if let _ = self as? NowPlayingViewController {
            
            return .fullPlayer
            
        } else if let _ = self as? ContainerViewController {
            
            return .miniPlayer
            
        } else if let _ = self as? QueueViewController {
            
            return .queue
            
        } else if let _ = self as? SearchViewController {
            
            return .search
            
        } else if let _ = self as? InfoViewController {
            
            return .info
            
        } else if let _ = self as? NewPlaylistViewController {
            
            return .newPlaylist
            
        } else {
            
            fatalError("No other VC should invoke this")
        }
    }
}

protocol EditControlContaining: class {
    
    var preferredEditingStyle: EditingStyle { get set }
}

protocol CentreViewDisplaying: class {
    
    var centreView: CentreView? { get set }
    var currentCentreView: CentreView.CurrentView { get set }
    var centreViewGiantImage: UIImage? { get set }
    var centreViewTitleLabelText: String? { get set }
    var centreViewSubtitleLabelText: String? { get set }
    var centreViewLabelsImage: UIImage? { get set }
}

extension CentreViewDisplaying {
    
    var shouldUpdateCentreView: Bool {
        
        if let contained = self as? Contained & UIViewController, let container = contained.container {
            
            return (container.activeViewController?.delegate as? NavigationAnimationController)?.animationInProgress != true && contained == container.activeViewController?.topViewController
        
        } else if let vc = self as? UIViewController, vc.parent is PresentedContainerViewController {
            
            return true
        }
        
        return false
    }
    
    func updateCurrentView(to view: CentreView.CurrentView, animated: Bool = true, setAlpha: Bool = true, alternateCentreView: CentreView? = nil, completion: (() -> ())? = nil) {
        
        let centreView = self.centreView ?? alternateCentreView
        
        if let tableContainer = self as? TableViewContaining {
            
            tableContainer.tableView?.isUserInteractionEnabled = view != .indicator
        }
        
        updateViews(to: view, alternateCentreView: centreView)
        
        if currentCentreView != view {
        
            currentCentreView = view
        }
        
        guard shouldUpdateCentreView else { return }

        centreView?.updateCurrentView(to: currentCentreView, animated: animated, setAlpha: setAlpha, completion: completion)
    }
    
    func updateViews(to view: CentreView.CurrentView, alternateCentreView: CentreView?) {
        
        let centreView = self.centreView ?? alternateCentreView
        
        switch view {
            
            case .none: break
            
            case .indicator:
            
                if let queueVC = self as? QueueViewController {
                    
                    centreView?.activityVisualEffectView.isHidden = queueVC.queueIsBeingEdited.inverted && isQueueAvailable.inverted && queueVC.firstScroll
                }
            
            case .labels(components: let components):
            
                if components.contains(.title), let text = centreViewTitleLabelText {
                    
                    centreView?.titleLabel.text = text
                    centreView?.titleLabel.attributes = [.init(name: .paragraphStyle, value: .other(NSMutableParagraphStyle.withLineHeight(1.2, alignment: .center)), range: text.nsRange())]
                }
                
                if components.contains(.subtitle), let text = centreViewSubtitleLabelText {
                        
                    centreView?.subtitleLabel.text = text
                    centreView?.subtitleLabel.attributes = [.init(name: .paragraphStyle, value: .other(NSMutableParagraphStyle.withLineHeight(1.2, alignment: .center)), range: text.nsRange())]
                }
                
                if components.contains(.image) {
                    
                    centreView?.labelsImageView.image = centreViewLabelsImage
                }
            
            case .image: break
        }
    }
}

protocol YAxisAnchorable {
    
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}

extension EntityArtworkType {
    
    var artwork: UIImage? { self.artwork(darkTheme: darkTheme) }
}

extension ThemeStatusProvider {
    
    var isDarkTheme: Bool { darkTheme }
}
