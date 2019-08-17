//
//  SongsViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 07/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SongsViewController: UIViewController, FilterContextDiscoverable, AlbumTransitionable, ArtistTransitionable, AlbumArtistTransitionable, ComposerTransitionable, GenreTransitionable, InfoLoading, CellAnimatable, SingleItemActionable, BorderButtonContaining, Refreshable, IndexContaining, LibrarySectionContainer, EntityVerifiable, TopScrollable, EntityContainer {

    @IBOutlet var tableView: MELTableView!
    lazy var headerView: HeaderView = {
        
        let view = HeaderView.fresh
        self.actionsStackView = view.actionsStackView
        self.stackView = view.scrollStackView
        view.showRecents = showRecentSongs
        view.collectionView.isHidden = true
        view.sortButton.setTitle(arrangementLabelText, for: .normal)
        view.sortButton.addTarget(self, action: #selector(showArranger), for: .touchUpInside)
        self.collectionView = view.collectionView
        view.viewController = self
        view.header.button.addTarget(self, action: #selector(backToStart), for: .touchUpInside)
        view.header.altButton.addTarget(isInDebugMode ? self : self.tableDelegate, action: isInDebugMode ? #selector(backToStart) : #selector(tableDelegate.viewSections), for: .touchUpInside)
        
        return view
    }()
    var actionsStackView: UIStackView! {
        
        didSet {
            
            let shuffleView = BorderedButtonView.with(title: .shuffleButtonTitle, image: #imageLiteral(resourceName: "Shuffle13"), tapAction: .init(action: #selector(shuffle), target: self))
            shuffleButton = shuffleView.button
            self.shuffleView = shuffleView
            
            let filterView = BorderedButtonView.with(title: "Filter", image: #imageLiteral(resourceName: "Filter13"), tapClosure: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                weakSelf.invokeSearch()
            })
            self.filterView = filterView
            
            let editView = BorderedButtonView.with(title: .inactiveEditButtonTitle, image: .inactiveEditImage, tapAction: .init(action: #selector(SongActionManager.toggleEditing(_:)), target: songManager), longPressAction: .init(action: #selector(SongActionManager.showActionsForAll(_:)), target: songManager))
            editButton = editView.button
            self.editView = editView
            
            [shuffleView, filterView, editView].forEach({ actionsStackView.addArrangedSubview($0) })
        }
    }
    
    var stackView: UIStackView! {
        
        didSet {
            
            let duration = ScrollHeaderSubview.with(title: "Duration", image: #imageLiteral(resourceName: "Time10"))
            totalDurationLabel = duration.label
            
            let size = ScrollHeaderSubview.with(title: "Size", image: #imageLiteral(resourceName: "FileSize10"))
            sizeLabel = size.label
            
            let plays = ScrollHeaderSubview.with(title: "Plays", image: #imageLiteral(resourceName: "Plays"))
            playsLabel = plays.label
            
            for view in [duration, size, plays] {
                
                stackView.addArrangedSubview(view)
            }
        }
    }
    
    var activityIndicator = MELActivityIndicatorView.init()
    var arrangeButton: MELButton!
    var editButton: MELButton! {
        
        didSet {
            
            let allHold = UILongPressGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.showActionsForAll(_:)))
            allHold.minimumPressDuration = longPressDuration
            editButton.addGestureRecognizer(allHold)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: allHold))
        }
    }
    var shuffleButton: MELButton!
    var shuffleView: BorderedButtonView!
    var filterView: BorderedButtonView!
    var editView: BorderedButtonView!
    var totalDurationLabel: MELLabel!
    var sizeLabel: MELLabel!
    var playsLabel: MELLabel!
    
    var borderedButtons = [BorderedButtonView?]()
    var sectionIndexViewController: SectionIndexViewController?
    var navigatable: Navigatable? { return libraryVC }
    let requiresLargerTrailingConstraint = false
    
    var actionableSongs: [MPMediaItem] { return filtering ? filteredSongs : songs }
    let applicableActions = [SongAction.collect, .info(context: .album(at: 0, within: [])), .newPlaylist, .addTo]
    lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
    lazy var tableDelegate: TableDelegate = { TableDelegate.init(container: self, location: .songs) }()
    var entities: [MPMediaEntity] { return songs }
    var query: MPMediaQuery? { return songsQuery }
    lazy var filteredEntities = [MPMediaEntity]()
    var highlightedEntity: MPMediaEntity? { return libraryVC?.highlightedEntities?.song }
    var filterContainer: (UIViewController & FilterContainer)?
    var filterEntities: FilterViewController.FilterEntities { return .songs(songs) }
    var highlightedIndex: Int?
    var collectionView: UICollectionView?
    
    lazy var refresher: Refresher = { Refresher.init(refreshable: self) }()
    
    var songs = [MPMediaItem]()
    var filteredSongs: [MPMediaItem] { return filteredEntities as! [MPMediaItem] }
    var ignorePropertyChange = false
    var songsQuery: MPMediaQuery = {
        
        let query = showiCloudItems ? MPMediaQuery.songs() : MPMediaQuery.init(filterPredicates: [.offline, MPMediaPropertyPredicate.init(value: MPMediaType.music.rawValue, forProperty: MPMediaItemPropertyMediaType)])
        
        if showUnaddedMusic {
            
            query.showAll()
        }
        
        return query
    }()
    lazy var sections = [SortSectionDetails]()
    lazy var filtering = false
    var filterText: String?
    var entityCount: Int { return songs.count }
    var ignoreKeyboardForInset = true
    lazy var wasFiltering = false
    var unfilteredPoint = CGPoint.zero
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
    var lifetimeObservers = Set<NSObject>()
    var transientObservers = Set<NSObject>()
    var firstLaunch = true
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var albumQuery: MPMediaQuery?
    @objc var composerQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    
    weak var libraryVC: LibraryViewController? { return parent as? LibraryViewController }
    
    var sortCriteria = SortCriteria(rawValue: songsCriteria) ?? .standard {
        
        didSet {
            
            if let _ = tableView {
                
                sortItems()
                headerView.sortButton.setTitle(arrangementLabelText, for: .normal)
                UIView.animate(withDuration: 0.3, animations: { self.headerView.layoutIfNeeded() })
                
                prefs.set(sortCriteria.rawValue, forKey: .songsSort)
            }
        }
    }
    var sortLocation: SortLocation = .songs
    var applySort = true
    var ascending = prefs.bool(forKey: .songsOrder) {
        
        didSet {
            
            if let _ = tableView {
                
                if applySort {
                    
                    sortItems()
                }
                prefs.set(ascending, forKey: .songsOrder)
            }
        }
    }
    
    let applicableSortCriteria: Set<SortCriteria> = [.duration, .artist, .album, .plays, .lastPlayed, .genre, .rating, .dateAdded, .year, .title, .fileSize]
    lazy var applicableFilterProperties: Set<Property> = { self.applicationItemFilterProperties }()
    lazy var sorter: Sorter = { Sorter.init(operation: self.operation) }()
    
    var operations = ImageOperations()
    @objc var infoOperations = InfoOperations()
    @objc let infoCache: InfoCache = {
        
        let cache = InfoCache()
        cache.name = "Info Cache"
        cache.countLimit = 2500
        
        return cache
    }()
    let imageOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Image Operation Queue"
        
        
        return queue
    }()
    let imageCache: ImageCache = {
        
        let cache = ImageCache()
        cache.name = "Image Cache"
        cache.countLimit = 500
        
        return cache
    }()
    
    let sortOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Songs Sort Operation Queue"
//        queue.qualityOfService = .userInteractive
        
        return queue
    }()
    var operation: BlockOperation?
    var recentOperation: BlockOperation?
    var filterOperation: BlockOperation?
    @objc var supplementaryOperation: BlockOperation?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        updateTopInset()
        adjustInsets(context: .container)
        
        updateTopLabels(setTitle: true)
        
        prepareLifetimeObservers()

        tableView.delegate = tableDelegate
        tableView.dataSource = tableDelegate
        tableView.tableFooterView = UIView.init(frame: .zero)
        tableView.tableHeaderView = headerView
//        tableView.tableHeaderView?.frame.size.height = 92
        
        let refreshControl = MELRefreshControl.init()
        refreshControl.addTarget(refresher, action: #selector(Refresher.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        prepareSupplementaryInfo(animated: false)
        updateHeaderView(withCount: (songsQuery.items ?? []).count)
        
        prepareGestures()
        
        sortItems()
    }
    
    func updateTopInset() {
        
        tableView.contentInset.top = libraryVC?.inset ?? VisualEffectNavigationBar.Location.main.total
        tableView.scrollIndicatorInsets.top = libraryVC?.inset ?? VisualEffectNavigationBar.Location.main.total
    }
    
    @objc func prepareSupplementaryInfo(animated: Bool = true) {
        
        if animated {
            
            UIView.animate(withDuration: 0.3, animations: { self.headerView.layoutIfNeeded() })
        }
        
        supplementaryOperation?.cancel()
        supplementaryOperation = BlockOperation()
        supplementaryOperation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self, let items = weakSelf.songsQuery.items else { return }
            
            let totalDuration = items.totalDuration.stringRepresentation(as: .short)
            let totalSize = FileSize.init(actualSize: items.totalSize).actualSize.fileSizeRepresentation
            let plays = items.totalPlays
            
            guard weakSelf.supplementaryOperation?.isCancelled == false else { return }
            
            OperationQueue.main.addOperation({
                
                weakSelf.totalDurationLabel.text = totalDuration
                weakSelf.sizeLabel.text = totalSize
                weakSelf.playsLabel.text = plays.formatted
            })
        })
        
        sortOperationQueue.addOperation(supplementaryOperation!)
    }
    
    func prepareGestures() {
        
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
    
    @objc func revealEntity(_ sender: Any) {
        
        guard let indexPath: IndexPath = {
            
            if let gr = sender as? UIGestureRecognizer {
                
                guard gr.state == .began else { return nil }
                
                return tableView.indexPathForRow(at: gr.location(in: tableView))
            }
            
            return sender as? IndexPath
            
        }() else { return }
        
        let song = getSong(from: indexPath, filtering: true)
        
        highlightedIndex = songs.firstIndex(of: song)
        scrollToHighlightedRow()
    }
   
    @objc func showOptions(_ sender: Any) {
        
        tableDelegate.showOptions(sender)
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
    
    func updateHeaderView(withCount count: Int) {
        
        tableView.tableHeaderView?.frame.size.height = 92 + (showRecentSongs ? headerView.collectionViewHeaderHeightConstraint.constant + headerView.collectionViewHeightConstraint.constant : 0)
        shuffleButton.superview?.isHidden = count < 2
        tableView.tableHeaderView = headerView
        
        var array = [shuffleView, filterView, editView]
        
        if count < 2 {
            
            array.remove(at: 0)
        }
        
        borderedButtons = array
        
        updateButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        prepareTransientObservers()
        
        let count = (firstLaunch ? (songsQuery.items ?? []) : songs).count
        
        updateHeaderView(withCount: count)
        
        let text = showiCloudItems ? "There are no songs in your library" : "There are no offline songs in your library"
        
        libraryVC?.updateEmptyLabel(withCount: count, text: text)
        libraryVC?.setCurrentOptions()
        
        if firstLaunch {
            
            firstLaunch = false
        }
        
        if count > 1 {
            
            if wasFiltering {
                
                invokeSearch()
                wasFiltering = false
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        unregisterAll(from: transientObservers)
    }
    
    func handleRightSwipe(_ sender: Any) {
        
        songManager.updateAddView(editing: true)
        
        tableView.setEditing(true, animated: true)
        
        if let collectionView = collectionView {
            
            collectionView.reloadData()//reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
    }
    
    func handleLeftSwipe(_ sender: Any) {
        
        if tableView.isEditing {
            
            songManager.updateAddView(editing: false)
            
            tableView.setEditing(false, animated: true)
            
            if let collectionView = collectionView {
                
                collectionView.reloadData()//reloadItems(at: collectionView.indexPathsForVisibleItems)
            }
        
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
    
    func updateTopLabels(setTitle: Bool) {
        
        libraryVC?.updateViews(inSection: .songs, count: (songsQuery.items ?? []).count, setTitle: setTitle)
    }
    
    @objc func updateWithQuery() {
        
        prepareSupplementaryInfo()
        sortItems()
    }
    
    func prepareTransientObservers() {
        
        let queueObserver = notifier.addObserver(forName: .endQueueModification, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.tableView.isEditing { weakSelf.songManager.toggleEditing(notification) }
        })
        
        transientObservers.insert(queueObserver as! NSObject)
        
        let reloadObserver = notifier.addObserver(forName: .songWasEdited, object: self, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let indexPath = notification.userInfo?["indexPath"] as? IndexPath else { return }
            
            weakSelf.tableView.reloadRows(at: [indexPath], with: .none)
        })
        
        transientObservers.insert(reloadObserver as! NSObject)
    }
    
    func prepareLifetimeObservers() {
        
        lifetimeObservers.insert(notifier.addObserver(forName: .resetInsets, object: nil, queue: nil, using: { [weak self] _ in self?.adjustInsets(context: .container) }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .iCloudVisibilityChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            if showiCloudItems {
                
                weakSelf.songsQuery.removeFilterPredicate(.offline)
                
            } else {
                
                weakSelf.songsQuery.addFilterPredicate(.offline)
            }
            
            weakSelf.updateWithQuery()
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .libraryUpdated, object: appDelegate, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.sortItems()
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
                
            for cell in weakSelf.tableView.visibleCells {
                
                guard let cell = cell as? SongTableViewCell, let indexPath = weakSelf.tableView.indexPath(for: cell) else { continue }
                
                if cell.playingView.isHidden.inverted && musicPlayer.nowPlayingItem != weakSelf.getSong(from: indexPath) {
                    
                    cell.playingView.isHidden = true
                    cell.indicator.state = .stopped
                
                } else if cell.playingView.isHidden && musicPlayer.nowPlayingItem == weakSelf.getSong(from: indexPath) {
                    
                    cell.playingView.isHidden = false
                    UniversalMethods.performOnMainThread({ cell.indicator.state = musicPlayer.isPlaying ? .playing : .paused }, afterDelay: 0.1)
                }
            }
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .showUnaddedSongsChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.songsQuery = weakSelf.getCurrentQuery()
            weakSelf.sortItems()
            weakSelf.updateTopLabels(setTitle: true)
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .showExplicitnessChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.tableView.reloadRows(at: weakSelf.tableView.indexPathsForVisibleRows ?? [], with: .none)
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .playOnlyChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.collectionView?.reloadData()
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .showRecentSongsChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.getRecents()
            
            if weakSelf.sortCriteria == .random {
                
                weakSelf.tableView.beginUpdates()
                weakSelf.tableView.endUpdates()
            }
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .headerHeightCalculated, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateTopInset()
            weakSelf.updateHeaderView(withCount: weakSelf.songs.count)
            
        }) as! NSObject)
    }
    
    func getCurrentQuery() -> MPMediaQuery {
        
        let query = showiCloudItems ? MPMediaQuery.songs() : MPMediaQuery.init(filterPredicates: [.offline])
        
        if showUnaddedMusic {
            
            query.showAll()
        }
        
        return query
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
            
            case "toArranger": Transitioner.shared.transition(to: segue.destination, from: self)
            
            default: break
        }
    }
    
    @IBAction func shuffle() {
        
        let songs = songsQuery.items ?? self.songs
        let canShuffleAlbums = songs.canShuffleAlbums
        
        if canShuffleAlbums {
            
            var array = [AlertAction]()
            
            let shuffle = AlertAction.init(title: .shuffle(.songs), style: .default, requiresDismissalFirst: true, handler: {
                
                musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: "All " ?+ self.libraryVC?.preferredTitle, alertTitle: .shuffle(.songs))
            })
            
            array.append(shuffle)
            
            let shuffleAlbums = AlertAction.init(title: .shuffle(.albums), style: .default, requiresDismissalFirst: true, handler: {
                
                musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: self, withTitle: "All" ?+ self.libraryVC?.preferredTitle, alertTitle: .shuffle(.albums))
            })
            
            array.append(shuffleAlbums)
            
            Transitioner.shared.showAlert(title: "All " ?+ self.libraryVC?.preferredTitle, from: self, with: array)
            
        } else {
            
            musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: "All Songs", alertTitle: .shuffle())
        }
    }
    
    @objc func backToStart() {
        
        collectionView?.setContentOffset(.zero, animated: true)
    }

    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "SVC going away...").show(for: 0.3)
        }
        
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
    
    func getIndex(from indexPath: IndexPath) -> Int {
        
        if filtering {
            
            return indexPath.row
            
        } else {
            
            switch sortCriteria {
                
                case .standard:
                    
                    if let itemSections = songsQuery.itemSections {
                        
                        return itemSections[indexPath.section].range.location + indexPath.row
                        
                    } else {
                        
                        return indexPath.row
                    }
                    
                case .random: return indexPath.row
                    
                default: return sections[indexPath.section].startingPoint + indexPath.row
            }
        }
    }
    
    func getSong(inSection section: Int, row: Int, filtering: Bool = false) -> MPMediaItem {
        
        if filtering {
            
            return filteredSongs[row]
            
        } else {
            
            switch sortCriteria {
                
                case .standard:
                    
                    if let itemSections = songsQuery.itemSections {
                        
                        return songs[itemSections[section].range.location + row]
                        
                    } else {
                        
                        return songs[row]
                    }
                    
                case .random: return songs[row]
                    
                default: return songs[sections[section].startingPoint + row]
            }
        }
    }
    
    func getSong(from indexPath: IndexPath, filtering: Bool = false) -> MPMediaItem {
        
        return getSong(inSection: indexPath.section, row: indexPath.row, filtering: filtering)
    }
}

extension SongsViewController: TableViewContainer {
    
    func selectCell(in tableView: UITableView, at indexPath: IndexPath, filtering: Bool) {
        
        let song = getSong(from: indexPath, filtering: filtering)
        
        musicPlayer.play(filtering ? filteredSongs : songs, startingFrom: song, from: filterContainer ?? self, withTitle: "All Songs", subtitle: "Starting from \(song.validTitle)", alertTitle: "Play", completion: { [weak self] in
            
            guard let weakSelf = self, filtering, let container = weakSelf.filterContainer else { return }
            
            container.saveRecentSearch(withTitle: container.searchBar.text, resignFirstResponder: false)
        })
    }
    
    func getEntity(at indexPath: IndexPath, filtering: Bool = false) -> MPMediaEntity {
        
        return getSong(from: indexPath, filtering: filtering)
    }
}

extension SongsViewController: FullySortable {
    
    func sortItems() {
        
        headerView.updateSortActivityIndicator(to: .visible)
        
        let mainBlock: ([MPMediaItem], [SortSectionDetails]) -> () = { [weak self] array, details in
            
            guard let weakSelf = self, weakSelf.operation?.isCancelled == false else {
                
                self?.headerView.updateSortActivityIndicator(to: .hidden)
                
                return
            }
            
            weakSelf.songs = array
            weakSelf.sections = details
            weakSelf.headerView.updateSortActivityIndicator(to: .hidden)
            weakSelf.updateTopLabels(setTitle: weakSelf.libraryVC?.container?.activeViewController?.topViewController == weakSelf.libraryVC)
            weakSelf.updateHeaderView(withCount: array.count)
            weakSelf.libraryVC?.updateEmptyLabel(withCount: array.count, text: "There are no songs in your library")
            
            if weakSelf.filtering, let filterContainer = weakSelf.filterContainer, let text = filterContainer.searchBar?.text {
                
                filterContainer.searchBar?(filterContainer.searchBar, textDidChange: text)
                
            } else {
                
                weakSelf.headerView.showRecents = showRecentSongs && weakSelf.sortCriteria != .dateAdded
                weakSelf.updateHeaderView(withCount: array.count)
                weakSelf.tableView.reloadData()
                weakSelf.animateCells(direction: .vertical, alphaOnly: weakSelf.highlightedIndex != nil)
                
                weakSelf.scrollToHighlightedRow()
            }
        }
        
        operation?.cancel()
        operation = BlockOperation()
//        operation?.qualityOfService = .userInteractive
        operation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self, let weakOperation = weakSelf.operation, !weakOperation.isCancelled, let items = weakSelf.songsQuery.items, !items.isEmpty else {
                
                UniversalMethods.performInMain {
                    
                    self?.headerView.updateSortActivityIndicator(to: .hidden)
                }
                
                return
            }
            
            let array: [MPMediaItem] = {
                
                switch weakSelf.sortCriteria {
                    
                    case .random: return items.shuffled()
                    
                    case .standard: return weakSelf.ascending ? items : items.reversed()
                    
                    default: return (items as NSArray).sortedArray(using: weakSelf.sortDescriptors) as! [MPMediaItem]
                }
            }()
            
            UniversalMethods.performInMain {
                
                if let song = weakSelf.libraryVC?.highlightedEntities?.song {
                    
                    weakSelf.highlightedIndex = array.firstIndex(of: song)
                }
            }
            
            guard !weakOperation.isCancelled else {
                
                UniversalMethods.performInMain {
                    
                    self?.headerView.updateSortActivityIndicator(to: .hidden)
                }
                
                return
            }
            
            let details = weakSelf.prepareSections(from: array)
            
            OperationQueue.main.addOperation({ mainBlock(array, details) })
        })
        
        sortOperationQueue.addOperation(operation!)
        
        getRecents()
    }
    
    func getRecents() {
        
        if showRecentSongs.inverted {
            
            recentOperation?.cancel()
            headerView.activityIndicatorView.stopAnimating()
            headerView.loadingEffectView.isHidden = true
            headerView.showRecents = showRecentSongs
            updateHeaderView(withCount: songsQuery.items?.count ?? 0)
            
            return
        
        } else {
            
            headerView.showRecents = showRecentSongs
            updateHeaderView(withCount: songsQuery.items?.count ?? 0)
        }
        
        guard Set(headerView.songs) != Set(songsQuery.items ?? []) else {
            
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
            
        if sortCriteria != .dateAdded && (songsQuery.items ?? []).count > 0 {
            
            headerView.activityIndicatorView.startAnimating()
            headerView.loadingEffectView.effect = headerView.songs.isEmpty ? nil : Themer.vibrancyContainingEffect
            headerView.loadingEffectView.isHidden = false
            collectionView?.isUserInteractionEnabled = false
        }
        
        recentOperation?.cancel()
        recentOperation = BlockOperation()
        recentOperation?.addExecutionBlock { [weak self] in
            
            guard let weakSelf = self, let weakOperation = weakSelf.recentOperation, !weakOperation.isCancelled, let items = weakSelf.songsQuery.items, !items.isEmpty else {
                
                return
            }
            
            let array = (items as NSArray).sortedArray(using: [NSSortDescriptor.init(key: #keyPath(MPMediaItem.validDateAdded), ascending: false)]) as! [MPMediaItem]
            
            guard !weakOperation.isCancelled else {
                
                return
            }
            
            OperationQueue.main.addOperation {
                
                guard !weakOperation.isCancelled else {
                    
                    return
                }
                
                weakSelf.headerView.songs = array
                
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

//extension SongsViewController: SongCellButtonDelegate {
//    
//    func showOptionsForSong(in cell: SongTableViewCell) {
//        
//        guard let indexPath = tableView.indexPath(for: cell) else { return }
//        
//        showOptions(indexPath)
//    }
//}

