//
//  ArtistAlbumsViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/11/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ArtistAlbumsViewController: UIViewController, FilterContextDiscoverable, SupplementaryHeaderInfoLoading, ArtistTransitionable, AlbumArtistTransitionable, GenreTransitionable, QueryUpdateable, CellAnimatable, EntityContainer, PillButtonContaining, Refreshable, IndexContaining, EntityVerifiable, TopScrollable, AlbumTransitionable, CollectionActionable {
    
    @IBOutlet var tableView: MELTableView! {
        
        didSet {
            
            let gr = UIPanGestureRecognizer.init(target: entityVC, action: #selector(EntityItemsViewController.updateSections))
            gr.delegate = entityVC
            tableView.addGestureRecognizer(gr)
        }
    }
    
    @objc lazy var headerView: HeaderView = {
        
        let view = HeaderView.instance
        self.actionsStackView = view.actionsStackView
        self.stackView = view.scrollStackView
        view.buttonDetails = [
            
            (.grouping, #imageLiteral(resourceName: "Grouping13"), currentArtistQuery?.collections?.count.fullCountText(for: .album, capitalised: false), { [weak self] in self?.entityVC?.showGroupings() }),
            (.sort, #imageLiteral(resourceName: "Order13"), arrangementLabelText, { [weak self] in self?.showArranger() }),
            (.info, #imageLiteral(resourceName: "InfoNoBorder13"), nil, { [weak self] in self?.entityVC?.showOptions() }),
            (.share, #imageLiteral(resourceName: "Share14"), nil, { })
        ]
        view.showInfo = true
        view.showGrouping = true
        view.sortButton.setTitle(arrangementLabelText, for: .normal)
        view.sortButton.addTarget(self, action: #selector(showArranger), for: .touchUpInside)
        view.groupingButton.setTitle((currentArtistQuery?.collections?.count ?? 0).fullCountText(for: .album, capitalised: true), for: .normal)
        view.infoButton.addTarget(entityVC, action: #selector(EntityItemsViewController.showOptions), for: .touchUpInside)
        view.groupingButton.addTarget(entityVC, action: #selector(EntityItemsViewController.showGroupings), for: .touchUpInside)
        
        return view
    }()
    @objc var actionsStackView: UIStackView! {
        
        didSet {
            
            let actionsView = PillButtonView.with(title: "Actions", image: #imageLiteral(resourceName: "ActionsMenu15"), tapAction: .init(action: #selector(SongActionManager.showActionsForAll(_:)), target: songManager), longPressAction: .init(action: #selector(SongActionManager.showActionsForAll(_:)), target: songManager))
            itemActionsButton = actionsView.button
            self.itemActionsView = actionsView
            
            let filterView = PillButtonView.with(title: "Filter", image: #imageLiteral(resourceName: "Filter13"), tapClosure: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                weakSelf.invokeSearch()
            })
            self.filterView = filterView
            
            let editView = PillButtonView.with(title: .inactiveEditButtonTitle, image: .inactiveEditImage, tapAction: .init(action: #selector(SongActionManager.toggleEditing(_:)), target: songManager))
            editButton = editView.button
            self.editView = editView
            
            [editView, filterView, actionsView].forEach({ actionsStackView.addArrangedSubview($0) })
        }
    }
    @objc var stackView: UIStackView! {
        
        didSet {
            
            let duration = ScrollHeaderSubview.with(title: "Duration", image: #imageLiteral(resourceName: "Time10"))
            totalDurationLabel = duration.label
            
            let created = ScrollHeaderSubview.with(title: "Added", image: #imageLiteral(resourceName: "DateAdded"), useSmallerImage: true)
            dateCreatedLabel = created.label
            
            let size = ScrollHeaderSubview.with(title: "Size", image: #imageLiteral(resourceName: "FileSize12"))
            sizeLabel = size.label
            
            let plays = ScrollHeaderSubview.with(title: "Plays", image: #imageLiteral(resourceName: "Plays"))
            playsLabel = plays.label
            
            for view in [duration, size, created, plays] {
                
                stackView.addArrangedSubview(view)
            }
        }
    }
    
    @objc var activityIndicator: MELActivityIndicatorView!
    @objc var arrangeButton: MELButton!
    @objc var editButton: MELButton!
    @objc var itemActionsButton: MELButton!
    @objc var totalDurationLabel: MELLabel!
    @objc var dateCreatedLabel: MELLabel!
    @objc var playsLabel: MELLabel!
    @objc var sizeLabel: MELLabel!
    
    @objc var itemActionsView: PillButtonView!
    @objc var filterView: PillButtonView!
    @objc var editView: PillButtonView!
    @objc var actionableActivityIndicator = MELActivityIndicatorView.init()
    
    var borderedButtons = [PillButtonView?]()
    var sectionIndexViewController: SectionIndexViewController?
    let requiresLargerTrailingConstraint = false
    var navigatable: Navigatable? { return entityVC }
    
    @objc lazy var sorter: Sorter = { Sorter.init(operation: self.operation) }()
    
    @objc var actionableSongs: [MPMediaItem] {
        
        get { songs }
        
        set { songs = newValue }
    }
    var actionableCollections: [MPMediaItemCollection] { return filtering ? filteredAlbums : albums }
    var shouldFillActionableSongs = false
    var isCollectingSongs = false
    var songs = [MPMediaItem]()
    #warning("Add filteredSongs array for this and CollectionsVC for Actionable actions during filtering")
    lazy var actionableAlertController = initialAlertController
    var actionableDetails: (action: SongAction, vc: UIViewController, useAlternateTitle: Bool)?
    
    var collectionKind: CollectionsKind { return entityVC?.kind.collectionKind ?? .artist }
    var applicableActions: [SongAction] {
        
        var name: String {
            
            guard let entityVC = entityVC, let item = artist?.representativeItem else { return "" }
            
            switch entityVC.kind {
                
                case .artist: return item.validArtist
                
                case .genre: return item.validGenre
                
                case .composer: return item.validComposer
                
                case .albumArtist: return item.validAlbumArtist
            }
        }
        
        return [SongAction.collect, .info(context: .album(at: 0, within: [])), .queue(type: .playNext, name: name, query: nil), .queue(type: .playLater, name: name, query: nil), .queue(type: .all, name: name, query: nil), .newPlaylist, .addTo]
    }
    @objc lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
    @objc lazy var refresher: Refresher = { Refresher.init(refreshable: self) }()
    
    @objc lazy var tableDelegate: TableDelegate = { TableDelegate.init(container: self, location: .artistAlbums(withinArtist: self.entityVC?.kind == .artist || self.entityVC?.kind == .albumArtist)) }()
    @objc var entities: [MPMediaEntity] {
        
        get { return albums }
        
        set { albums = newValue as? [MPMediaItemCollection] ?? [] }
    }
    @objc lazy var filteredEntities = [MPMediaEntity]()
    @objc var query: MPMediaQuery? { return currentArtistQuery }
    @objc var highlightedEntity: MPMediaEntity? { return entityVC?.highlightedEntities?.collection }
    @objc var cellDelegate: Any { return self }
    var filterContainer: (UIViewController & FilterContainer)?
    var filterEntities: FilterViewController.FilterEntities { return .collections(albums, kind: .album) }
    var collectionView: UICollectionView?
    
    var needsToUpdateHeaderView = false
    
    var staticSortCriteria = SortCriteria.standard
    var sortCriteria: SortCriteria {
        
        get { return staticSortCriteria }
        
        set {
            
            if let _ = tableView, let id = entityVC?.collection?.persistentID {
                
                staticSortCriteria = newValue
                sortAllItems()
                
                prepare(.sort, reload: true, animateHeader: true)
//                headerView.sortButton.setTitle(arrangementLabelText, for: .normal)
                UIView.animate(withDuration: 0.3, animations: { self.headerView.layoutIfNeeded() })
                UniversalMethods.saveSortableItem(withPersistentID: id, order: ascending, sortCriteria: staticSortCriteria, kind: .artistAlbums)
            }
        }
        
//        didSet {
//
//            if let _ = tableView {
//
//                sortAllItems()
//                headerView.sortButton.setTitle(arrangementLabelText, for: .normal)
//                UIView.animate(withDuration: 0.3, animations: { self.headerView.layoutIfNeeded() })
//
//                if let collection = entityVC?.collection {
//
//                    UniversalMethods.saveSortableItem(withPersistentID: collection.persistentID, order: ascending, sortCriteria: sortCriteria, kind: .artistAlbums)
//                }
//            }
//        }
    }
    var applySort = true
    @objc var ascending = true {
        
        didSet {
            
            if let _ = tableView {
                
                if applySort {
                    
                    if sortCriteria == .random {
                        
                        albums.reverse()
                        tableView.reloadData()
                        
                    } else {
                    
                        sortAllItems()
                    }
                }
                
                if let collection = entityVC?.collection {
                    
                    UniversalMethods.saveSortableItem(withPersistentID: collection.persistentID, order: ascending, sortCriteria: sortCriteria, kind: .artistAlbums)
                }
            }
        }
    }
    var applicableSortCriteria: Set<SortCriteria> {
        
        get {
            
            guard let entityVC = entityVC else { return [] }
            
            let set: Set<SortCriteria> = [.album, .duration, .year, .genre, .artist, .plays, .dateAdded, .fileSize, .songCount]
            
            switch entityVC.kind {
                
                case .artist, .albumArtist: return set.subtracting([.artist])
                
                case .genre: return set.subtracting([.genre])
                
                case .composer: return set
            }
        }
    }
    @objc var operation: BlockOperation?
    var sortLocation: SortLocation = .collections

    @objc weak var entityVC: EntityItemsViewController? { return parent as? EntityItemsViewController }
    @objc var artist: MPMediaItemCollection? { return currentArtistQuery?.collections?.first }
    @objc var currentArtistQuery: MPMediaQuery?
    var entityKind: AlbumBasedCollectionKind?
    
    var applicableSupplementaryProperties = [SecondaryCategory.duration, .fileSize, .plays, .dateAdded]
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    @objc var albumQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    
    @objc var albums = [MPMediaItemCollection]()
    @objc var filteredAlbums: [MPMediaItemCollection] { return filteredEntities as! [MPMediaItemCollection] }
    lazy var sections = [SortSectionDetails]()
    @objc lazy var filtering = false
    var filterText: String?
    var ignorePropertyChange = false
    var entityCount: Int { return albums.count }
    @objc var ignoreKeyboardForInset = true
    @objc lazy var wasFiltering = false
    
    var highlightedIndex: Int?
    @objc var lifetimeObservers = Set<NSObject>()
    @objc var transientObservers = Set<NSObject>()
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
    lazy var applicableFilterProperties: Set = self.applicableCollectionFilterProperties.subtracting([.isCompilation, .artwork, .albumCount, .artist])
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
    @objc let sortOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Sort Operation Queue"
        queue.qualityOfService = .userInitiated
        
        return queue
    }()
    let actionableQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Actionable Operation Queue"
        queue.qualityOfService = .userInitiated
        
        return queue
    }()
    @objc let imageCache: ImageCache = {
        
        let cache = ImageCache()
        cache.name = "Image Cache"
        cache.countLimit = 500
        
        return cache
    }()
    @objc var filterOperation: BlockOperation?
    @objc var supplementaryOperation: BlockOperation?
    var actionableOperation: BlockOperation?
    @objc var searchText: String?

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        currentArtistQuery = entityVC?.query?.copy() as? MPMediaQuery
        currentArtistQuery?.groupingType = .album
        
        entityKind = entityVC?.kind
        
        updateTopInset()
        adjustInsets(context: .container)
        
        prepareLifetimeObservers()
        prepareSupplementaryInfo(animated: false)
        
        tableView.delegate = tableDelegate
        tableView.dataSource = tableDelegate
        tableView.tableHeaderView = headerView
        
        let refreshControl = MELRefreshControl.init()
        refreshControl.addTarget(refresher, action: #selector(Refresher.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        sortAllItems()
        
        updateHeaderView(withCount: (currentArtistQuery?.items ?? []).count)
        
        registerForPreviewing(with: self, sourceView: tableView)
        
        prepareGestures()
    }
    
    func updateTopInset() {
        
        let inset = entityVC?.peeker != nil ? 0 : entityVC?.inset ?? VisualEffectNavigationBar.Location.entity.inset
        tableView.contentInset.top = inset
        tableView.scrollIndicatorInsets.top = inset
    }
    
    @objc func prepareGestures() {
        
        let swipeRight = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeRight.direction = .right
        tableView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeLeft.direction = .left
        tableView.addGestureRecognizer(swipeLeft)
    }
    
    @objc func revealEntity(_ sender: Any) {
        
        guard let indexPath: IndexPath = {
            
            if let gr = sender as? UIGestureRecognizer {
                
                guard gr.state == .began else { return nil }
                
                return tableView.indexPathForRow(at: gr.location(in: tableView))
            }
            
            return sender as? IndexPath
            
        }() else { return }
        
        let collection = getCollection(from: indexPath, filtering: true)
                
        entityVC?.highlightedEntities?.collection = collection
        highlightedIndex = albums.firstIndex(of: collection)
        scrollToHighlightedRow()
    }
    
    /*@objc func prepareSupplementaryInfo(animated: Bool = true) {
        
        guard let entityVC = entityVC, let collection: MPMediaItemCollection = {
        
            let query = currentArtistQuery?.copy() as? MPMediaQuery
            query?.groupingType = entityVC.kind.grouping
            
            return query?.collections?.first
        
        }(), let _ = viewIfLoaded else { return }
        
        supplementaryOperation?.cancel()
        supplementaryOperation = BlockOperation()
        supplementaryOperation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self else { return }
            
            let duration = collection.totalDuration.stringRepresentation(as: .short)
            let created = collection.recentlyAdded.timeIntervalSinceNow.shortStringRepresentation
            let plays = collection.totalPlays.formatted
            let count = (weakSelf.currentArtistQuery?.collections?.count ?? 0).fullCountText(for: .album, capitalised: false)
            let totalSize = FileSize.init(actualSize: collection.totalSize).actualSize.fileSizeRepresentation
            
            guard weakSelf.supplementaryOperation?.isCancelled == false else { return }
            
            OperationQueue.main.addOperation({
                
                weakSelf.headerView.groupingButton.setTitle(count, for: .normal)
                weakSelf.totalDurationLabel.text = duration
                weakSelf.dateCreatedLabel.text = created
                weakSelf.playsLabel.text = plays
                weakSelf.sizeLabel.text = totalSize
            })
        })
        
        sortOperationQueue.addOperation(supplementaryOperation!)
    }*/
    
    @objc func showOptions(_ sender: Any) {
        
        tableDelegate.showOptions(self)
    }
    
    @objc func showArranger() {
        
        performSegue(withIdentifier: "toArranger", sender: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        for cell in tableView.visibleCells {
            
            if let cell = cell as? EntityTableViewCell, !cell.playingView.isHidden {
                
                cell.indicator.state = musicPlayer.isPlaying ? .playing : .paused
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        prepareTransientObservers()
        
        if wasFiltering {
            
            invokeSearch()
            wasFiltering = false
        }
        
        if needsToUpdateHeaderView {
            
            prepareSupplementaryInfo()
            needsToUpdateHeaderView = false
        }
        
        entityVC?.setCurrentOptions()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        unregisterAll(from: transientObservers)
    }
    
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
    
    @objc func prepareTransientObservers() {
        
        let queueObserver = notifier.addObserver(forName: .endQueueModification, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.tableView.isEditing { weakSelf.songManager.toggleEditing(notification) }
        })
        
        transientObservers.insert(queueObserver as! NSObject)
        
        let secondaryObserver = notifier.addObserver(forName: .performSecondaryAction, object: navigationController, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self, weakSelf.albums.count > 1 else { return }
      
            weakSelf.invokeSearch()
        })
        
        transientObservers.insert(secondaryObserver as! NSObject)
    }
    
    @objc func prepareLifetimeObservers() {
        
        let insetsObserver = notifier.addObserver(forName: .resetInsets, object: nil, queue: nil, using: { [weak self] _ in self?.adjustInsets(context: .container) })
        
        lifetimeObservers.insert(insetsObserver as! NSObject)
        
        lifetimeObservers.insert((notifier.addObserver(forName: .libraryUpdated, object: appDelegate, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateWithQuery()
            
        })) as! NSObject)
        
        [Notification.Name.playerChanged, .MPMusicPlayerControllerNowPlayingItemDidChange].forEach({
        
            lifetimeObservers.insert(notifier.addObserver(forName: $0, object: /*musicPlayer*/nil, queue: nil, using: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                for cell in weakSelf.tableView.visibleCells {
                    
                    guard let entityCell = cell as? EntityTableViewCell, let indexPath = weakSelf.tableView.indexPath(for: entityCell), let nowPlaying = musicPlayer.nowPlayingItem else {
                        
                        (cell as? EntityTableViewCell)?.playingView.isHidden = true
                        (cell as? EntityTableViewCell)?.indicator.state = .stopped
                        
                        continue
                    }
                    
                    if entityCell.playingView.isHidden.inverted && Set(weakSelf.getCollection(from: indexPath).items).contains(nowPlaying).inverted {
                        
                        entityCell.playingView.isHidden = true
                        entityCell.indicator.state = .stopped
                        
                    } else if entityCell.playingView.isHidden && Set(weakSelf.getCollection(from: indexPath).items).contains(nowPlaying) {
                        
                        entityCell.playingView.isHidden = false
                        UniversalMethods.performOnMainThread({ entityCell.indicator.state = musicPlayer.isPlaying ? .playing : .paused }, afterDelay: 0.1)
                    }
                }
                
            }) as! NSObject)
        })
        
        lifetimeObservers.insert(notifier.addObserver(forName: .lineHeightsCalculated, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateTopInset()
            
        }) as! NSObject)
    }
    
    @objc func updateWithQuery() {
        
        if let entityVC = entityVC {
            
            currentArtistQuery = entityVC.query?.copy() as? MPMediaQuery
        }
        
        currentArtistQuery?.groupingType = .album
//        prepareSupplementaryInfo()
        sortAllItems()
    }
    
    @objc func updateHeaderView(withCount count: Int) {
        
//        itemActionsButton.superview?.isHidden = count < 2
        tableView.tableHeaderView?.frame.size.height = 92
        tableView.tableHeaderView = headerView
        
        let array = [editView, filterView, itemActionsView]
        
//        if count < 2 {
//
//            array.remove(at: 0)
//        }
        
        borderedButtons = array
        
        updateButtons()
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
            
            tableDelegate.showGoToMenu(via: sender)
            
//            guard let gr = sender as? UISwipeGestureRecognizer, let indexPath = tableView.indexPathForRow(at: gr.location(in: tableView)) else { return }
//
//            let album = getCollection(inSection: indexPath.section, row: indexPath.row)
//
//            guard album.representativeItem?.isCompilation == false else {
//
//                performSegue(withIdentifier: "toAlbum", sender: album)
//
//                return
//            }
            
//            guard let song = album.representativeItem, entityVC?.kind != .artist else { return }
//
//            let filterPredicates: Set<MPMediaPropertyPredicate> = showiCloudItems ? [.for(.artist, using: song.artistPersistentID)] : [.for(.artist, using: song.artistPersistentID), .offline]
//
//            let query = MPMediaQuery.init(filterPredicates: filterPredicates)
//            query.groupingType = albumArtistsAvailable ? .albumArtist : .artist
//
//            if let collections = query.collections, !collections.isEmpty {
//
//                artistQuery = query
//                currentAlbum = album
//
//                performSegue(withIdentifier: .artistUnwind, sender: nil)
//
//            } else {
//
//                artistQuery = nil
//                currentAlbum = nil
//
//                let newBanner = Banner.init(title: showiCloudItems ? "This artist is not in your library" : "This artist is not available offline", subtitle: nil, image: nil, backgroundColor: .black, didTapBlock: nil)
//                newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
//                newBanner.show(duration: 0.7)
//            }
        }
    }
    
    @IBAction func shuffle() {
        
        guard let songs = currentArtistQuery?.items else { return }
        
        let canShuffleAlbums = songs.canShuffleAlbums
        
        if canShuffleAlbums {
            
            let shuffle = AlertAction.init(title: .shuffle(.songs), style: .default, requiresDismissalFirst: true, handler: { musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: self.entityVC?.title, alertTitle: .shuffle(.songs)) })
            
            let shuffleAlbums = AlertAction.init(title: .shuffle(.albums), style: .default, requiresDismissalFirst: true, handler: { musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: self, withTitle: self.entityVC?.title, alertTitle: .shuffle(.albums)) })
            
            showAlert(title: entityVC?.title, with: shuffle, shuffleAlbums)
            
        } else {
            
            musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: entityVC?.title, alertTitle: .shuffle())
        }
    }
    
    @objc func getCollection(inSection section: Int, row: Int, filtering: Bool = false) -> MPMediaItemCollection {
        
        if filtering {
            
            return filteredAlbums[row]
            
        } else {
            
            switch sortCriteria {
                
                case .standard:
                
                    if let collectionSections = currentArtistQuery?.collectionSections {
                        
                        return albums[collectionSections[section].range.location + row]
                        
                    } else {
                        
                        return albums[row]
                    }
                
                case .random: return albums[row]
                
                default: return albums[sections[section].startingPoint + row]
            }
        }
    }
    
    @objc func getCollection(from indexPath: IndexPath, filtering: Bool = false) -> MPMediaItemCollection {
        
        return getCollection(inSection: indexPath.section, row: indexPath.row, filtering: filtering)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier else { return }
        
        switch id {
            
            case "toAlbum": Transitioner.shared.transition(to: .album, vc: segue.destination, from: entityVC, sender: sender, filter: self)
            
            case "toArranger": Transitioner.shared.transition(to: segue.destination, from: self)
            
            default: break
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "AAVC going away...").show(for: 0.3)
        }

        unregisterAll(from: lifetimeObservers)
        notifier.removeObserver(self)
    }
}

extension ArtistAlbumsViewController: TableViewContainer {
    
    @objc func getEntity(at indexPath: IndexPath, filtering: Bool = false) -> MPMediaEntity {
        
        return getCollection(from: indexPath, filtering: filtering)
    }
    
    @objc func selectCell(in tableView: UITableView, at indexPath: IndexPath, filtering: Bool) {
        
        performSegue(withIdentifier: "toAlbum", sender: getCollection(inSection: indexPath.section, row: indexPath.row, filtering: filtering))
        
        filterContainer?.saveRecentSearch(withTitle: filterContainer?.searchBar.text, resignFirstResponder: false)
    }
}

extension ArtistAlbumsViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        if let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath) {
            
            let vc = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
            
            previewingContext.sourceRect = cell.frame
            
            return Transitioner.shared.transition(to: .album, vc: vc, from: entityVC, sender: getCollection(inSection: indexPath.section, row: indexPath.row), preview: true)
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        performCommitActions(on: viewControllerToCommit)
        
        show(viewControllerToCommit, sender: nil)
    }
}

// MARK: - Arrangeable
extension ArtistAlbumsViewController: FullySortable {
    
    /*@objc func sortItems() {
        
        guard let _ = viewIfLoaded else { return }
        
        headerView.updateSortActivityIndicator(to: .visible)
        
        let mainBlock: ([MPMediaItemCollection], [SortSectionDetails]) -> () = { [weak self] array, details in
        
            guard let weakSelf = self, weakSelf.operation?.isCancelled == false else {
                
                self?.headerView.updateSortActivityIndicator(to: .hidden)
                
                return
            }
            
            weakSelf.albums = array
            weakSelf.sections = details
            weakSelf.headerView.updateSortActivityIndicator(to: .hidden)
            weakSelf.updateHeaderView(withCount: (weakSelf.currentArtistQuery?.items ?? []).count)
            weakSelf.prepareSupplementaryInfo()
            
            if weakSelf.filtering, let filterContainer = weakSelf.filterContainer, let text = filterContainer.searchBar?.text {
                
                filterContainer.searchBar?(filterContainer.searchBar, textDidChange: text)
                
            } else {
                
                weakSelf.tableView.reloadData()
                
                if weakSelf.entityVC?.peeker == nil {
                    
                    weakSelf.animateCells(direction: .vertical, alphaOnly: weakSelf.highlightedIndex != nil)
                }
                
                weakSelf.scrollToHighlightedRow()
            }
        }
        
        operation?.cancel()
        operation = BlockOperation()
        operation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self, let operation = weakSelf.operation, !operation.isCancelled, let entities = weakSelf.currentArtistQuery?.collections, !entities.isEmpty else {
                
                UniversalMethods.performInMain {
                    
                    self?.headerView.updateSortActivityIndicator(to: .hidden)
                }
                
                return
            }
            
            let array: [MPMediaItemCollection] = {
                
                switch weakSelf.sortCriteria {
                    
                    case .random: return entities.shuffled()
                        
                    case .standard: return weakSelf.ascending ? entities : entities.reversed()
                        
                    default: return (entities as NSArray).sortedArray(using: weakSelf.sortDescriptors) as! [MPMediaItemCollection]
                }
            }()
            
            if let entity = self?.entityVC?.highlightedEntities?.collection {
                
                self?.highlightedIndex = array.firstIndex(of: entity)
            }
            
            guard !operation.isCancelled else {
                
                UniversalMethods.performInMain {
                    
                    self?.headerView.updateSortActivityIndicator(to: .hidden)
                }
                
                return
            }
            
            let details = weakSelf.prepareSections(from: entities)
            
            OperationQueue.main.addOperation({ mainBlock(array, details) })
        })
        
        sortOperationQueue.addOperation(operation!)
        
        getActionableSongs()
    }*/
}
