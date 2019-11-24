//
//  QueueTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 07/08/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class QueueViewController: UIViewController, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, AlbumTransitionable, ArtistTransitionable, AlbumArtistTransitionable, GenreTransitionable, ComposerTransitionable, InfoLoading, BackgroundHideable, Dismissable, EntityContainer, CellAnimatable, Peekable, SingleItemActionable, IndexContaining, LargeActivityIndicatorContaining, EntityVerifiable, Detailing {
    
    @IBOutlet var tableView: MELTableView!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var queueStackView: UIStackView!
    @IBOutlet var queueStackViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var activityIndicator: MELActivityIndicatorView!
    @IBOutlet var largeActivityIndicator: MELActivityIndicatorView!
    @IBOutlet var activityView: UIView!
    @IBOutlet var activityVisualEffectView: MELVisualEffectView!
    @IBOutlet var actionsButton: MELButton! {
        
        didSet {
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(showSettings(with:)))
            gr.minimumPressDuration = longPressDuration
            actionsButton.addGestureRecognizer(gr)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        }
    }
    @IBOutlet var editButton: MELButton! {
        
        didSet {
            
            editButton.setImage(.inactiveEditImage, for: .normal)
            editButton.setTitle(.inactiveEditButtonTitle, for: .normal)
            
            editButton.addTarget(songManager, action: #selector(SongActionManager.toggleEditing(_:)), for: .touchUpInside)
        }
    }
    
    enum ShuffleMode { case none, songs, albums }
    
    @objc var presenter: PresentedContainerViewController? { return parent as? PresentedContainerViewController }
    weak var searchBar: MELSearchBar?
    @objc var firstScroll = true
    @objc var presented = false
    @objc var itemsToAdd = [MPMediaItem]()
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var albumQuery: MPMediaQuery?
    @objc var composerQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    
    var preferredEditingStyle = EditingStyle.select
    
    @objc var query: MPMediaQuery?
    #warning("This will need investigating when testing moving rows in systemMusicPlayer")
    @objc var queue: [MPMediaItem] {
        
        get { return isQueueAvailable ? Queue.shared.currentQueue : systemQueue }
        
        set(newValue) { systemQueue = newValue }
    }
    lazy var systemQueue = [MPMediaItem]()
    lazy var queueIsBeingEdited = false
    lazy var shouldReload = true
    lazy var shuffleMode = ShuffleMode.none
    var queueCount: Int { return isQueueAvailable ? queue.count : musicPlayer.queueCount() }
    var isQueueAvailable: Bool { if !useSystemPlayer, forceOldStyleQueue.inverted, #available(iOS 10.3, *), let _ = musicPlayer as? MPMusicPlayerApplicationController { return true } else { return false } }
    var nowPlaying: MPMediaItem?
    @objc var queueExists: Bool { return musicPlayer.nowPlayingItem != nil }
    @objc var userScrolled = false
    @objc var needsDismissal = false
    @objc var allowPresentation = true // used for presenting actions when controlling music player
    lazy var limit: Int = {
        
        if #available(iOS 12, *) { return 99 }
        
        return 499
    }()
    
    @objc weak var peeker: UIViewController? {
        
        didSet {
            
            guard peeker == nil else { return }
            
            tableView.reloadData()
        }
    }
    var oldArtwork: UIImage?
    
    var manager: QueueManager?
    var sectionIndexViewController: SectionIndexViewController?
    var navigatable: Navigatable?
    let requiresLargerTrailingConstraint = true
    lazy var notificationName = isQueueAvailable ? Notification.Name.indexUpdated : .nowPlayingItemChanged
    
    @objc var actionableSongs: [MPMediaItem] { return queue }
    let applicableActions = [.collect, SongAction.newPlaylist, .addTo]
    @objc lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
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
    @objc let saveOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Save Operation Queue"
        
        
        return queue
    }()
    @objc var saveOperation: BlockOperation?

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let _ = peeker, let container = appDelegate.window?.rootViewController as? ContainerViewController {
            
            ArtworkManager.shared.currentlyPeeking = self
            temporaryImageView.image = container.imageView.image
        }
        
        nowPlaying = musicPlayer.nowPlayingItem
        
        shouldReturnToContainer = false
        
        notifier.addObserver(self, selector: #selector(applicationChangedState(_:)), name: UIApplication.willEnterForegroundNotification, object: UIApplication.shared)
        
        notifier.addObserver(self, selector: #selector(applicationChangedState(_:)), name: UIApplication.didEnterBackgroundNotification, object: UIApplication.shared)
        
        notifier.addObserver(self, selector: #selector(reload(_:)), name: notificationName, object: musicPlayer)
        
        notifier.addObserver(self, selector: #selector(reload), name: .shuffleInvoked, object: nil)
        
        notifier.addObserver(self, selector: #selector(updateQueue), name: .queueUpdated, object: musicPlayer)
        
        notifier.addObserver(self, selector: #selector(reload(_:)), name: .queueModified, object: nil)
        
        notifier.addObserver(self, selector: #selector(updateExplicitVisibility), name: .showExplicitnessChanged, object: nil)
        
        notifier.addObserver(tableView as Any, selector: #selector(UITableView.reloadData), name: .lineHeightsCalculated, object: nil)
        
        notifier.addObserver(self, selector: #selector(playbackStopped), name: .playbackStopped, object: nil)
        
        if presented {
            
            if manager == nil {
                
                presenter?.rightButton.isHidden = true
                presenter?.rightBorderView.isHidden = true
            }
            
            bottomView.isHidden = true
            
            tableView.scrollIndicatorInsets.bottom = 14
        
        } else {
            
            queueStackViewHeightConstraint.constant = 44
            
            tableView.register(UINib.init(nibName: "PlaybackCell", bundle: nil), forCellReuseIdentifier: "cell")
            
            let swipeRight = UISwipeGestureRecognizer.init(target: self, action: #selector(handleRightSwipe(_:)))
            swipeRight.direction = .right
            tableView.addGestureRecognizer(swipeRight)
            
            let swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(handleLeftSwipe(_:)))
            swipeLeft.direction = .left
            tableView.addGestureRecognizer(swipeLeft)
            
            let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(performHold(_:)))
            hold.minimumPressDuration = longPressDuration
            hold.delegate = self
            tableView.addGestureRecognizer(hold)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
            
            let allHold = UILongPressGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.showActionsForAll(_:)))
            allHold.minimumPressDuration = longPressDuration
            editButton.addGestureRecognizer(allHold)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: allHold))
        }
        
        let edge = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(updateSections))
        edge.edges = .right
        parent?.view.addGestureRecognizer(edge)
        
        let ownEdge = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(updateSections))
        ownEdge.edges = .right
        view.addGestureRecognizer(ownEdge)
        
        tableView.tableFooterView = UIView.init(frame: .zero)
        
        updateQueue()
    }
    
    @objc func updateExplicitVisibility() {
        
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        
        tableView.reloadRows(at: indexPaths, with: .none)
    }
    
    @objc func applicationChangedState(_ notification: Notification) {
        
        if notification.name == UIApplication.didEnterBackgroundNotification {
            
            notifier.removeObserver(self, name: .nowPlayingItemChanged, object: musicPlayer)
        
        } else {
            
            reload(self)
            
            notifier.addObserver(self, selector: #selector(reload), name: .nowPlayingItemChanged, object: musicPlayer)
            
//            if #available(iOS 10, *) { } else { reload() }
        }
    }
    
    @objc func updateQueue() {
        
//        tableView.reloadData()
//        
//        guard !useSystemPlayer, forceOldStyleQueue.inverted, #available(iOS 10.3, *), let musicPlayer = musicPlayer as? MPMusicPlayerApplicationController else { return }
//
//        updateLoadingViews(hidden: false)
//
//        musicPlayer.perform(queueTransaction: { _ in }, completionHandler: { [weak self] controller, _ in
//
//            guard let weakSelf = self else { return }
//
//            UniversalMethods.performInMain {
//
//                weakSelf.queue = controller.items
//                weakSelf.tableView.reloadData()
////            if weakSelf.presented { weakSelf.animateCells() }
//
//                weakSelf.updateLoadingViews(hidden: true)
//            }
//        })
    }
    
    @objc func performHold(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
            
            case .began:
            
                guard let indexPath = tableView.indexPathForRow(at: sender.location(in: tableView)), let cell = tableView.cellForRow(at: indexPath) as? SongTableViewCell, let item = getSong(from: indexPath) else { return }
                
                var actions = [SongAction.collect, .info(context: context(from: indexPath)), .queue(name: cell.nameLabel.text, query: nil), .newPlaylist, .addTo].map({ singleItemAlertAction(for: $0, entity: .song, using: item, from: self) })
                
                if item.existsInLibrary.inverted {
                    
                    actions.insert(singleItemAlertAction(for: .library, entity: .song, using: item, from: self), at: 3)
                }
                
                showAlert(title: cell.nameLabel.text, with: actions)
            
            case .changed, .ended:
            
                guard let top = topViewController as? VerticalPresentationContainerViewController else { return }
            
                top.gestureActivated(sender)
            
            default: break
        }
    }
    
    @objc func showOptions(_ sender: Any) {
        
        var actualIndexPath: IndexPath?
        
        if let sender = sender as? UIGestureRecognizer {
            
            guard sender.state == .began else { return }
            
            actualIndexPath = tableView.indexPathForRow(at: sender.location(in: tableView))
            
        } else if let cell = sender as? UITableViewCell {
            
            actualIndexPath = tableView.indexPath(for: cell)
        
        } else if let indexPath = sender as? IndexPath {
            
            actualIndexPath = indexPath
        }
        
        guard let indexPath = actualIndexPath else { return }
        
        Transitioner.shared.showInfo(from: self, with: context(from: indexPath))
    }
    
    func context(from indexPath: IndexPath) -> InfoViewController.Context {
        
        if let index = getIndex(from: indexPath) {
            
            if #available(iOS 10.3, *), !useSystemPlayer, forceOldStyleQueue.inverted {
                
                return .song(location: .queue(loaded: true, index: index), at: index, within: queue)
                
            } else if queueIsBeingEdited {
                
                return .song(location: .queue(loaded: true, index: index), at: index, within: queue)
                
            } else {
                
                return .song(location: .queue(loaded: false, index: index), at: 0, within: [getSong(from: indexPath)].compactMap({ $0 }))
            }
            
        } else {
            
            return .song(location: .queue(loaded: true, index: Queue.shared.indexToUse), at: 0, within: [musicPlayer.nowPlayingItem].compactMap({ $0 }))
        }
    }
    
    @IBAction func showLibraryOptions() {
        
        let vc = popoverStoryboard.instantiateViewController(withIdentifier: "actionsVC")
        vc.modalPresentationStyle = .popover
        
        guard let actionsVC = Transitioner.shared.transition(to: vc, using: .init(fromVC: self, configuration: .queue), sourceView: actionsButton) else { return }
        
        show(actionsVC, sender: nil)
    }
    
    @objc func snapToNowPlaying() {
        
        if isQueueAvailable, queue.isEmpty { return }
        
        if let index = Queue.shared.indexToUse, index == 0 {
            
            tableView.scrollToRow(at: IndexPath.init(row: 0, section: 1), at: .top, animated: true)
            
        } else if let indexPaths = tableView.indexPathsForVisibleRows, indexPaths.contains(IndexPath.init(row: 0, section: 1)) {
            
            tableView.scrollToRow(at: IndexPath.init(row: 0, section: 1), at: .top, animated: true)
        }
    }
    
    @objc func playbackStopped() {
        
        guard !(presentingViewController is NowPlayingViewController) else { return }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func reload(_ sender: Any) {
        
        if useSystemPlayer || forceOldStyleQueue {
            
            guard shouldReload else { return }
        }
        
        guard let _ = musicPlayer.nowPlayingItem else {
            
            if presentedViewController == nil {
                
                guard !(presentingViewController is NowPlayingViewController), useSystemPlayer else { return }
                
                dismiss(animated: true, completion: nil)
                
            } else {
                
                needsDismissal = true
            }
            
            return
        }
        
//        if queueIsSetUpForMove {
//            
//            queueIsSetUpForMove = false
//            queue = []
//        }
        
        needsDismissal = false
        
        if let notification = sender as? Notification, let _ = notification.userInfo?[.queueChange], nowPlaying == musicPlayer.nowPlayingItem {
            
            // was causing crashes. Will be an issue when a single song is done playing and notification is sent
//            tableView.reloadRows(at: [.init(row: 0, section: 1)], with: .none)
            
        } else {
            
            nowPlaying = musicPlayer.nowPlayingItem
            tableView.reloadData()
            animateCells(direction: .vertical)
            toggleEditing(false)
            snapToNowPlaying()
        }
        
        presenter?.prepare(animated: true, updateConstraintsAndButtons: false)
    }
    
    @objc func viewSections() {
        
        guard let sectionVC = popoverStoryboard.instantiateViewController(withIdentifier: String.init(describing: SectionIndexViewController.self)) as? SectionIndexViewController, let sections = self.sectionIndexTitles(for: tableView), !sections.isEmpty else { return }
        
        sectionVC.array = sections.map({ SectionIndexViewController.IndexKind.text($0) })
        sectionVC.container = self
        sectionIndexViewController = sectionVC
        
        present(sectionVC, animated: true, completion: nil)
    }
    
    @objc func updateSections(_ gr: UIScreenEdgePanGestureRecognizer) {
        
        switch gr.state {
            
            case .began:
                
                guard let sectionVC = popoverStoryboard.instantiateViewController(withIdentifier: String.init(describing: SectionIndexViewController.self)) as? SectionIndexViewController, let sections = self.sectionIndexTitles(for: tableView), !sections.isEmpty else { return }
                
                sectionVC.array = sections.map({ SectionIndexViewController.IndexKind.text($0) })
                sectionVC.container = self
                sectionIndexViewController = sectionVC
                
                present(sectionVC, animated: true, completion: nil)
            
            case .changed:
                
                guard let sectionVC = sectionIndexViewController, let view = sectionVC.view, let collectionView = sectionVC.collectionView, let containerView = sectionVC.containerView, let effectView = sectionVC.effectView, let location: CGPoint = {
                    
                    if view.convert(effectView.frame, from: containerView).contains(gr.location(in: view)) {
                        
                        return gr.location(in: collectionView)
                        
                    } else if sectionVC.overflowBahaviour == .squeeze || sectionVC.array.count <= sectionVC.maxRowsAtMaxFontSize, let location: CGPoint = {
                        
                        let height: CGFloat = {
                            
                            if gr.location(in: collectionView).y < 0 {
                                
                                return 1 + 4
                                
                            } else if gr.location(in: collectionView).y > collectionView.frame.height {
                                
                                return collectionView.frame.height - 1 - 3
                            }
                            
                            return gr.location(in: collectionView).y
                        }()
                        
                        return .init(x: collectionView.center.x, y: height)
                        
                    }() {
                        
                        return location
                    }
                    
                    return nil
                    
                }(), let indexPath = collectionView.indexPathForItem(at: location) else { return }
                
                sectionVC.container?.tableView.scrollToRow(at: .init(row: NSNotFound, section: indexPath.row), at: .top, animated: false)
            
            case .ended, .failed/*, .cancelled*/: sectionIndexViewController?.dismissVC()
            
            default: break
        }
    }
    
    @objc func handleRightSwipe(_ sender: Any) {
        
        guard queueCount > 1 else { return }
        
        toggleEditing(true)
    }
    
    @objc func handleLeftSwipe(_ sender: Any) {
        
        if tableView.isEditing {
            
            toggleEditing(false)
            
            if !useSystemPlayer, #available(iOS 10.3, *), forceOldStyleQueue.inverted {
                
                return
            
            } else if queueIsBeingEdited {
                
                shouldReload = false
                updateLoadingViews(hidden: false)
                
                UniversalMethods.performOnMainThread({ [weak self] in
                    
                    guard let weakSelf = self else { return }
                
                    musicPlayer.play(weakSelf.queue, startingFrom: musicPlayer.nowPlayingItem, respectingPlaybackState: true, from: nil, withTitle: nil, alertTitle: "Update Queue", completion: {
                        
                        weakSelf.queueIsBeingEdited = false
                        weakSelf.queue = []
                        weakSelf.tableView.reloadData()
                        weakSelf.toggleEditing(false)
                        weakSelf.snapToNowPlaying()
                        weakSelf.presenter?.prepare(animated: true, updateConstraintsAndButtons: false)
                        weakSelf.updateLoadingViews(hidden: true)
                        weakSelf.shouldReload = true
                        
                        if let sender = weakSelf.presentingViewController as? NowPlayingViewController {
                            
                            sender.modifyQueueLabel()
                        }
                    })
                
                }, afterDelay: 0.01)
            }
            
//            if queueIsSetUpForMove {
//                
//                musicPlayer.play(.init(items: queue), startingFrom: musicPlayer.nowPlayingItem, from: nil, withTitle: nil, alertTitle: "Move Song")
//            }
        
        } else {
            
            guard !presented, let gr = sender as? UISwipeGestureRecognizer, let indexPath = tableView.indexPathForRow(at: gr.location(in: tableView)), let song = getSong(from: indexPath) else { return }
            
            let filterPredicates: Set<MPMediaPropertyPredicate> = showiCloudItems ? [.for(.album, using: song.albumPersistentID)] : [.for(.album, using: song.albumPersistentID), .offline]
            
            let query = MPMediaQuery.init(filterPredicates: filterPredicates)
            query.groupingType = .album
            
            if let collections = query.collections, !collections.isEmpty {
                
                albumQuery = query
                currentItem = song
                
                useAlternateAnimation = true
                
                performSegue(withIdentifier: .albumUnwind, sender: nil)
                
            } else {
                
                albumQuery = nil
                currentItem = nil
                
                let newBanner = Banner.init(title: showiCloudItems ? "This album is not in your library" : "This album is not available offline", subtitle: nil, image: nil, backgroundColor: .black, didTapBlock: nil)
                newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                newBanner.show(duration: 0.7)
            }
        }
    }
    
    @objc func toggleEditing(_ editing: Bool, animated: Bool = true) {
            
        tableView.setEditing(editing, animated: animated)
    }
    
    @objc func showNowPlaying() {
        
        let base = basePresentedOrNowPlayingViewController(from: parent)
        
        base?.dismiss(animated: base is NowPlayingViewController, completion: {
            
            guard !(base is NowPlayingViewController), let presenter = appDelegate.window?.rootViewController as? ContainerViewController, let nowPlayingVC = presenter.moveToNowPlaying(vc: nowPlayingStoryboard.instantiateViewController(withIdentifier: "nowPlaying"), showingQueue: false) else { return }
            
            presenter.present(nowPlayingVC, animated: true, completion: nil)
        })
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) { }
    
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        
        if action == #selector(unwind(_:)) {
            
            if shouldReturnToContainer || presented {
                
                return false
                
            } else {
                
                return presentedViewController != nil && parent?.presentedViewController != nil
            }
        }
        
        return false
    }
    
    @IBAction func keepSelected() {
        
        guard let index = Queue.shared.indexToUse, let nowPlaying = musicPlayer.nowPlayingItem else { return }
        
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            
            let banner = Banner.init(title: "No songs selected", subtitle: nil, image: nil, backgroundColor: .azure, didTapBlock: nil)
            banner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
            banner.show(duration: 0.5)
            
            return
        }
        
        if !useSystemPlayer, forceOldStyleQueue.inverted, #available(iOS 10.3, *), let musicPlayer = musicPlayer as? MPMusicPlayerApplicationController {
            
            let update = AlertAction.init(title: "Update Queue", style: .destructive, requiresDismissalFirst: true, handler: { [weak self] in
                
                guard let weakSelf = self else { return }
                
                let set = Set(indexPaths.map({ weakSelf.getSong(from: $0) }).compactMap({ $0 }) + [musicPlayer.nowPlayingItem].compactMap({ $0 }))
                
                var removedItems = [MPMediaItem]()
                
                musicPlayer.perform(queueTransaction: { controller in
                    
                    self?.updateLoadingViews(hidden: false)
                    
                    let subtracted = controller.items.filter({ !set.contains($0) })
                    
                    DispatchQueue.main.async { removedItems = subtracted }
                    
                    for item in subtracted {
                        
                        controller.remove(item)
                    }
                    
                }, completionHandler: { controller, error in
                    
                    if let error = error, isInDebugMode {
                        
                        UniversalMethods.banner(withTitle: error.localizedDescription).show(for: 1)
                    }
                    
                    Queue.shared.remove(removedItems, completion: .none(completion: {
                        
                        weakSelf.tableView.reloadData()
                        weakSelf.toggleEditing(false)
                        weakSelf.snapToNowPlaying()
                        weakSelf.presenter?.prepare(animated: true, updateConstraintsAndButtons: false)
                        notifier.post(name: .queueModified, object: nil, userInfo: [.queueChange: true])
                    }))
                    
                    self?.updateLoadingViews(hidden: true)
                    
//                    notifier.post(name: .saveQueue, object: musicPlayer, userInfo: [String.queueItems: controller.items])
//                    weakSelf.queue = controller.items
//                    weakSelf.tableView.reloadData()
//                    weakSelf.toggleEditing(false)
//                    weakSelf.snapToNowPlaying()
//                    weakSelf.presenter?.prepare(animated: true, updateConstraintsAndButtons: false)
//
//                    if let sender = weakSelf.presentingViewController as? NowPlayingViewController {
//
//                        sender.modifyQueueLabel()
//                    }
                })
            })
            
            showAlert(title: (indexPaths.count + 1).fullCountText(for: .song).capitalized, with: update)
            
//            let alert = UniversalMethods.alertController(withTitle: (indexPaths.count + 1).fullCountText(for: .song).capitalized, message: nil, preferredStyle: .actionSheet, actions: update, UniversalMethods.cancelAlertAction())
//
//            present(alert, animated: true, completion: nil)
            
            return
        }
        
        var startOfQueue = [MPMediaItem]()
        var endOfQueue = [MPMediaItem]()
        
        for indexPath in indexPaths {
            
            let song: MPMediaItem? = {
                
                if indexPath.section == 0 {
                    
                    return musicPlayer.item(at: indexPath.row)
                    
                } else if indexPath.section == 1 {
                    
                    return musicPlayer.nowPlayingItem
                    
                } else {
                    
                    return musicPlayer.item(at: index + 1 + indexPath.row)
                }
            }()
            
            if let song = song {
                
                if indexPath.section == 0 {
                    
                    startOfQueue.append(song)
                    
                } else {
                    
                    endOfQueue.append(song)
                }
            }
        }
        
        shouldReload = false
        
        musicPlayer.play(startOfQueue + [nowPlaying] + endOfQueue, startingFrom: musicPlayer.nowPlayingItem, shuffleMode: .off, respectingPlaybackState: true, from: self, withTitle: "\(indexPaths.count + 1) Songs", subtitle: nil, alertTitle: "Update Queue", completion: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            weakSelf.queueIsBeingEdited = false
            weakSelf.queue = []
            weakSelf.tableView.reloadData()
            weakSelf.toggleEditing(false)
            weakSelf.snapToNowPlaying()
            weakSelf.presenter?.prepare(animated: true, updateConstraintsAndButtons: false)
            weakSelf.shouldReload = true
            
            if let sender = weakSelf.presentingViewController as? NowPlayingViewController {
                
                sender.modifyQueueLabel()
            }
        })
    }
    
    @IBAction func removeSelected(_ sender: Any) {
        
        guard let index = Queue.shared.indexToUse, let nowPlaying = musicPlayer.nowPlayingItem else { return }
        
        guard let indexPaths = sender as? [IndexPath] ?? tableView.indexPathsForSelectedRows else {
            
            let banner = Banner.init(title: "No songs selected", subtitle: nil, image: nil, backgroundColor: .azure, didTapBlock: nil)
            banner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
            banner.show(duration: 0.5)
            
            return
        }
        
        if !useSystemPlayer, forceOldStyleQueue.inverted, #available(iOS 10.3, *), let musicPlayer = musicPlayer as? MPMusicPlayerApplicationController {
            
            let update = AlertAction.init(title: "Update Queue", style: .destructive, requiresDismissalFirst: true, handler: { [weak self] in
                
                guard let weakSelf = self else { return }
                
                var removedItems = [MPMediaItem]()
                
                self?.updateLoadingViews(hidden: false)
                
                musicPlayer.perform(queueTransaction: { controller in
                    
                    for indexPath in indexPaths {
                        
                        if let item = weakSelf.getSong(from: indexPath) {
                            
                            DispatchQueue.main.async { removedItems.append(item) }
                            
                            controller.remove(item)
                        }
                    }
                    
                    }, completionHandler: { controller, error in
                        
                        if let error = error, isInDebugMode {
                            
                            UniversalMethods.banner(withTitle: error.localizedDescription).show(for: 1)
                        }
                        
                        Queue.shared.remove(removedItems, completion: .none(completion: {
                            
                            weakSelf.tableView.reloadData()
                            weakSelf.toggleEditing(false)
                            weakSelf.snapToNowPlaying()
                            weakSelf.presenter?.prepare(animated: true, updateConstraintsAndButtons: false)
                            notifier.post(name: .queueModified, object: nil, userInfo: [.queueChange: true])
                        }))
                        
                        self?.updateLoadingViews(hidden: true)
                        
//                        notifier.post(name: .saveQueue, object: musicPlayer, userInfo: [String.queueItems: controller.items])
//                        weakSelf.queue = controller.items
//                        weakSelf.tableView.reloadData()
//                        weakSelf.toggleEditing(false)
//                        weakSelf.snapToNowPlaying()
//                        weakSelf.presenter?.prepare(animated: true, updateConstraintsAndButtons: false)
//
//                        if let sender = weakSelf.presentingViewController as? NowPlayingViewController {
//
//                            sender.modifyQueueLabel()
//                        }
                })
            })
            
            showAlert(title: (queueCount - indexPaths.count).fullCountText(for: .song).capitalized, with: update)
            
            return
        }
        
        let array = index == 0 ? [] : Array(0...(index - 1))
        let endArray = (index + 1) == musicPlayer.queueCount() ? [] : Array((index + 1)...(musicPlayer.queueCount() - 1))
        var startOfQueue = [MPMediaItem]()
        var endOfQueue = [MPMediaItem]()
        
        array.forEach({
            
            if let item = musicPlayer.item(at: $0) {
                
                startOfQueue.append(item)
            }
        })
        
        endArray.forEach({
            
            if let item = musicPlayer.item(at: $0) {
                
                endOfQueue.append(item)
            }
        })
        
        let firstArray = indexPaths.filter({ $0.section == 0 }).map({ $0.row })
        let nextArray = indexPaths.filter({ $0.section == 2 }).map({ $0.row })
        
        let finalStart = startOfQueue.enumerated().filter({ !firstArray.contains($0.offset) }).map({ $0.element })
        let finalEnd = endOfQueue.enumerated().filter({ !nextArray.contains($0.offset) }).map({ $0.element })
        
        shouldReload = false
        
        musicPlayer.play(finalStart + [nowPlaying] + finalEnd, startingFrom: musicPlayer.nowPlayingItem, shuffleMode: .off, respectingPlaybackState: true, from: self, withTitle: "\(finalStart.count + finalEnd.count + 1) Songs", subtitle: nil, alertTitle: "Update Queue", completion: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            weakSelf.queueIsBeingEdited = false
            weakSelf.queue = []
            weakSelf.tableView.reloadData()
            weakSelf.toggleEditing(false)
            weakSelf.snapToNowPlaying()
            weakSelf.presenter?.prepare(animated: true, updateConstraintsAndButtons: false)
            weakSelf.shouldReload = true
            
            if let sender = weakSelf.presentingViewController as? NowPlayingViewController {
                
                sender.modifyQueueLabel()
            }
        })
    }
    
    @IBAction func clearQueue(_ sender: AnyObject) {
        
        guard let _ = musicPlayer.nowPlayingItem else { return }
        
        let clear = AlertAction.init(info: .init(title: "All But Now Playing", accessoryType: .none), context: .alert(.destructive), handler: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            weakSelf.clearQueue()
        })
        
        let stop = AlertAction.init(info: .init(title: "All", accessoryType: .none), context: .alert(.destructive), requiresDismissalFirst: true, handler: NowPlaying.shared.stopPlayback)
        
        let clearSelected = AlertAction.init(info: .init(title: "Selected", accessoryType: .none), context: .alert(.destructive), requiresDismissalFirst: true, handler: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            weakSelf.removeSelected(weakSelf)
        })
        
        let clearUnselected = AlertAction.init(info: .init(title: "Unselected", accessoryType: .none), context: .alert(.destructive), requiresDismissalFirst: true, handler: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            weakSelf.keepSelected()
        })
        
        let allBut = queueCount > 1 ? [clear] : []
        var selected: [AlertAction] {
            
            if let indexPaths = tableView.indexPathsForSelectedRows, indexPaths.isEmpty.inverted {
                
                if #available(iOS 11.3, *), !useSystemPlayer, forceOldStyleQueue.inverted { return [] }
                
                return [clearSelected, clearUnselected]
            }
            
            return []
        }
        
        showAlert(title: "Clear...", context: .other, with: [stop] + selected + allBut)
    }
    
    @objc func clearQueue() {
        
        guard let nowPlaying = musicPlayer.nowPlayingItem else { return }
        
        if !useSystemPlayer, forceOldStyleQueue.inverted, #available(iOS 10.3, *), let musicPlayer = musicPlayer as? MPMusicPlayerApplicationController, let index = Queue.shared.indexToUse, queue.filter({ $0 == nowPlaying }).count < 2 {
            
            musicPlayer.perform(queueTransaction: { [weak self] controller in
                
                guard let weakSelf = self else { return }
                
                self?.updateLoadingViews(hidden: false)
                
                for song in weakSelf.queue.enumerated() where song.offset != index {
                    
                    controller.remove(song.element)
                }
                
            }, completionHandler: { [weak self] controller, error in
                
                if let error = error, isInDebugMode {
                    
                    UniversalMethods.banner(withTitle: error.localizedDescription).show(for: 1)
                }
            
                Queue.shared.clearAllButNowPlaying(completion: {
                    
                    notifier.post(name: .queueModified, object: nil, userInfo: [.queueChange: true])
                    
                    guard let weakSelf = self else { return }
                    
                    weakSelf.tableView.reloadData()
                    weakSelf.toggleEditing(false)
                    weakSelf.animateCells(direction: .vertical)
                    weakSelf.presenter?.prepare(animated: true, updateConstraintsAndButtons: false)
                })
                
                self?.updateLoadingViews(hidden: true)
                
//                notifier.post(name: .saveQueue, object: musicPlayer, userInfo: [String.queueItems: controller.items])
//                notifier.post(name: .queueModified, object: nil)
//                weakSelf.queue = controller.items
//                weakSelf.tableView.reloadData()
//                weakSelf.animateCells(direction: .vertical)
//                weakSelf.presenter?.prepare(animated: true, updateConstraintsAndButtons: false)
            })
            
        } else {
            
            shouldReload = false
            
            musicPlayer.play([nowPlaying], startingFrom: nowPlaying, respectingPlaybackState: true, from: nil, withTitle: nil, alertTitle: "", completion: { [weak self] in
                
                guard let weakSelf = self else { return }
                
                notifier.post(name: .queueModified, object: nil)
                weakSelf.queueIsBeingEdited = false
                weakSelf.queue = []
                weakSelf.tableView.reloadData()
                weakSelf.animateCells(direction: .vertical)
                weakSelf.presenter?.prepare(animated: true, updateConstraintsAndButtons: false)
                weakSelf.shouldReload = true
            })
        }
    }
    
    @objc func presentActionsForAll(_ sender: Any) {
        
        activityIndicator.startAnimating()
        editButton.alpha = 0
        
        saveOperation = BlockOperation()
        saveOperation?.addExecutionBlock({ [weak self, weak saveOperation] in
            
            guard let weakSelf = self, let operation = saveOperation, !operation.isCancelled else { return }
            
            let array = weakSelf.getQueue(with: operation)
            
            OperationQueue.main.addOperation({
                
                guard !operation.isCancelled else { return }
                
                weakSelf.queue = array
                weakSelf.showArrayActions(sender)
                weakSelf.activityIndicator.stopAnimating()
                weakSelf.editButton.alpha = 1
            })
        })
        
        saveOperationQueue.addOperation(saveOperation!)
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        imageCache.removeAllObjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        allowPresentation = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        allowPresentation = false
        saveOperation?.cancel()
        
        activityIndicator.stopAnimating()
        editButton.alpha = 1
    }

    override func viewDidLayoutSubviews() {

        if firstScroll {

            if #available(iOS 11.3, *), !useSystemPlayer, forceOldStyleQueue.inverted, queue.isEmpty { return }

            tableView.scrollToRow(at: IndexPath.init(row: 0, section: presented ? 2 : 1), at: .top, animated: false)
//            tableView.tableHeaderView?.isHidden = false

            if peeker == nil, let parent = parent as? PresentedContainerViewController, parent.altAnimator?.interactor.interactionInProgress != true {

                animateCells(direction: .vertical)
            }

            firstScroll = false
        }
    }
    
    @objc func getQueue(with operation: BlockOperation? = nil) -> [MPMediaItem] {
        
        if operation?.isCancelled == true { return [] }
        
        let array = (0..<max(1, musicPlayer.queueCount())).compactMap({ musicPlayer.item(at: $0) })
        
        if operation?.isCancelled == true { return [] }
        
        return array
    }
    
    @objc func getSong(from indexPath: IndexPath) -> MPMediaItem? {
        
        if indexPath.section == 0 {
            
            guard let _ = Queue.shared.indexToUse else { return nil }
            
            if queueIsBeingEdited {
                
                return queue[indexPath.row]
            }
            
            return isQueueAvailable ? queue.value(at: indexPath.row) : musicPlayer.item(at: indexPath.row)
            
        } else if indexPath.section == 1 {
            
            return musicPlayer.nowPlayingItem
            
        } else {
            
            guard let index = Queue.shared.indexToUse else { return nil }
            
            return isQueueAvailable ? queue.value(at: index + 1 + indexPath.row) : musicPlayer.item(at: index + 1 + indexPath.row)
        }
    }
    
    func getIndex(from indexPath: IndexPath) -> Int? {
        
        guard let index = Queue.shared.indexToUse, tableView.cellForRow(at: indexPath) is SongTableViewCell else { return nil }
        
        if indexPath.section == 0 {
            
            return indexPath.row
        
        } else if indexPath.section == 1 {
            
            return Queue.shared.indexToUse
            
        } else {
            
            return index + 1 + indexPath.row
        }
    }
    
    func goToDetails(basedOn entity: Entity) -> (entities: [Entity], albumArtOverride: Bool) {
        
        return ([Entity.artist, .genre, .album, .composer, .albumArtist], true)
    }
    
//    @objc func updateLoadingViews(hidden: Bool) {
//
//        activityVisualEffectView.isHidden = queueIsBeingEdited ? hidden : firstScroll
//        activityView.isHidden = hidden
//        hidden ? largeActivityIndicator.stopAnimating() : largeActivityIndicator.startAnimating()
//    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "QVC going away...").show(for: 0.3)
        }
        
        if let _ = peeker, let container = appDelegate.window?.rootViewController as? ContainerViewController {
            
            ArtworkManager.shared.currentlyPeeking = nil
            
            UIView.transition(with: container.imageView, duration: 0.5, options: .transitionCrossDissolve, animations: { container.imageView.image = ArtworkManager.shared.activeContainer?.modifier?.artworkType.image/*self.oldArtwork*/ }, completion: nil)
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        
        return queueIsBeingEdited ? 1 : 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            
        if isQueueAvailable {
            
            if queueExists && queue.isEmpty {
                
                return 0
                
            } else if !queueExists {
                
                return 1
            }
        }
        
        if queueIsBeingEdited {
            
            return queue.count
        }
        
        if #available(iOS 11.3, *), useSystemPlayer || forceOldStyleQueue {
            
            if section == 0 {
                
                guard let index = Queue.shared.indexToUse else { return 1 }
                
                return index == 0 ? 1 : min(index, limit)
                
            } else if section == 1 {
                
                return presented ? 1 : 2
                
            } else if section == 2 {
                
                guard let index = Queue.shared.indexToUse else { return 1 }
                
                return (queueCount - (index + 1)) == 0 ? 1 : min(limit, queueCount - (index + 1))
            }
            
        } else {
        
            if section == 0 {
                
                guard let index = Queue.shared.indexToUse else { return 1 }
                
                return index == 0 ? 1 : index
                
            } else if section == 1 {
                
                return presented ? 1 : 2
                
            } else if section == 2 {
                
                guard let index = Queue.shared.indexToUse else { return 1 }
                
                return (queueCount - (index + 1)) == 0 ? 1 : queueCount - (index + 1)
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if queueIsBeingEdited, let _ = Queue.shared.indexToUse {
            
            return songCell(at: indexPath, with: getSong(from: indexPath))
        }
        
        if indexPath.section == 0 {
            
            guard let index = Queue.shared.indexToUse else { return standardCell(at: indexPath) }
            
            if index == 0 {
                
                return standardCell(at: indexPath)
                
            } else {
                
                if #available(iOS 11.3, *), useSystemPlayer || forceOldStyleQueue, index > limit {
                    
                    return songCell(at: indexPath, with: getSong(from: .init(row: index - (limit - indexPath.row), section: 0)))
                }
                
                return songCell(at: indexPath, with: getSong(from: indexPath))
            }
            
        } else if indexPath.section == 1 {
            
            if let item = musicPlayer.nowPlayingItem, indexPath.row == 0 {
                
                return songCell(at: indexPath, with: item)
                
            } else if indexPath.row == 1 {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PlaybackTableViewCell
                
                NowPlaying.shared.cell = cell
                cell.updateSliderDuration()
                cell.modifyRepeatButton(changingMusicPlayer: false)
                cell.modifyShuffleState(changingMusicPlayer: false)
                
                return cell
                
            } else {
                
                return standardCell(at: indexPath)
            }
            
        } else if indexPath.section == 2 {
            
            guard let index = Queue.shared.indexToUse else { return standardCell(at: indexPath) }
            
            if queueCount == (index + 1) {
                
                return standardCell(at: indexPath)
                
            } else {
                
                return songCell(at: indexPath, with: getSong(from: indexPath))
            }
            
        } else {
            
            fatalError("There shouldn't be more rows")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if presented {
            
            guard let index = Queue.shared.indexToUse else { return }
            
            let isQuery = manager == nil
            let song = getSong(from: indexPath)//musicPlayer.item(at: index + 1 + indexPath.row)
            var entityTitle: String {
                
                if let title = title {
                    
                    return title
                }
                
                if let query = query {
                    
                    switch query.groupingType {
                        
                        case .album: return query.collections?.first?.representativeItem?.albumTitle ??? .untitledAlbum
                        
                        case .artist: return query.collections?.first?.representativeItem?.artist ??? .unknownArtist
                        
                        case .composer: return query.collections?.first?.representativeItem?.composer ??? .unknownComposer
                        
                        case .genre: return query.collections?.first?.representativeItem?.genre ??? .untitledGenre
                        
                        case .playlist: return (query.collections?.first as? MPMediaPlaylist)?.name ??? .untitledPlaylist
                        
                        case .title: return query.items?.first?.title ??? .untitledSong
                        
                        default: return .unknownEntity
                    }
                }
                
                return ""
            }
            
            var count = 0
            
            let queries: (() -> [MPMediaQuery]) = {
                
                if let query = self.query {
                    
                    count = query.items?.count ?? 0
                    return [query]
                    
                } else {
                    
                    let items: [MPMediaItem] = {
                        
                        switch self.shuffleMode {
                            
                            case .none: return self.manager?.queue ?? self.itemsToAdd
                            
                            case .songs: return (self.manager?.queue ?? self.itemsToAdd).shuffled()
                            
                            case .albums: return (self.manager?.queue ?? self.itemsToAdd).albumsShuffled
                        }
                    }()
                    
                    count = items.count
                    
                    return items.map({ MPMediaQuery.init(filterPredicates: [.for(.song, using: $0)]) })
                }
            }
            
            let items: (() -> [MPMediaItem]) = {
                
                if let query = self.query {
                    
                    count = query.items?.count ?? 0
                    return query.items ?? []
                    
                } else {
                    
                    let items: [MPMediaItem] = {
                        
                        switch self.shuffleMode {
                            
                            case .none: return self.manager?.queue ?? self.itemsToAdd
                            
                            case .songs: return (self.manager?.queue ?? self.itemsToAdd).shuffled()
                            
                            case .albums: return (self.manager?.queue ?? self.itemsToAdd).albumsShuffled
                        }
                    }()
                    
                    count = items.count
                    
                    return items
                }
            }
            
            var kind: MPMusicPlayerController.QueueKind {
                
                if useMediaItems {
                    
                    return .items(items())
                    
                } else {
                    
                    return .queries(queries())
                }
            }
            
            var afterIndex: Int {
                
                if indexPath.section == 0 {
                    
                    return indexPath.row
                    
                } else if indexPath.section == 1 {
                    
                    return index
                    
                } else {
                    
                    return index + 1 + indexPath.row
                }
            }
            
            musicPlayer.insert(kind, .after(item: song, index: afterIndex), alertType: isQuery ? .entity(name: entityTitle) : .arbitrary(count: count), from: self, withTitle: song?.title ??? "Untitled Song", subtitle: nil, alertTitle: "Play After", completionKind: .completion({ [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.parent?.performSegue(withIdentifier: "unwind", sender: nil)
                
                if weakSelf.manager != nil {
                    
                    notifier.post(name: .endQueueModification, object: nil)
                }
            }))
            
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else {
            
            if !tableView.isEditing {
                
                let play: (MPMediaItem?, Int) -> () = { item, index in
                    
                    let wasPlaying = musicPlayer.isPlaying
                    
                    if self.isQueueAvailable {
                        
                        musicPlayer.setQueue(with: .init(items: self.queue))
                        musicPlayer.nowPlayingItem = item
                        musicPlayer.currentPlaybackTime = 0
                        musicPlayer.prepareToPlay()
                        
                        Queue.shared.indexOfNowPlayingItem = index
                        
                    } else {
                    
                        musicPlayer.nowPlayingItem = item
                    }
                    
                    if #available(iOS 11.3, *), wasPlaying.inverted {
                        
                        musicPlayer.pause()
                    
                    } else if wasPlaying {
                        
                        musicPlayer.play()
                    }
                    
                    prefs.set(index, forKey: .indexOfNowPlayingItem)
                }
                
                if indexPath.section == 0 {
                    
                    guard let _ = Queue.shared.indexToUse else { return }
                    
                    let item = getSong(from: indexPath)
                    
                    if warnForQueueInterruption && changeGuard {
                        
                        let play = AlertAction.init(title: "Change Song", style: .default, handler: {  play(item, indexPath.row) })
                        
                        showAlert(title: item?.validTitle, with: play)
                        
//                        present(UniversalMethods.alertController(withTitle: item?.validTitle, message: nil, preferredStyle: .actionSheet, actions: play, UniversalMethods.cancelAlertAction()), animated: true, completion: nil)
                        
                    } else {
                        
                        play(item, indexPath.row)
                    }
                    
                } else if indexPath.section == 1 {
                    
                    showNowPlaying()
                    
                } else if indexPath.section == 2 {
                    
                    guard let index = Queue.shared.indexToUse else { return }
                    
                    let item = getSong(from: indexPath)//musicPlayer.item(at: index + 1 + indexPath.row)
                    
                    if warnForQueueInterruption && changeGuard {
                        
                        let play = AlertAction.init(title: "Change Song", style: .default, handler: {  play(item, index + 1 + indexPath.row) })
                        
                        showAlert(title: item?.validTitle, with: play)
                        
                    } else {
                        
                        play(item, index + 1 + indexPath.row)
                    }
                }
                
                tableView.deselectRow(at: indexPath, animated: true)
                
            } else {
                
                if indexPath.section == 1 {
                    
                    tableView.deselectRow(at: indexPath, animated: true)
                    
                } else {
                    
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return indexPath.section == 1 && indexPath.row == 1 ? 88 : FontManager.shared.entityCellHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        guard !queueIsBeingEdited else { return 0.001 }
        
        return .textHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    @objc func standardCell(at indexPath: IndexPath) -> MELTableViewCell {
        
        let cell = tableView.regularCell(for: indexPath)
        
        cell.emptyView.isHidden = false
        
        return cell
    }
    
    @objc func songCell(at indexPath: IndexPath, with song: MPMediaItem?) -> SongTableViewCell {
        
        let cell = tableView.songCell(for: indexPath)
        
        if let song = song {
            
            let songNumber: Int? = {
                
                guard let index = Queue.shared.indexToUse, indexPath.section != 1 else { return nil }
                
                if queueIsBeingEdited { return indexPath.row + 1 }
                
                let numberToUse: Int = {
                    
                    if #available(iOS 11.3, *), useSystemPlayer || forceOldStyleQueue, index > limit {
                        
                        return index - (limit - indexPath.row) + 1
                    }
                    
                    return indexPath.row + 1
                }()
                
                return indexPath.section == 0 ? numberToUse : index + 1 + indexPath.row + 1
            }()
            
            cell.prepare(with: song, songNumber: songNumber, hideOptionsView: presented ? true : !showInfoButtons)

            cell.delegate = self
            cell.swipeDelegate = self
            cell.preferredEditingStyle = preferredEditingStyle
            cell.playButton.isUserInteractionEnabled = false

            updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: tableView)
            
            for category in [SecondaryCategory.loved, .plays, .rating, .lastPlayed, .dateAdded, .genre, .year, .fileSize] {
                
                update(category: category, using: song, in: cell, at: indexPath, reusableView: tableView as Any)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        return
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        operations[indexPath]?.cancel()
        
        if indexPath.section == 1, indexPath.row == 1 {
            
            NowPlaying.shared.cell = nil
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        if indexPath.section == 0 {
            
            guard let index = Queue.shared.indexToUse else { return false }
            
            if index == 0 {
                
                return false
            }
            
        } else if indexPath.section == 2 {
            
            guard let index = Queue.shared.indexToUse else { return false }
            
            if (index + 1) == queueCount {
                
                return false
            }
        }
        
        return (indexPath.section == 1 && indexPath.row == 1).inverted
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        guard !presented, let index = Queue.shared.indexToUse else { return false }
        
        if queueIsBeingEdited { return true }
        
        if indexPath.section == 2 {
            
            guard (index + 1) != queueCount else { return false }
            
            return true
            
        } else if indexPath.section == 0 {
            
            guard index != 0 else { return false }
            
            return true
            
        } else {
            
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        if #available(iOS 13, *) {
            
            return true
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        
        guard let _ = Queue.shared.indexToUse else { return false }
        
        if #available(iOS 11.3, *), useSystemPlayer || forceOldStyleQueue { return false }
        
        if queueIsBeingEdited { return true }
        
        return Set([0, 2]).contains(indexPath.section)
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        guard !queueIsBeingEdited else { return proposedDestinationIndexPath }
        
        return Set([0, 2]).contains(proposedDestinationIndexPath.section) ? proposedDestinationIndexPath : sourceIndexPath
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        guard destinationIndexPath != sourceIndexPath, let index = Queue.shared.indexToUse, let relevantItem = getSong(from: sourceIndexPath) else { return }
        
        if !useSystemPlayer, forceOldStyleQueue.inverted, #available(iOS 10.3, *), let musicPlayer = musicPlayer as? MPMusicPlayerApplicationController {
            
            var item: MPMediaItem?
            
            musicPlayer.perform(queueTransaction: { controller in
                
                self.updateLoadingViews(hidden: false)
                
                let itemBefore: MPMediaItem? = {
                    
                    if destinationIndexPath.section == 0 {
                        
                        if destinationIndexPath.row == 0 || index == 0 {
                            
                            return nil
                        }
                        
                        return sourceIndexPath.section == 0 && sourceIndexPath.row < destinationIndexPath.row ? self.queue[destinationIndexPath.row] : self.queue[destinationIndexPath.row - 1]
                        
                    } else {
                        
                        if index == self.queueCount - 1 || destinationIndexPath.row == 0 {
                            
                            return musicPlayer.nowPlayingItem
                        }
                        
                        return sourceIndexPath.section != 0 && sourceIndexPath.row < destinationIndexPath.row ? self.queue[index + 1 + destinationIndexPath.row] : self.queue[index + 1 + destinationIndexPath.row - 1]
                    }
                }()
                
                controller.remove(relevantItem)
                controller.insert(MPMusicPlayerMediaItemQueueDescriptor.init(query: .init(filterPredicates: [.for(.song, using: relevantItem)])), after: itemBefore)
                
                DispatchQueue.main.async { item = itemBefore }
                
            }, completionHandler: { [weak self] controller, error in
                
//                notifier.post(name: .saveQueue, object: musicPlayer, userInfo: [String.queueItems: controller.items])
                
                if let error = error, isInDebugMode {
                    
                    UniversalMethods.banner(withTitle: error.localizedDescription).show(for: 3)
                }
                
//                let indexToRemove = sourceIndexPath.section == 0 ? sourceIndexPath.row : index + 1 + sourceIndexPath.row
//                let indexToAdd: Int = {
//
//                    if destinationIndexPath.section == 0 {
//
//                        if destinationIndexPath.row == 0 || index == 0 {
//
//                            return 0
//                        }
//
//                        return destinationIndexPath.row
//
//                    } else {
//
//                        if index + 1 + destinationIndexPath.row >= Queue.shared.queueCount - 1 {
//
//                            return Queue.shared.currentQueue.endIndex - 1
//                        }
//
//                        return sourceIndexPath.section == 0 ? index + 1 + destinationIndexPath.row - 1 : index + 1 + destinationIndexPath.row
//                    }
//                }()
                
                Queue.shared.remove([relevantItem], completion: .placeAfter(item: item, completion: {
                    
                    if let weakSelf = self {
                        
                        weakSelf.tableView.reloadData()
                    }
                    
                    notifier.post(name: .queueModified, object: nil, userInfo: [.queueChange: true])
                }))

//                Queue.shared.remove(at: indexToRemove, movingTo: indexToAdd, completion: {
//
//                    if let weakSelf = self {
//
//                        weakSelf.tableView.reloadData()
//                    }
//
//                    notifier.post(name: .queueModified, object: nil, userInfo: [.queueChange: true])
//                })
                
                self?.updateLoadingViews(hidden: true)
                
//                weakSelf.queue.remove(at: indexToRemove)
//                weakSelf.queue.insert(relevantItem, at: indexToAdd)
//                weakSelf.tableView.reloadData()
//                notifier.post(name: .queueModified, object: nil, userInfo: [.queueChange: true])
            })
            
            return
        
        } else {
            
            if queueIsBeingEdited {
                
                queue.remove(at: sourceIndexPath.row)
                queue.insert(relevantItem, at: destinationIndexPath.row)
                tableView.reloadData()
                
            } else {
                
                updateLoadingViews(hidden: false)
                
                UniversalMethods.performOnMainThread({ [weak self] in
                    
                    guard let weakSelf = self else { return }
                
                    weakSelf.queueIsBeingEdited = true
                    weakSelf.queue = weakSelf.getQueue()
                    let indexToRemove = sourceIndexPath.section == 0 ? sourceIndexPath.row : index + 1 + sourceIndexPath.row
                    let indexToAdd: Int = {
                        
                        if destinationIndexPath.section == 0 {
                            
                            if destinationIndexPath.row == 0 || index == 0 {
                                
                                return 0
                            }
                            
                            return destinationIndexPath.row
                            
                        } else {
                            
                            if index + 1 + destinationIndexPath.row >= weakSelf.queue.count - 1 {
                                
                                return weakSelf.queue.endIndex - 1
                            }
                            
                            return sourceIndexPath.section == 0 ? index + 1 + destinationIndexPath.row - 1 : index + 1 + destinationIndexPath.row
                        }
                    }()
                    
                    let indexPath = tableView.indexPathsForVisibleRows?.first
                    
                    weakSelf.queue.remove(at: indexToRemove)
                    weakSelf.queue.insert(relevantItem, at: indexToAdd)
                    weakSelf.tableView.reloadData()
                    
                    if let indexPath = indexPath {
                        
                        if indexPath.section == 0 {
                            
                            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            
                        } else if indexPath.section == 2 {
                            
                            tableView.scrollToRow(at: IndexPath.init(row: indexPath.row + 1 + index, section: 0), at: .top, animated: true)
                        }
                    }
                    
                    weakSelf.updateLoadingViews(hidden: true)
                
                }, afterDelay: 0.01)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard !queueIsBeingEdited else { return nil }
        
        if isQueueAvailable, queue.isEmpty { return nil }
        
        let header = tableView.sectionHeader
        
        if section == 0 || (section == 1 && peeker != nil) || section == 2 {
            
            header?.attributor = self
            header?.section = section
            updateAttributedText(for: header, inSection: section)
            
        } else {
            
            header?.attributor = nil
            header?.label.text = "now playing"
            header?.label.attributes = nil
        }
        
        header?.altButton.addTarget(self, action: #selector(viewSections), for: .touchUpInside)
        
        return header
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        return ["P", "N", "U"]
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        guard !tableView.isEditing else { return false }
        
        if touch.location(in: parent?.view).x < 44 {
            
            return false
        
        } else if let indexPath = tableView.indexPathForRow(at: touch.location(in: tableView)), let _ = tableView.cellForRow(at: indexPath) as? PlaybackTableViewCell {
            
            return false
        }
        
        return true
    }
}

extension QueueViewController: Attributor {
    
    @objc func updateAttributedText(for view: TableHeaderView?, inSection section: Int) {
        
        view?.label.updateTheme = false
        view?.label.greyOverride = true
        
        if section == 1 {
            
            let title = "now playing"
            
            let initial: String = {
                
                if let index = Queue.shared.indexToUse {
                    
                    return (index + 1).formatted
                }
                
                return "?"
            }()
            
            let end = queueCount.formatted
            
            let string = initial + " of " + end
            let final = "\(title) (\(string))"
            view?.label.text = final
            
            view?.label.attributes = [
                
                .init(kind: .title, range: final.nsRange(of: initial)),
                .init(kind: .title, range: final.nsRange(of: end))
            ]
            
        } else {
            
            var string = ""
            
            if let index = Queue.shared.indexToUse {
                
                let numberToUse: Int = {
                    
                    if #available(iOS 11.3, *), useSystemPlayer || forceOldStyleQueue {
                        
                        return section == 0 ? min(limit, index) : min(limit, queueCount - (index + 1))
                    }
                    
                    return section == 0 ? index : queueCount - (index + 1)
                }()
                
                string = numberToUse.formatted
                
            } else {
                
                string = "-"
            }
            
            let title = section == 0 ? "previous" : "up next"
            let final = "\(title) (\(string))"
            view?.label.text = final
            view?.label.attributes = [.init(kind: .title, range: final.nsRange(of: string))]
            
            if view?.label.updateTheme == false { view?.label.updateTheme = true }
        }
    }
}

//extension QueueViewController: SongCellButtonDelegate {
//    
//    @objc func showOptionsForSong(in cell: SongTableViewCell) {
//        
//        guard let indexPath = tableView.indexPath(for: cell), let song = getSong(from: indexPath) else { return }
//        
//        Transitioner.shared.showInfo(from: self, with: .song(location: .list, at: 0, within: [song]))
//    }
//}

extension QueueViewController {
    
    override var previewActionItems: [UIPreviewActionItem] {
        
        let clear = UIPreviewAction.init(title: queueCount > 1 ? "Clear Queue" : "Stop Playback", style: .destructive, handler: { [weak self] _, vc in
            
            guard let weakSelf = self else { return }
            
            guard weakSelf.queueCount > 1 else {
                
                weakSelf.peeker? .guardQueue(with: [.stop], onCondition: warnForQueueInterruption && clearGuard, fallBack: NowPlaying.shared.stopPlayback)
                
                return
            }
            
            let clear: (UIViewController) -> () = { vc in
                
                guard let nowPlaying = musicPlayer.nowPlayingItem else { return }
                
                if !useSystemPlayer, forceOldStyleQueue.inverted, #available(iOS 10.3, *), let musicPlayer = musicPlayer as? MPMusicPlayerApplicationController, let index = Queue.shared.indexToUse, let vc = vc as? QueueViewController, vc.queue.filter({ $0 == nowPlaying }).count < 2 {
                    
                    self?.updateLoadingViews(hidden: false)
                    
                    musicPlayer.perform(queueTransaction: { controller in
                        
                        for song in controller.items.enumerated() where song.offset != index {
                            
                            controller.remove(song.element)
                        }
                        
                    }, completionHandler: { controller, error in
                        
                        if let error = error, isInDebugMode {
                            
                            UniversalMethods.banner(withTitle: error.localizedDescription).show(for: 1)
                        }
                        
                        Queue.shared.clearAllButNowPlaying(completion: {
                            
                            notifier.post(name: .queueModified, object: nil, userInfo: [.queueChange: true])
                        })
                        
                        self?.updateLoadingViews(hidden: true)
                        
//                        notifier.post(name: .saveQueue, object: musicPlayer, userInfo: [String.queueItems: controller.items])
//                        notifier.post(name: .queueModified, object: nil)
                        
                        let banner = UniversalMethods.banner(withTitle: "Queue Cleared")
                        banner.titleLabel.font = .myriadPro(ofWeight: .light, size: 25)
                        banner.show(for: 0.5)
                    })
                    
                } else {
                    
                    musicPlayer.play([nowPlaying], startingFrom: nowPlaying, respectingPlaybackState: true, from: nil, withTitle: nil, alertTitle: "")
                }
            }
            
            let action = AlertAction.init(title: "Clear Queue", style: .destructive, handler: { clear(vc) })
            
            weakSelf.peeker?.showAlert(title: nil, with: action)
            
//            weakSelf.peeker?.present(UIAlertController.withTitle(nil, message: nil, style: .actionSheet, actions: action, .cancel()), animated: true, completion: nil)
        })
        
        return [clear]
    }
}

extension QueueViewController: EntityCellDelegate {
    
    func editButtonHeld(in cell: SongTableViewCell) {
        
        Transitioner.shared.performDeepSelection(from: self, title: cell.nameLabel.text)
    }
    
    func editButtonTapped(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        if cell.isSelected {
            
            tableView.deselectRow(at: indexPath, animated: false)
            
        } else {
            
            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    func artworkTapped(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell), indexPath.section != 1 else { return }
        
        cell.setHighlighted(true, animated: true)
        self.tableView(tableView, didSelectRowAt: indexPath)
        cell.setHighlighted(false, animated: true)
    }
    
    func artworkHeld(in cell: SongTableViewCell) {
        
        
    }
    
    func accessoryButtonTapped(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell), let item = getSong(from: indexPath) else { return }
        
        var actions = [SongAction.collect, .info(context: context(from: indexPath)), .queue(name: cell.nameLabel.text, query: nil), .newPlaylist, .addTo].map({ singleItemAlertAction(for: $0, entity: .song, using: item, from: self) })
        
        if item.existsInLibrary.inverted {
            
            actions.insert(singleItemAlertAction(for: .library, entity: .song, using: item, from: self), at: 3)
        }
        
        showAlert(title: cell.nameLabel.text, with: actions)
    }
    
    func accessoryButtonHeld(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell), let action = self.tableView(tableView, editActionsForRowAt: indexPath, for: .right)?.first else { return }
        
        action.handler?(action, indexPath)
    }
    
    func scrollViewTapped(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        if tableView.isEditing, indexPath.section != 1 {
            
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            
        } else {
            
            cell.setHighlighted(true, animated: true)
            self.tableView(self.tableView, didSelectRowAt: indexPath)
            cell.setHighlighted(false, animated: true)
        }
    }
}

extension QueueViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        return TableDelegate.editActions(for: self, orientation: orientation, using: getSong(from: indexPath), at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        
        var options = SwipeTableOptions()
        options.transitionStyle = .drag
        options.expansionStyle = .selection
        
        return options
    }
}
