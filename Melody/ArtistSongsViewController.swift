//
//  ArtistSongsViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/11/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ArtistSongsViewController: UIViewController, FilterContextDiscoverable, InfoLoading, AlbumTransitionable, GenreTransitionable, ArtistTransitionable, AlbumArtistTransitionable, ComposerTransitionable, SongContainer, QueryUpdateable, CellAnimatable, SingleItemActionable, BorderButtonContaining, Refreshable, IndexContaining, EntityVerifiable, TopScrollable {
    
    @IBOutlet weak var tableView: MELTableView!
    
    @objc lazy var headerView: HeaderView = {
        
        let view = HeaderView.fresh
        self.actionsStackView = view.actionsStackView
        self.stackView = view.scrollStackView
        
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
            LongPressManager.shared.gestureRecognisers.insert(Weak.init(value: allHold))
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
    
    var borderedButtons = [BorderedButtonView?]()
    var sectionIndexViewController: SectionIndexViewController?
    let requiresLargerTrailingConstraint = false
    
    @objc var actionableSongs: [MPMediaItem] { return filtering ? filteredSongs : songs }
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
    
    @objc lazy var tableDelegate: TableDelegate = { TableDelegate.init(container: self, location: .artistSongs(withinArtist: self.entityVC?.kind == .artist || self.entityVC?.kind == .albumArtist)) }()
    @objc var entities: [MPMediaEntity] { return songs }
    @objc var query: MPMediaQuery? { return currentArtistQuery }
    @objc lazy var filteredEntities = [MPMediaEntity]()
    @objc var highlightedEntity: MPMediaEntity? { return entityVC?.highlightedEntities?.song }
    @objc var cellDelegate: Any { return songDelegate }
    var filterContainer: (UIViewController & FilterContainer)?
    var filterEntities: FilterViewController.FilterEntities { return .songs(songs) }
    var ignorePropertyChange = false
    var collectionView: UICollectionView?
    
    @objc lazy var refresher: Refresher = { Refresher.init(refreshable: self) }()
    
    @objc weak var entityVC: EntityItemsViewController? { return parent as? EntityItemsViewController }
    @objc var artist: MPMediaItemCollection? { return currentArtistQuery?.collections?.first }
    @objc var currentArtistQuery: MPMediaQuery?
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var albumQuery: MPMediaQuery?
    @objc var composerQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    
    @objc var ascending = true {
        
        didSet {
            
            if let tableView = tableView, let button = arrangeButton, let id = entityVC?.collection?.persistentID {
                
                songs.reverse()
                
                if filtering {
                    
                    filteredEntities.reverse()
                }
                
                sections = entityVC?.kind == .artist ? altSections().details : prepareSections(from: songs)
                UniversalMethods.saveSortableItem(withPersistentID: id, order: ascending, sortCriteria: sortCriteria, kind: .artistSongs)
                tableView.reloadData()
                animateCells(direction: .vertical)
                updateImage(for: button)
            }
        }
    }
    var location: SortLocation = .songs
    var sortCriteria = SortCriteria.standard {
        
        didSet {
            
            if let _ = tableView, let id = entityVC?.collection?.persistentID {
                
                sortItems()
                orderLabel.text = arrangementLabelText
                UniversalMethods.saveSortableItem(withPersistentID: id, order: ascending, sortCriteria: sortCriteria, kind: .artistSongs)
            }
        }
    }
    var applicableSortCriteria: Set<SortCriteria> {
        
        get {
            
            guard let entityVC = entityVC else { return [] }
            
            let set: Set<SortCriteria> = [.duration, .artist, .album, .plays, .lastPlayed, .genre, .rating, .dateAdded, .title, .fileSize]
            
            switch entityVC.kind {
                
                case .artist, .albumArtist: return set.subtracting([.artist])
                    
                case .genre: return set.subtracting([.genre])
                
                case .composer: return set
            }
        }
    }
    lazy var applicableFilterProperties: Set<Property> = { self.applicationItemFilterProperties.subtracting([.artist]) }()
    @objc var songs = [MPMediaItem]()
    @objc var filteredSongs: [MPMediaItem] { return filteredEntities as! [MPMediaItem] }
    lazy var sections = [SortSectionDetails]()
    @objc lazy var filtering = false
    var filterText: String?
    var entityCount: Int { return songs.count }
    @objc var ignoreKeyboardForInset = true
    @objc lazy var wasFiltering = false
    
    @objc var lifetimeObservers = Set<NSObject>()
    @objc var transientObservers = Set<NSObject>()
    var highlightedIndex: Int?
    @objc lazy var songDelegate: SongDelegate = { SongDelegate.init(container: self) }()
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
    @objc var operations = ImageOperations()
    @objc var infoOperations = InfoOperations()
    @objc lazy var sorter: Sorter = { Sorter.init(operation: self.operation) }()
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
    @objc let infoCache: InfoCache = {
        
        let cache = InfoCache()
        cache.name = "Info Cache"
        cache.countLimit = 2500
        
        return cache
    }()
    @objc let sortOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Sort Operation Queue"
        queue.maxConcurrentOperationCount = 3
        
        return queue
    }()
    @objc var operation: BlockOperation?
    @objc var filterOperation: BlockOperation?
    @objc var supplementaryOperation: BlockOperation?
    @objc var searchText: String?
    
    // MARK: - Methods

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        currentArtistQuery = entityVC?.query?.copy() as? MPMediaQuery
        currentArtistQuery?.groupingType = .title        
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
        LongPressManager.shared.gestureRecognisers.insert(Weak.init(value: itemOptionsHold))
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
    
    @objc func prepareSupplementaryInfo() {
        
        supplementaryOperation?.cancel()
        supplementaryOperation = BlockOperation()
        supplementaryOperation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self, let _ = weakSelf.viewIfLoaded, let entityVC = weakSelf.entityVC, let collection: MPMediaItemCollection = {
                
                let query = weakSelf.currentArtistQuery?.copy() as? MPMediaQuery
                query?.groupingType = entityVC.kind.grouping/*{
                    
                    switch entityVC.kind {
                        
                        case .artist: return .artist
                            
                        case .composer: return .composer
                            
                        case .genre: return .genre
                    }
                }()*/
                
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
        
        let reloadObserver = notifier.addObserver(forName: .songWasEdited, object: self, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let indexPath = notification.userInfo?["indexPath"] as? IndexPath else { return }
            
            weakSelf.tableView.reloadRows(at: [indexPath], with: .none)
        })
        
        transientObservers.insert(reloadObserver as! NSObject)
        
        let secondaryObserver = notifier.addObserver(forName: .performSecondaryAction, object: navigationController, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self, weakSelf.songs.count > 1 else { return }
            
            weakSelf.invokeSearch()
        })
        
        transientObservers.insert(secondaryObserver as! NSObject)
    }

    @objc func prepareLifetimeObservers() {
        
        lifetimeObservers.insert((notifier.addObserver(forName: .resetInsets, object: nil, queue: nil, using: { [weak self] _ in self?.adjustInsets(context: .container) })) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.tableView.reloadData()
            
        }) as! NSObject)
        
        lifetimeObservers.insert((notifier.addObserver(forName: .libraryUpdated, object: appDelegate, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateWithQuery()
            
        })) as! NSObject)
    }
    
    @objc func updateWithQuery() {
        
        if let entityVC = entityVC {
            
            currentArtistQuery = entityVC.query?.copy() as? MPMediaQuery
        }
        
        currentArtistQuery?.groupingType = .title
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
    
    @objc func getSong(inSection section: Int, row: Int, filtering: Bool = false) -> MPMediaItem {
        
        if filtering {
            
            return filteredSongs[row]
            
        } else {
            
            switch sortCriteria {
                
                case .standard:
                    
                    if entityVC?.kind == .artist || entityVC?.kind == .albumArtist {
                        
                        return songs[sections[section].startingPoint + row]
                    }
                
                    if let itemSections = currentArtistQuery?.itemSections {
                        
                        return songs[itemSections[section].range.location + row]
                        
                    } else {
                        
                        return songs[row]
                    }
                
                case .random: return songs[row]
                
                default: return songs[sections[section].startingPoint + row]
            }
        }
    }
    
    @objc func getSong(from indexPath: IndexPath, filtering: Bool = false) -> MPMediaItem {
        
        return getSong(inSection: indexPath.section, row: indexPath.row, filtering: filtering)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier else { return }
        
        switch id {
            
            case "toArranger": Transitioner.shared.transition(to: segue.destination, from: self)
            
            default: break
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "ASVC going away...").show(for: 0.3)
        }
        
        unregisterAll(from: lifetimeObservers)
        notifier.removeObserver(self)
        
        operation?.cancel()
    }
}

extension ArtistSongsViewController: TableViewContainer {
    
    @objc func selectCell(in tableView: UITableView, at indexPath: IndexPath, filtering: Bool) {
        
        let item = getSong(from: indexPath, filtering: filtering)
        
        musicPlayer.play(filtering ? filteredSongs : songs, startingFrom: item, from: filterContainer ?? self, withTitle: "\(filtering ? "Filtered songs" : "Songs") by \(item.validArtist)", subtitle: "Starting from \(item.validTitle)", alertTitle: "Play", completion: { [weak self] in
            
            guard let weakSelf = self, filtering, let container = weakSelf.filterContainer else { return }
            
            container.saveRecentSearch(withTitle: container.searchBar.text, resignFirstResponder: false)
        })
    }
    
    @objc func getEntity(at indexPath: IndexPath, filtering: Bool = false) -> MPMediaEntity {
        
        return getSong(from: indexPath, filtering: filtering)
    }
}

extension ArtistSongsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if filtering {
            
            return filteredSongs.count
            
        } else {
            
            switch sortCriteria {
                
                case .standard: return !songs.isEmpty ? currentArtistQuery?.itemSections?[section].range.length ?? songs.count : songs.count
                
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
                
                case .standard: return currentArtistQuery?.itemSections?.count ?? 1
                    
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
        
        cell.prepare(with: song, songNumber: indexPath.row + 1, highlightedSong: entityVC?.highlightedEntities?.song)
        updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: tableView)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        return .insert
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing {
            
            self.tableView(tableView, commit: .insert, forRowAt: indexPath)
            
        } else {
            
            let item = getSong(from: indexPath)
                        
            musicPlayer.play(filtering ? filteredSongs : songs, startingFrom: item, from: self, withTitle: "\(filtering ? "Filtered songs" : "Songs") by \(item.validArtist)", subtitle: "Starting from \(item.validTitle)", alertTitle: "Play")
            
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let song = getSong(from: indexPath)
        
        notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: [song]])
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if filtering {
            
            return 11
            
        } else {
            
            switch sortCriteria {
                
            case .random, 
                 .standard where currentArtistQuery?.itemSections == nil: return 11
                
            default:
                
                let height = ("eh" as NSString).boundingRect(with: CGSize(width: 100, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.myriadPro(ofWeight: .light, size: 20)], context: nil).height
                
                return height + 24
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        guard !filtering else { return nil }
        
        switch sortCriteria {
            
            case .standard:
                
                let array = currentArtistQuery?.itemSections?.map({ $0.title })
                
                return ascending ? array : array?.reversed()
                
            case .random: return nil
                
            default: return sections.map({ $0.indexTitle })
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
                
                if let _ = currentArtistQuery?.itemSections {
                    
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
}

extension ArtistSongsViewController: Arrangeable {
    
    @objc func sortItems() {
        
        guard let _ = viewIfLoaded else { return }
        
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
        
        operation = BlockOperation()
        operation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self, let operation = weakSelf.operation, !operation.isCancelled, let entities = weakSelf.currentArtistQuery?.items, !entities.isEmpty else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    self?.arrangeButton.alpha = 1
                }
                
                return
            }
            
            let other = weakSelf.sortCriteria == .standard && (weakSelf.entityVC?.kind == .artist || weakSelf.entityVC?.kind == .albumArtist) ? weakSelf.altSections() : (items: [], details: [])
            
            let array: [MPMediaItem] = {
                
                    switch weakSelf.sortCriteria {
                        
                    case .random: return entities.shuffled()
                        
                    case .standard:
                        
                        if weakSelf.entityVC?.kind == .artist || weakSelf.entityVC?.kind == .albumArtist { return other.items }
                        
                        return weakSelf.ascending ? entities : entities.reversed()
                        
                    default: return (entities as NSArray).sortedArray(using: weakSelf.sortDescriptors) as! [MPMediaItem]
                }
            }()
            
            if let song = self?.entityVC?.highlightedEntities?.song {
                
                self?.highlightedIndex = array.index(of: song)
            }
            
            guard !operation.isCancelled else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    self?.arrangeButton.alpha = 1
                }
                
                return
            }
            
            let details = weakSelf.sortCriteria == .standard && (weakSelf.entityVC?.kind == .artist || weakSelf.entityVC?.kind == .albumArtist) ? other.details : weakSelf.prepareSections(from: array)
            
            OperationQueue.main.addOperation({ mainBlock(array, details) })
        })
        
        sortOperationQueue.addOperation(operation!)
    }
    
    func altSections() -> (items: [MPMediaItem], details: [SortSectionDetails]) {
        
        let query = currentArtistQuery?.copy() as? MPMediaQuery
        query?.groupingType = .album
        
        let things = (ascending ? query?.collections : query?.collections?.reversed()) ?? []
        let albums = things.map({ ($0.items.first?.albumTitle ??? .untitledAlbum)/*.lowercased()*/ })
        let items = things.map({ $0.items }).reduce([MPMediaItem](), { $0 + $1 })
//        let x = albums.map({ !CharacterSet.letters.contains(String($0.characters.prefix(1)).unicodeScalars.first!) ? "#" : String($0.characters.prefix(1)).uppercased() }).map({ $0.folding(options: .diacriticInsensitive, locale: .current) })
        let y = albums.map({ _ in "." })
        let indices = y
        
        return (items: items, details: getSectionDetails(from: items.map({ $0.validAlbum }), withOrderedArray: albums, sectionTitles: albums.map({ $0.lowercased() }), indexTitles: indices))
    }
}

