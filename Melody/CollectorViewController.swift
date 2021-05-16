//
//  QueueItemsViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 12/08/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class CollectorViewController: UIViewController, InfoLoading, BackgroundHideable, EntityContainer, Peekable, SingleItemActionable, AlbumTransitionable, ArtistTransitionable, AlbumArtistTransitionable, GenreTransitionable, ComposerTransitionable, EntityVerifiable, Detailing {
    
    @IBOutlet var tableView: MELTableView!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var editButton: MELButton!
    @IBOutlet var itemActionsButton: MELButton! {
        
        didSet {
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(showActions))
            gr.minimumPressDuration = longPressDuration
            itemActionsButton.addGestureRecognizer(gr)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        }
    }
    @IBOutlet var actionsButton: MELButton! {

        didSet {

            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(showSettings(with:)))
            gr.minimumPressDuration = longPressDuration
            actionsButton.addGestureRecognizer(gr)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        }
    }
    
    var manager: QueueManager!
    @objc lazy var itemsToAdd = [MPMediaItem]()
    
    @objc var peeker: UIViewController?
    var oldArtwork: UIImage?
    
    var preferredEditingStyle = EditingStyle.select
    
    lazy var songManager: SongActionManager = { SongActionManager.init(actionable: self) }()
    var actionableSongs: [MPMediaItem] { return manager.queue }
    var applicableActions: [SongAction] {
        
        var array = [SongAction.newPlaylist,
                     .addTo,
                     .info(context: .song(location: .list, at: 0, within: manager.queue)),
        ]
        
        if manager.queue.count > 1 {
            
            array.append(.shuffle(mode: .songs, title: "Collected Songs", completion: { notifier.post(name: .endQueueModification, object: nil) }))
            
            if manager.queue.canShuffleAlbums {
                
                array.append(.shuffle(mode: .albums, title: "Collected Songs", completion: { notifier.post(name: .endQueueModification, object: nil) }))
            }
        }
        
        if musicPlayer.nowPlayingItem != nil {
            
            array.append(contentsOf: [
                
                .queue(type: .all, name: "Collected Songs", query: nil),
                .queue(type: .playNext, name: "Collected Songs", query: nil),
                .queue(type: .playLater, name: "Collected Songs", query: nil)
            ])
        }
        
        return array
    }
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var albumQuery: MPMediaQuery?
    @objc var composerQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    
    @objc var operations = ImageOperations()
    @objc var infoOperations = InfoOperations()
    @objc let infoCache: InfoCache = {
        
        let cache = InfoCache()
        cache.name = "Info Cache"
        cache.countLimit = 2500
        
        return cache
    }()
    @objc let imageOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Image Operation Queue"
        
        return queue
    }()
    @objc let imageCache: ImageCache = {
        
        let cache = ImageCache()
        cache.name = "Image Cache"
        cache.countLimit = 500
        
        return cache
    }()
    @objc lazy var temporaryImageView: UIImageView = {
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    @objc lazy var temporaryEffectView: MELVisualEffectView = {
        
        let view = MELVisualEffectView()
        view.alphaOverride = 0.4
        
        return view
    }()
    
    @objc var showTemporaryImage: Bool = false

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let _ = peeker, let container = appDelegate.window?.rootViewController as? ContainerViewController {
            
            ArtworkManager.shared.currentlyPeeking = self
            
//            oldArtwork = container.imageView.image
            temporaryImageView.image = container.imageView.image
        }

        tableView.tableFooterView = UIView.init(frame: .zero)
        
        let inset = 56 as CGFloat
        tableView.contentInset.bottom = inset
        
        if #available(iOS 13, *) {

            tableView.verticalScrollIndicatorInsets.bottom = inset

        } else {

            tableView.scrollIndicatorInsets.bottom = inset
        }
        
        editButton.addTarget(songManager, action: #selector(SongActionManager.toggleEditing(_:)), for: .touchUpInside)
        itemActionsButton.addTarget(self, action: #selector(showActions), for: .touchUpInside)
        
        let swipeRight = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeRight.direction = .right
        tableView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeLeft.direction = .left
        tableView.addGestureRecognizer(swipeLeft)
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(performHold(_:)))
        hold.minimumPressDuration = longPressDuration
        hold.delegate = self
        tableView.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        
        updatePlayingIndicators()
        
        [Notification.Name.playerChanged, .MPMusicPlayerControllerNowPlayingItemDidChange].forEach({ notifier.addObserver(self, selector: #selector(updatePlayingIndicators), name: $0, object: /*musicPlayer*/nil) })
        notifier.addObserver(self, selector: #selector(updateForChangedItems), name: .managerItemsChanged, object: nil)
        notifier.addObserver(tableView as Any, selector: #selector(UITableView.reloadData), name: .lineHeightsCalculated, object: nil)
        [Notification.Name.entityCountVisibilityChanged, .showExplicitnessChanged].forEach({ notifier.addObserver(self, selector: #selector(updateEntityCountVisibility), name: $0, object: nil) })
        
        if animateWithPresentation {
        
            bottomView.transform = .init(translationX: 0, y: inset)
        }
    }
    
    @objc func updateEntityCountVisibility() {
        
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        
        tableView.reloadRows(at: indexPaths, with: .none)
    }
    
    @objc func showActions(_ sender: Any) {
        
        let block: () -> Void = { [weak self] in
            
            guard let self = self else { return }
        
            let actions = self.applicableActions.map({ self.alertAction(for: $0, from: self, using: self.manager.queue) })
            
            let leftAction: AccessoryButtonAction = { _, vc in vc.dismiss(animated: true, completion: { [weak self] in
                
                guard let self = self else { return }
                                                            
                self.actionDetails(for: .play(title: "Collected Songs", completion: { notifier.post(name: .endQueueModification, object: nil) }), from: self, using: self.actionableSongs, useAlternateTitle: false).handler()
                })
            }
            
            let rightAction: AccessoryButtonAction = { [weak self] _, vc in
                
                guard let self = self else { return }
                
                vc.dismiss(animated: true, completion: { self.clear() })
            }
            
            self.showAlert(title: "Collected Songs", subtitle: self.manager.queue.count.fullCountText(for: .song), with: actions, leftAction: leftAction, rightAction: rightAction, images: (#imageLiteral(resourceName: "PlayFilled12"), #imageLiteral(resourceName: "Discard15")), configurationActions: { vc in vc.leftButton.contentEdgeInsets = .init(top: 0, left: 2, bottom: 1, right: 0) })
        }
        
        if let gr = sender as? UILongPressGestureRecognizer {
            
            gr.recogniseContinuously(with: block, and: nil)
            
        } else {
            
            block()
        }
    }
    
    @objc func performHold(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
            
            case .began:
            
                guard let indexPath = tableView.indexPathForRow(at: sender.location(in: tableView)), let cell = tableView.cellForRow(at: indexPath) as? EntityTableViewCell, let item = manager?.queue[indexPath.row] else { return }
                
                let location = sender.location(in: cell)
                
                if cell.editingView.frame.contains(location) {
                    
                    Transitioner.shared.performDeepSelection(from: self, title: cell.nameLabel.text)
                    
                } else if cell.mainView.convert(cell.infoButton.frame, to: cell).contains(location) {
                    
                    singleItemActionDetails(for: .show(title: cell.nameLabel.text, context: .song(location: .list, at: indexPath.row, within: manager.queue), canDisplayInLibrary: true), entityType: .song, using: item, from: self, useAlternateTitle: true).handler()
                
                } else {
                    
                    var actions = [SongAction.queue(type: .all, name: cell.nameLabel.text, query: nil), .queue(type: .playNext, name: cell.nameLabel.text, query: nil), .queue(type: .playLater, name: cell.nameLabel.text, query: nil), .newPlaylist, .addTo, .show(title: cell.nameLabel.text, context: .song(location: .list, at: indexPath.row, within: manager.queue), canDisplayInLibrary: true), .remove(indexPath)/*, .search(unwinder: { [weak self] in self?.parent })*/].map({ singleItemAlertAction(for: $0, entityType: .song, using: item, from: self) })
                    
                    if item.canBeAddedToLibrary {
                        
                        actions.append(singleItemAlertAction(for: .library, entityType: .song, using: item, from: self))
                    }
                    
                    actions.append(.init(title: "Get Info", style: .default, image: SongAction.info(context: .album(at: 0, within: [])).icon22, requiresDismissalFirst: true, handler: { [weak self] in

                        guard let weakSelf = self else { return }

                        Transitioner.shared.showInfo(from: weakSelf, with: .song(location: .list, at: indexPath.row, within: weakSelf.manager.queue))

                    }))
                                        
                    showAlert(title: cell.nameLabel.text, with: actions)
                }
            
            case .changed, .ended:
            
                guard let top = topViewController as? VerticalPresentationContainerViewController else { return }
            
                top.gestureActivated(sender)
            
            default: break
        }
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        imageCache.removeAllObjects()
    }
    
    @objc func dismissVC() {
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleRightSwipe(_ sender: Any) {
        
        toggleEditing(true)
    }
    
    @objc func handleLeftSwipe(_ sender: Any) {
        
        if tableView.isEditing {
        
            toggleEditing(false)
            
        } else if let gr = sender as? UIGestureRecognizer, let indexPath = tableView.indexPathForRow(at: gr.location(in: tableView)), let cell = tableView.cellForRow(at: indexPath) as? EntityTableViewCell, let item = manager?.queue[indexPath.row] {
            
            singleItemActionDetails(for: .show(title: cell.nameLabel.text, context: .song(location: .list, at: indexPath.row, within: manager.queue), canDisplayInLibrary: true), entityType: .song, using: item, from: self, useAlternateTitle: true).handler()
        }
    }
    
    @objc func toggleEditing(_ editing: Bool) {
        
        if editing {
            
            if !tableView.isEditing {
                
                tableView.setEditing(true, animated: true)
            }
            
        } else {
            
            if tableView.isEditing {
                
                tableView.setEditing(false, animated: true)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)

        tableView.flashScrollIndicators()
    }
    
    @objc func updateForChangedItems() {
        tableView.reloadData()
    }
    
    @objc func updatePlayingIndicators() {
        
        if peeker != nil {
        
            oldArtwork = ArtworkManager.shared.activeContainer?.modifier?.artworkType.image
        }
        
        for cell in tableView.visibleCells {
            
            guard let cell = cell as? EntityTableViewCell, let indexPath = tableView.indexPath(for: cell) else { continue }
            
            if cell.playingView.isHidden.inverted && musicPlayer.nowPlayingItem != manager?.queue[indexPath.row] {
                
                cell.playingView.isHidden = true
                cell.indicator.state = .stopped
                
            } else if cell.playingView.isHidden && musicPlayer.nowPlayingItem == manager?.queue[indexPath.row] {
                
                cell.playingView.isHidden = false
                UniversalMethods.performOnMainThread({ cell.indicator.state = musicPlayer.isPlaying ? .playing : .paused }, afterDelay: 0.1)
            }
        }
    }
    
    @IBAction func showLibraryOptions() {
        
        let vc = popoverStoryboard.instantiateViewController(withIdentifier: "actionsVC")
        vc.modalPresentationStyle = .popover
        
        guard let actionsVC = Transitioner.shared.transition(to: vc, using: .init(fromVC: self, configuration: .collected), sourceView: actionsButton) else { return }
        
        show(actionsVC, sender: nil)
    }
    
    func updateItems(at indexPaths: [IndexPath], for action: SelectionAction) {
        
        guard let parent = parent as? PresentedContainerViewController else { return }
        
        let details: (indexPathsToRemove: [IndexPath], songsToRetain: [MPMediaItem]) = {
            
            switch action {
                
                case .keep: return (manager.queue.enumerated().filter({ Set(indexPaths.map({ $0.row })).contains($0.offset).inverted }).map({ IndexPath.init(row: $0.offset, section: 0) }), manager.queue.enumerated().filter({ indexPaths.map({ $0.row }).contains($0.offset) }).map({ $0.element }))
                
                case .remove: return (indexPaths, manager.queue.enumerated().filter({ indexPaths.map({ $0.row }).contains($0.offset).inverted }).map({ $0.element }))
            }
        }() // using var crashes things on .keep for some reason.
        
        manager.queue = details.songsToRetain
        notifier.post(name: .removedFromQueue, object: nil)
        
        if let presenter = parent.presentingViewController as? PresentedContainerViewController {
            
            presenter.prepare(animated: false)
            presenter.queueVC.tableView.reloadData()
        }
        
        if manager.queue.count == 0 {
            
            parent.dismiss(animated: true, completion: nil)
        }
        
        tableView.deleteRows(at: details.indexPathsToRemove, with: .none)
        parent.prepare(animated: true)
        songManager.toggleEditing(editButton as Any)
//        updateHeaderView(with: (manager?.queue ?? playlistItems).count, animated: true)
    }
    
    @objc func clear() {

        var array = [AlertAction]()

        let clearAll = AlertAction.init(info: .init(title: "All", accessoryType: .none), context: .alert(.destructive), handler: { notifier.post(name: .endQueueModification, object: nil) })
        
        array.append(clearAll)

        if let indexPaths = tableView.indexPathsForSelectedRows, !indexPaths.isEmpty {

            let clear = AlertAction.init(info: .init(title: "Selected", accessoryType: .none), context: .alert(.destructive), handler: { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf/*.updateItems(at: indexPaths, for: .remove)*/.removeSelected()
            })

            array.append(clear)

            if indexPaths.count < manager.queue.count {

                let keep = AlertAction.init(info: .init(title: "Unselected", accessoryType: .none), context: .alert(.destructive), handler: { [weak self] in
                    
                    guard let weakSelf = self else { return }
                    
                    weakSelf/*.updateItems(at: indexPaths, for: .remove)*/.retainSelected()
                })

                array.append(keep)
            }
        }
        
        showAlert(title: "Clear...", context: .other, with: array)
    }
    
    @IBAction func removeSelected() {

        if let indexPaths = tableView.indexPathsForSelectedRows, let array = manager?.queue.enumerated().filter({ !indexPaths.map({ $0.row }).contains($0.offset) }).map({ $0.element }) {

            manager?.queue = array
            tableView.deleteRows(at: indexPaths, with: .none)

            notifier.post(name: .removedFromQueue, object: nil)

            (parent as? PresentedContainerViewController)?.prepare(animated: true)

            if manager?.queue.count == 0, let parent = parent as? PresentedContainerViewController {

                parent.dismiss(animated: true, completion: nil)
            }

            songManager.toggleEditing(editButton as Any)
        }
    }

    @IBAction func retainSelected() {

        if let indexPaths = tableView.indexPathsForSelectedRows, let array = manager?.queue.enumerated().filter({ indexPaths.map({ $0.row }).contains($0.offset) }).map({ $0.element }) {

            let set = Set(indexPaths.map({ $0.row }))
            let rowsToDelete = (manager?.queue ?? []).enumerated().filter({ !set.contains($0.offset) }).map({ IndexPath.init(row: $0.offset, section: 0) })

            manager?.queue = array
            tableView.deleteRows(at: rowsToDelete, with: .none)//reloadData()

            (parent as? PresentedContainerViewController)?.prepare(animated: true)

            notifier.post(name: .removedFromQueue, object: nil)

            songManager.toggleEditing(editButton as Any)
        }
    }
    
    func removeDuplicates() {
        
        manager.queue.removeDuplicates()
        tableView.reloadData()
        (parent as? PresentedContainerViewController)?.prepare(animated: true, updateConstraintsAndButtons: false)
        
        notifier.post(name: .removedFromQueue, object: nil)
    }
    
    func goToDetails(basedOn entity: EntityType) -> (entities: [EntityType], albumArtOverride: Bool) {
        
        return ([EntityType.artist, .genre, .album, .composer, .albumArtist], true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier else { return }
        
        switch id {
            
            case "toPlaylists":
            
                guard let presentedVC = segue.destination as? PresentedContainerViewController else { return }
            
                presentedVC.manager = manager
                presentedVC.context = .playlists
                presentedVC.playlistsVC.sectionOverride = .playlists
            
            case "toQueue":
            
                guard let presentedVC = segue.destination as? PresentedContainerViewController else { return }
                
                presentedVC.manager = manager
                presentedVC.context = .playAfter
            
            default: break
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "CoVC going away...").show(for: 0.3)
        }
        
        if let _ = peeker, let container = appDelegate.window?.rootViewController as? ContainerViewController {
            
            ArtworkManager.shared.currentlyPeeking = nil
            
            UIView.transition(with: container.imageView, duration: 0.5, options: .transitionCrossDissolve, animations: { container.imageView.image = ArtworkManager.shared.activeContainer?.modifier?.artworkType.image/*self.oldArtwork*/ }, completion: nil)
        }
        
        notifier.removeObserver(self)
    }
}

extension CollectorViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return manager?.queue.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        operations[indexPath]?.cancel()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.songCell(for: indexPath)
        
        if let song = manager?.queue[indexPath.row] {

            cell.delegate = self
//            cell.swipeDelegate = self
            cell.preferredEditingStyle = preferredEditingStyle
            cell.playButton.isUserInteractionEnabled = false
            cell.prepare(with: song, songNumber: songCountVisible.inverted ? nil : indexPath.row + 1)
            updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: tableView)
            updateInfo(for: song, ofType: .song, in: cell, at: indexPath, within: tableView)
//            for category in [SecondaryCategory.loved, .plays, .rating, .lastPlayed, .dateAdded, .genre, .year, .fileSize] {
//
//                update(category: category, using: song, in: cell, at: indexPath, reusableView: tableView)
//            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return FontManager.shared.entityCellHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        guard sourceIndexPath != destinationIndexPath else { return }
        
        if let song = manager?.queue[sourceIndexPath.row] {
            
            manager?.queue.remove(at: sourceIndexPath.row)
            manager?.queue.insert(song, at: destinationIndexPath.row)
            
            if songCountVisible {

                tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        switch editingStyle {
            
            case .delete:
                
                manager?.queue.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .none)
                
                (parent as? PresentedContainerViewController)?.prepare(animated: true)
                
                notifier.post(name: .removedFromQueue, object: nil)
                
                if manager?.queue.count == 0, let parent = parent as? PresentedContainerViewController {
                    
                    parent.dismiss(animated: true, completion: nil)
                }
                
            default: break
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if !tableView.isEditing {
            
            guard let queue = manager?.queue else { return }
            
            musicPlayer.play(queue, startingFrom: queue[indexPath.row], shuffleMode: manager.shuffled ? .songs : .off, respectingPlaybackState: false, from: self, withTitle: "Collected Songs", alertTitle: manager.shuffled ? .shuffle() : "Play", completion: { notifier.post(name: .endQueueModification, object: nil) })
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        return false
    }
}

extension CollectorViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let _ = gestureRecognizer as? UILongPressGestureRecognizer {
            
            guard tableView.isEditing.inverted else { return false }
            
            return gestureRecognizer.location(in: parent?.view).x > 22
        }
        
        return true
    }
}
//extension CollectorViewController: SongCellButtonDelegate {
//    
//    @objc func showOptionsForSong(in cell: EntityTableViewCell) {
//        
//        guard let indexPath = tableView.indexPath(for: cell) else { return }
//        
//        let song = manager.queue[indexPath.row]
//        Transitioner.shared.showInfo(from: self, with: .song(location: .list, at: 0, within: [song]))
//    }
//}

extension CollectorViewController: EntityCellDelegate {
    
    func handleScrollSwipe(from gr: UIGestureRecognizer, direction: UISwipeGestureRecognizer.Direction) {
        
        switch direction {
            
            case .left: handleLeftSwipe(gr)
            
            case .right: handleRightSwipe(gr)
            
            default: break
        }
    }
    
    func editButtonHeld(in cell: EntityTableViewCell) {
        
        Transitioner.shared.performDeepSelection(from: self, title: cell.nameLabel.text)
    }
    
    func editButtonTapped(in cell: EntityTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        if cell.isSelected {
            
            tableView.deselectRow(at: indexPath, animated: false)
            
        } else {
            
            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    func artworkTapped(in cell: EntityTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        if tableView.isEditing.inverted {
        
            cell.setHighlighted(true, animated: true)
            self.tableView(tableView, didSelectRowAt: indexPath)
            cell.setHighlighted(false, animated: true)
        
        } else {
            
            if cell.isSelected {
                
                tableView.deselectRow(at: indexPath, animated: false)
                
            } else {
                
                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
    }
    
    func artworkHeld(in cell: EntityTableViewCell) {
        
        
    }
    
    func accessoryButtonTapped(in cell: EntityTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        let item = manager.queue[indexPath.row]
        
        var actions = [SongAction.queue(type: .all, name: cell.nameLabel.text, query: nil), .queue(type: .playNext, name: cell.nameLabel.text, query: nil), .queue(type: .playLater, name: cell.nameLabel.text, query: nil), .newPlaylist, .addTo, .show(title: cell.nameLabel.text, context: .song(location: .list, at: indexPath.row, within: manager.queue), canDisplayInLibrary: true), .remove(indexPath)/*, .search(unwinder: { [weak self] in self?.parent })*/].map({ singleItemAlertAction(for: $0, entityType: .song, using: item, from: self) })
        
        if item.canBeAddedToLibrary {
            
            actions.insert(singleItemAlertAction(for: .library, entityType: .song, using: item, from: self), at: 1)
        }
        
        actions.append(.init(title: "Get Info", style: .default, image: SongAction.info(context: .album(at: 0, within: [])).icon22, requiresDismissalFirst: false, handler: { [weak self] in

            guard let weakSelf = self else { return }

            Transitioner.shared.showInfo(from: weakSelf, with: .song(location: .list, at: indexPath.row, within: weakSelf.manager.queue))

        }))
        
        showAlert(title: cell.nameLabel.text, with: actions)
    }
    
    func accessoryButtonHeld(in cell: EntityTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell), let action = self.tableView(tableView, editActionsForRowAt: indexPath, for: .right)?.first else { return }
        
        action.handler?(action, indexPath)
    }
    
    func scrollViewTapped(in cell: EntityTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        if tableView.isEditing {
            
            if cell.isSelected {
                
                tableView.deselectRow(at: indexPath, animated: false)
                
            } else {
                
                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            
        } else {
            
            cell.setHighlighted(true, animated: true)
            self.tableView(self.tableView, didSelectRowAt: indexPath)
            cell.setHighlighted(false, animated: true)
        }
    }
}

extension CollectorViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        return TableDelegate.editActions(for: self, orientation: orientation, using: manager.queue[indexPath.row], at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        
        var options = SwipeTableOptions()
        options.transitionStyle = .drag
        options.expansionStyle = orientation == .right && isInDebugMode.inverted ? .destructive(automaticallyDelete: false) : .selection
        
        return options
    }
}
