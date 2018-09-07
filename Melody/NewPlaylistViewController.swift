//
//  NewPlaylistViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 15/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class NewPlaylistViewController: UIViewController, InfoLoading, EntityContainer, SingleItemActionable, BorderButtonContaining {

    @IBOutlet weak var tableView: MELTableView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var stackView: UIStackView! {
        
        didSet {
            
            let addView = BorderedButtonView.with(title: "Add", image: #imageLiteral(resourceName: "AddNoBorderSmall"), action: #selector(addSongs), target: self)
            addButton = addView.button
            self.addView = addView
            
            let clearView = BorderedButtonView.with(title: "Clear...", image: #imageLiteral(resourceName: "Discard"), action: #selector(clear), target: self)
            clearButton = clearView.button
            self.clearView = clearView
            
            let editView = BorderedButtonView.with(title: .inactiveEditButtonTitle, image: .inactiveEditImage, action: #selector(SongActionManager.toggleEditing(_:)), target: songManager)
            editButton = editView.button
            self.editView = editView
            
            for view in [addView, clearView, editView] {
                
                view.button.contentEdgeInsets.top = 10
                view.button.contentEdgeInsets.bottom = 0
                view.borderViewBottomConstraint.constant = 2
                view.borderViewTopConstraint.constant = 10
//                view.borderView.layer.cornerRadius = 8
                stackView.addArrangedSubview(view)
            }
        }
    }
    @IBOutlet weak var nameSearchBar: MELSearchBar!
    @IBOutlet weak var bottomViewBottomConstraint: NSLayoutConstraint!
    
    @objc var addButton: MELButton!
    @objc var clearButton: MELButton!
    @objc var editButton: MELButton!
    
    @objc var addView: BorderedButtonView!
    @objc var clearView: BorderedButtonView!
    @objc var editView: BorderedButtonView!
    
    var borderedButtons = [BorderedButtonView?]()
    
    @objc var actionableSongs: [MPMediaItem] { return manager?.queue ?? playlistItems }
    let applicableActions = [SongAction.remove]
    @objc lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
    // TODO:- Replace with protocol to modify main playlist (maybe also in playlistsVC)
    var manager: QueueManager?
    @objc lazy var playlistItems = [MPMediaItem]()
    @objc var fromQueue = false
    @objc var creatorText: String?
    @objc var descriptionText: String?
    var wasFirstResponder = false
    
    @objc var operations = [IndexPath: Operation]()
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
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.rowHeight = 72
        
        view.layoutIfNeeded()
        
        updateHeaderView(with: (manager?.queue ?? playlistItems).count, animated: false)
        
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let swipeRight = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeRight.direction = .right
        tableView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeLeft.direction = .left
        tableView.addGestureRecognizer(swipeLeft)
        
        notifier.addObserver(self, selector: #selector(updateEntityCountVisibility), name: .entityCountVisibilityChanged, object: nil)
        notifier.addObserver(self, selector: #selector(updateNowPlaying), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer)
        
        nameSearchBar.setImage(#imageLiteral(resourceName: "Playlists16"), for: .search, state: .normal)
        nameSearchBar.becomeFirstResponder()
        nameSearchBar.textField?.clearButtonMode = .whileEditing
        
        (parent as? PresentedContainerViewController)?.transitionStart = { [weak self] in
            
            guard let weakSelf = self, weakSelf.nameSearchBar.isFirstResponder else { return }
            
            weakSelf.bottomViewBottomConstraint.constant = 0
            weakSelf.wasFirstResponder = true
        }
        
        (parent as? PresentedContainerViewController)?.transitionAnimation = { [weak self] in
            
            guard let weakSelf = self, weakSelf.wasFirstResponder else { return }
            
            weakSelf.nameSearchBar.resignFirstResponder()
            weakSelf.view.layoutIfNeeded()
        }
        
        (parent as? PresentedContainerViewController)?.transitionCancellation = { [weak self] in
            
            guard let weakSelf = self, weakSelf.wasFirstResponder else { return }
            
            weakSelf.nameSearchBar.becomeFirstResponder()
            weakSelf.wasFirstResponder = false
        }
    }
    
    @objc func updateEntityCountVisibility() {
        
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        
        tableView.reloadRows(at: indexPaths, with: .none)
    }
    
    @objc func updateNowPlaying() {
        
        for cell in tableView.visibleCells {
            
            guard let cell = cell as? SongTableViewCell, let indexPath = tableView.indexPath(for: cell) else { continue }
            
            if cell.playingView.isHidden.inverted && musicPlayer.nowPlayingItem != (manager?.queue ?? playlistItems)[indexPath.row] {
                
                cell.playingView.isHidden = true
                cell.indicator.state = .stopped
                
            } else if cell.playingView.isHidden && musicPlayer.nowPlayingItem == (manager?.queue ?? playlistItems)[indexPath.row] {
                
                cell.playingView.isHidden = false
                UniversalMethods.performOnMainThread({ cell.indicator.state = musicPlayer.isPlaying ? .playing : .paused }, afterDelay: 0.1)
            }
        }
    }
    
    @objc func adjustKeyboard(with notification: Notification) {
        
        guard let keyboardHeightAtEnd = ((notification as NSNotification).userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height, nameSearchBar.isFirstResponder, let duration = (notification as NSNotification).userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        let keyboardWillShow = notification.name == UIResponder.keyboardWillShowNotification
        
        bottomViewBottomConstraint.constant = keyboardWillShow ? keyboardHeightAtEnd - 6 : 0
        
        UIView.animate(withDuration: duration, animations: { self.view.layoutIfNeeded() })
    }
    
    @objc func updateHeaderView(with count: Int, animated: Bool = true) {
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            
            ([self.editView, self.clearView] as [UIView]).forEach({
                
                if $0.isHidden && count == 0 { } else {
                    
                    $0.isHidden = count == 0
                    $0.alpha = count == 0 ? 0 : 1
                }
            })
        
        })
        
        var array = [addView, clearView, editView]
        
        if count == 0 {
            
            array.removeLast(2)
        }
        
        borderedButtons = array
        
        updateButtons()
    }
    
    @objc func handleRightSwipe(_ sender: Any) {
        
        guard !(manager?.queue ?? playlistItems).isEmpty else { return }
        
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
    
    @objc func createPlaylist() {
        
        guard nameSearchBar.text?.isEmpty == false else {
            
            let newBanner = Banner.init(title: "Your playlist must have a name", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
            newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
            newBanner.show(duration: 0.6)
            
            return
        }
        
        let creationMetadata = MPMediaPlaylistCreationMetadata.init(name: nameSearchBar.text!)
        creationMetadata.authorDisplayName = creatorText
        creationMetadata.descriptionText = descriptionText ?? ""
        
//        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        (parent as? PresentedContainerViewController)?.activityIndicator.startAnimating()
        (parent as? PresentedContainerViewController)?.rightButton.isHidden = true
        (parent as? PresentedContainerViewController)?.rightBorderView.isHidden = true
            
        musicLibrary.getPlaylist(with: UUID(), creationMetadata: creationMetadata, completionHandler: { [weak self] playlist, error in
            
            guard let weakSelf = self, let parent = weakSelf.parent as? PresentedContainerViewController else { return }
            
            if isInDebugMode {
                
                UniversalMethods.performInMain { UniversalMethods.banner(withTitle: "Is Editable: " ?+ (playlist?.value(forProperty: .isEditable) as? Bool)?.description).show(for: 1) }
            }
            
            UniversalMethods.performInMain {
                
                if error == nil {
                    
                    if (weakSelf.manager?.queue ?? weakSelf.playlistItems).isEmpty {
                        
                        let newBanner = Banner.init(title: "Playlist Created", subtitle: nil, image: nil, backgroundColor: .deepGreen, didTapBlock: nil)
                        newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                        newBanner.show(duration: 0.6)
                        
                        if weakSelf.fromQueue, let _ = weakSelf.manager {
                            
                            parent.rightButton.isHidden = false
                            parent.activityIndicator.stopAnimating()
//                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            notifier.post(name: .endQueueModification, object: nil)
                            
                        } else {
                            
                            parent.rightButton.isHidden = false
                            parent.rightBorderView.isHidden = false
                            parent.activityIndicator.stopAnimating()
//                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            parent.performSegue(withIdentifier: "unwind", sender: nil)
                        }
                        
                    } else {
                        
                        let array = weakSelf.manager?.queue ?? weakSelf.playlistItems
                        
                        UniversalMethods.performOnMainThread({
                        
                            playlist?.add(array, completionHandler: { error in
                                
                                if isInDebugMode {
                                    
                                    UniversalMethods.performInMain { UniversalMethods.banner(withTitle: "Is Editable: " ?+ (playlist?.value(forProperty: .isEditable) as? Bool)?.description).show(for: 1) }
                                }
                                
                                UniversalMethods.performInMain {
                                    
                                    if error == nil {
                                        
                                        let newBanner = Banner.init(title: "Playlist created with \(array.count) \(array.count == 1 ? "song" : "songs")", subtitle: nil, image: nil, backgroundColor: .deepGreen, didTapBlock: nil)
                                        newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                                        newBanner.show(duration: 0.5)
                                        
                                        notifier.post(name: .songsAddedToPlaylists, object: nil, userInfo: [String.addedPlaylists: [playlist?.persistentID ?? 0], String.addedSongs: array])
                                        
                                        if weakSelf.fromQueue, let _ = weakSelf.manager {
                                            
                                            parent.rightButton.isHidden = false
                                            parent.rightBorderView.isHidden = false
                                            parent.activityIndicator.stopAnimating()
//                                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                            notifier.post(name: .endQueueModification, object: nil)
                                            
                                        } else {
                                            
                                            parent.rightButton.isHidden = false
                                            parent.rightBorderView.isHidden = false
                                            parent.activityIndicator.stopAnimating()
//                                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                            parent.performSegue(withIdentifier: "unwind", sender: nil)
                                        }
                                        
                                    } else {
                                        
                                        let newBanner = Banner.init(title: "Unable to add \(array.count) \(array.count == 1 ? "song" : "songs") to created playlist", subtitle: nil, image: nil, backgroundColor: .orange, didTapBlock: nil)
                                        newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                                        newBanner.show(duration: 1)
                                        
                                        if weakSelf.fromQueue {
                                            
                                            parent.rightButton.isHidden = false
                                            parent.rightBorderView.isHidden = false
                                            parent.activityIndicator.stopAnimating()
//                                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                            notifier.post(name: .endQueueModification, object: nil)
                                            
                                        } else {
                                            
                                            parent.rightButton.isHidden = false
                                            parent.rightBorderView.isHidden = false
                                            parent.activityIndicator.stopAnimating()
//                                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                            parent.performSegue(withIdentifier: "unwind", sender: nil)
                                        }
                                    }
                                }
                            })
                            
                        }, afterDelay: 0.5)
                    }
                    
                } else {
                    
                    let newBanner = Banner.init(title: "Unable to create playlist", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
                    newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                    newBanner.show(duration: 0.6)
                    
                    parent.rightButton.isHidden = false
                    parent.rightBorderView.isHidden = false
                    parent.activityIndicator.stopAnimating()
//                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
    }
    
    func updateItems(at indexPaths: [IndexPath], for action: SelectionAction) {
        
        guard let parent = parent as? PresentedContainerViewController else { return }
        
        let details: (indexPathsToRemove: [IndexPath], songsToRetain: [MPMediaItem]) = {
            
            switch action {
                
                case .keep: return ((manager?.queue ?? playlistItems).enumerated().filter({ Set(indexPaths.map({ $0.row })).contains($0.offset).inverted }).map({ IndexPath.init(row: $0.offset, section: 0) }), (manager?.queue ?? playlistItems).enumerated().filter({ indexPaths.map({ $0.row }).contains($0.offset) }).map({ $0.element }))
                
                case .remove: return (indexPaths, (manager?.queue ?? playlistItems).enumerated().filter({ indexPaths.map({ $0.row }).contains($0.offset).inverted }).map({ $0.element }))
            }
        }() // using var crashes things on .keep for some reason.
        
        if let manager = manager {
            
            manager.queue = details.songsToRetain
            notifier.post(name: .removedFromQueue, object: nil)
            
            if let presenter = parent.presentingViewController as? PresentedContainerViewController {
                
                presenter.prepare(animated: false)
                presenter.queueVC.tableView.reloadData()
            }
            
            if manager.queue.count == 0 {
                
                parent.dismiss(animated: true, completion: nil)
            }
            
        } else {
            
            playlistItems = details.songsToRetain
            parent.itemsToAdd = details.songsToRetain
        }
        
        tableView.deleteRows(at: details.indexPathsToRemove, with: .none)
        UniversalMethods.performOnMainThread({ self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRows ?? [], with: .none) }, afterDelay: 0.3)
        parent.prepare(animated: true)
        updateHeaderView(with: (manager?.queue ?? playlistItems).count, animated: true)
    }
    
    @objc func clear() {
        
        var array = [UIAlertAction]()
        
        let clearAll = alertAction(for: .remove, from: self, using: manager?.queue ?? playlistItems)
        array.append(clearAll)
        
        if let indexPaths = tableView.indexPathsForSelectedRows, !indexPaths.isEmpty {
            
            let clear = UIAlertAction.init(title: "Selected", style: .destructive, handler: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                weakSelf.updateItems(at: indexPaths, for: .remove)
            })
            
            array.append(clear)
            
            if indexPaths.count < (manager?.queue ?? playlistItems).count {
                
                let keep = UIAlertAction.init(title: "Unselected", style: .destructive, handler: { [weak self] _ in
                    
                    guard let weakSelf = self else { return }
                    
                    weakSelf.updateItems(at: indexPaths, for: .keep)
                })
                
                array.append(keep)
            }
        }
        
        present(UIAlertController.withTitle("Clear...", message: nil, style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
    }
    
    @IBAction func addSongs() {
        
        let picker = MPMediaPickerController.init(mediaTypes: .music)
        picker.allowsPickingMultipleItems = true
        picker.delegate = self
        picker.modalPresentationStyle = .overFullScreen
        
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func enterName(_ sender: AnyObject) {
        
        nameSearchBar.becomeFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toDetails", let presentedVC = segue.destination as? PresentedContainerViewController {
            
            if nameSearchBar.isFirstResponder {
                
                nameSearchBar.resignFirstResponder()
                wasFirstResponder = true
            }
            
            presentedVC.newVC = self
            presentedVC.context = .playlistDetails
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "NPVC going away...").show(for: 0.3)
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        notifier.removeObserver(self)
    }
}

extension NewPlaylistViewController: MPMediaPickerControllerDelegate {
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        if let manager = manager, let parent = parent as? PresentedContainerViewController {
            
            notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: mediaItemCollection.items])
            
            parent.prepare(animated: true)
            
            if let presenter = presentingViewController as? PresentedContainerViewController, presenter.context == .items {
                
                presenter.prepare(animated: false)
                presenter.queueVC.tableView.reloadData()
            }
            
            updateHeaderView(with: manager.queue.count, animated: false)
            tableView.reloadData()
        
        } else {
            
            let array = playlistItems + mediaItemCollection.items
            playlistItems = array
            (parent as? PresentedContainerViewController)?.itemsToAdd = array
            
            tableView.reloadData()
            updateHeaderView(with: playlistItems.count, animated: false)
            
            (parent as? PresentedContainerViewController)?.prepare(animated: false)
        }
    }
}

extension NewPlaylistViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return (manager?.queue ?? playlistItems).count
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        operations[indexPath]?.cancel()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
        let cell = tableView.songCell(for: indexPath)
        
        let song = (manager?.queue ?? playlistItems)[indexPath.row]
        
        cell.prepare(with: song, songNumber: songCountVisible.inverted ? nil : indexPath.row + 1)
        cell.delegate = self
        cell.swipeDelegate = self
        cell.playButton.isUserInteractionEnabled = false
        cell.infoButton.isUserInteractionEnabled = false
        cell.infoButton.alpha = 0
        cell.optionsView.isHidden = true
        cell.editingView.isHidden = true
        cell.editingView.alpha = 0
        updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: tableView)
        
        for category in [SecondaryCategory.loved, .plays, .rating, .lastPlayed, .dateAdded, .genre, .year, .fileSize] {
            
            update(category: category, using: song, in: cell, at: indexPath, reusableView: tableView)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if !tableView.isEditing { tableView.deselectRow(at: indexPath, animated: true) }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        
        return actionableSongs.count > 1
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let song = (manager?.queue ?? playlistItems)[sourceIndexPath.row]
        
        if let _ = manager {
            
            manager?.queue.remove(at: sourceIndexPath.row)
            manager?.queue.insert(song, at: destinationIndexPath.row)
            
            if let presenter = presentingViewController as? PresentedContainerViewController, presenter.context == .items {
                
                presenter.queueVC.tableView.reloadData()
            }
            
        } else {
            
            playlistItems.remove(at: sourceIndexPath.row)
            playlistItems.insert(song, at: destinationIndexPath.row)
        }
    }
}

extension NewPlaylistViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        (parent as? PresentedContainerViewController)?.rightButtonTapped()
        
        if searchBar.text?.isEmpty == false {
            
            searchBar.resignFirstResponder()
        }
    }
}

extension NewPlaylistViewController: EntityCellDelegate {
    
    func editButtonTapped(in cell: SongTableViewCell) {
        
        
    }
    
    func artworkTapped(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        cell.setHighlighted(true, animated: true)
        self.tableView(tableView, didSelectRowAt: indexPath)
        cell.setHighlighted(false, animated: true)
    }
    
    func accessoryButtonTapped(in cell: SongTableViewCell) {
        
        
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

extension NewPlaylistViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        return TableDelegate.editActions(for: self, orientation: orientation, using: (manager?.queue ?? playlistItems)[indexPath.row], at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        
        var options = SwipeTableOptions()
        options.transitionStyle = .drag
        options.expansionStyle = orientation == .right ? .destructive(automaticallyDelete: false) : .selection
        
        return options
    }
}
