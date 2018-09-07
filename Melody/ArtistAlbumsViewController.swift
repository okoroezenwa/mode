//
//  ArtistAlbumsViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/11/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ArtistAlbumsViewController: UIViewController, FilterContextDiscoverable, InfoLoading, ArtistTransitionable, AlbumArtistTransitionable, GenreTransitionable, QueryUpdateable, CellAnimatable, EntityContainer, BorderButtonContaining, Refreshable, IndexContaining, EntityVerifiable, TopScrollable {
    
    @IBOutlet weak var tableView: MELTableView!
    
    @objc lazy var headerView: HeaderView = {
        
        let view = HeaderView.fresh
        self.actionsStackView = view.actionsStackView
        self.stackView = view.scrollStackView
        view.showInfo = true
        view.infoButton.addTarget(entityVC, action: #selector(EntityItemsViewController.showOptions), for: .touchUpInside)
        
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
            editView.borderView.centre(actionableActivityIndicator)
            editButton = editView.button
            self.editView = editView
            
            [shuffleView, arrangeBorderView, editView].forEach({ actionsStackView.addArrangedSubview($0) })
        }
    }
    @objc var stackView: UIStackView! {
        
        didSet {
            
            let order = ScrollHeaderSubview.with(title: arrangementLabelText, image: #imageLiteral(resourceName: "Order10"))
            orderLabel = order.label
            
            let duration = ScrollHeaderSubview.with(title: "Duration", image: #imageLiteral(resourceName: "Time10"))
            totalDurationLabel = duration.label
            
            let created = ScrollHeaderSubview.with(title: "Created", image: #imageLiteral(resourceName: "DateAdded"), useSmallerImage: true)
            dateCreatedLabel = created.label
            
            let plays = ScrollHeaderSubview.with(title: "Plays", image: #imageLiteral(resourceName: "Plays"))
            playsLabel = plays.label
            
            for view in [order, duration, created, plays] {
                
                stackView.addArrangedSubview(view)
            }
        }
    }
    
    @objc var activityIndicator = MELActivityIndicatorView.init()
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
    @objc var orderLabel: MELLabel!
    @objc var totalDurationLabel: MELLabel!
    @objc var dateCreatedLabel: MELLabel!
    @objc var playsLabel: MELLabel!
    @objc var shuffleView: BorderedButtonView!
    @objc var arrangeBorderView: BorderedButtonView!
    @objc var editView: BorderedButtonView!
    @objc var actionableActivityIndicator = MELActivityIndicatorView.init()
    
    var borderedButtons = [BorderedButtonView?]()
    var sectionIndexViewController: SectionIndexViewController?
    let requiresLargerTrailingConstraint = false
    var navigatable: Navigatable? { return entityVC }
    
    @objc lazy var sorter: Sorter = { Sorter.init(operation: self.operation) }()
    
    @objc var actionableSongs: [MPMediaItem] { return songs }
    var shouldFillActionableSongs = false
    var showActionsAfterFilling = false
    var collectionsCount: Int { return albums.count }
    var songs = [MPMediaItem]()
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
        
        return [SongAction.collect, .info(context: .album(at: 0, within: [])), .queue(name: name, query: nil), .newPlaylist, .addTo]
    }
    @objc lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
    @objc lazy var refresher: Refresher = { Refresher.init(refreshable: self) }()
    
    @objc lazy var tableDelegate: TableDelegate = { TableDelegate.init(container: self, location: .artistAlbums(withinArtist: self.entityVC?.kind == .artist || self.entityVC?.kind == .albumArtist)) }()
    @objc var entities: [MPMediaEntity] { return albums }
    @objc lazy var filteredEntities = [MPMediaEntity]()
    @objc var query: MPMediaQuery? { return currentArtistQuery }
    @objc var highlightedEntity: MPMediaEntity? { return entityVC?.highlightedEntities?.album }
    @objc var cellDelegate: Any { return self }
    var filterContainer: (UIViewController & FilterContainer)?
    var filterEntities: FilterViewController.FilterEntities { return .collections(albums, kind: .album) }
    var collectionView: UICollectionView?
    
    var sortCriteria = SortCriteria.standard {
        
        didSet {
            
            if let _ = tableView, let _ = arrangeButton {
                
                sortItems()
                orderLabel.text = arrangementLabelText
                
                if let collection = entityVC?.collection {

                    UniversalMethods.saveSortableItem(withPersistentID: collection.persistentID, order: ascending, sortCriteria: sortCriteria, kind: .artistAlbums)
                }
            }
        }
    }
    @objc var ascending = true {
        
        didSet {
            
            if let tableView = tableView, let button = arrangeButton {
                
                albums.reverse()
                
                if filtering {
                    
                    filteredEntities.reverse()
                }
                
                sections = prepareSections(from: albums)
                tableView.reloadData()
                animateCells(direction: .vertical)
                updateImage(for: button)
                
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
    var location: SortLocation = .collections

    @objc weak var entityVC: EntityItemsViewController? { return parent as? EntityItemsViewController }
    @objc var artist: MPMediaItemCollection? { return currentArtistQuery?.collections?.first }
    @objc var currentArtistQuery: MPMediaQuery?
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
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
    lazy var applicableFilterProperties: Set<Property> = { self.applicableCollectionFilterProperties.subtracting([.isCompilation, .artwork, .albumCount, .artist]) }()
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
    @objc var filterOperation: BlockOperation?
    @objc var supplementaryOperation: BlockOperation?
    var actionableOperation: BlockOperation?
    @objc var searchText: String?

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        currentArtistQuery = entityVC?.query?.copy() as? MPMediaQuery
        currentArtistQuery?.groupingType = .album
        
        let inset = entityVC?.peeker != nil ? 0 : entityVC?.inset ?? 0
        tableView.contentInset.top = inset
        tableView.scrollIndicatorInsets.top = inset
        adjustInsets(context: .container)
        
        prepareLifetimeObservers()
        prepareSupplementaryInfo()
        
        tableView.delegate = tableDelegate
        tableView.dataSource = tableDelegate
        tableView.tableHeaderView = headerView
        
        let refreshControl = MELRefreshControl.init()
        refreshControl.addTarget(refresher, action: #selector(Refresher.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        sortItems()
        
        updateImage(for: arrangeButton)
        updateHeaderView(withCount: (currentArtistQuery?.items ?? []).count)
        
        registerForPreviewing(with: self, sourceView: tableView)
        
        prepareGestures()
    }
    
    @objc func prepareGestures() {
        
        let swipeRight = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeRight.direction = .right
        tableView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeLeft.direction = .left
        tableView.addGestureRecognizer(swipeLeft)
        
        let itemOptionsHold = UILongPressGestureRecognizer.init(target: tableDelegate, action: #selector(TableDelegate.showOptions(_:)))
        itemOptionsHold.minimumPressDuration = longPressDuration
        tableView.addGestureRecognizer(itemOptionsHold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: itemOptionsHold))
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
                
        entityVC?.highlightedEntities?.album = collection
        highlightedIndex = albums.index(of: collection)
        scrollToHighlightedRow()
    }
    
    @objc func prepareSupplementaryInfo() {
        
        supplementaryOperation?.cancel()
        supplementaryOperation = BlockOperation()
        supplementaryOperation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self, let _ = weakSelf.viewIfLoaded, let entityVC = weakSelf.entityVC, let collection: MPMediaItemCollection = {
                
                let query = weakSelf.currentArtistQuery?.copy() as? MPMediaQuery
                query?.groupingType = entityVC.kind.grouping
                
                return query?.collections?.first
                
                }() else { return }
            
            let duration = collection.totalDuration.stringRepresentation(as: .short)
            let created = collection.recentlyAdded.timeIntervalSinceNow.shortStringRepresentation
            let plays = collection.totalPlays.formatted
            
            guard weakSelf.supplementaryOperation?.isCancelled == false else { return }
            
            OperationQueue.main.addOperation({
                
                weakSelf.totalDurationLabel.text = duration
                weakSelf.dateCreatedLabel.text = created
                weakSelf.playsLabel.text = plays
            })
        })
        
        sortOperationQueue.addOperation(supplementaryOperation!)
    }
    
    @objc func showOptions(_ sender: Any) {
        
        tableDelegate.showOptions(self)
    }
    
    @objc func showArranger() {
        
        performSegue(withIdentifier: "toArranger", sender: nil)
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
        
        prepareTransientObservers()
        
        if wasFiltering {
            
            invokeSearch()
            wasFiltering = false
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
        
        lifetimeObservers.insert(notifier.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            for cell in weakSelf.tableView.visibleCells {
                
                guard let entityCell = cell as? SongTableViewCell, let indexPath = weakSelf.tableView.indexPath(for: entityCell), let nowPlaying = musicPlayer.nowPlayingItem else {
                    
                    (cell as? SongTableViewCell)?.playingView.isHidden = true
                    (cell as? SongTableViewCell)?.indicator.state = .stopped
                    
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
    }
    
    @objc func updateWithQuery() {
        
        if let entityVC = entityVC {
            
            currentArtistQuery = entityVC.query?.copy() as? MPMediaQuery
        }
        
        currentArtistQuery?.groupingType = .album
        prepareSupplementaryInfo()
        sortItems()
    }
    
    @objc func updateHeaderView(withCount count: Int) {
        
        shuffleButton.superview?.isHidden = count < 2
        tableView.tableHeaderView?.frame.size.height = 92
        tableView.tableHeaderView = headerView
        
        var array = [shuffleView, arrangeBorderView, editView]
        
        if count < 2 {
            
            array.remove(at: 0)
        }
        
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
            
            guard let gr = sender as? UISwipeGestureRecognizer, let indexPath = tableView.indexPathForRow(at: gr.location(in: tableView)) else { return }
            
            let album = getCollection(inSection: indexPath.section, row: indexPath.row)
            
            guard album.representativeItem?.isCompilation == false else {
                
                performSegue(withIdentifier: "toAlbum", sender: album)
                
                return
            }
            
            guard let song = album.representativeItem, entityVC?.kind != .artist else { return }
            
            let filterPredicates: Set<MPMediaPropertyPredicate> = showiCloudItems ? [.for(.artist, using: song.artistPersistentID)] : [.for(.artist, using: song.artistPersistentID), .offline]
            
            let query = MPMediaQuery.init(filterPredicates: filterPredicates)
            query.groupingType = albumArtistsAvailable ? .albumArtist : .artist
            
            if let collections = query.collections, !collections.isEmpty {
                
                artistQuery = query
                currentAlbum = album
                
                performSegue(withIdentifier: .artistUnwind, sender: nil)
                
            } else {
                
                artistQuery = nil
                currentAlbum = nil
                
                let newBanner = Banner.init(title: showiCloudItems ? "This artist is not in your library" : "This artist is not available offline", subtitle: nil, image: nil, backgroundColor: .black, didTapBlock: nil)
                newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                newBanner.show(duration: 0.7)
            }
        }
    }
    
    @IBAction func shuffle() {
        
        guard let songs = currentArtistQuery?.items else { return }
        
        let canShuffleAlbums = songs.canShuffleAlbums
        
        if canShuffleAlbums {
            
            var array = [UIAlertAction]()
            
            let shuffle = UIAlertAction.init(title: .shuffle(.songs), style: .default, handler: { _ in
                
                musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: self.entityVC?.title, alertTitle: .shuffle(.songs))
            })
            
            array.append(shuffle)
            
            let shuffleAlbums = UIAlertAction.init(title: .shuffle(.albums), style: .default, handler: { _ in
                
                musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: self, withTitle: self.entityVC?.title, alertTitle: .shuffle(.albums))
            })
            
            array.append(shuffleAlbums)
            
            present(UIAlertController.withTitle(nil, message: entityVC?.titleLabel.text, style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
            
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
            
            return Transitioner.shared.transition(to: .album, vc: vc, from: self, sender: getCollection(inSection: indexPath.section, row: indexPath.row), preview: true)
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        if let vc = viewControllerToCommit as? BackgroundHideable {
            
            vc.modifyBackgroundView(forState: .removed)
        }
        
        if let vc = viewControllerToCommit as? Arrangeable {
            
            vc.updateImage(for: vc.arrangeButton)
        }
        
        if let vc = viewControllerToCommit as? Peekable {
            
            vc.peeker = nil
            vc.oldArtwork = nil
        }
        
        if let vc = viewControllerToCommit as? Navigatable, let indexer = vc.activeChildViewController as? IndexContaining {
            
            indexer.tableView.contentInset.top = vc.inset
            indexer.tableView.scrollIndicatorInsets.top = vc.inset
            
            if let sortable = indexer as? FullySortable, sortable.highlightedIndex == nil {
                
                indexer.tableView.contentOffset.y = -vc.inset
            }
            
            entityVC?.container?.imageView.image = vc.artworkType.image
            entityVC?.container?.visualEffectNavigationBar.backBorderView.alpha = 1
            entityVC?.container?.visualEffectNavigationBar.backView.isHidden = false
            entityVC?.container?.visualEffectNavigationBar.backLabel.text = vc.backLabelText
            entityVC?.container?.visualEffectNavigationBar.titleLabel.text = vc.title
            entityVC?.container?.visualEffectNavigationBar.animateRelevantConstraints(direction: .forward, section: .end(completed: true), with: nil, and: indexer.navigatable)
        }
        
        show(viewControllerToCommit, sender: nil)
    }
}

// MARK: - Arrangeable
extension ArtistAlbumsViewController: FullySortable {
    
    @objc func sortItems() {
        
        guard let _ = viewIfLoaded else { return }
        
        arrangeButton.alpha = 0
        activityIndicator.startAnimating()
        
        let mainBlock: ([MPMediaItemCollection], [SortSectionDetails]) -> () = { [weak self] array, details in
        
            guard let weakSelf = self, weakSelf.operation?.isCancelled == false else {
                
                self?.activityIndicator.stopAnimating()
                self?.arrangeButton.alpha = 1
                
                return
            }
            
            weakSelf.albums = array
            weakSelf.sections = details
            weakSelf.activityIndicator.stopAnimating()
            weakSelf.arrangeButton.alpha = 1
            weakSelf.updateHeaderView(withCount: (weakSelf.currentArtistQuery?.items ?? []).count)
            
            if weakSelf.filtering, let filterContainer = weakSelf.filterContainer, let text = filterContainer.searchBar?.text {
                
                filterContainer.searchBar?(filterContainer.searchBar, textDidChange: text)
                
            } else {
                
                weakSelf.tableView.reloadData()
                
                if weakSelf.entityVC?.peeker == nil {
                    
                    weakSelf.animateCells(direction: .vertical)
                }
                
                weakSelf.scrollToHighlightedRow()
            }
        }
        
        operation?.cancel()
        operation = BlockOperation()
        operation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self, let operation = weakSelf.operation, !operation.isCancelled, let entities = weakSelf.currentArtistQuery?.collections, !entities.isEmpty else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    self?.arrangeButton.alpha = 1
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
            
            if let entity = self?.entityVC?.highlightedEntities?.album {
                
                self?.highlightedIndex = array.index(of: entity)
            }
            
            guard !operation.isCancelled else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    self?.arrangeButton.alpha = 1
                }
                
                return
            }
            
            let details = weakSelf.prepareSections(from: entities)
            
            OperationQueue.main.addOperation({ mainBlock(array, details) })
        })
        
        sortOperationQueue.addOperation(operation!)
        
        getActionableSongs()
    }
}

extension ArtistAlbumsViewController: CollectionActionable {
    
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
            
            let items = weakSelf.albums.reduce([], { $0 + $1.items })
            
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
