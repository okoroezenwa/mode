//
//  QueueItemsViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 12/08/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class CollectorViewController: UIViewController, InfoLoading, BackgroundHideable, EntityContainer, Peekable, SingleItemActionable, AlbumTransitionable, ArtistTransitionable, AlbumArtistTransitionable, GenreTransitionable, ComposerTransitionable, EntityVerifiable, BorderButtonContaining, Detailing {
    
    @IBOutlet var tableView: MELTableView!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var actionsView: UIView!
    @IBOutlet var actionsButton: MELButton! {
        
        didSet {
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(showSettings(with:)))
            gr.minimumPressDuration = longPressDuration
            actionsButton.addGestureRecognizer(gr)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        }
    }
    @IBOutlet var stackView: UIStackView! {
        
        didSet {
            
//            let lockView = BorderedButtonView.with(title: "Lock", image: #imageLiteral(resourceName: "Locked13"), action: /*#selector(addSongs)*/nil, target: self)
//            lockButton = lockView.button
//            self.lockView = lockView
            
            let clearView = BorderedButtonView.with(title: "Clear...", image: #imageLiteral(resourceName: "Discard"), tapAction: .init(action: #selector(clear), target: self))
            clearButton = clearView.button
            self.clearView = clearView
            
            let editView = BorderedButtonView.with(title: .inactiveEditButtonTitle, image: .inactiveEditImage, tapAction: .init(action: #selector(SongActionManager.toggleEditing(_:)), target: songManager))
            editButton = editView.button
            self.editView = editView
            
            for view in [/*lockView, */clearView, editView] {
                
//                view.button.contentEdgeInsets.top = 10
//                view.button.contentEdgeInsets.bottom = 0
                view.borderViewBottomConstraint.constant = 2
                view.borderViewTopConstraint.constant = 10
                stackView.addArrangedSubview(view)
            }
        }
    }
    @IBOutlet var addToButton: MELButton!
    @IBOutlet var upNextButton: MELButton!
    @IBOutlet var playButton: MELButton!
    @IBOutlet var shuffleButton: MELButton!
    
//    @objc var lockButton: MELButton!
    @objc var clearButton: MELButton!
    @objc var editButton: MELButton!
//    @objc var lockView: BorderedButtonView!
    @objc var clearView: BorderedButtonView!
    @objc var editView: BorderedButtonView!
    
    var borderedButtons = [BorderedButtonView?]()
    
    var manager: QueueManager!
    @objc lazy var itemsToAdd = [MPMediaItem]()
    
    @objc var peeker: UIViewController?
    var oldArtwork: UIImage?
    
    lazy var songManager: SongActionManager = { SongActionManager.init(actionable: self) }()
    var actionableSongs: [MPMediaItem] { return manager.queue }
    let applicableActions = [SongAction.newPlaylist, .addTo]
    
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
        
        let swipeRight = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeRight.direction = .right
        tableView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeLeft.direction = .left
        tableView.addGestureRecognizer(swipeLeft)
        
        updateUpNextButton()
        updateShuffleButton()
        updateHeaderView()
        
        notifier.addObserver(self, selector: #selector(updateUpNextButton), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer)
        notifier.addObserver(self, selector: #selector(updateForChangedItems), name: .managerItemsChanged, object: nil)
        notifier.addObserver(tableView as Any, selector: #selector(UITableView.reloadData), name: .lineHeightsCalculated, object: nil)
        [Notification.Name.entityCountVisibilityChanged, .showExplicitnessChanged].forEach({ notifier.addObserver(self, selector: #selector(updateEntityCountVisibility), name: $0, object: nil) })
    }
    
    @objc func updateEntityCountVisibility() {
        
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        
        tableView.reloadRows(at: indexPaths, with: .none)
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
        
        toggleEditing(false)
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
        
        updateShuffleButton()
        tableView.reloadData()
    }
    
    @objc func updateShuffleButton() {
        
        shuffleButton.lightOverride = manager.queue.count < 2
        shuffleButton.isUserInteractionEnabled = manager.queue.count > 1
    }
    
    @objc func updateUpNextButton() {
        
        if peeker != nil {
        
            oldArtwork = ArtworkManager.shared.activeContainer?.modifier?.artworkType.image
        }
        
        upNextButton.lightOverride = musicPlayer.nowPlayingItem == nil
        upNextButton.isUserInteractionEnabled = musicPlayer.nowPlayingItem != nil
        
        for cell in tableView.visibleCells {
            
            guard let cell = cell as? SongTableViewCell, let indexPath = tableView.indexPath(for: cell) else { continue }
            
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
    
    @IBAction func showAddActions() {
        
        let actions = applicableActions.map({ alertAction(for: $0, from: self, using: manager.queue) }) + [.cancel()]
        
        present(UIAlertController.withTitle(nil, message: "Add To...", style: .actionSheet, actions: actions), animated: true, completion: nil)
    }
    
    @IBAction func showPlayShuffleActions(_ sender: Any) {
        
        if (sender as? UIButton) == playButton {
            
            musicPlayer.play(manager.queue, startingFrom: nil, from: self, withTitle: nil, alertTitle: "Play", completion: { notifier.post(name: .endQueueModification, object: nil) })
        
        } else if (sender as? UIButton) == shuffleButton {
            
            let canShuffleAlbums = manager.queue.canShuffleAlbums
            
            if canShuffleAlbums {
                
                let shuffleSongs = UIAlertAction.init(title: .shuffle(.songs), style: .default, handler: { [weak self] _ in
                    
                    guard let weakSelf = self else { return }
                    
                    musicPlayer.play(weakSelf.manager.queue.shuffled(), startingFrom: nil, from: weakSelf, withTitle: nil, alertTitle: .shuffle(.songs), completion: { notifier.post(name: .endQueueModification, object: nil) })
                })
                
                let shuffleAlbums = UIAlertAction.init(title: .shuffle(.albums), style: .default, handler: { [weak self] _ in
                    
                    guard let weakSelf = self else { return }
                    
                    musicPlayer.play(weakSelf.manager.queue.albumsShuffled, startingFrom: nil, from: weakSelf, withTitle: nil, alertTitle: .shuffle(.albums), completion: { notifier.post(name: .endQueueModification, object: nil) })
                })
                
                present(UIAlertController.withTitle(nil, message: "Collected Songs", style: .actionSheet, actions: shuffleSongs, shuffleAlbums, .cancel()), animated: true, completion: nil)
                
            } else {
                
                musicPlayer.play(manager.queue.shuffled(), startingFrom: nil, from: self, withTitle: nil, alertTitle: .shuffle(), completion: { notifier.post(name: .endQueueModification, object: nil) })
            }
        
        } else if (sender as? UIButton) == upNextButton {
            
            Transitioner.shared.addToQueue(from: self, kind: .items(manager.queue), context: .collector(manager: manager), index: (parent as? PresentedContainerViewController)?.index ?? -1)
        }
    }
    
    @objc func updateHeaderView() {
        
//        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
//
//            ([self.editView, self.clearView] as [UIView]).forEach({
//
//                if $0.isHidden && count == 0 { } else {
//
//                    $0.isHidden = count == 0
//                    $0.alpha = count == 0 ? 0 : 1
//                }
//            })
//        })
//
//        var array = [lockView, clearView, editView]
//
//        if count == 0 {
//
//            array.removeLast(2)
//        }
        
        borderedButtons = [/*lockView, */clearView, editView]//array
        
        updateButtons()
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

        var array = [UIAlertAction]()

        let clearAll = UIAlertAction.init(title: "All", style: .destructive, handler: { _ in notifier.post(name: .endQueueModification, object: nil) })
        
        array.append(clearAll)

        if let indexPaths = tableView.indexPathsForSelectedRows, !indexPaths.isEmpty {

            let clear = UIAlertAction.init(title: "Selected", style: .destructive, handler: { [weak self] _ in

                guard let weakSelf = self else { return }

                weakSelf/*.updateItems(at: indexPaths, for: .remove)*/.removeSelected()
            })

            array.append(clear)

            if indexPaths.count < manager.queue.count {

                let keep = UIAlertAction.init(title: "Unselected", style: .destructive, handler: { [weak self] _ in

                    guard let weakSelf = self else { return }

                    weakSelf/*.updateItems(at: indexPaths, for: .keep)*/.retainSelected()
                })

                array.append(keep)
            }
        }

        present(UIAlertController.withTitle("Clear...", message: nil, style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
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
    
    func goToDetails(basedOn entity: Entity) -> (entities: [Entity], albumArtOverride: Bool) {
        
        return ([Entity.artist, .genre, .album, .composer, .albumArtist], true)
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
                presentedVC.context = .upNext
            
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
            cell.swipeDelegate = self
            cell.playButton.isUserInteractionEnabled = false
            cell.prepare(with: song, songNumber: songCountVisible.inverted ? nil : indexPath.row + 1)
            updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: tableView)
            
            for category in [SecondaryCategory.loved, .plays, .rating, .lastPlayed, .dateAdded, .genre, .year, .fileSize] {
                
                update(category: category, using: song, in: cell, at: indexPath, reusableView: tableView)
            }
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
        
        if let song = manager?.queue[sourceIndexPath.row] {
            
            manager?.queue.remove(at: sourceIndexPath.row)
            manager?.queue.insert(song, at: destinationIndexPath.row)
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
}

//extension CollectorViewController: SongCellButtonDelegate {
//    
//    @objc func showOptionsForSong(in cell: SongTableViewCell) {
//        
//        guard let indexPath = tableView.indexPath(for: cell) else { return }
//        
//        let song = manager.queue[indexPath.row]
//        Transitioner.shared.showInfo(from: self, with: .song(location: .list, at: 0, within: [song]))
//    }
//}

extension CollectorViewController: EntityCellDelegate {
    
    func editButtonTapped(in cell: SongTableViewCell) {
        
        
    }
    
    func artworkTapped(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        cell.setHighlighted(true, animated: true)
        self.tableView(tableView, didSelectRowAt: indexPath)
        cell.setHighlighted(false, animated: true)
    }
    
    func accessoryButtonTapped(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        let item = manager.queue[indexPath.row]
        
        var actions = [SongAction.queue(name: cell.nameLabel.text, query: nil), .newPlaylist, .addTo].map({ singleItemAlertAction(for: $0, entity: .song, using: item, from: self) })
        
        if item.existsInLibrary.inverted {
            
            actions.insert(singleItemAlertAction(for: .library, entity: .song, using: item, from: self), at: 1)
        }
        
//        actions.insert(.init(title: "Get Info", style: .default, handler: { [weak self] _ in
//
//            guard let weakSelf = self else { return }
//
//            Transitioner.shared.showInfo(from: weakSelf, with: .song(location: .list, at: indexPath.row, within: weakSelf.manager.queue))
//
//        }), at: 0)
        
        present(UIAlertController.withTitle(nil, message: cell.nameLabel.text, style: .actionSheet, actions: actions + [.cancel()] ), animated: true, completion: nil)
    }
    
    func scrollViewTapped(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        if tableView.isEditing {
            
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            
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
