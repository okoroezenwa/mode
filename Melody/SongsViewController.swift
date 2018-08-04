//
//  SongsViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 07/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SongsViewController: UIViewController, FilterContextDiscoverable, AlbumTransitionable, ArtistTransitionable, AlbumArtistTransitionable, ComposerTransitionable, GenreTransitionable, InfoLoading, SongContainer, CellAnimatable, SingleItemActionable, BorderButtonContaining, Refreshable, IndexContaining, LibrarySectionContainer, EntityVerifiable, TopScrollable {

    @IBOutlet weak var tableView: MELTableView!
    lazy var headerView: HeaderView = {
        
        let view = HeaderView.fresh
        self.actionsStackView = view.actionsStackView
        self.stackView = view.scrollStackView
        view.showRecents = showRecentSongs
        view.collectionView.isHidden = true
        self.collectionView = view.collectionView
        view.viewController = self
        view.header.button.addTarget(self, action: #selector(backToStart), for: .touchUpInside)
        view.header.altButton.addTarget(self.tableDelegate, action: #selector(tableDelegate.viewSections), for: .touchUpInside)
        
        return view
    }()
    var actionsStackView: UIStackView! {
        
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
    
    var stackView: UIStackView! {
        
        didSet {
            
            let view = ScrollHeaderSubview.with(title: arrangementLabelText, image: #imageLiteral(resourceName: "Order10"))
            
            orderLabel = view.label
            
            for view in [view] {
                
                stackView.addArrangedSubview(view)
            }
        }
    }
    
    var orderLabel: MELLabel!
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
    var arrangeBorderView: BorderedButtonView!
    var editView: BorderedButtonView!
    
    var borderedButtons = [BorderedButtonView?]()
    var sectionIndexViewController: SectionIndexViewController?
    let requiresLargerTrailingConstraint = false
    
    var actionableSongs: [MPMediaItem] { return filtering ? filteredSongs : songs }
    let applicableActions = [SongAction.collect, .info(context: .album(at: 0, within: [])), .newPlaylist, .addTo]
    lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
    lazy var tableDelegate: TableDelegate = { TableDelegate.init(container: self, location: .songs) }()
    var entities: [MPMediaEntity] { return songs }
    var query: MPMediaQuery? { return songsQuery }
    lazy var filteredEntities = [MPMediaEntity]()
    var highlightedEntity: MPMediaEntity?
    var filterContainer: (UIViewController & FilterContainer)?
    var filterEntities: FilterViewController.FilterEntities { return .songs(songs) }
    var cellDelegate: Any { return songDelegate }
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
    lazy var songDelegate: SongDelegate = { SongDelegate.init(container: self) }()
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
            
            if let _ = tableView, let label = orderLabel {
                
                sortItems()
                label.text = arrangementLabelText
                prefs.set(sortCriteria.rawValue, forKey: .songsSort)
            }
        }
    }
    var location: SortLocation = .songs
    var ascending = prefs.bool(forKey: .songsOrder) {
        
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
        queue.maxConcurrentOperationCount = 3
        
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
        queue.maxConcurrentOperationCount = 3
        
        return queue
    }()
    var operation: BlockOperation?
    var recentOperation: BlockOperation?
    var filterOperation: BlockOperation?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        adjustInsets(context: .container)
        
        updateTopLabels()
        
        prepareLifetimeObservers()

        tableView.delegate = tableDelegate
        tableView.dataSource = tableDelegate
        tableView.tableFooterView = UIView.init(frame: .zero)
        tableView.tableHeaderView = headerView
//        tableView.tableHeaderView?.frame.size.height = 92
        
        let refreshControl = MELRefreshControl.init()
        refreshControl.addTarget(refresher, action: #selector(Refresher.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        updateHeaderView(withCount: (songsQuery.items ?? []).count)
        
        prepareGestures()
        
        sortItems()
        updateImage(for: arrangeButton)
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
    
    @objc func showFilteredContext(_ sender: Any) {
        
        guard let indexPath: IndexPath = {
            
            if let gr = sender as? UIGestureRecognizer {
                
                guard gr.state == .began else { return nil }
                
                return tableView.indexPathForRow(at: gr.location(in: tableView))
            }
            
            return sender as? IndexPath
            
        }() else { return }
        
        let song = getSong(from: indexPath, filtering: true)
        
        highlightedIndex = songs.index(of: song)
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
        
        var array = [shuffleView, arrangeBorderView, editView]
        
        if count < 2 {
            
            array.remove(at: 0)
        }
        
        borderedButtons = array
        
        updateButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
//        for cell in tableView.visibleCells {
//            
//            if let cell = cell as? SongTableViewCell, !cell.playingView.isHidden {
//                
//                cell.indicator.state = musicPlayer.isPlaying ? .playing : .paused
//            }
//        }
        
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
            
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
    }
    
    func handleLeftSwipe(_ sender: Any) {
        
        if tableView.isEditing {
            
            songManager.updateAddView(editing: false)
            
            tableView.setEditing(false, animated: true)
            
            if let collectionView = collectionView {
                
                collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
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
    
    func updateTopLabels(withFilteredCount count: Int? = nil) {
        
        libraryVC?.updateViews(inSection: .songs, count: (songsQuery.items ?? []).count, filteredCount: count)
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
            
            weakSelf.sortItems()
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .libraryUpdated, object: appDelegate, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.sortItems()
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.tableView.reloadData()
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .showUnaddedSongsChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.songsQuery = weakSelf.getCurrentQuery()
            weakSelf.sortItems()
            weakSelf.updateTopLabels()
            
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
            
            var array = [UIAlertAction]()
            
            let shuffle = UIAlertAction.init(title: .shuffle(.songs), style: .default, handler: { _ in
                
                musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: self.libraryVC?.titleButton.titleLabel?.text, alertTitle: .shuffle(.songs))
            })
            
            array.append(shuffle)
            
            let shuffleAlbums = UIAlertAction.init(title: .shuffle(.albums), style: .default, handler: { _ in
                
                musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: self, withTitle: self.libraryVC?.titleButton.titleLabel?.text, alertTitle: .shuffle(.albums))
            })
            
            array.append(shuffleAlbums)
            
            present(UIAlertController.withTitle(nil, message: libraryVC?.titleButton.titleLabel?.text?.lowercased(), style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
            
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

extension SongsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if filtering {
            
            return filteredSongs.count
            
        } else {
            
            switch sortCriteria {
                
                case .standard: return !songs.isEmpty ? songsQuery.itemSections?[section].range.length ?? songs.count : songs.count
                
                case .random: return songs.count
                
                default: return sections[section].count
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if filtering {
            
            return 1
            
        } else {
            
            switch sortCriteria {
                
                case .standard: return songsQuery.itemSections?.count ?? 1
                
                case .random: return 1
                
                default: return sections.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        operations[indexPath]?.cancel()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.songCell(for: indexPath)
        
//        cell.delegate = songDelegate
//        cell.scrollDelegate = songDelegate
        
        let song = getSong(from: indexPath)
        
        cell.prepare(with: song)
        updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: tableView)

        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        guard !filtering else { return nil }
        
        switch sortCriteria {
            
            case .standard:
                
                let array = songsQuery.itemSections?.map({ $0.title })
                
                return ascending ? array : array?.reversed()
            
            case .random: return nil
                
            default: return sections.map({ $0.indexTitle })
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing {
            
            self.tableView(tableView, commit: .insert, forRowAt: indexPath)
        
        } else {
            
            let song = getSong(from: indexPath)
            
            musicPlayer.play(filtering ? filteredSongs : songs, startingFrom: song, from: self, withTitle: "All Songs", subtitle: "Starting from \(song.validTitle)", alertTitle: "Play")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        return .insert
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .insert {
            
            let song = getSong(from: indexPath)
            
            notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: [song]])
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard !songs.isEmpty else { return nil }
        
        let header = tableView.sectionHeader
        
        if filtering {
            
            header?.label.text = nil
            
        } else {
            
            switch sortCriteria {
                
                case .random: header?.label.text = nil
                
                case .standard:
                    
                    if let _ = songsQuery.itemSections {
                        
                        header?.label.text = self.sectionIndexTitles(for: tableView)?[section]
                    
                    } else {
                        
                        header?.label.text = nil
                    }
                    
                default:
                    
                    header?.label.text = sections[section].title.uppercased()
            }
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if filtering {
            
            return 11
            
        } else {
            
            switch sortCriteria {
                
                case .random,
                     .standard where songsQuery.itemSections == nil: return 11
                    
                default:
                    
                    let height = ("eh" as NSString).boundingRect(with: .init(width: 100, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.myriadPro(ofWeight: .light, size: 20)], context: nil).height
                    
                    return height + 24
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.001
    }
}

extension SongsViewController: Arrangeable {
    
    func sortItems() {
        
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
            weakSelf.updateTopLabels()
            weakSelf.updateHeaderView(withCount: array.count)
            weakSelf.libraryVC?.updateEmptyLabel(withCount: array.count, text: "There are no songs in your library")
            
            if weakSelf.filtering, let filterContainer = weakSelf.filterContainer, let text = filterContainer.searchBar?.text {
                
                filterContainer.searchBar?(filterContainer.searchBar, textDidChange: text)
                
            } else {
                
                weakSelf.headerView.showRecents = showRecentSongs && weakSelf.sortCriteria != .dateAdded
                weakSelf.updateHeaderView(withCount: array.count)
                weakSelf.tableView.reloadData()
                weakSelf.animateCells(direction: .vertical)
            }
        }
        
        operation?.cancel()
        operation = BlockOperation()
        operation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self, let weakOperation = weakSelf.operation, !weakOperation.isCancelled, let items = weakSelf.songsQuery.items, !items.isEmpty else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    self?.arrangeButton.alpha = 1
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
            
            guard !weakOperation.isCancelled else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    self?.arrangeButton.alpha = 1
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

