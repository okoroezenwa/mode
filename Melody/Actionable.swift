//
//  EntityArrayContaining.swift
//  Melody
//
//  Created by Ezenwa Okoro on 23/04/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

protocol SongActionable: class {
    
    var applicableActions: [SongAction] { get }
    var actionableSongs: [MPMediaItem] { get }
    var songManager: SongActionManager { get }
    var editButton: MELButton! { get set }
}

extension SongActionable {
    
    private var isQueueItems: Bool { return self is CollectorViewController }
    private func shuffleText(shuffled: Bool) -> String { return shuffled ? .shuffle() : "Play" }
    
    func showArrayActions(_ sender: Any) {
        
        guard !actionableSongs.isEmpty, let vc = self as? UIViewController else { return }
        
        var selection: [AlertAction] {
            
            if let container = self as? EntityContainer, container.tableView.isEditing {
                
                return [AlertAction.init(title: "End Editing", style: .default, handler: { [weak self] in
                
                    guard let weakSelf = self, container.tableView.isEditing else { return }
                    
                    weakSelf.songManager.toggleEditing("end")
                })]
            }
            
            return []
        }
        
        let actions = alertActions(from: vc) + selection// + [.cancel()]
        
        let title: String? = {
            
            if vc is InfoViewController { return "Add to..." }
            
            if vc is NewPlaylistViewController { return "Remove..." }
            
            guard actionableSongs.count > 1 else { return actionableSongs.first?.validTitle }
            
            var collectionTitle: String? {
                
                guard let collectionActionable = self as? CollectionActionable else { return nil }
                
                return collectionActionable.collectionsCount.fullCountText(for: collectionActionable.collectionKind.entity) + ", "
            }
            
            return (collectionTitle ?? "") + actionableSongs.count.fullCountText(for: .song)
        }()
        
        let infoAccessory: () -> AccessoryButtonAction? = { [weak vc] in
            
            guard let vc = vc, let entityVC = vc.parent as? EntityItemsViewController else { return nil }
            
            return { _, presenter in presenter.dismiss(animated: true, completion: { entityVC.showOptions() }) }
        }
        
        vc.showAlert(title: title, with: actions, segmentDetails: (isInDebugMode && (vc is InfoViewController).inverted) ? ([.init(title: "All"), .init(title: "Selected")], [{ _ in }, { _ in }]) : ([], []), rightAction: infoAccessory())
        
//        let alert = UIAlertController.withTitle(nil, message: title, style: .actionSheet, actions: actions)
//        vc.present(alert, animated: true, completion: nil)
    }
    
    func alertActions(from vc: UIViewController) -> [AlertAction] {
        
        return applicableActions.map({ alertAction(for: $0, from: vc, using: actionableSongs, alternateTitle: vc is InfoViewController) })
    }
    
    func alertAction(for action: SongAction, from vc: UIViewController, using array: [MPMediaItem], alternateTitle: Bool = false) -> AlertAction {
        
        let details = actionDetails(for: action, from: vc, using: array, alternateTitle: alternateTitle)
        
        return AlertAction.init(title: details.title, style: details.style, requiresDismissalFirst: action.requiresDismissalFirst, handler: { details.handler() })
    }
    
    func systemAlertActions(from vc: UIViewController) -> [UIAlertAction] {
        
        return applicableActions.map({ systemAlertAction(for: $0, from: vc, using: actionableSongs, alternateTitle: vc is InfoViewController) })
    }
    
    func systemAlertAction(for action: SongAction, from vc: UIViewController, using array: [MPMediaItem], alternateTitle: Bool = false) -> UIAlertAction {
        
        let details = actionDetails(for: action, from: vc, using: array, alternateTitle: alternateTitle)
        
        return UIAlertAction.init(title: details.title, style: details.style, handler: { _ in details.handler() })
    }
    
    func actionDetails(for action: SongAction, from vc: UIViewController, using array: [MPMediaItem], alternateTitle: Bool) -> ActionDetails {
        
        switch action {
            
            case .collect:
                
                return (action: action, title: alternateTitle ? "Collector" : "Collect", style: .default, {
                
                    notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: array])
                    
                    if vc.parent is PresentedContainerViewController || vc is NowPlayingViewController {
                        
                        useAlternateAnimation = true
                        shouldReturnToContainer = true
                        (vc.parent ?? vc).performSegue(withIdentifier: "unwind", sender: nil)
                    }
                })
            
            case .addTo:
            
                return (action: action, title: alternateTitle ? "Existing Playlists..." : "Add to Playlists...", style: .default, handler: {
                    
                    guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
                    
                    if let parent = vc.parent as? PresentedContainerViewController, let manager = parent.manager {
                        
                        presentedVC.manager = manager
                        
                    } else {
                        
                        presentedVC.itemsToAdd = array
                    }
                    
                    presentedVC.context = .playlists
                    presentedVC.fromQueue = false
                    presentedVC.playlistsVC.sectionOverride = .playlists
                    
                    vc.present(presentedVC, animated: true, completion: nil)
                })
            
            case .newPlaylist:
            
                return (action: action, title: alternateTitle ? "New Playlist..." : "Create Playlist...", style: .default, handler: {
                    
                    guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
                    
                    if let parent = vc.parent as? PresentedContainerViewController, let manager = parent.manager {
                        
                        presentedVC.manager = manager
                        
                    } else {
                        
                        presentedVC.itemsToAdd = array
                    }
                    
                    presentedVC.context = .newPlaylist
                    presentedVC.fromQueue = false
                    
                    vc.present(presentedVC, animated: true, completion: nil)
                })
            
            case .remove:
            
                return (action: action, title: "All", style: .destructive, handler: {
                    
                    guard let vc = vc as? NewPlaylistViewController/*, let parent = vc.parent as? PresentedContainerViewController*/ else { return }
                    
                    if vc.tableView.isEditing {
                        
                        vc.songManager.toggleEditing(vc.editButton as Any)
                    }
                    
                    vc.updateItems(at: (0..<vc.tableView.numberOfRows(inSection: 0)).map({ IndexPath.init(row: $0, section: 0) }), for: .remove)
                })
            
            case .library:
            
                return (action: action, title: alternateTitle ? "Library" : "Add to Library", style: .default, handler: {
                    
                    if #available(iOS 10.3, *), let item = musicPlayer.nowPlayingItem {
                        
                        guard let addable = self as? EntityVerifiable, addable.verifyLibraryStatus(of: item, itemProperty: .song) == .absent else {
                
                            let banner = Banner.init(title: "This song is already in your library", subtitle: nil, image: nil, backgroundColor: .deepGreen, didTapBlock: nil)
                            banner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                            banner.show(duration: 0.5)
                
                            (self as? EntityVerifiable)?.updateAddButton(hidden: true, animated: true)
                            return
                        }

                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                        
                        UniversalMethods.add(item, completions: ({ [weak self, weak vc] in
                            
                            guard let weakSelf = self else { return }
                            
                            if let addable = weakSelf as? EntityVerifiable {
                                
                                addable.updateAddButton(hidden: true, animated: true)
                            }
                            
                            if vc is InfoViewController {
                                
                                vc?.dismiss(animated: true, completion: nil)
                            }
                        
                        }, {  }))
                        
                        return
                    }

                    UniversalMethods.addToLibrary(array.first, completions: (success: { [weak vc] in vc?.dismiss(animated: true, completion: nil) }, error: { }), sameSongAction: { [weak self] bool in
                        
                        guard let weakSelf = self, let addable = weakSelf as? EntityVerifiable else { return }
                        
                        addable.updateAddButton(hidden: bool, animated: true)
                    })
                })
            
            case .queue(name: let name, query: _):
            
                return (action: action, title: "Queue...", style: .default, {
                    
                    Transitioner.shared.addToQueue(from: vc, kind: .items(array), context: .other, title: name)
                })
            
            case .likedState, .rate, .insert, .show, .reveal, .play, .shuffle:
            
                return (action: action, title: "", style: .default, {
                    
                    
                })
            
            case .info:
            
                return (action: action, title: alternateTitle ? "Info" : "Get Info", style: .default, {
                    
                    if let artistAlbumsVC = vc as? ArtistAlbumsViewController {
                        
                        Transitioner.shared.showInfo(from: artistAlbumsVC, with: .album(at: 0, within: artistAlbumsVC.albums))
                    
                    } else if let collectionsVC = vc as? CollectionsViewController {
                        
                        switch collectionsVC.collectionKind {
                            
                            case .album, .compilation: Transitioner.shared.showInfo(from: collectionsVC, with: .album(at: 0, within: collectionsVC.collections))
                            
                            case .playlist: Transitioner.shared.showInfo(from: collectionsVC, with: .playlist(at: 0, within: (collectionsVC.collectionKind == .playlist ? collectionsVC.collections.filter({ ($0 as? MPMediaPlaylist)?.isFolder.inverted ?? true }) : collectionsVC.collections) as? [MPMediaPlaylist] ?? []))
                            
                            default: Transitioner.shared.showInfo(from: collectionsVC, with: .collection(kind: collectionsVC.collectionKind.albumBasedCollectionKind, at: 0, within: collectionsVC.collections))
                        }
                        
                    } else {
                        
                        Transitioner.shared.showInfo(from: vc, with: .song(location: .list, at: 0, within: array))
                    }
                })
        }
    }
}

class SongActionManager: NSObject {
    
    private weak var actionable: SongActionable?
    
    init(actionable: SongActionable) {
        
        self.actionable = actionable
        
        super.init()
    }
    
    @objc func showActionsForAll(_ sender: Any) {
        
        let block: (() -> Void) = {
            
            if let actionable = self.actionable as? QueueViewController {
                
                if #available(iOS 10.3, *) {
                    
                    guard !useSystemPlayer && forceOldStyleQueue.inverted else {
                        
                        actionable.presentActionsForAll(sender)
                        return
                    }
                    
                    actionable.showArrayActions(sender)
                    
                } else {
                    
                    actionable.presentActionsForAll(sender)
                }
                
            } else {
                
                self.actionable?.showArrayActions(sender)
            }
        }
        
        if let gr = sender as? UILongPressGestureRecognizer {
            
            guard gr.state == .began else { return }
            
            if let collectionActionable = actionable as? CollectionActionable {
                
//                guard collectionActionable.collectionKind != .playlist else { return }
                
                if collectionActionable.actionableSongs.isEmpty || collectionActionable.actionableOperation?.isExecuting == true {
                    
                    collectionActionable.actionableActivityIndicator.startAnimating()
                    collectionActionable.shouldFillActionableSongs = true
                    collectionActionable.showActionsAfterFilling = true
                    (collectionActionable.editButton.superview as? PillButtonView)?.stackView?.alpha = 0
                    
                    if collectionActionable.actionableSongs.isEmpty {
                        
                        if let operation = collectionActionable.actionableOperation, operation.isExecuting { return }
                        
                        collectionActionable.getActionableSongs()
                    }
                    
                    return
                }
                
                block()
            
            } else {
                
                block()
            }
            
            return
        }
        
        block()
    }
    
    @objc func toggleEditing(_ sender: Any) {
        
        if actionable is QueueViewController, Queue.shared.queueCount < 2 { return }
        
        if let searchVC = actionable as? SearchViewController {
            
            searchVC.tableView.isEditing ? searchVC.handleLeftSwipe(searchVC) : searchVC.handleRightSwipe(searchVC)
            
            return
        }
        
        guard let actionable = actionable, let container = actionable as? EntityContainer, actionable is QueueViewController && (useSystemPlayer || forceOldStyleQueue) ? true : {
            
            if let collectionActionable = actionable as? CollectionActionable {
                
                return collectionActionable.collectionsCount > 0
            
            } else {
                
                if actionable is FilterViewController {
                    
                    return true
                }
                
                return actionable.actionableSongs.isEmpty.inverted
            }
            
        }() else { return }
        
        var leftAction: Bool {
            
            if let sender = sender as? UISwipeGestureRecognizer {
                
                return sender.direction == .left
                
            } else {
                
                return container.tableView.isEditing
            }
        }
        
        let isEditing = container.tableView.isEditing
        
        if leftAction {
            
            if isEditing {
                
//                if sender is UILongPressGestureRecognizer || sender is UISwipeGestureRecognizer || sender is UIAlertAction || (sender as? String) == "end" || ((container is CollectorViewController || container is NewPlaylistViewController || (container is FilterViewController && (container as? FilterViewController)?.filtering == false)) && (sender is UIButton || sender is UITapGestureRecognizer)) || sender is SwipeAction || sender is Notification {
                
                    if let superview = actionable.editButton.superview as? PillButtonView {
                        
                        superview.animateChange(title: .inactiveEditButtonTitle, image: .inactiveEditImage)
                    
                    } else if let snapshot = actionable.editButton.snapshotView(afterScreenUpdates: false) {
                        
                        actionable.editButton.superview?.superview?.addSubview(snapshot)
                        snapshot.frame = actionable.editButton.frame
                        actionable.editButton.alpha = 0
                        actionable.editButton.transform = .init(scaleX: 0.2, y: 0.2)
                        
                        actionable.editButton.setTitle(.inactiveEditButtonTitle, for: .normal)
                        actionable.editButton.setImage(.inactiveEditImage, for: .normal)
                        
                        UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: .calculationModeCubic, animations: {
                            
                            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/2, animations: {
                                
                                snapshot.transform = .init(scaleX: 0.2, y: 0.2)
                                snapshot.alpha = 0
                            })
                            
                            UIView.addKeyframe(withRelativeStartTime: 1/2, relativeDuration: 1/2, animations: {
                                
                                actionable.editButton.transform = .identity
                                actionable.editButton.alpha = 1
                            })
                            
                        }, completion: { _ in snapshot.removeFromSuperview() })
//                    }
                }
            }
            
            if sender is UIAlertAction, isEditing {
                
                container.handleLeftSwipe(actionable.editButton as Any)
                
            } else if sender is UIButton || sender is UITapGestureRecognizer, !(container is CollectorViewController || container is NewPlaylistViewController), isEditing {
                
                if let filterVC = actionable as? FilterViewController, filterVC.filtering.inverted {
                    
                    filterVC.handleLeftSwipe(sender)
                
                /*} else if let collectionActionable = actionable as? CollectionActionable {
                    
                    if collectionActionable.actionableSongs.isEmpty || collectionActionable.actionableOperation?.isExecuting == true {
                        
                        collectionActionable.actionableActivityIndicator.startAnimating()
                        collectionActionable.shouldFillActionableSongs = true
                        collectionActionable.showActionsAfterFilling = true
                        (collectionActionable.editButton.superview as? PillButtonView)?.stackView?.alpha = 0
                        collectionActionable.editButton.superview?.isUserInteractionEnabled = false
                        
                        if collectionActionable.actionableSongs.isEmpty {
                            
                            if let operation = collectionActionable.actionableOperation, operation.isExecuting { return }
                            
                            collectionActionable.getActionableSongs()
                        }
                        
                        return
                    }
                    
                    container.handleLeftSwipe(actionable.editButton as Any)//showActionsForAll(sender)
                    
                */} else {
                    
                    container.handleLeftSwipe(actionable.editButton as Any)//showActionsForAll(sender)
                }
                
            } else {
                
                container.handleLeftSwipe(sender)
            }
            
        } else {
            
            if !isEditing {
                
                let details: (title: String, image: UIImage) = /*container is CollectorViewController || container is NewPlaylistViewController || (container is FilterViewController && (container as? FilterViewController)?.filtering == false) ?*/ ("Done", .doneImage)// : (.activeEditButtonTitle, .moreEditImage)
                
                if let vc = container as? NewPlaylistViewController {
                    
                    vc.nameSearchBar.resignFirstResponder()
                }
                
                if let superview = actionable.editButton.superview as? PillButtonView {
                    
                    superview.animateChange(title: details.title, image: details.image)
                
                } else if let snapshot = actionable.editButton.snapshotView(afterScreenUpdates: false) {
                    
                    actionable.editButton.superview?.superview?.addSubview(snapshot)
                    snapshot.frame = actionable.editButton.frame
                    actionable.editButton.alpha = 0
                    actionable.editButton.transform = .init(scaleX: 0.2, y: 0.2)
                    
                    actionable.editButton.setTitle(details.title, for: .normal)
                    actionable.editButton.setImage(details.image, for: .normal)
                    
                    UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: .calculationModeCubic, animations: {
                        
                        UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/2, animations: {
                            
                            snapshot.transform = .init(scaleX: 0.2, y: 0.2)
                            snapshot.alpha = 0
                        })
                        
                        UIView.addKeyframe(withRelativeStartTime: 1/2, relativeDuration: 1/2, animations: {
                            
                            actionable.editButton.transform = .identity
                            actionable.editButton.alpha = 1
                        })
                        
                    }, completion: { _ in snapshot.removeFromSuperview() })
                }
            }
            
            container.handleRightSwipe(sender)
        }
    }
    
    @objc func updateAddView(editing: Bool) {
        
        guard let actionable = actionable, let container = actionable as? EntityContainer, {
            
            if let collectionActionable = actionable as? CollectionActionable {
                
                return collectionActionable.collectionsCount > 0
            }
            
            return actionable.actionableSongs.isEmpty.inverted
            
        }() else { return }
        
        if let indexPaths = container.tableView.indexPathsForVisibleRows {
            
            let views = Set(indexPaths.map({ $0.section })).map({ container.tableView.headerView(forSection: $0) as? TableHeaderView }).compactMap({ $0 })
            
            for view in views {
                
                guard view.canShowLeftButton else { return }
                
                view.updateLabelConstraint(showButton: editing)
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    let superview = view.button.superview
                    
                    if editing.inverted && view.showButton.inverted { } else {
                        
                        view.showButton = editing
                    }
                    
                    superview?.alpha = editing ? 1 : 0
                    superview?.superview?.superview?.layoutIfNeeded()
                })
            }   
        }
    }
}

protocol SingleItemActionable: SongActionable { }

extension SingleItemActionable {
    
    func singleItemSystemAlertAction(for action: SongAction, entity: Entity, using item: MPMediaEntity, from vc: UIViewController, useAlternateTitle alternateTitle: Bool = false) -> UIAlertAction {
        
        let details = singleItemActionDetails(for: action, entity: entity, using: item, from: vc, useAlternateTitle: alternateTitle)
        
        return UIAlertAction.init(title: details.title, style: details.style, handler: { _ in details.handler() })
    }
    
    func singleItemAlertAction(for action: SongAction, entity: Entity, using item: MPMediaEntity, from vc: UIViewController, useAlternateTitle alternateTitle: Bool = false) -> AlertAction {
        
        let details = singleItemActionDetails(for: action, entity: entity, using: item, from: vc, useAlternateTitle: alternateTitle)
        
        return AlertAction.init(title: details.title, style: details.style, requiresDismissalFirst: action.requiresDismissalFirst, handler: details.handler)
    }
    
    func singleItemActionDetails(for action: SongAction, entity: Entity, using item: MPMediaEntity, from vc: UIViewController, useAlternateTitle alternateTitle: Bool = false) -> ActionDetails {
        
        switch action {
            
            case .collect:
                
                return (action: action, title: "Collect", style: .default, {
                    
                    guard let array: [MPMediaItem] = {
                        
                        if let song = item as? MPMediaItem {
                            
                            return [song]
                            
                        } else if let collection = item as? MPMediaItemCollection {
                            
                            return collection.items
                        }
                        
                        return nil
                        
                    }() else { return }
                
                    notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: array])
                    
                    if let container = vc as? FilterContainer & UIViewController {
                        
                        container.saveRecentSearch(withTitle: container.searchBar.text, resignFirstResponder: false)
                    }
                    
                    if vc.parent is PresentedContainerViewController || vc is NowPlayingViewController {
                        
                        if let parent = vc.parent as? PresentedContainerViewController, parent.context == .filter {
                            
                            return
                        }
                        
                        useAlternateAnimation = true
                        shouldReturnToContainer = true
                        (vc.parent ?? vc).performSegue(withIdentifier: "unwind", sender: nil)
                    }
                    
//                    if let parent = vc.parent as? PresentedContainerViewController, parent.context != .filter {
//
//                        useAlternateAnimation = true
//                        shouldReturnToContainer = true
//                        parent.performSegue(withIdentifier: "unwind", sender: nil)
//                    }
                })
            
            case .addTo:
            
                return (action: action, title: "Add to Playlists...", style: .default, handler: {
                    
                    guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController, let array: [MPMediaItem] = {
                        
                        if let song = item as? MPMediaItem {
                            
                            return [song]
                            
                        } else if let collection = item as? MPMediaItemCollection {
                            
                            return collection.items
                        }
                        
                        return nil
                        
                    }() else { return }
                    
                    presentedVC.itemsToAdd = array
                    presentedVC.context = .playlists
                    presentedVC.fromQueue = false
                    presentedVC.playlistsVC.sectionOverride = .playlists
                    
                    vc.present(presentedVC, animated: true, completion: nil)
                    
                    if let container = vc as? FilterContainer & UIViewController {
                        
                        container.saveRecentSearch(withTitle: container.searchBar.text, resignFirstResponder: false)
                    }
                })
            
            case .newPlaylist:
            
                return (action: action, title: "Create Playlist...", style: .default, handler: {
                    
                    guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController, let array: [MPMediaItem] = {
                        
                        if let song = item as? MPMediaItem {
                            
                            return [song]
                            
                        } else if let collection = item as? MPMediaItemCollection {
                            
                            return collection.items
                        }
                        
                        return nil
                        
                    }() else { return }
                    
                    presentedVC.itemsToAdd = array
                    presentedVC.context = .newPlaylist
                    presentedVC.fromQueue = false
                    
                    vc.present(presentedVC, animated: true, completion: nil)
                    
                    if let container = vc as? FilterContainer & UIViewController {
                        
                        container.saveRecentSearch(withTitle: container.searchBar.text, resignFirstResponder: false)
                    }
                })
            
            case .remove:
            
                return (action: action, title: "Remove All", style: .destructive, handler: {
                    
                    guard let vc = vc as? NewPlaylistViewController, let parent = vc.parent as? PresentedContainerViewController else { return }
                    
                    if let _ = vc.manager {
                        
                        vc.manager?.queue = []
                        vc.tableView.reloadData()//deleteRows(at: vc.tableView.indexPathsForVisibleRows ?? [], with: .none)
                        
                        notifier.post(name: .endQueueModification, object: nil)
                        
                        parent.prepare(animated: true)
                        
                        if let presenter = parent.presentingViewController as? PresentedContainerViewController {
                            
                            presenter.prepare(animated: false)
                            presenter.queueVC.tableView.reloadData()
                        }
                        
                        if vc.tableView.isEditing { vc.toggleEditing(false) }
                        
                    } else {
                        
                        vc.playlistItems = []
                        parent.itemsToAdd = []
                        vc.tableView.reloadData()//deleteRows(at: vc.tableView.indexPathsForVisibleRows ?? [], with: .none)
                        
                        parent.prepare(animated: true)
                        
                        if vc.tableView.isEditing { vc.toggleEditing(false) }
                    }
                    
                    vc.updateHeaderView(with: 0, animated: true)
                })
            
            case .library:
            
                return (action: action, title: "Add to Library", style: .default, handler: {
                    
                    guard let item = item as? MPMediaItem else { return }
                    
                    if #available(iOS 10.3, *) {
                        
                        guard let addable = self as? EntityVerifiable, addable.verifyLibraryStatus(of: item, itemProperty: .song) == .absent else {
                
                            let banner = Banner.init(title: "This song is already in your library", subtitle: nil, image: nil, backgroundColor: .deepGreen, didTapBlock: nil)
                            banner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                            banner.show(duration: 0.5)
                
                            (self as? EntityVerifiable)?.updateAddButton(hidden: true, animated: true)
                            return
                        }

                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                        
                        UniversalMethods.add(item, completions: ({ [weak self, weak vc] in
                            
                            guard let weakSelf = self else { return }
                            
                            if let addable = weakSelf as? EntityVerifiable {
                                
                                addable.updateAddButton(hidden: true, animated: true)
                            }
                            
                            if vc is InfoViewController {
                                
                                vc?.dismiss(animated: true, completion: nil)
                            }
                        
                        }, {  }))
                        
                    } else {

                        UniversalMethods.addToLibrary(item, completions: (success: { [weak vc] in vc?.dismiss(animated: true, completion: nil) }, error: { }), sameSongAction: { [weak self] bool in
                            
                            guard let weakSelf = self, let addable = weakSelf as? EntityVerifiable else { return }
                            
                            addable.updateAddButton(hidden: bool, animated: true)
                        })
                    }
                    
                    if let container = vc as? FilterContainer & UIViewController {
                        
                        container.saveRecentSearch(withTitle: container.searchBar.text, resignFirstResponder: false)
                    }
                })
            
            case .queue(name: let name, query: let query):
            
                return (action: action, title: "Queue...", style: .default, {
                    
                    guard let kind: MPMusicPlayerController.QueueKind = {
                        
                        if let query = query {
                            
                            return .queries([query])
                            
                        } else if let song = item as? MPMediaItem {
                            
                            return .items([song])
                            
                        } else if let collection = item as? MPMediaItemCollection {
                            
                            return .items(collection.items)
                        }
                        
                        return nil
                        
                    }() else { return }
                    
                    var context: QueueInsertController.Context {
                        
                        if let container = vc as? FilterContainer & UIViewController {
                            
                            return .filterContainer(container)
                        }
                        
                        return .other
                    }
                    
                    Transitioner.shared.addToQueue(from: vc, kind: kind, context: context, title: name)
                })
            
            case .info(let context):
            
                return (action: action, title: "\(alternateTitle.inverted ? "Get " : "")Info", style: .default, {
                    
                    Transitioner.shared.showInfo(from: vc, with: context)
                    
                    if let container = vc as? FilterContainer & UIViewController {
                        
                        container.saveRecentSearch(withTitle: container.searchBar.text, resignFirstResponder: false)
                    }
                })
            
            case .show(title: let title, context: let context, canDisplayInLibrary: let canDisplay):
            
                return (action: action, title: useSystemAlerts ? "Show..." : "Go To...", style: .default, {
                    
                    guard let details: (entities: [Entity], albumArtOverride: Bool) = {
                        
                        if let container = vc as? TableViewContainer {
                            
                            return container.tableDelegate.goToDetails()
                        
                        } else if let detailer = vc as? Detailing {
                            
                            return detailer.goToDetails(basedOn: entity)
                        
                        } else if let filterVC = vc as? FilterViewController {
                            
                            return filterVC.tableContainer?.tableDelegate.goToDetails()
                        }
                        
                        return nil
                    
                    }(), let song: MPMediaItem = (item as? MPMediaItemCollection)?.items.first ?? item as? MPMediaItem, let verifiable = vc as? EntityVerifiable else { return }
                    
                    var actions = [AlertAction]()
                    var parameters = [ShowMenuParameters]()
                    
                    details.entities.filter({ verifiable.verifyLibraryStatus(of: song, itemProperty: $0, animated: false, updateButton: false) == .present }).enumerated().forEach({ index, verifiedEntity in
                        
                        let collection = verifiedEntity.collection(from: item)
                        parameters.append((collection, verifiedEntity))
                        
                        actions.append(
                            .init(info: .init(title: "\(entity == verifiedEntity ? "This " : "")" + verifiedEntity.title(albumArtistOverride: details.albumArtOverride).capitalized,
                                subtitle: item.title(for: verifiedEntity, basedOn: entity),
                                image: verifiedEntity.images.size22,
                                accessoryType: .button(type: .image(#imageLiteral(resourceName: "InfoNoBorder13")), bordered: true)),
                            
                            handler: { [weak vc, weak item] in
                                
                                if entity == .playlist {
                                    
                                    guard let playlist = item as? MPMediaPlaylist, let transitioner = vc as? PlaylistTransitionable else { return }
                                    
                                    transitioner.playlistQuery = MPMediaQuery.init(filterPredicates: [.for(.playlist, using: playlist)]).grouped(by: .playlist)
                                    
                                    verifiable.performUnwindSegue(with: .playlist, isEntityAvailable: true, title: "playlist", completion: {
                                        
                                        if let container = vc as? FilterContainer & UIViewController {
                                            
                                            container.saveRecentSearch(withTitle: container.searchBar.text, resignFirstResponder: false)
                                        }
                                    })
                                    
                                    return
                                }
                                
                                verifiable.performUnwindSegue(with: verifiedEntity, isEntityAvailable: true, title: verifiedEntity.title(albumArtistOverride: true), completion: {
                                    
                                    if let container = vc as? FilterContainer & UIViewController {
                                        
                                        container.saveRecentSearch(withTitle: container.searchBar.text, resignFirstResponder: false)
                                    }
                                })
                                
                            }, accessoryAction: { [weak item, weak self] _, presenter in
                                    
                                    guard let item = item, let collection = collection, let context = verifiedEntity.singleCollectionInfoContext(for: collection) else { return }
                                    
                                    presenter.dismiss(animated: true, completion: {
                                        
                                        self?.singleItemActionDetails(for: .info(context: context), entity: entity, using: item, from: vc, useAlternateTitle: alternateTitle).handler()
                                    })
                            
                            }, previewAction: { [weak item] source in
                                
                                guard let vc = entityStoryboard.instantiateViewController(withIdentifier: "entityItems") as? EntityItemsViewController, let item = item else { return nil }
                                
                                var highlightedAlbum: MPMediaItemCollection? {
                                    
                                    switch entity {
                                        
                                        case .album: return item as? MPMediaItemCollection
                                        
                                        case .song: return MPMediaQuery.init(filterPredicates: [.for(.album, using: song.albumPersistentID)]).grouped(by: .album).collections?.first
                                        
                                        default: return nil
                                    }
                                }
                                
                                return Transitioner
                                    .shared
                                    .transition(
                                        to: verifiedEntity,
                                        vc: vc,
                                        from: source,
                                        sender: MPMediaQuery.init(filterPredicates: [.for(entity == verifiedEntity ? entity : verifiedEntity, using: entity == verifiedEntity ? item.persistentID : verifiedEntity.persistentID(from: song))]).grouped(by: verifiedEntity.grouping).collections?.first,
                                        highlightedItem: entity == .song ? song : nil,
                                        highlightedAlbum: highlightedAlbum,
                                        preview: true,
                                        titleOverride: ((appDelegate.window?.rootViewController as? ContainerViewController)?.activeViewController?.topViewController as? Navigatable)?.preferredTitle
                                )
                        }))
                    })
                    
                    if useSystemAlerts {
                        
                        let details = self.singleItemActionDetails(for: .info(context: context), entity: entity, using: item, from: vc, useAlternateTitle: true)
                        
                        actions.insert(.init(title: details.title, handler: details.handler), at: 0)
                        
                        #warning("Add support for Show in Library using a UIAlertController or UIContextMenuInteraction")
//                        actions.append(.init(title: "Show in \(2.countText(for: entity, compilationOverride: song.isCompilation, capitalised: true))", handler: { verifiable.showInLibrary(entity: item, type: entity, unwinder: vc) }))
                    }
                    
                    vc.showAlert(
                        title: item.title(for: entity, basedOn: entity),
                        subtitle: useSystemAlerts ? "Show..." : "Go to...",
                        context: .show,
                        with: actions,
                        segmentDetails: (canDisplay ? [.init(title: "Show in \(2.countText(for: entity, compilationOverride: song.isCompilation, capitalised: true))")] : [], canDisplay ? [{ alertVC in verifiable.showInLibrary(entity: item, type: entity, unwinder: alertVC) }] : []),
                        rightAction: { [weak self] _, presenter in presenter.dismiss(animated: true, completion: { self?.singleItemActionDetails(for: .info(context: context), entity: entity, using: item, from: vc, useAlternateTitle: alternateTitle).handler() }) },
                        showMenuParameters: parameters
                    )
                })
            
            case .rate:
            
                return (action: action, title: "Rate...", style: .default, {
                    
                    guard let song = item as? MPMediaItem else { return }
                    
                    let actions = Array(0...5).map({ value in
                        
                        AlertAction.init(title: value == 0 ? "Unrated" : "\(value) stars", style: .default, handler: {
                            
                            song.set(property: MPMediaItemPropertyRating, to: value)
                            
                            if songSecondaryDetails?.contains(.rating) == true {
                                
                                notifier.post(name: .ratingChanged, object: nil, userInfo: [String.id: song.persistentID])
                            }
                        })
                    })
                    
                    vc.showAlert(title: song.validTitle, subtitle: "Rate...", with: actions)
                })
            
            case .likedState:
            
                return (action: action, title: "Like...", style: .default, {
                    
                    guard let settable = item as? Settable else { return }
                    
                    let actions = [.none, LikedState.liked, .disliked].map({ value -> AlertAction in
                        
                        var title: String {
                            
                            switch value {
                                
                                case .liked: return "Liked"
                                
                                case .none: return "Neutral"
                                
                                case .disliked: return "Disliked"
                            }
                        }
                        
                        return AlertAction.init(title: title, style: .default, handler: {
                            
                            settable.set(property: item is MPMediaItem || item is MPMediaPlaylist ? .likedState : .albumLikedState, to: NSNumber.init(value: value.rawValue))
                            
                            if songSecondaryDetails?.contains(.loved) == true {
                                
                                notifier.post(name: .likedStateChanged, object: nil, userInfo: [String.id: item.persistentID])
                            }
                        })
                    })
                })
            
            case .reveal(indexPath: let indexPath):
            
                return (action: action, title: "Reveal", style: .default, {
                    
                    guard let container = vc as? FilterContaining & FilterContextDiscoverable else { return }
                    
                    container.filterContainer?.saveRecentSearch(withTitle: container.filterContainer?.searchBar?.text, resignFirstResponder: false)
                    _ = container.filterContainer?.searchBar.resignFirstResponder
                    container.filterContainer?.dismiss(animated: true, completion: nil)
                    container.revealEntity(indexPath)
                })
            
            case .insert(items: let items, completions: let completions):
            
                return (action: action, title: "Insert", style: .default, {
                    
                    guard let playlist = item as? MPMediaPlaylist, playlist.isAppleMusic.inverted, items.isEmpty.inverted else { return }
                    
                    playlist.add(items, completionHandler: { error in
                        
                        guard error == nil else {
                            
                            UniversalMethods.performInMain {
                                
                                UniversalMethods.banner(withTitle: "Unable to add \(items.count.fullCountText(for: .song))", subtitle: nil, image: nil, backgroundColor: .red, titleFont: .myriadPro(ofWeight: .light, size: 20), didTapBlock: nil).show(duration: .bannerInterval)
                                
                                completions?.error()
                            }
                            
                            return
                        }
                        
                        UniversalMethods.performInMain {
                            
                            UniversalMethods.banner(withTitle: "\(playlist.name ??? "Untitled Playlist")", subtitle: "Added \(items.count.fullCountText(for: .song))", image: nil, backgroundColor: .deepGreen, titleFont: .myriadPro(ofWeight: .light, size: 25), subtitleFont: .myriadPro(ofWeight: .light, size: 20), didTapBlock: nil).show(duration: .bannerInterval)
                            
                            notifier.post(name: .songsAddedToPlaylists, object: nil, userInfo: [String.addedPlaylists: [playlist.persistentID], String.addedSongs: items])
                            completions?.success()
                        }
                    })
                })
            
            case .play(title: let title, completion: let completion):
            
                return (action: action, title: "Play", style: .default, {
                    
                    guard let items = [item] as? [MPMediaItem] ?? (item as? MPMediaItemCollection)?.items else { return }
                    
                    musicPlayer.play(items, startingFrom: items.first, from: vc, withTitle: title, alertTitle: "Play", completion: completion)
                })
            
            case .shuffle(mode: let mode, title: let title, completion: let completion):
            
                return (action: action, title: .shuffle(alternateTitle ? .none : mode), style: .default, {
                    
                    guard let items = (item as? MPMediaItemCollection)?.items else { return }
                    
                    musicPlayer.play(mode == .albums ? items.albumsShuffled : items, startingFrom: nil, shuffleMode: mode == .songs ? .songs : .off, from: vc, withTitle: title, alertTitle: .shuffle(mode), completion: completion)
                })
        }
    }
}

protocol CollectionActionable: SingleItemActionable {
    
    var collectionKind: CollectionsKind { get }
    var collectionsCount: Int { get }
    var actionableActivityIndicator: MELActivityIndicatorView { get }
    var shouldFillActionableSongs: Bool { get set }
    var showActionsAfterFilling: Bool { get set }
    var actionableOperation: BlockOperation? { get set }
    var actionableQueue: OperationQueue { get }
    func getActionableSongs()
}
