//
//  CollectionsViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 18/11/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class CollectionsViewController: UIViewController, InfoLoading, AlbumTransitionable, ArtistTransitionable, AlbumArtistTransitionable, GenreTransitionable, PlaylistTransitionable, ComposerTransitionable, FilterContextDiscoverable, CellAnimatable, EntityContainer, BorderButtonContaining, Refreshable, QueryUpdateable, IndexContaining, LibrarySectionContainer, EntityVerifiable, TopScrollable {
    
    @IBOutlet weak var tableView: MELTableView!
    @IBOutlet weak var bottomViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var actionsButton: MELButton!  {
        
        didSet {
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(showSettings(with:)))
            gr.minimumPressDuration = longPressDuration
            actionsButton.addGestureRecognizer(gr)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        }
    }
    
    enum PlaylistSection: Int { case recent, smart, genius, regular }
    
    @objc lazy var headerView: HeaderView = {
        
        let view = HeaderView.fresh
        self.actionsStackView = view.actionsStackView
        self.stackView = view.scrollStackView
        
        view.showRecents = self.showRecents
        
        if collectionKind == .playlist {
            
            view.tableHeaderContainer.isHidden = true
            
        } else {
            
            view.collectionView.isHidden = true
            view.context = {
                
                switch collectionKind {
                    
                    case .playlist: return .playlists([])
                    
                    case .album, .compilation: return .albums([])
                    
                    default: return .collections(kind: collectionKind.albumBasedCollectionKind, [])
                }
            }()
        }
        
        self.collectionView = view.collectionView
        view.viewController = self
        view.header.button.addTarget(self, action: #selector(backToStart), for: .touchUpInside)
        view.header.altButton.addTarget(isInDebugMode ? self : self.tableDelegate, action: isInDebugMode ? #selector(backToStart) : #selector(tableDelegate.viewSections), for: .touchUpInside)
        
        return view
    }()
    @objc var actionsStackView: UIStackView! {
        
        didSet {
            
            let shuffleView = collectionKind == .playlist ? BorderedButtonView.with(title: "New", image: #imageLiteral(resourceName: "AddNoBorderSmall"), action: #selector(showNewPlaylist), target: self) : BorderedButtonView.with(title: .shuffleButtonTitle, image: #imageLiteral(resourceName: "Shuffle13"), action: #selector(shuffle), target: self)
            shuffleButton = shuffleView.button
            self.shuffleView = shuffleView
            
            let arrangeBorderView = BorderedButtonView.with(title: .arrangeButtonTitle, image: #imageLiteral(resourceName: "AscendingLines"), action: #selector(showArranger), target: self)
            arrangeBorderView.borderView.centre(activityIndicator)
            arrangeButton = arrangeBorderView.button
            self.arrangeBorderView = arrangeBorderView
            
            let editView: BorderedButtonView? = {
                
                guard !presented else { return nil }
                
                let editView = BorderedButtonView.with(title: .inactiveEditButtonTitle, image: .inactiveEditImage, action: #selector(SongActionManager.toggleEditing(_:)), target: songManager)
                editView.borderView.centre(actionableActivityIndicator)
                editButton = editView.button
                self.editView = editView
                
                return editView
            }()
            
            [shuffleView, arrangeBorderView, editView].compactMap({ $0 }).forEach({ actionsStackView.addArrangedSubview($0) })
        }
    }
    
    @objc var stackView: UIStackView! {
        
        didSet {
            
            let order = ScrollHeaderSubview.with(title: arrangementLabelText, image: #imageLiteral(resourceName: "Order10"))
            orderLabel = order.label
            
            stackView.addArrangedSubview(order)
            
            if collectionKind == .playlist {
                
                let view = ScrollHeaderSubview.with(title: playlistsViewText, image: #imageLiteral(resourceName: "List"))
                playlistViewLabel = view.label
                
                stackView.addArrangedSubview(view)
            }
        }
    }
    
    @objc var playlistsViewText: String {
        
        switch currentPlaylistsView {
            
            case .all: return "All Playlists"
                
            case .appleMusic: return "Apple Music Playlists"
                
            case .user: return "My Playlists"
        }
    }
    
    @objc var orderLabel: MELLabel!
    @objc var activityIndicator = MELActivityIndicatorView.init()
    @objc var actionableActivityIndicator = MELActivityIndicatorView.init()
    var shouldFillActionableSongs = false
    var showActionsAfterFilling = false
    var collectionsCount: Int { return filterContainer?.filtering == true ? filteredCollections.count : collections.count }
    @objc var arrangeButton: MELButton!
    @objc var editButton: MELButton! {
        
        didSet {
            
            let allHold = UILongPressGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.showActionsForAll(_:)))
            allHold.minimumPressDuration = longPressDuration
            editButton.addGestureRecognizer(allHold)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: allHold))
        }
    }
    @objc var shuffleButton: MELButton!
    @objc var shuffleView: BorderedButtonView!
    @objc var arrangeBorderView: BorderedButtonView!
    @objc var editView: BorderedButtonView?
    @objc var playlistViewLabel: MELLabel!
    
    var borderedButtons = [BorderedButtonView?]()
    var currentPlaylistsView: PlaylistView { return presented ? .user : PlaylistView(rawValue: playlistsView) ?? .all }
    var presentedPlaylistsView: PlaylistView?
    @objc var presentedEmptyPlaylists = true
    @objc var onlineOverride = false
    
    @objc var actionableSongs: [MPMediaItem] { return songs }
    var songs = [MPMediaItem]()
    let applicableActions = [SongAction.collect, .info(context: .album(at: 0, within: [])), .newPlaylist, .addTo]
    @objc lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
    @objc lazy var refresher: Refresher = { Refresher.init(refreshable: self) }()
    @objc lazy var sorter: Sorter = { Sorter.init(operation: self.operation) }()
    @objc lazy var tableDelegate: TableDelegate = { TableDelegate.init(container: self, location: .collections(kind: self.collectionKind)) }()
    @objc var entities: [MPMediaEntity] { return collections }
    @objc lazy var filteredEntities = [MPMediaEntity]()
    @objc var query: MPMediaQuery? { return collectionsQuery }
    @objc var highlightedEntity: MPMediaEntity?
    var filterContainer: (UIViewController & FilterContainer)?
    var filterEntities: FilterViewController.FilterEntities { return .collections(collectionKind == .playlist ? collections.filter({ ($0 as? MPMediaPlaylist)?.isFolder.inverted ?? true }) : collections, kind: collectionKind) }
    var ignorePropertyChange = false
    var highlightedIndex: Int?
    @objc var cellDelegate: Any { return self }

    lazy var selectedPlaylists = [MPMediaPlaylist]()
    
    var showRecents: Bool {
        
        switch self.collectionKind {
            
            case .album: return showRecentAlbums
            
            case .artist, .albumArtist: return showRecentArtists
            
            case .compilation: return showRecentCompilations
            
            case .composer: return showRecentComposers
            
            case .genre: return showRecentGenres
            
            case .playlist: return showRecentPlaylists
        }
    }
    
    @objc var collectionView: UICollectionView?
    var sectionIndexViewController: SectionIndexViewController?
    var navigatable: Navigatable? { return libraryVC }
    var requiresLargerTrailingConstraint: Bool { return presented }
    
    @objc var collections = [MPMediaItemCollection]()
    @objc var filteredCollections: [MPMediaItemCollection] { return filteredEntities as! [MPMediaItemCollection] }
    lazy var sections = [SortSectionDetails]()
    
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var currentItem: MPMediaItem?
    @objc var albumQuery: MPMediaQuery?
    @objc var composerQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    @objc var playlistQuery: MPMediaQuery?
    
    var collectionKind = CollectionsKind.artist
    @objc weak var libraryVC: LibraryViewController? { return parent as? LibraryViewController }
    @objc var type: String {
        
        switch collectionKind {
            
            case .album: return "Albums"
                
            case .artist, .albumArtist: return "Artists"
                
            case .compilation: return "Compilations"
                
            case .composer: return "Composers"
                
            case .genre: return "Genres"
            
            case .playlist: return "Playlists"
        }
    }
    var settingsKeys: (criteria: String, order: String, sortPreference: Int, orderPreference: Bool) {
        
        switch collectionKind {
            
            case .album: return (.albumsSort, .albumsOrder, albumsCriteria, albumsOrder)
                
            case .artist, .albumArtist: return (.artistsSort, .artistsOrder, artistsCriteria, artistsOrder)
                
            case .compilation: return (.compilationsSort, .compilationsOrder, compilationsCriteria, compilationsOrder)
                
            case .composer: return (.composersSort, .composersOrder, composersCriteria, composersOrder)
                
            case .genre: return (.genresSort, .genresOrder, genresCriteria, genresOrder)
            
            case .playlist: return (.playlistsSort, .playlistsOrder, playlistsCriteria, playlistsOrder)
        }
    }
    
    var sortCriteria: SortCriteria {
        
        get { return SortCriteria(rawValue: settingsKeys.sortPreference) ?? .standard }
        
        set(criteria) {
            
            if let _ = tableView, let label = orderLabel {
                
                prefs.set(criteria.rawValue, forKey: settingsKeys.criteria)
                sortItems()
                label.text = arrangementLabelText
            }
        }
    }
    
    @objc var ascending: Bool {
        
        get { return settingsKeys.orderPreference }
        
        set(order) {
            
            if let tableView = tableView, let button = arrangeButton {
                
                activityIndicator.startAnimating()
                button.alpha = 0
                
                collections.reverse()
                
                if filtering {
                    
                    filteredEntities.reverse()
                }
                
                prefs.set(order, forKey: settingsKeys.order)
                sections = {
                    
                    if collectionKind == .playlist, let playlists = collections as? [MPMediaPlaylist] {
                        
                        if showPlaylistFolders {
                            
                            let reduced = playlists.foldersConsidered.map({ $0.reduced })
                            
                            tableDelegate.playlistContainers = reduced.reduce([], { $0 + $1.containers })
                            collections = reduced.reduce([], { $0 + $1.dataSource })
                            
                            return prepareSections(from: reduced.reduce([], { $0 + $1.arrangeable }))
                        }
                        
                        return prepareSections(from: playlists)
                    }
                    
                    return prepareSections(from: collections)
                }()
                
                tableView.reloadData()
                animateCells(direction: .vertical)
                updateImage(for: button)
                activityIndicator.stopAnimating()
                button.alpha = 1
            }
        }
    }
    
    var applicableSortCriteria: Set<SortCriteria> {
        
        let set: Set<SortCriteria> = [.album, .duration, .year, .genre, .artist, .plays, .dateAdded, .fileSize, .songCount, .albumCount, .title]
        
        switch collectionKind {
            
            case .album: return set.subtracting([.albumCount])
            
            case .compilation: return set.subtracting([.albumCount, .artist])
            
            case .artist, .albumArtist: return set.subtracting([.year, .genre, .title])
            
            case .genre, .composer: return set.subtracting([.year, .genre, .artist, .album])
            
            case .playlist: return set.subtracting([.album, .year, .genre, .artist, .albumCount])
        }
    }
    var location: SortLocation { return collectionKind == .playlist ? .playlistList : .collections }
    
    @objc lazy var collectionsQuery: MPMediaQuery = { self.getCurrentQuery() }()
    @objc lazy var recentsQuery: MPMediaQuery? = { self.getRecentsQuery() }()
    
    @objc var presented = false
    @objc var itemsToAdd = [MPMediaItem]()
    @objc var fromQueue = false
    var manager: QueueManager?
    @objc lazy var filtering = false
    var filterText: String?
    var entityCount: Int { return collections.count }
    lazy var applicableFilterProperties: Set<Property> = {
        
        let propertiesToRemove: Set<Property> = {
            
            switch self.collectionKind {
                
                case .album: return [.artwork, .albumCount]
                
                case .compilation: return [.artwork, .albumCount, .isCompilation]
                
                case .playlist: return [.artist, .genre, .isCompilation, .year]
                
                case .artist, .albumArtist, .composer, .genre: return [.artist, .genre, .artwork, .isCompilation, .year, .status]
            }
        }()
        
        return applicableCollectionFilterProperties.subtracting(propertiesToRemove)
    }()
    @objc var ignoreKeyboardForInset = true
    @objc lazy var wasFiltering = false
    
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
    @objc var lifetimeObservers = Set<NSObject>()
    @objc var transientObservers = Set<NSObject>()
    @objc lazy var artworkOperationQueue: OperationQueue = {
        
        let queue = OperationQueue.init()
        queue.name = "Artwork Operation Queue"
        
        
        return queue
    }()
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
    let actionableQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Actionable Operation Queue"
        
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
        
        
        return queue
    }()
    @objc var filterOperation: BlockOperation?
    @objc var operation: BlockOperation?
    var recentOperation: BlockOperation?
    var actionableOperation: BlockOperation?
    lazy var playlistsLoaded = false

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        onlineOverride = presented
        
        if !presented {
            
            adjustInsets(context: .container)
            
            tableView.contentInset.top = libraryVC?.inset ?? 0
            tableView.scrollIndicatorInsets.top = libraryVC?.inset ?? 0
            
        } else {
            
            bottomView.isHidden = false
            bottomViewHeightConstraint.constant = 44
            tableView.allowsMultipleSelection = true
        }
        
        prepareLifetimeObservers()
            
        updateTopLabels()
        
        tableView.delegate = tableDelegate
        tableView.dataSource = tableDelegate
        tableView.tableFooterView = UIView.init(frame: .zero)
        tableView.tableHeaderView = headerView
        
        let refreshControl = MELRefreshControl.init()
        refreshControl.addTarget(refresher, action: #selector(Refresher.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        updateHeaderView(withCount: collectionKind == .playlist ? 0 : (collectionsQuery.items ?? []).count)
        
        sortItems()
        
        prepareGestures()
        
        registerForPreviewing(with: self, sourceView: tableView)
        updateImage(for: arrangeButton)
    }
    
    @objc func prepareGestures() {
        
        if !presented {
            
            let swipeRight = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
            swipeRight.direction = .right
            tableView.addGestureRecognizer(swipeRight)
            
            let swipeLeft = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
            swipeLeft.direction = .left
            tableView.addGestureRecognizer(swipeLeft)
            
            let hold = UILongPressGestureRecognizer.init(target: tableDelegate, action: #selector(TableDelegate.showOptions(_:)))
            hold.minimumPressDuration = longPressDuration
            tableView.addGestureRecognizer(hold)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        }
    }
    
    @objc func showFilteredContext(_ sender: Any) {
        
        guard let indexPath: IndexPath = {
            
            if let gr = sender as? UIGestureRecognizer {
                
                guard gr.state == .began else { return nil }
                
                return tableView.indexPathForRow(at: gr.location(in: tableView))
            }
            
            return sender as? IndexPath
            
        }() else { return }
        
        let collection = getCollection(from: indexPath, filtering: true)
        
        highlightedIndex = collections.index(of: collection)
        scrollToHighlightedRow()
    }
    
    @objc func showArranger() {
        
        performSegue(withIdentifier: "toArranger", sender: nil)
    }
    
    @objc func showNewPlaylist() {
        
        parent?.performSegue(withIdentifier: "toNewPlaylist", sender: nil)
    }
    
    @objc func changeRecentsType() {
        
        let added = UIAlertAction.init(title: "Added", style: .default, handler: { [weak self] action in
            
            guard let weakSelf = self, recentlyUpdatedPlaylistSorts.contains(weakSelf.currentPlaylistsView) else { return }
            
            let array = Array(recentlyUpdatedPlaylistSorts.subtracting([weakSelf.currentPlaylistsView])).map({ $0.rawValue })
            prefs.set(array, forKey: .recentlyUpdatedPlaylistSorts)
            
            notifier.post(name: .recentlyUpdatedPlaylistSortsChanged, object: nil, userInfo: ["playlistsView": weakSelf.currentPlaylistsView.rawValue])
        
        }).checked(given: recentlyUpdatedPlaylistSorts.contains(currentPlaylistsView))
        
        let updated = UIAlertAction.init(title: "Updated", style: .default, handler: { [weak self] action in
            
            guard let weakSelf = self, recentlyUpdatedPlaylistSorts.contains(weakSelf.currentPlaylistsView).inverted else { return }
            
            let array = Array(recentlyUpdatedPlaylistSorts.union([weakSelf.currentPlaylistsView])).map({ $0.rawValue })
            prefs.set(array, forKey: .recentlyUpdatedPlaylistSorts)
            
            notifier.post(name: .recentlyUpdatedPlaylistSortsChanged, object: nil, userInfo: ["playlistsView": weakSelf.currentPlaylistsView.rawValue])
        
        }).checked(given: recentlyUpdatedPlaylistSorts.contains(currentPlaylistsView).inverted)
        
        present(UIAlertController.withTitle(nil, message: "Recently...", style: .actionSheet, actions: added, updated, .cancel()), animated: true, completion: nil)
    }
    
    @IBAction func showOptions() {
        
        guard let vc: UIViewController = {
            
            let vc = popoverStoryboard.instantiateViewController(withIdentifier: "actionsVC")
            vc.modalPresentationStyle = .popover
            
            return Transitioner.shared.transition(to: vc, using: .init(fromVC: self, configuration: .library, count: collections.count), sourceView: actionsButton)
            
            }() else { return }
        
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func filterButtonTapped() {
        
        invokeSearch()
    }

    @objc func showOptions(_ sender: Any) {

        tableDelegate.showOptions(sender)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        imageCache.removeAllObjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
    }
    
    @objc func updateHeaderView(withCount count: Int) {
        
        tableView.tableHeaderView?.frame.size.height = 92 + (showRecents ? headerView.collectionViewHeaderHeightConstraint.constant + headerView.collectionViewHeightConstraint.constant : 0)
        tableView.tableHeaderView = headerView
        
        var array = [shuffleView, arrangeBorderView, editView].compactMap({ $0 })
        
        if collectionKind != .playlist {
            
            if count < 2 {
                
                array.remove(at: 0)
            }
            
            shuffleButton.superview?.isHidden = count < 2
        
//        } else {
//            
//            headerView.showRecents = count > 0
//            headerView.tableHeaderContainer.isHidden = count < 0
        }
        
        borderedButtons = array
        
        updateButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        prepareTransientObservers()
        
        let count = collectionKind == .playlist ? collectionsQuery.collections?.value(given: collections.isEmpty)?.count ?? collections.count : (collectionsQuery.items ?? []).count
        
        updateHeaderView(withCount: count)
        
        var text: String {
            
            guard collectionKind != .playlist else {
                
                return "Create a new playlist or use iTunes to create other types of playlists"
            }
            
            return showiCloudItems ? "There are no \(type.lowercased()) in your library" : "There are no offline \(type.lowercased()) in your library"
        }
        
        libraryVC?.updateEmptyLabel(withCount: count, text: text)
        libraryVC?.setCurrentOptions()
        
        if count > 1 {
            
            if wasFiltering {
                
                invokeSearch()
                wasFiltering = false
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        notifier.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            notifier.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
        unregisterAll(from: transientObservers)
    }
    
    func updateTopLabels(withFilteredCount count: Int? = nil) {
        
        if collectionKind == .playlist, !playlistsLoaded {
            
            return
        }
        
        let section: LibrarySection = {
            
            switch collectionKind {
                
                case .album: return .albums
                    
                case .artist, .albumArtist: return .artists
                    
                case .compilation: return .compilations
                    
                case .composer: return .composers
                    
                case .genre: return .genres
                
                case .playlist: return .playlists
            }
        }()
        
        libraryVC?.updateViews(inSection: section, count: collectionKind == .playlist ? collections.count : (collectionsQuery.collections ?? []).count, filteredCount: count)
    }
    
    @objc func prepareTransientObservers() {
        
        let queueObserver = notifier.addObserver(forName: .endQueueModification, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.tableView.isEditing {
                
                weakSelf.songManager.toggleEditing(notification)
                
//                if weakSelf.collectionKind == .playlist, let collectionView = weakSelf.collectionView {
//                    
//                    collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
//                }
            }
        })
        
        transientObservers.insert(queueObserver as! NSObject)
        
        if collectionKind == .playlist {
            
            let emptyObserver = notifier.addObserver(forName: .emptyPlaylistsVisibilityChanged, object: nil, queue: nil, using: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                weakSelf.updateWithQuery()
            })
            
            transientObservers.insert(emptyObserver as! NSObject)
        }
    }
    
    @objc func prepareLifetimeObservers() {
        
        let insetsObserver = notifier.addObserver(forName: .resetInsets, object: nil, queue: nil, using: { [weak self] _ in self?.adjustInsets(context: .container) })
        
        lifetimeObservers.insert(insetsObserver as! NSObject)
        
        let iCloudObserver = notifier.addObserver(forName: .iCloudVisibilityChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.collectionKind == .playlist {
                
                weakSelf.onlineOverride = false
                weakSelf.updateOfflineFilterPredicates(onCondition: weakSelf.onlineOverride)
//                weakSelf.updateTempView(hidden: true)
                weakSelf.updateOfflineFilterPredicates(onCondition: showiCloudItems)
                
            } else {
                
                if showiCloudItems {
                    
                    weakSelf.collectionsQuery.removeFilterPredicate(.offline)
                    
                } else {
                    
                    weakSelf.collectionsQuery.addFilterPredicate(.offline)
                }
            }
            
            weakSelf.updateWithQuery()
        })
        
        lifetimeObservers.insert(iCloudObserver as! NSObject)
        
        let libraryObserver = notifier.addObserver(forName: .libraryUpdated, object: appDelegate, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateWithQuery()
        })
        
        lifetimeObservers.insert(libraryObserver as! NSObject)
        
        if collectionKind == .artist {
            
            let firstLaunchObserver = notifier.addObserver(forName: Notification.Name.init("updateSection"), object: nil, queue: nil, using: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                UniversalMethods.performInMain {
                    
                    weakSelf.collectionsQuery = weakSelf.getCurrentQuery()
                    weakSelf.updateWithQuery()
                }
            })
            
            lifetimeObservers.insert(firstLaunchObserver as! NSObject)
        }
        
        if !presented {
            
            let playOnlyObserver = notifier.addObserver(forName: .playOnlyChanged, object: nil, queue: nil, using: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                weakSelf.collectionView?.reloadData()
            })
            
            lifetimeObservers.insert(playOnlyObserver as! NSObject)
        }
        
        if collectionKind == .playlist {
            
            if presented.inverted {
                
                lifetimeObservers.insert(notifier.addObserver(forName: .recentlyUpdatedPlaylistSortsChanged, object: nil, queue: nil, using: { [weak self] notification in
                    
                    guard let weakSelf = self, let rawValue = notification.userInfo?["playlistsView"] as? Int, rawValue == weakSelf.currentPlaylistsView.rawValue else { return }
                    
                    weakSelf.headerView.activityIndicatorView.startAnimating()
                    weakSelf.headerView.loadingEffectView.effect = weakSelf.headerView.collections.isEmpty ? nil : Themer.vibrancyContainingEffect
                    weakSelf.headerView.loadingEffectView.isHidden = false
                    weakSelf.collectionView?.isUserInteractionEnabled = false
                    
                    weakSelf.headerView.playlists = weakSelf.recentPlaylists(from: weakSelf.collections)
                    
                    weakSelf.collectionView?.isHidden = true
                    weakSelf.collectionView?.reloadData()
                    weakSelf.collectionView?.isUserInteractionEnabled = true
                    weakSelf.headerView.activityIndicatorView.stopAnimating()
                    weakSelf.headerView.loadingEffectView.isHidden = true
                    UniversalMethods.performOnMainThread({ weakSelf.animateCollectionCells() }, afterDelay: 0.1)
                    
                }) as! NSObject)
                
                lifetimeObservers.insert(notifier.addObserver(forName: .songsAddedToPlaylists, object: nil, queue: nil, using: { [weak self] notification in
                    
                    guard let weakSelf = self, let ids = notification.userInfo?[String.addedPlaylists] as? [MPMediaEntityPersistentID] else { return }
                    
                    if let indexPaths = weakSelf.tableView.indexPathsForVisibleRows?.filter({ Set(ids).contains (weakSelf.getCollection(from: $0).persistentID) }), indexPaths.isEmpty.inverted {
                        
                        weakSelf.tableView.reloadRows(at: indexPaths, with: .none)
                    }
                    
                    if let indexPaths = weakSelf.collectionView?.indexPathsForVisibleItems.filter({ Set(ids).contains (weakSelf.headerView.playlists[$0.row].persistentID) }), indexPaths.isEmpty.inverted {
                        
                        weakSelf.collectionView?.reloadItems(at: indexPaths)
                        indexPaths.forEach({
                            
                            guard let collectionView = weakSelf.collectionView, let cell = weakSelf.collectionView?.cellForItem(at: $0) else { return }
                            
                            weakSelf.headerView.collectionView(collectionView, willDisplay: cell, forItemAt: $0)
                        })
                    }
                    
                }) as! NSObject)
            }

            lifetimeObservers.insert(notifier.addObserver(forName: .showPlaylistFoldersChanged, object: nil, queue: nil, using: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                weakSelf.collectionsQuery = weakSelf.getCurrentQuery()
                weakSelf.updateWithQuery()
                
            }) as! NSObject)
        }
        
        let name: NSNotification.Name = {
            
            switch collectionKind {
                
                case .album: return .showRecentAlbumsChanged
                
                case .albumArtist, .artist: return .showRecentArtistsChanged
                
                case .playlist: return .showRecentPlaylistsChanged
                
                case .compilation: return .showRecentCompilationsChanged
                
                case .composer: return .showRecentComposersChanged
                
                case .genre: return .showRecentGenresChanged
            }
        }()
        
        lifetimeObservers.insert(notifier.addObserver(forName: name, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.getRecents()
            
            if weakSelf.sortCriteria == .random {
                
                weakSelf.tableView.beginUpdates()
                weakSelf.tableView.endUpdates()
            }
            
        }) as! NSObject)
    }
    
    @objc func getCurrentQuery() -> MPMediaQuery {
        
        let query: MPMediaQuery = {
            
            switch self.collectionKind {
                
                case .album: return .albums()
                    
                case .artist, .albumArtist: return MPMediaQuery.value(forKey: "albumArtistsQuery") as? MPMediaQuery ?? .artists()
                    
                case .compilation: return .compilations()
                    
                case .composer: return .composers()
                    
                case .genre: return .genres()
                
                case .playlist: return MPMediaQuery.playlists().foldersAllowed(showPlaylistFolders)
            }
        }()
        
        if showiCloudItems.inverted && onlineOverride.inverted {
            
            query.addFilterPredicate(.offline)
        }
        
        return query
    }
    
    @objc func updateWithQuery() {
        
        sortItems()
    }
    
    @objc func getRecentsQuery() -> MPMediaQuery? {
        
        if MPMediaQuery.responds(to: NSSelectorFromString("playlistsRecentlyAddedQuery")), let query = MPMediaQuery.value(forKey: "playlistsRecentlyAddedQuery") as? MPMediaQuery {
            
            if showiCloudItems.inverted && onlineOverride.inverted {
                
                query.addFilterPredicate(.offline)
            }
            
            return query
        }
        
        return nil
    }
    
//    func predicate(for view: PlaylistView) -> MPMediaPropertyPredicate? {
//
//        guard !presented else {
//
//            if appDelegate.appleMusicStatus != .appleMusic(libraryAccess: true) {
//
//                return nil
//            }
//
//            return .user
//        }
//
//        switch view {
//
//            case .all: return nil
//
//            case .appleMusic: return .am
//            
//            case .user: return .user
//        }
//    }
    
    func condition(for playlist: MPMediaPlaylist) -> Bool {
        
        switch self.presentedPlaylistsView ?? self.currentPlaylistsView {
            
            case .all: return true
            
            case .appleMusic: return playlist.isAppleMusic
            
            case .user: return !playlist.isAppleMusic
        }
    }
    
    func changeView(from currentView: PlaylistView, to newView: PlaylistView) {
        
//        if let predicate = predicate(for: currentView) {
//
//            collectionsQuery.removeFilterPredicate(predicate)
//            recentsQuery?.removeFilterPredicate(predicate)
//        }
//
//        if let predicate = predicate(for: newView) {
//
//            collectionsQuery.addFilterPredicate(predicate)
//            recentsQuery?.addFilterPredicate(predicate)
//        }
        
        updateWithQuery()
        
        if !presented {
            
            prefs.set(newView.rawValue, forKey: .playlistsView)
            
        } else {
            
            presentedPlaylistsView = newView
        }
        
        playlistViewLabel.text = playlistsViewText
    }
    
    @objc func handleRightSwipe(_ sender: Any) {
        
        guard !presented else { return }
        
        songManager.updateAddView(editing: true)
        
        tableView.setEditing(true, animated: true)
        
        if let collectionView = collectionView {
            
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
    }
    
    @objc func handleLeftSwipe(_ sender: Any) {
        
        if tableView.isEditing {
            
            songManager.updateAddView(editing: false)
            
            tableView.setEditing(false, animated: true)
            
            if let collectionView = collectionView {
                
                collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            }
        
        } else {
            
            guard let gr = sender as? UISwipeGestureRecognizer, collectionKind == .album, let indexPath = tableView.indexPathForRow(at: gr.location(in: tableView)) else { return }
            
            let album = getCollection(inSection: indexPath.section, row: indexPath.row)
            
            guard let song = album.representativeItem else { return }
            
            let query = MPMediaQuery.init(filterPredicates: [.for(albumArtistsAvailable ? .albumArtist : .artist, using: albumArtistsAvailable ? song.albumArtistPersistentID : song.artistPersistentID)]).cloud.grouped(by: albumArtistsAvailable ? .albumArtist : .artist)
            
            if let collections = query.collections, !collections.isEmpty {
                
                albumArtistsAvailable ? (albumArtistQuery = query) : (artistQuery = query)
                currentAlbum = album
                
                performSegue(withIdentifier: albumArtistsAvailable ? .albumArtistUnwind : .artistUnwind, sender: nil)
                
            } else {
                
                artistQuery = nil
                currentAlbum = nil
                
                let newBanner = Banner.init(title: showiCloudItems ? "This artist is not in your library" : "This artist is not available offline", subtitle: nil, image: nil, backgroundColor: .black, didTapBlock: nil)
                newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                newBanner.show(duration: 0.7)
            }
        }
    }
    
    func adjustInsets(context: InsetContext) {
        
        switch context {
            
        case .filter(let inset):
            
            tableView.scrollIndicatorInsets.bottom = inset
            tableView.contentInset.bottom = inset
            
        case .container:
            
            if let container = appDelegate.window?.rootViewController as? ContainerViewController, ignoreKeyboardForInset {
                
                tableView.scrollIndicatorInsets.bottom = presented ? 0 : container.inset
                tableView.contentInset.bottom = presented ? 0 : container.inset
            }
        }
    }
    
    @objc func push(_ vc: UIViewController) {
        
        libraryVC?.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier else { return }
        
        switch id {
            
            case "toAlbum", "toArtist", "toPlaylist": Transitioner.shared.transition(to: collectionKind.entity, vc: segue.destination, from: libraryVC, sender: sender, filter: self)
            
            case "toArranger": Transitioner.shared.transition(to: segue.destination, from: self)
            
            case "toNewPlaylist":
            
                if let presentedVC = segue.destination as? PresentedContainerViewController {
                    
                    presentedVC.itemsToAdd = itemsToAdd
                    presentedVC.manager = manager
                    presentedVC.context = .newPlaylist
                    presentedVC.fromQueue = fromQueue
                }
            
            default: break
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        switch identifier {
            
            case "toAlbum", "toArtist": return !tableView.isEditing
            
            case "toPlaylist": return !tableView.isEditing && !presented
                
            default: return true
        }
    }
    
    @IBAction func shuffle() {
        
        let songs = collectionsQuery.items ?? collections.flatMap({ $0.items })
        let canShuffleAlbums = songs.canShuffleAlbums
        
        var array = [UIAlertAction]()
        
        let shuffle = UIAlertAction.init(title: .shuffle(canShuffleAlbums ? .songs : .none), style: .default, handler: { _ in
            
            musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: self.libraryVC?.titleButton.titleLabel?.text, alertTitle: .shuffle(canShuffleAlbums ? .songs : .none))
        })
        
        array.append(shuffle)
        
        if canShuffleAlbums {
        
            let shuffleAlbums = UIAlertAction.init(title: .shuffle(.albums), style: .default, handler: { _ in
                
                musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: self, withTitle: self.libraryVC?.titleButton.titleLabel?.text, alertTitle: .shuffle(.albums))
            })
            
            array.append(shuffleAlbums)
        }
        
        present(UIAlertController.withTitle(nil, message: libraryVC?.titleButton.titleLabel?.text?.lowercased(), style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
    }
    
    @objc func getCollection(inSection section: Int, row: Int, filtering: Bool = false) -> MPMediaItemCollection {
        
        if filtering {
            
            return filteredCollections[row]
            
        } else {
            
            switch sortCriteria {
                
                case .standard where collectionKind != .playlist:
                
                    if let collectionSections = collectionsQuery.collectionSections {
                        
                        return collections[collectionSections[section].range.location + row]
                        
                    } else {
                        
                        return collections[row]
                    }
                
                case .random: return collections[row]
                
                default: return collections[sections[section].startingPoint + row]
            }
        }
    }
    
    @objc func getCollection(from indexPath: IndexPath, filtering: Bool = false) -> MPMediaItemCollection {
        
        return getCollection(inSection: indexPath.section, row: indexPath.row, filtering: filtering)
    }
    
    @objc func backToStart() {
        
        collectionView?.setContentOffset(.zero, animated: true)
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "CVC going away...").show(for: 0.3)
        }
    
        unregisterAll(from: lifetimeObservers)
        
        notifier.removeObserver(self)
    }
    
    @objc func animateCollectionCells() {
        
        guard let collectionView = collectionView else { return }
        
        for cell in collectionView.visibleCells {
            
            cell.alpha = 0
            cell.transform = .init(translationX: collectionView.bounds.size.width, y: 0)
        }
        
        collectionView.isHidden = false
        
        for cell in collectionView.visibleCells.enumerated() {
            
            UIView.animate(withDuration: 0.6, delay: 0.02 * Double(cell.offset), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
                
                cell.element.alpha = 1
                cell.element.transform = .identity
                
            }, completion: nil)
        }
    }
    
    @IBAction func addItemsToSelectedPlaylists() {
        
        guard selectedPlaylists.isEmpty.inverted else {
            
            UniversalMethods.banner(withTitle: "Select a playlist", titleFont: .myriadPro(ofWeight: .semibold, size: 17)).show(for: 1)
            
            return
        }
        
        let duplicates = selectedPlaylists.reduce([], { $0 + Array(Set($1.items).intersection(Set(manager?.queue ?? itemsToAdd))) })
        let duplicateText = duplicates.count == 1 ? "duplicate" : "duplicates"
        let filtering = filterContainer != nil
        
        guard let parent = (filterContainer?.parent ?? parent?.parent) as? PresentedContainerViewController else { return }
        
        let addSongs: (Bool) -> () = { [weak self] allowDuplicates in
            
            guard let weakSelf = self else { return }
            
            let array: [MPMediaItem] = {
                
                if allowDuplicates {
                    
                    return weakSelf.manager?.queue ?? weakSelf.itemsToAdd
                }
                
                return (weakSelf.manager?.queue ?? weakSelf.itemsToAdd).filter({ !duplicates.contains($0) })
            }()
            
            let staticCount = weakSelf.selectedPlaylists.count
            var errors = [(error: Error?, playlist: MPMediaPlaylist)]()
            var count = staticCount {
                
                didSet {
                    
                    if count == 0 {
                        
                        var details: (title: String, subtitle: String?, colour: UIColor) {
                            
                            switch errors.count {
                                
                                case 0: return ("\(array.count.fullCountText(for: .song)) added to \(staticCount.fullCountText(for: .playlist))", nil, .deepGreen)
                                
                                case let y where (1..<staticCount).contains(y): return ("\(array.count.fullCountText(for: .song)) added to \((staticCount - y).fullCountText(for: .playlist)), unable to add to \(y.fullCountText(for: .playlist))", errors.first?.error?.localizedDescription, .yellow)
                                
                                default: return ("Unable to add \(array.count.fullCountText(for: .song)) to \(staticCount.fullCountText(for: .playlist))", errors.first?.error?.localizedDescription, .red)
                            }
                        }
                        
                        let newBanner = Banner.init(title: details.title, subtitle: details.subtitle, image: nil, backgroundColor: details.colour, didTapBlock: nil)
                        newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                        newBanner.detailLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                        newBanner.show(duration: 1.5)
                        
                        if let _ = weakSelf.manager {
                            
                            notifier.post(name: .endQueueModification, object: nil)
                            
                        } else {
                            
                            weakSelf.performSegue(withIdentifier: "unwind", sender: nil)
                        }
                        
                        notifier.post(name: .songsAddedToPlaylists, object: nil, userInfo: [String.addedPlaylists: Set(weakSelf.selectedPlaylists).subtracting(Set(errors.map({ $0.playlist }))).map({ $0.persistentID }), String.addedSongs: array])
                    }
                }
            }
            
            parent.activityIndicator.startAnimating()
            
            if !filtering {
                
                parent.rightButton.isHidden = true
                parent.rightBorderView.isHidden = true
            }
            
            weakSelf.selectedPlaylists.forEach({ playlist in playlist.add(array, completionHandler: { error in
                
                UniversalMethods.performInMain {
                    
                    if let error = error { errors.append((error, playlist)) }
                    
                    count -= 1
                }
                
            }) })
        }
        
        let add = [UIAlertAction.init(title: duplicates.count > 0 ? "Add With \(duplicateText.capitalized)" : "Add \((manager?.queue ?? itemsToAdd).count.fullCountText(for: .song, capitalised: true))", style: .default, handler: { _ in
            addSongs(true) })]
        
        let noDuplicates = duplicates.isEmpty ? [] : [UIAlertAction.init(title: "Add Without \(duplicateText.capitalized)", style: .default, handler: { _ in addSongs(false) })]
        
//        let review = duplicates.isEmpty ? [] : [UIAlertAction.init(title: "Review Duplicates", style: .default, handler: nil)]
        
        (filterContainer ?? self).present(UniversalMethods.alertController(withTitle: selectedPlaylists.count.fullCountText(for: .playlist, capitalised: true), message: !duplicates.isEmpty ? duplicates.count.formatted + " " + duplicateText : nil, preferredStyle: .actionSheet, actions: add + noDuplicates + [.cancel()]), animated: true, completion: nil)
    }
    
    @objc func addItems(to playlist: MPMediaPlaylist) {
        
        let duplicates = Set(playlist.items).intersection(Set(manager?.queue ?? itemsToAdd))
        let duplicateText = duplicates.count == 1 ? "duplicate" : "duplicates"
        let filtering = filterContainer != nil
        
        guard let parent = (filterContainer?.parent ?? parent?.parent) as? PresentedContainerViewController else { return }
        
        let addSongs: (Bool) -> () = { [weak self] allowDuplicates in
            
            guard let weakSelf = self else { return }
            
            let array: [MPMediaItem] = {
                
                if allowDuplicates {
                    
                    return weakSelf.manager?.queue ?? weakSelf.itemsToAdd
                }
                
                return (weakSelf.manager?.queue ?? weakSelf.itemsToAdd).filter({ !duplicates.contains($0) })
            }()
            
            parent.activityIndicator.startAnimating()
            
            if !filtering {
                
                parent.rightButton.isHidden = true
                parent.rightBorderView.isHidden = true
            }
            
            playlist.add(array, completionHandler: { error in
                
                guard error == nil else {
                    
                    UniversalMethods.performInMain {
                        
                        let newBanner = Banner.init(title: "Unable to add \(array.count.fullCountText(for: .song)) to \(playlist.name ??? "Untitled Playlist")", subtitle: error?.localizedDescription, image: nil, backgroundColor: .red, didTapBlock: nil)
                        newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                        newBanner.detailLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                        newBanner.show(duration: 1)
                        
                        parent.activityIndicator.stopAnimating()
                        
                        if !filtering {
                            
                            parent.rightButton.isHidden = false
                            parent.rightBorderView.isHidden = false
                        }
                    }
                    
                    return
                }
                
                UniversalMethods.performInMain {
                    
                    let newBanner = Banner.init(title: "\(array.count.fullCountText(for: .song)) added to \(playlist.name ??? "Untitled Playlist")", subtitle: nil, image: nil, backgroundColor: .deepGreen, didTapBlock: nil)
                    newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                    newBanner.show(duration: 0.5)
                    
                    if let _ = weakSelf.manager {
                        
                        notifier.post(name: .endQueueModification, object: nil)
                        
                    } else {
                        
                        weakSelf.performSegue(withIdentifier: "unwind", sender: nil)
                    }
                    
                    notifier.post(name: .songsAddedToPlaylists, object: nil, userInfo: [String.addedPlaylists: [playlist.persistentID], String.addedSongs: array])
                    
                    parent.activityIndicator.stopAnimating()
                }
            })
        }
        
        let add = [UIAlertAction.init(title: duplicates.count > 0 ? "Add With \(duplicateText.capitalized)" : "Add \((manager?.queue ?? itemsToAdd).count == 1 ? "Song" : "Songs")", style: .default, handler: { _ in
            
            addSongs(true)
        })]
        
        let noDuplicates = duplicates.isEmpty || duplicates.count == (manager?.queue ?? itemsToAdd).count ? [] : [UIAlertAction.init(title: "Add Without \(duplicateText.capitalized)", style: .default, handler: { _ in addSongs(false) })]
        
        (filterContainer ?? self).present(UniversalMethods.alertController(withTitle: playlist.name ??? "Untitled Playlist", message: !duplicates.isEmpty ? duplicates.count.formatted + " " + duplicateText : nil, preferredStyle: .actionSheet, actions: add + noDuplicates + [.cancel()]), animated: true, completion: nil)
    }
}

extension CollectionsViewController: TableViewContainer {
    
    @objc func getEntity(at indexPath: IndexPath, filtering: Bool = false) -> MPMediaEntity {
        
        return getCollection(from: indexPath, filtering: filtering)
    }
    
    @objc func selectCell(in tableView: UITableView, at indexPath: IndexPath, filtering: Bool) {
        
        if let playlist = getCollection(inSection: indexPath.section, row: indexPath.row, filtering: filtering) as? MPMediaPlaylist, playlist.isFolder {
            
            let index = sortCriteria == .random ? indexPath.row : (sections[indexPath.section].startingPoint + indexPath.row)
            let container = tableDelegate.playlistContainers[index]
            let reducedCount = container.reduced.dataSource.count - 1

            Array(tableDelegate.playlistContainers[index...(index + reducedCount)]).forEach({ $0.isExpanded = container.isExpanded.inverted })

//            tableView.reloadRows(at: (index...(index + reducedCount)).map({ IndexPath.init(row: $0, section: indexPath.section) }), with: .fade)
            
            UIView.animate(withDuration: 0.4, animations: {
                
                tableView.beginUpdates()
                tableView.endUpdates()
            })
            
            return
        }
        
        if presented {
            
            guard let playlist = getCollection(from: indexPath, filtering: filtering) as? MPMediaPlaylist else { return }
            
            if selectedPlaylists.firstIndex(of: playlist) == nil {
                
                selectedPlaylists.append(playlist)
                
                if let selectedIndexPath = collectionView?.indexPathsForVisibleItems.first(where: { headerView.playlists.value(at: $0.row) == playlist }), let cell = collectionView?.cellForItem(at: selectedIndexPath), cell.isSelected.inverted {
                    
                    collectionView?.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
                }
                
                if filterContainer != nil, let selectedIndexPath = self.tableView.indexPathsForVisibleRows?.first(where: { getCollection(from: $0, filtering: false) == playlist }) {
                    
                    self.tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
                }
            }
            
        } else {
            
            let id: String = {
                
                switch collectionKind {
                    
                    case .album, .compilation: return "toAlbum"
                    
                    case .genre, .artist, .composer, .albumArtist: return "toArtist"
                    
                    case .playlist: return "toPlaylist"
                }
            }()
            
            let collection = getCollection(inSection: indexPath.section, row: indexPath.row, filtering: filtering)
            
            performSegue(withIdentifier: id, sender: collection)
            
            filterContainer?.saveRecentSearch(withTitle: filterContainer?.searchBar.text, resignFirstResponder: false)
        }
    }
    
    func deselectCell(in tableView: UITableView, at indexPath: IndexPath, filtering: Bool) {
        
        guard presented, let playlist = getCollection(from: indexPath, filtering: filtering) as? MPMediaPlaylist, let index = selectedPlaylists.firstIndex(of: playlist) else { return }
        
        selectedPlaylists.remove(at: index)
        
        if let selectedIndexPath = collectionView?.indexPathsForVisibleItems.first(where: { headerView.playlists.value(at: $0.row) == playlist }), let indexPaths = collectionView?.indexPathsForSelectedItems, Set(indexPaths).contains(selectedIndexPath) {
            
            collectionView?.deselectItem(at: selectedIndexPath, animated: false)
        }
        
        if filterContainer != nil, let selectedIndexPath = self.tableView.indexPathsForVisibleRows?.first(where: { getCollection(from: $0, filtering: false) == playlist }) {
            
            self.tableView.deselectRow(at: selectedIndexPath, animated: false)
        }
    }
}

// MARK: - Arrangeable
extension CollectionsViewController: FullySortable {
    
    @objc func getPlaylists(from playlists: [MPMediaPlaylist]) -> [MPMediaPlaylist] {
        
        var array = [MPMediaPlaylist]()
        
        for playlist in playlists where playlistIsEmpty(playlist) { array.append(playlist) }
        
        return array
    }
    
    @objc func standardPlaylists(from playlists: [MPMediaPlaylist]) -> [MPMediaPlaylist] {
        
        var geniusArray = [MPMediaPlaylist]()
        var smartArray = [MPMediaPlaylist]()
        var regularArray = [MPMediaPlaylist]()
        var appleMusicArray = [MPMediaPlaylist]()
        var foldersArray = [MPMediaPlaylist]()
        
        let addToPlaylists: (MPMediaPlaylist, Bool) -> Void = { playlist, emptyCheck in
            
            if playlist.playlistAttributes == .genius, emptyCheck {
                
                geniusArray.append(playlist)
                
            } else if playlist.playlistAttributes == .smart, emptyCheck {
                
                smartArray.append(playlist)
                
            } else if emptyCheck {
                
                if playlist.isFolder {
                    
                    foldersArray.append(playlist)
                
                } else if playlist.isAppleMusic {
                    
                    appleMusicArray.append(playlist)
                    
                } else {
                    
                    regularArray.append(playlist)
                }
            }
        }
        
        playlists.forEach { addToPlaylists($0, playlistIsEmpty($0)) }
        
        let array = foldersArray + smartArray + geniusArray + regularArray + appleMusicArray
        
        return ascending ? array : array.reversed()
    }
    
    @objc func playlistIsEmpty(_ playlist: MPMediaPlaylist) -> Bool {
        
        var query: MPMediaQuery? {
            
            if showiCloudItems.inverted && onlineOverride.inverted {
                
                return offlineQuery(for: playlist)
            }
            
            return nil
        }
        
        let emptyAllowed = (query?.items?.isEmpty ?? playlist.items.isEmpty) && presented ? presentedEmptyPlaylists : !shouldHideEmptyPlaylists
        
        return (query?.items?.isEmpty ?? playlist.items.isEmpty).inverted || emptyAllowed || playlist.isFolder
    }
    
    @objc func offlineQuery(for playlist: MPMediaPlaylist) -> MPMediaQuery {
        
        let selString = NSString.init(format: "%@%@%@", "item", "sQu", "ery")
        let sel = NSSelectorFromString(selString as String)
        
        if playlist.responds(to: sel), let query = playlist.value(forKey: "itemsQuery") as? MPMediaQuery {
            
            query.filterPredicates = [.for(.playlist, using: playlist.persistentID)]
            query.addFilterPredicate(.offline)
            
            return query
            
        } else {
            
            let query = MPMediaQuery.init(filterPredicates: [.for(.playlist, using: playlist.persistentID), .offline])
            query.groupingType = .playlist
            
            return query
        }
    }
    
    func recentPlaylists(from entities: [MPMediaItemCollection]) -> [MPMediaPlaylist] {
        
        guard collectionKind == .playlist, let entities = entities as? [MPMediaPlaylist], sortCriteria != .dateAdded else { return [] }
        
        if recentlyUpdatedPlaylistSorts.contains(currentPlaylistsView) {
            
            return entities.sorted(by: { ($0.dateUpdated ?? Date.distantPast) > ($1.dateUpdated ?? Date.distantPast) }).filter({ condition(for: $0) && $0.isFolder.inverted })
        
        } else if let query = recentsQuery {
            
            return getPlaylists(from: query.collections as? [MPMediaPlaylist] ?? []).filter({ condition(for: $0) })
            
        } else {
            
            return entities.sorted(by: { $0.dateCreated > $1.dateCreated }).filter({ condition(for: $0) && $0.isFolder.inverted })
        }
    }
    
    @objc func sortItems() {
        
        arrangeButton.alpha = 0
        activityIndicator.startAnimating()
        
        let mainBlock: ([MPMediaItemCollection], [MPMediaPlaylist], [SortSectionDetails], [PlaylistContainer]) -> () = { [weak self] array, recentArray, details, containers in
            
            guard let weakSelf = self, weakSelf.operation?.isCancelled == false else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    self?.arrangeButton.alpha = 1
                }
                
                return
            }
            
            weakSelf.collections = array
            
            if weakSelf.collectionKind == .playlist {
                
                weakSelf.headerView.playlists = recentArray
                weakSelf.playlistsLoaded = true
                weakSelf.libraryVC?.setCurrentOptions()
                
                if showPlaylistFolders {
                    
                    weakSelf.tableDelegate.playlistContainers = containers
                }
            }
            
            weakSelf.sections = details
            weakSelf.activityIndicator.stopAnimating()
            weakSelf.arrangeButton.alpha = 1
            
            guard weakSelf.operation?.isCancelled == false else { return }
            
            weakSelf.updateTopLabels()
            weakSelf.updateHeaderView(withCount: array.count)
            
            var text: String {
                
                guard weakSelf.collectionKind != .playlist else {
                    
                    return "Create a new playlist or use iTunes to create other types of playlists"
                }
                
                return showiCloudItems ? "There are no \(weakSelf.type.lowercased()) in your library" : "There are no offline \(weakSelf.type.lowercased()) in your library"
            }
            
            weakSelf.libraryVC?.updateEmptyLabel(withCount: array.count, text: text)
            
            if weakSelf.filtering, let filterContainer = weakSelf.filterContainer, let text = filterContainer.searchBar?.text {
                
                filterContainer.searchBar?(filterContainer.searchBar, textDidChange: text)
                
            } else {
                
                weakSelf.headerView.showRecents = weakSelf.showRecents && weakSelf.sortCriteria != .dateAdded
                weakSelf.updateHeaderView(withCount: array.count)
                
                weakSelf.tableView.reloadData()
                
                if weakSelf.collectionKind == .playlist {
                    
                    weakSelf.collectionView?.isHidden = true
                }
                
                weakSelf.animateCells(direction: .vertical)
                
                if weakSelf.collectionKind == .playlist && weakSelf.sortCriteria != .dateAdded {
                    
                    weakSelf.collectionView?.reloadData()
                    UniversalMethods.performOnMainThread({ weakSelf.animateCollectionCells() }, afterDelay: 0.1)
                }
            }
        }
        
        operation?.cancel()
        operation = BlockOperation()
        operation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self, let operation = weakSelf.operation, !operation.isCancelled, let entities = weakSelf.collectionsQuery.collections, !entities.isEmpty else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    self?.arrangeButton.alpha = 1
                }
                
                return
            }
            
            var containers = [PlaylistContainer]()
            var reduced = [ReducedPlaylist]()
            
            let array: [MPMediaItemCollection] = {
                
                switch weakSelf.sortCriteria {
                    
                case .random:
                    
                    if weakSelf.collectionKind == .playlist {
                        
                        let playlists = weakSelf.getPlaylists(from: entities as! [MPMediaPlaylist]).filter({ weakSelf.condition(for: $0) }).shuffled()
                        
                        if showPlaylistFolders {
                            
                            reduced = playlists.foldersConsidered.map({ $0.reduced })
                            containers = reduced.reduce([], { $0 + $1.containers })
                            
                            return reduced.reduce([], { $0 + $1.dataSource })
                        }

                        return playlists
                    }
                    
                    return entities.shuffled()
                    
                case .standard:
                    
                    if weakSelf.collectionKind == .playlist {

                        let playlists = weakSelf.standardPlaylists(from: entities as! [MPMediaPlaylist]).filter({ weakSelf.condition(for: $0) })
                        
                        if showPlaylistFolders {
                            
                            reduced = playlists.foldersConsidered.map({ $0.reduced })
                            containers = reduced.reduce([], { $0 + $1.containers })
                            
                            return reduced.reduce([], { $0 + $1.dataSource })
                        }
                        
                        return playlists
                    }
                    
                    return weakSelf.ascending ? entities : entities.reversed()
                    
                case .dateAdded where weakSelf.collectionKind == .playlist:
                    
                    if let recentsQuery = weakSelf.recentsQuery {
                        
                        let array = weakSelf.getPlaylists(from: recentsQuery.collections as? [MPMediaPlaylist] ?? []).filter({ weakSelf.condition(for: $0) })
                        
                        let playlists = weakSelf.ascending ? array.reversed() : array
                        
                        if showPlaylistFolders {
                            
                            reduced = playlists.foldersConsidered.map({ $0.reduced })
                            containers = reduced.reduce([], { $0 + $1.containers })
                            
                            return reduced.reduce([], { $0 + $1.dataSource })
                        }
                        
                        return playlists
                    }
                    
                    return (weakSelf.getPlaylists(from: entities as! [MPMediaPlaylist]).filter({ weakSelf.condition(for: $0) }) as NSArray).sortedArray(using: weakSelf.sortDescriptors) as! [MPMediaPlaylist]
                    
                default:
                    
                    if weakSelf.collectionKind == .playlist {
                        
                        let playlists = (weakSelf.getPlaylists(from: entities as! [MPMediaPlaylist]).filter({ weakSelf.condition(for: $0) }) as NSArray).sortedArray(using: weakSelf.sortDescriptors) as! [MPMediaPlaylist]
                        
                        if showPlaylistFolders {
                            
                            reduced = playlists.foldersConsidered.map({ $0.reduced })
                            containers = reduced.reduce([], { $0 + $1.containers })
                            
                            return reduced.reduce([], { $0 + $1.dataSource })
                        }
                        
                        return playlists
                    }
                    
                    return (entities as NSArray).sortedArray(using: weakSelf.sortDescriptors) as! [MPMediaItemCollection]
                }
            }()
            
            let recentArray = weakSelf.recentPlaylists(from: array)
            
            guard !operation.isCancelled else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    self?.arrangeButton.alpha = 1
                }
                
                return
            }
            
            let details = weakSelf.collectionKind == .playlist ? weakSelf.prepareSections(from: showPlaylistFolders ? reduced.reduce([], { $0 + $1.arrangeable }) : array as! [MPMediaPlaylist]) : weakSelf.prepareSections(from: array)
            
            OperationQueue.main.addOperation({
                
                guard weakSelf.operation?.isCancelled == false else { return }
                
                mainBlock(array, recentArray, details, containers)
                
            })
        })
        
        sortOperationQueue.addOperation(operation!)
        
        guard collectionKind != .playlist else { return }
    
        getActionableSongs()
        getRecents()
    }
    
    func getRecents() {
        
        if showRecents.inverted {
            
            recentOperation?.cancel()
            headerView.activityIndicatorView.stopAnimating()
            headerView.loadingEffectView.isHidden = true
            headerView.showRecents = showRecents
            updateHeaderView(withCount: collectionsQuery.collections?.count ?? 0)
            
            return
            
        } else {
            
            headerView.showRecents = showRecents
            updateHeaderView(withCount: collectionsQuery.collections?.count ?? 0)
        }
        
        guard Set(headerView.collections) != Set(collectionsQuery.collections ?? []) else {
            
            if sortCriteria != .dateAdded {
                
                recentOperation?.cancel()
                collectionView?.reloadData()
                collectionView?.isUserInteractionEnabled = true
                headerView.activityIndicatorView.stopAnimating()
                headerView.loadingEffectView.isHidden = true
                UniversalMethods.performOnMainThread({ self.animateCollectionCells() }, afterDelay: 0.1)
            }
            
            return
        }
        
        if sortCriteria != .dateAdded && (collectionsQuery.collections ?? []).count > 0 {
            
            headerView.activityIndicatorView.startAnimating()
            headerView.loadingEffectView.effect = headerView.collections.isEmpty ? nil : Themer.vibrancyContainingEffect
            headerView.loadingEffectView.isHidden = false
            collectionView?.isUserInteractionEnabled = false
        }
        
        recentOperation?.cancel()
        recentOperation = BlockOperation()
        recentOperation?.addExecutionBlock { [weak self] in
            
            guard let weakSelf = self, let weakOperation = weakSelf.recentOperation, !weakOperation.isCancelled, let collections = weakSelf.collectionsQuery.collections, !collections.isEmpty else {
                
                return
            }
            
            let array = (collections as NSArray).sortedArray(using: [NSSortDescriptor.init(key: #keyPath(MPMediaItemCollection.recentlyAdded), ascending: false)]) as! [MPMediaItemCollection]
            
            guard !weakOperation.isCancelled else {
                
                return
            }
            
            OperationQueue.main.addOperation {
                
                guard !weakOperation.isCancelled else {
                    
                    return
                }
                
                weakSelf.headerView.collections = array
                
                if weakSelf.sortCriteria != .dateAdded {
                    
                    weakSelf.collectionView?.isHidden = true
                    weakSelf.collectionView?.reloadData()
                    weakSelf.collectionView?.isUserInteractionEnabled = true
                    weakSelf.headerView.activityIndicatorView.stopAnimating()
                    weakSelf.headerView.loadingEffectView.isHidden = true
                    UniversalMethods.performOnMainThread({ weakSelf.animateCollectionCells() }, afterDelay: 0.1)
                }
            }
        }
        
        sortOperationQueue.addOperation(recentOperation!)
    }
}

extension CollectionsViewController: CollectionActionable {
    
    func getActionableSongs() {
        
        guard shouldFillActionableSongs else { return }
        
        actionableOperation?.cancel()
        actionableOperation = BlockOperation()
        actionableOperation?.addExecutionBlock { [weak self] in
            
            guard let weakSelf = self, let operation = weakSelf.actionableOperation, operation.isCancelled.inverted else {
                
                self?.actionableActivityIndicator.stopAnimating()
                self?.editButton.alpha = 1
                self?.showActionsAfterFilling = false
                
                return
            }
            
            let items = weakSelf.collections.reduce([], { $0 + $1.items })
            
            OperationQueue.main.addOperation {
                
                guard operation.isCancelled.inverted else {
                    
                    weakSelf.actionableActivityIndicator.stopAnimating()
                    weakSelf.editButton.alpha = 1
                    weakSelf.showActionsAfterFilling = false
                    
                    return
                }
                
                weakSelf.songs = items
                
                if weakSelf.showActionsAfterFilling {
                    
                    weakSelf.showArrayActions(weakSelf.tableView.isEditing ? weakSelf.editButton : weakSelf as Any)
                }
                
                weakSelf.actionableActivityIndicator.stopAnimating()
                weakSelf.editButton.alpha = 1
                weakSelf.showActionsAfterFilling = false
            }
        }
        
        actionableQueue.addOperation(actionableOperation!)
    }
}

extension CollectionsViewController: OnlineOverridable {
    
    @IBAction func performOnlineOverride() {
        
        onlineOverride = !onlineOverride
        
        updateOfflineFilterPredicates(onCondition: onlineOverride)
        
//        if !presented {
//            
//            updateTempView(hidden: !onlineOverride)
//        }
        
        updateWithQuery()
    }
    
    @objc func updateOfflineFilterPredicates(onCondition condition: Bool) {
        
        if condition {
            
            collectionsQuery.removeFilterPredicate(.offline)
            recentsQuery?.removeFilterPredicate(.offline)
            
        } else {
            
            collectionsQuery.addFilterPredicate(.offline)
            recentsQuery?.addFilterPredicate(.offline)
        }
    }
}

// 3D Touch
extension CollectionsViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard !presented, !tableView.isEditing else { return nil }
        
        if let header = tableView.tableHeaderView as? HeaderView, header.frame.contains(location) {
            
            guard let collectionView = collectionView, let collectionIndexPath = collectionView.indexPathForItem(at: collectionView.convert(header.convert(location, from: tableView), from: header)), let collectionCell = collectionView.cellForItem(at: collectionIndexPath), let vc = entityStoryboard.instantiateViewController(withIdentifier: "entityItems") as? EntityItemsViewController else { return nil }
            
            previewingContext.sourceRect = tableView.convert(collectionCell.frame, from: collectionView)
            
            let sender: [MPMediaItemCollection] = {
                
                switch collectionKind {
                    
                    case .playlist: return header.playlists
                    
                    default: return header.collections
                }
            }()
            
            return Transitioner.shared.transition(to: collectionKind.entity, vc: vc, from: libraryVC, sender: sender[collectionIndexPath.row], preview: true, filter: self)
            
            
        } else {
            
            guard let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath), let vc = entityStoryboard.instantiateViewController(withIdentifier: "entityItems") as? EntityItemsViewController else { return nil }
            
            previewingContext.sourceRect = cell.frame
            
            return Transitioner.shared.transition(to: collectionKind.entity, vc: vc, from: libraryVC, sender: getCollection(from: indexPath), preview: true, filter: self)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        (viewControllerToCommit as? BackgroundHideable)?.modifyBackgroundView(forState: .removed)
        
        if let vc = viewControllerToCommit as? Arrangeable {
            
            vc.updateImage(for: vc.arrangeButton)
        }
        
        if let vc = viewControllerToCommit as? Peekable {
            
            vc.peeker = nil
        }
        
        if let vc = viewControllerToCommit as? Navigatable, let indexer = vc.activeChildViewController as? IndexContaining {
            
            indexer.tableView.contentInset.top = vc.inset
            indexer.tableView.scrollIndicatorInsets.top = vc.inset
            
            if let sortable = indexer as? FullySortable, sortable.highlightedIndex == nil {
                
                indexer.tableView.contentOffset.y = -vc.inset
            }
            
            libraryVC?.container?.visualEffectNavigationBar.backBorderView.alpha = 1
            libraryVC?.container?.visualEffectNavigationBar.backView.isHidden = false
            libraryVC?.container?.visualEffectNavigationBar.backLabel.text = vc.backLabelText
            libraryVC?.container?.visualEffectNavigationBar.titleLabel.text = vc.title
        }
        
        show(viewControllerToCommit, sender: nil)
    }
}
