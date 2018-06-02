//
//  PlaylistViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 07/07/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit
import CoreData
import StoreKit

class PlaylistItemsViewController: UIViewController, FilterContextDiscoverable, AlbumTransitionable, AlbumArtistTransitionable, GenreTransitionable, ComposerTransitionable, ArtistTransitionable, InfoLoading, SongContainer, QueryUpdateable, CellAnimatable, SingleItemActionable, BorderButtonContaining, Refreshable, IndexContaining, EntityVerifiable, TopScrollable {

    @IBOutlet weak var tableView: MELTableView!
    @IBOutlet weak var emptyStackView: UIStackView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var emptySubLabel: UILabel!
    @objc lazy var headerView: HeaderView = {
        
        let view = HeaderView.fresh
        self.actionsStackView = view.actionsStackView
        self.stackView = view.scrollStackView
        view.showTextView = true
        view.showLoved = true
        self.descriptionTextView = view.descriptionTextView
        self.likedImageView = view.likedStateImageView
        
        return view
    }()
    @objc var actionsStackView: UIStackView! {
        
        didSet {
            
            let shuffleView = BorderedButtonView.with(title: .shuffleButtonTitle, image: #imageLiteral(resourceName: "Shuffle13"), action: #selector(shuffle), target: self)
            shuffleButton = shuffleView.button
            self.shuffleView = shuffleView
            
            let arrangeBorderView = BorderedButtonView.with(title: .arrangeButtonTitle, image: #imageLiteral(resourceName: "AscendingLines"), action: #selector(showArranger), target: self)
            arrangeBorderView.borderView.centre(activityIndicator)
            arrangeButton = arrangeBorderView.button
            self.arrangeBorderView = arrangeBorderView
            
            let editView = BorderedButtonView.with(title: .inactiveEditButtonTitle, image: .inactiveEditImage, action: #selector(SongActionManager.toggleEditing(_:)), target: songManager)
            editButton = editView.button
            self.editView = editView
            
            [shuffleView, arrangeBorderView, editView].forEach({ actionsStackView.addArrangedSubview($0) })
        }
    }
    @objc var stackView: UIStackView! {
        
        didSet {
            
            let count = ScrollHeaderSubview.with(title: "Count", image: #imageLiteral(resourceName: "Songs10"), useSmallerImage:  true)
            songCountLabel = count.label
            
            let order = ScrollHeaderSubview.with(title: arrangementLabelText, image: #imageLiteral(resourceName: "Order10"))
            orderLabel = order.label
            
            let duration = ScrollHeaderSubview.with(title: "Duration", image: #imageLiteral(resourceName: "Time10"))
            totalDurationLabel = duration.label
            
            let created = ScrollHeaderSubview.with(title: "Created", image: #imageLiteral(resourceName: "DateAdded"), useSmallerImage: true)
            dateCreatedLabel = created.label
            
            for view in [count, order, duration, created] {
                
                stackView.addArrangedSubview(view)
            }
        }
    }
    
    @objc var totalDurationLabel: MELLabel!
    @objc var dateCreatedLabel: MELLabel!
    @objc var descriptionTextView: MELTextView!
    @objc var activityIndicator = MELActivityIndicatorView.init()
    @objc var arrangeButton: MELButton!
    @objc var editButton: MELButton! {
        
        didSet {
            
            let allHold = UILongPressGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.showActionsForAll(_:)))
            allHold.minimumPressDuration = longPressDuration
            editButton.addGestureRecognizer(allHold)
            LongPressManager.shared.gestureRecognisers.insert(Weak.init(value: allHold))
        }
    }
    @objc var shuffleButton: MELButton!
    @objc var songCountLabel: MELLabel!
    @objc var orderLabel: MELLabel!
    @objc var likedImageView: MELImageView!
    @objc var shuffleView: BorderedButtonView!
    @objc var arrangeBorderView: BorderedButtonView!
    @objc var editView: BorderedButtonView!
    
    var borderedButtons = [BorderedButtonView?]()
    var sectionIndexViewController: SectionIndexViewController?
    let requiresLargerTrailingConstraint = false
    
    @objc lazy var sorter: Sorter = { Sorter.init(operation: self.operation) }()
    
    @objc var actionableSongs: [MPMediaItem] { return filtering ? filteredSongs : songs }
    var applicableActions: [SongAction] { return [SongAction.collect, .info(context: .album(at: 0, within: [])), .queue(name: playlist?.name ??? .untitledPlaylist, query: nil), .newPlaylist, .addTo] }
    @objc lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
    @objc var playlistQuery: MPMediaQuery? { return entityVC?.query }
    @objc var playlist: MPMediaPlaylist? { return playlistQuery?.collections?.first as? MPMediaPlaylist }
    @objc weak var entityVC: EntityItemsViewController? { return parent as? EntityItemsViewController }
    
    @objc lazy var tableDelegate: TableDelegate = { TableDelegate.init(container: self, location: .playlist) }()
    @objc var entities: [MPMediaEntity] { return songs }
    @objc var query: MPMediaQuery? { return albumQuery }
    @objc lazy var filteredEntities = [MPMediaEntity]()
    @objc var highlightedEntity: MPMediaEntity? { return entityVC?.highlightedEntities?.song }
    @objc var cellDelegate: Any { return songDelegate }
    var filterContainer: (UIViewController & FilterContainer)?
    var filterEntities: FilterViewController.FilterEntities { return .songs(songs) }
    var collectionView: UICollectionView?
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var albumQuery: MPMediaQuery?
    @objc var composerQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    
    @objc lazy var songDelegate: SongDelegate = { SongDelegate.init(container: self) }()
    @objc var hasDescriptionText: Bool { return playlist?.descriptionText != nil && playlist?.descriptionText != "" }
    @objc var ascending = true {
        
        didSet {
            
            if let tableView = tableView, let button = arrangeButton {
                
                songs.reverse()
                
                if filtering {
                    
                    filteredEntities.reverse()
                }
                
                sections = prepareSections(from: songs)
                tableView.reloadData()
                animateCells(direction: .vertical)
                updateImage(for: button)
                
                if let playlist = playlist {
                    
                    UniversalMethods.saveSortableItem(withPersistentID: playlist.persistentID, order: ascending, sortCriteria: sortCriteria, kind: SortableKind.playlist)
                }
            }
        }
    }
    lazy var sections = [SortSectionDetails]()
    @objc var songs = [MPMediaItem]()
    @objc var needsUpdating = false
    var highlightedIndex: Int?
    @objc var filteredSongs: [MPMediaItem] { return filteredEntities as! [MPMediaItem] }
    @objc lazy var filtering = false
    var filterText: String?
    var ignorePropertyChange = false
    var entityCount: Int { return songs.count }
    @objc var ignoreKeyboardForInset = true
    @objc lazy var wasFiltering = false
    @objc var backLabelText: String?
    
    var filterProperty: Property = .title {
        
        didSet(oldValue) {
            
            guard ignorePropertyChange.inverted, let filterContainer = filterContainer, filterContainer.filtering, let text = filterContainer.searchBar.text, filterProperty != oldValue else { return }
            
            filterContainer.searchBar?(filterContainer.searchBar, textDidChange: text)
        }
    }
    var propertyTest: PropertyTest = .contains {
        
        didSet(oldValue) {
            
            guard ignorePropertyChange.inverted, let filterContainer = filterContainer, filterContainer.filtering, let text = filterContainer.searchBar.text, propertyTest != oldValue else { return }
            
            filterContainer.searchBar?(filterContainer.searchBar, textDidChange: text)
        }
    }
    var sortCriteria = SortCriteria.standard {
        
        didSet {
            
            if let _ = tableView, let _ = arrangeButton {
                
                sortItems()
                orderLabel.text = arrangementLabelText
                
                if let playlist = playlist {
                    
                    UniversalMethods.saveSortableItem(withPersistentID: playlist.persistentID, order: ascending, sortCriteria: sortCriteria, kind: SortableKind.playlist)
                }
            }
        }
    }
    var location: SortLocation = .playlist
    let applicableSortCriteria: Set<SortCriteria> = [.duration, .title, .artist, .album, .plays, .year, .lastPlayed, .genre, .rating, .dateAdded, .fileSize]
    lazy var applicableFilterProperties: Set<Property> = { self.applicationItemFilterProperties }()
    @objc var transientObservers = Set<NSObject>()
    @objc var lifetimeObservers = Set<NSObject>()
    
    @objc lazy var refresher: Refresher = { Refresher.init(refreshable: self) }()
    
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
        queue.maxConcurrentOperationCount = 3
        
        return queue
    }()
    @objc let imageCache: ImageCache = {
        
        let cache = ImageCache()
        cache.name = "Image Cache"
        cache.countLimit = 500
        
        return cache
    }()
    @objc let sortOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Sort Operation Queue"
        queue.maxConcurrentOperationCount = 3
        
        return queue
    }()
    @objc var operation: BlockOperation?
    @objc var artworkOperation: BlockOperation?
    @objc var filterOperation: BlockOperation?
    @objc var supplementaryOperation: BlockOperation?
    // MARK: - Methods

    override func viewDidLoad() {
        
        super.viewDidLoad()
        prepareLifetimeObservers()
        
        tableView.delegate = tableDelegate
        tableView.dataSource = tableDelegate
        tableView.tableHeaderView = headerView
        
        let refreshControl = MELRefreshControl.init()
        refreshControl.addTarget(refresher, action: #selector(Refresher.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
//        prepareTopArtwork()
        prepareSupplementaryInfo()
        
        UIView.performWithoutAnimation { self.descriptionTextView.layoutIfNeeded() }
        updateHeaderView(withCount: (playlistQuery?.items ?? []).count)
        
        adjustInsets(context: .container)
        
        updateEmptyLabel(withCount: (playlistQuery?.items ?? []).count)
        sortItems()
        updateImage(for: arrangeButton)
        
        prepareGestures()
    }
    
    @objc func prepareSupplementaryInfo() {
        
        supplementaryOperation?.cancel()
        supplementaryOperation = BlockOperation()
        supplementaryOperation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self, let items = weakSelf.playlistQuery?.items else { return }
            
            let songCount = weakSelf.songCount()
            let dateCreated = weakSelf.playlist?.dateCreated.timeIntervalSinceNow.shortStringRepresentation
            let totalDuration = items.map({ $0.playbackDuration }).reduce(0, +).stringRepresentation(as: .short)
            
            let image: UIImage? = {
                
                switch weakSelf.playlist?.likedState {
                    
                    case .some(.liked): return #imageLiteral(resourceName: "Loved")
                    
                    case .some(.disliked): return #imageLiteral(resourceName: "Unloved")
                        
                    case .some(.none): return #imageLiteral(resourceName: "NoLove")
                        
                    default:
                        
                        weakSelf.headerView.showLoved = false
                        return nil
                }
            }()
            
            guard weakSelf.supplementaryOperation?.isCancelled == false else { return }
            
            OperationQueue.main.addOperation({
            
                weakSelf.dateCreatedLabel.text = dateCreated
                weakSelf.songCountLabel.text = songCount
                weakSelf.totalDurationLabel.text = totalDuration
                weakSelf.likedImageView.image = image
            })
        })
        
        sortOperationQueue.addOperation(supplementaryOperation!)
    }
    
    @objc func updateHeaderView(withCount count: Int) {
        
        let descriptionHeight: CGFloat = {
            
            if hasDescriptionText {
                
                if prepareDescriptionText() {
                    
                    descriptionTextView.textContainerInset.top = 10
                    descriptionTextView.textContainerInset.bottom = -4
                }
                
                return descriptionTextView.intrinsicContentSize.height
                
            } else {
                
                return 0
            }
        }()
        
        shuffleButton.superview?.isHidden = count < 2
        tableView.tableHeaderView?.frame.size.height = 92 + descriptionHeight
        tableView.tableHeaderView = headerView
        
        var array = [shuffleView, arrangeBorderView, editView]
        
        if count < 2 {
            
            array.remove(at: 0)
        }
        
        borderedButtons = array
        
        updateButtons()
    }
    
    @objc @discardableResult func prepareDescriptionText() -> Bool {
        
        guard let text = playlist?.descriptionText else { return false }
        
        let style = NSMutableParagraphStyle.init()
        style.lineHeightMultiple = 1.15
        
        let attributed = NSAttributedString.init(string: text, attributes: [
            
            .paragraphStyle: style,
            .font: UIFont.myriadPro(ofWeight: .regular, size: 15),
            .foregroundColor: Themer.textColour(for: .title)
        ])
        
        descriptionTextView.attributedText = attributed
        
        return true
    }
    
    func updateEmptyView(forState state: EmptyViewState, subLabelText: String?) {
        
        switch state {
            
            case .completelyHidden: emptyStackView.isHidden = true
                
            case .subLabelHidden:
                
                emptyStackView.isHidden = false
                emptySubLabel.isHidden = true
                
            case .completelyVisible:
                
                emptyStackView.isHidden = false
                emptySubLabel.isHidden = false
                emptySubLabel.attributedText = NSAttributedString.init(string: subLabelText ?? "")
        }
    }
    
    @objc func updateEmptyLabel(withCount count: Int) {
        
        if count < 1 {
            
            let text: String = {
                
                guard showiCloudItems else { return "No offline songs in this playlist" }
                
                if playlist?.playlistAttributes == .genius {
                    
                    return "Nothing in your library fits with the song this playlist is based on"
                    
                } else if playlist?.playlistAttributes == .smart {
                    
                    return "No songs match your smart playlist criteria"
                    
                } else {
                    
                    return "You can add songs by tapping the artwork above"
                }
            }()
            
            updateEmptyView(forState: .completelyVisible, subLabelText: text)
            
        } else {
            
            updateEmptyView(forState: .completelyHidden, subLabelText: nil)
        }
    }
    
    @objc func showOptions(_ sender: Any) {

        tableDelegate.showOptions(sender)
    }
    
    @objc func showArranger() {
        
        performSegue(withIdentifier: "toArranger", sender: nil)
    }
    
    @objc func prepareGestures() {
        
        let swipeRight = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeRight.direction = .right
        tableView.addGestureRecognizer(swipeRight)

        let swipeLeft = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeLeft.direction = .left
        tableView.addGestureRecognizer(swipeLeft)
        
        let optionsHold = UILongPressGestureRecognizer.init(target: tableDelegate, action: #selector(TableDelegate.showOptions(_:)))
        optionsHold.minimumPressDuration = longPressDuration
        optionsHold.delegate = self
        tableView.addGestureRecognizer(optionsHold)
        LongPressManager.shared.gestureRecognisers.insert(Weak.init(value: optionsHold))
    }
    
    @objc func showFilteredContext(_ sender: Any) {
        
        guard let indexPath: IndexPath = {
            
            if let gr = sender as? UIGestureRecognizer {
                
                guard gr.state == .began else { return nil }
                
                return tableView.indexPathForRow(at: gr.location(in: tableView))
            }
            
            return sender as? IndexPath
            
        }() else { return }
        
        let song = getSong(from: indexPath, filtering: true)
        
        entityVC?.highlightedEntities?.song = song
        highlightedIndex = songs.index(of: song)
        scrollToHighlightedRow()
    }
    
    @objc func clearSavedPlaylists(_ gr: UILongPressGestureRecognizer) {
        
        if gr.state == .began {
            
            let reset = UIAlertAction.init(title: "Reset", style: .destructive, handler: { _ in UniversalMethods.deleteSortableItems() })
            
            present(UniversalMethods.alertController(withTitle: "Remove Sortable Entities?", message: "This will remove all sorted entities, reverting them to their default orders", preferredStyle: .alert, actions: reset, UniversalMethods.cancelAlertAction()), animated: true, completion: nil)
        }
    }
    
    @objc func songCount() -> String {
        
        if filtering {
            
            let initial = filteredSongs.count.formatted
            
            let end = (playlistQuery?.items ?? []).count.formatted
            
            return initial + " of " + end
            
        } else {
        
            return (playlistQuery?.items ?? []).count.formatted
        }
    }
    
    /*func prepareTopArtwork() {
        
        guard let items = playlistQuery?.items, !items.isEmpty else {
            
            artwork = nil
            
            return
        }
        
        artworkOperation?.cancel()
        artworkOperation = BlockOperation()
        artworkOperation?.addExecutionBlock { [weak artworkOperation, weak self] in
            
            guard let weakSelf = self, let operation = artworkOperation, !operation.isCancelled else { return }
            
            var art = [MPMediaItem]()
            
            for item in items.shuffled() where art.count < 4 {
                
                guard !operation.isCancelled else { break }
                
                if let album = item.albumTitle, album != "", let artwork = item.artwork, artwork.bounds.width != 0, !Set(art.map({ $0.albumTitle! })).contains(album) {
                    
                    art.append(item)
                }
            }
            
            OperationQueue.main.addOperation({
                
                guard !operation.isCancelled else { return }
                
                let width = weakSelf.imageViewsContainer.frame.width / 2
                let artwork = art.map({ $0.artwork!.image(at: CGSize(width: width, height: width))! })
            
                if artwork.isEmpty {
                    
                    guard !operation.isCancelled else { return }
                    
                    weakSelf.artworkView.image = #imageLiteral(resourceName: "BackgroundLightBlurred")
                    weakSelf.artwork = #imageLiteral(resourceName: "NoArt")
                    
                } else if artwork.count < 4 {
                    
                    guard !operation.isCancelled else { return }
                    
                    weakSelf.artworkView.image = artwork.first
                    weakSelf.artwork = artwork.shuffled().first?.at(.init(width: 20, height: 20))
                    
                } else {
                    
                    guard !operation.isCancelled else { return }
                    
                    let image = UIImage.collage(ofSize: CGSize.init(width: weakSelf.artworkView.frame.width * 2, height: weakSelf.artworkView.frame.height * 2), withImages: artwork)
                    weakSelf.artworkView.image = image
                    weakSelf.artwork = artwork.shuffled().first?.at(.init(width: 20, height: 20))
                }
            })
        }
        
        sortOperationQueue.addOperation(artworkOperation!)
    }*/
    
    func adjustInsets(context: InsetContext) {
        
        switch context {
            
        case .filter(let inset):
            
            tableView.scrollIndicatorInsets.bottom = inset
            tableView.contentInset.bottom = inset
            
        case .container:
            
            if let container = appDelegate.window?.rootViewController as? ContainerViewController, ignoreKeyboardForInset {
                
                tableView.scrollIndicatorInsets.bottom = container.inset
                tableView.contentInset.bottom = container.inset
            }
        }
    }
    
    @objc func handleRightSwipe(_ sender: Any) {
        
        songManager.updateAddView(editing: true)
        tableView.setEditing(true, animated: true)
    }
    
    @objc func handleLeftSwipe(_ sender: Any) {
        
        if tableView.isEditing {
            
            songManager.updateAddView(editing: false)
            
            tableView.setEditing(false, animated: true)
        
        } else {
            
            guard let gr = sender as? UISwipeGestureRecognizer, let indexPath = tableView.indexPathForRow(at: gr.location(in: tableView)) else { return }
            
            let song = getSong(from: indexPath)
            
            let filterPredicates: Set<MPMediaPropertyPredicate> = showiCloudItems ? [.for(.album, using: song.albumPersistentID)] : [.for(.album, using: song.albumPersistentID), .offline]
            
            let query = MPMediaQuery.init(filterPredicates: filterPredicates)
            query.groupingType = .album
            
            if let collections = query.collections, !collections.isEmpty {
                
                albumQuery = query
                currentItem = song
                
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
    
    @objc func prepareTransientObservers() {
        
        transientObservers.insert(notifier.addObserver(forName: .performSecondaryAction, object: navigationController, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self, weakSelf.songs.count > 1 else { return }
  
            weakSelf.invokeSearch()
        
        }) as! NSObject)
        
        transientObservers.insert(notifier.addObserver(forName: .endQueueModification, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.tableView.isEditing { weakSelf.songManager.toggleEditing(notification) }
        
        }) as! NSObject)
        
        transientObservers.insert(notifier.addObserver(forName: .songWasEdited, object: self, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let indexPath = notification.userInfo?["indexPath"] as? IndexPath else { return }
            
            weakSelf.tableView.reloadRows(at: [indexPath], with: .none)
        
        }) as! NSObject)
    }
    
    @objc func prepareLifetimeObservers() {
        
        lifetimeObservers.insert(notifier.addObserver(forName: .resetInsets, object: nil, queue: nil, using: { [weak self] _ in self?.adjustInsets(context: .container) }) as! NSObject)
        
        notifier.addObserver(self, selector: #selector(prepareDescriptionText), name: .themeChanged, object: nil)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.tableView.reloadData()
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .songAddedToPlaylist, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let id = notification.userInfo?["playlist"] as? MPMediaEntityPersistentID, id == weakSelf.playlist?.persistentID else { return }
            
            if let query = weakSelf.getCurrentQuery() {
                
                weakSelf.entityVC?.query = query
            }
            
            weakSelf.sortItems()
            
        }) as! NSObject)
        
        lifetimeObservers.insert((notifier.addObserver(forName: .libraryUpdated, object: appDelegate, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateWithQuery()
            
        })) as! NSObject)
    }
    
    @objc func getCurrentQuery() -> MPMediaQuery? {
        
        guard let playlist = playlist else { return nil }
        
        let query = MPMediaQuery.init(filterPredicates: [.for(.playlist, using: playlist)])
        
        if !showiCloudItems {
            
            query.addFilterPredicate(.offline)
        }
        
        query.groupingType = .playlist
        
        guard !(query.items ?? []).isEmpty else { return nil }
        
        return query
    }
    
    @objc func verifyValidityInLibrary() -> MPMediaQuery? {
        
        guard let playlist = playlist else { return nil }
        
        let query = MPMediaQuery.init(filterPredicates: [.for(.playlist, using: playlist)])
        query.groupingType = .playlist
        
        guard !(query.collections ?? []).isEmpty else { return nil }
        
        return query
    }
    
    @objc func updateWithQuery() {
        
        needsUpdating = false
        
        prepareSupplementaryInfo()
//        prepareTopArtwork()
        sortItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        for cell in tableView.visibleCells {
            
            if let cell = cell as? SongTableViewCell, !cell.playingView.isHidden {
                
                cell.indicator.state = musicPlayer.isPlaying ? .playing : .paused
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
//        if artworkSet, peeker == nil {
//            
//            container?.currentModifier = self
//            
//            if container?.deferToNowPlayingViewController == false, !nowPlayingAsBackground {
//                
//                if let _ = artwork {
//                    
//                    container?.shouldUseNowPlayingArt = false
//                    container?.updateBackgroundViaModifier()
//                    
//                } else {
//                    
//                    container?.shouldUseNowPlayingArt = true
//                    container?.updateBackgroundWithNowPlaying()
//                }
//            }
//        }
        
        prepareTransientObservers()
        
        if needsUpdating {
            
            if let vc = presentedViewController {
                
                vc.dismiss(animated: false, completion: nil)
            }
            
            let banner = Banner.init(title: "This playlist has no offline songs", subtitle: nil, image: nil, backgroundColor: .orange, didTapBlock: nil)
            banner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
            banner.show(view, duration: 1.5)
            
            sortItems()
        }
        
        if wasFiltering {
            
            invokeSearch()
            wasFiltering = false
        }
        
        entityVC?.setCurrentOptions()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        notifier.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notifier.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        unregisterAll(from: transientObservers)
    }
    
    @objc func getSong(inSection section: Int, row: Int, filtering: Bool = false) -> MPMediaItem {
        
        if filtering {
            
            return filteredSongs[row]
            
        } else {
            
            switch sortCriteria {
                
                case .standard, .random: return songs[row]
                    
                default: return songs[sections[section].startingPoint + row]
            }
        }
    }
    
    @objc func getSong(from indexPath: IndexPath, filtering: Bool = false) -> MPMediaItem {
        
        return getSong(inSection: indexPath.section, row: indexPath.row, filtering: filtering)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        imageCache.removeAllObjects()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier else { return }
        
        switch id {
            
            case "toArranger": Transitioner.shared.transition(to: segue.destination, from: self)
            
            default: break
        }
    }
    
    @IBAction func shuffle() {
        
        let songs = playlistQuery?.items ?? self.songs
        let canShuffleAlbums = songs.canShuffleAlbums
        
        if canShuffleAlbums {
            
            var array = [UIAlertAction]()
            
            let shuffle = UIAlertAction.init(title: .shuffle(.songs), style: .default, handler: { _ in
                
                musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: self.playlist?.name ??? "Untitled Playlist", alertTitle: .shuffle(.songs), queueGuardCriteria: false)
            })
            
            array.append(shuffle)
            
            let shuffleAlbums = UIAlertAction.init(title: .shuffle(.albums), style: .default, handler: { _ in
                
                musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: self, withTitle: self.playlist?.name ??? "Untitled Playlist", alertTitle: .shuffle(.albums), queueGuardCriteria: false)
            })
            
            array.append(shuffleAlbums)
            
            present(UIAlertController.withTitle(nil, message: entityVC?.titleLabel.text, style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
            
        } else {
            
            musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: playlist?.name ??? "Untitled Playlist", alertTitle: .shuffle())
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "PIVC going away...").show(for: 0.3)
        }
        
        notifier.removeObserver(self)
        
        unregisterAll(from: lifetimeObservers)
        
        sortOperationQueue.cancelAllOperations()
        operation?.cancel()
        artworkOperation?.cancel()
        filterOperation?.cancel()
    }
}

extension PlaylistItemsViewController: TableViewContainer {
    
    @objc func selectCell(in tableView: UITableView, at indexPath: IndexPath, filtering: Bool) {
        
        let song: MPMediaItem = getSong(from: indexPath, filtering: filtering)
        
        musicPlayer.play(filtering ? filteredSongs : songs, startingFrom: song, from: filterContainer ?? self, withTitle: playlist?.name ??? .untitledPlaylist, subtitle: "Starting from \(song.validTitle)", alertTitle: "Play", completion: { [weak self] in
            
            guard let weakSelf = self, filtering, let container = weakSelf.filterContainer else { return }
            
            container.saveRecentSearch(withTitle: container.searchBar.text, resignFirstResponder: false)
        })
    }
    
    @objc func getEntity(at indexPath: IndexPath, filtering: Bool = false) -> MPMediaEntity {
        
        return getSong(from: indexPath, filtering: filtering)
    }
}

extension PlaylistItemsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if filtering {
            
            return filteredSongs.count
            
        } else {
            
            switch sortCriteria {
                
                case .standard, .random: return songs.count
                    
                default: return sections[section].count
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if filtering {
            
            return 1
            
        } else {
            
            switch sortCriteria {
                
                case .standard, .random: return 1
                    
                default: return sections.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        operations[indexPath]?.cancel()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.songCell(for: indexPath)
        let song = getSong(from: indexPath)
        
//        cell.delegate = songDelegate
//        cell.scrollDelegate = songDelegate
        cell.prepare(with: song, highlightedSong: entityVC?.highlightedEntities?.song)
        updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: tableView)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing {
            
            self.tableView(tableView, commit: self.tableView(tableView, editingStyleForRowAt: indexPath), forRowAt: indexPath)
            
        } else {
            
            let song: MPMediaItem = getSong(from: indexPath)
            
            musicPlayer.play(filtering ? filteredSongs : songs, startingFrom: song, from: self, withTitle: playlist?.name ??? "Unnamed Playlist", subtitle: "Starting from \(song.validTitle)", alertTitle: "Play")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard !songs.isEmpty else { return nil }
        
        let header = tableView.sectionHeader
        
        if filtering {
            
            header?.label.text = nil
            
        } else {
            
            switch sortCriteria {
                
                case .standard, .random: header?.label.text = nil
                    
                default: header?.label.text = sections[section].title.uppercased()
            }
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if filtering {
            
            return 11
            
        } else {
            
            switch sortCriteria {
                
            case .standard, .random: return 11
                
            default:
        
                let height = ("eh" as NSString).boundingRect(with: CGSize(width: 100, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.myriadPro(ofWeight: .light, size: 20)], context: nil).height
                
                return height + 24
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        return .insert
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        guard !filtering else { return nil }
        
        guard sections.count > 1 else { return nil }
        
        switch sortCriteria {
            
            case .standard, .random: return nil
            
            default: return sections.map({ $0.indexTitle })
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .insert {
            
            let song: MPMediaItem = getSong(from: indexPath)
            
            notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: [song]])
        }
    }
}

extension PlaylistItemsViewController: Arrangeable {
    
    @objc func sortItems() {
        
        arrangeButton.alpha = 0
        activityIndicator.startAnimating()
        
        let mainBlock: ([MPMediaItem], [SortSectionDetails]) -> () = { [weak self] array, details in

            guard let weakSelf = self, weakSelf.operation?.isCancelled == false else {

                self?.activityIndicator.stopAnimating()
                self?.arrangeButton.alpha = 1

                return
            }

            weakSelf.songs = array
            weakSelf.sections = details
            weakSelf.activityIndicator.stopAnimating()
            weakSelf.arrangeButton.alpha = 1
            weakSelf.updateEmptyLabel(withCount: weakSelf.songs.count)
            weakSelf.updateHeaderView(withCount: weakSelf.songs.count)
            weakSelf.tableView.reloadData()

            if weakSelf.filtering, let filterContainer = weakSelf.filterContainer, let text = filterContainer.searchBar?.text {
                
                filterContainer.searchBar?(filterContainer.searchBar, textDidChange: text)

            } else {

                if weakSelf.entityVC?.peeker == nil {

                    weakSelf.animateCells(direction: .vertical)
                }

                weakSelf.scrollToHighlightedRow()
            }
        }
        
        operation?.cancel()
        operation = BlockOperation()
        operation?.addExecutionBlock({ [weak operation, weak self] in
            
            guard let weakSelf = self, let weakOperation = operation, !weakOperation.isCancelled, let items = weakSelf.playlistQuery?.items, !items.isEmpty else {
                
                OperationQueue.main.addOperation { [weak self] in
                    
                    self?.activityIndicator.stopAnimating()
                    self?.arrangeButton.alpha = 1
                    
                    guard (self?.playlistQuery?.items ?? []).isEmpty else { return }
                    
                    self?.updateEmptyLabel(withCount: 0)
                    self?.songs = []
                    self?.tableView.reloadData()
                    self?.updateHeaderView(withCount: 0)
                }
                
                return
            }
            
            let array: [MPMediaItem] = {
                
                switch weakSelf.sortCriteria {
                    
                    case .standard: return weakSelf.ascending ? items : items.reversed()
                    
                    case .random: return items.shuffled()
                    
                    default: return (items as NSArray).sortedArray(using: weakSelf.sortDescriptors) as! [MPMediaItem]
                }
            }()
            
            if let song = weakSelf.entityVC?.highlightedEntities?.song {
                
                weakSelf.highlightedIndex = array.index(of: song)
            }
            
            guard !weakOperation.isCancelled else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    self?.arrangeButton.alpha = 1
                }
                
                return
            }
            
            let details = weakSelf.prepareSections(from: array)
            
            OperationQueue.main.addOperation({

                guard weakSelf.operation?.isCancelled == false else {

                    weakSelf.activityIndicator.stopAnimating()
                    weakSelf.arrangeButton.alpha = 1

                    return
                }

                mainBlock(array, details)
            })
        })
        
        sortOperationQueue.addOperation(operation!)
    }
}

extension PlaylistItemsViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if touch.view?.isDescendant(of: headerView) == true {
            
            return false
        }
        
        return true
    }
}
