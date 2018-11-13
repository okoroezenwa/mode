//
//  AlbumViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 31/08/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class AlbumItemsViewController: UIViewController, FilterContextDiscoverable, InfoLoading, QueryUpdateable, CellAnimatable, SingleItemActionable, BorderButtonContaining, Refreshable, IndexContaining, AlbumArtistTransitionable, ArtistTransitionable, GenreTransitionable, ComposerTransitionable, EntityVerifiable, TopScrollable, EntityContainer {
    
    @IBOutlet var tableView: MELTableView!

    @objc lazy var headerView: HeaderView = {
        
        let view = HeaderView.fresh
        self.actionsStackView = view.actionsStackView
        self.stackView = view.scrollStackView
        view.showArtistView = true
        view.showLoved = true
        view.showInfo = true
        self.artistButton = view.artistButton
        self.artistImageView = view.chevron
        self.artistChevronBorder = view.chevronBorder
        view.infoButton.addTarget(entityVC, action: #selector(EntityItemsViewController.showOptions), for: .touchUpInside)
        view.likedStateButton.addTarget(self, action: #selector(setLiked), for: .touchUpInside)
        
        updateLikedButton(view.likedStateButton)
        
        return view
    }()
    @objc var artistButton: MELButton! {
        
        didSet {
            
            artistButton.addTarget(self, action: #selector(goToArtist), for: .touchUpInside)
        }
    }
    @objc var actionsStackView: UIStackView! {
        
        didSet {
            
            let shuffleView = BorderedButtonView.with(title: .shuffleButtonTitle, image: #imageLiteral(resourceName: "Shuffle13"), tapAction: .init(action: #selector(shuffle), target: self))
            shuffleButton = shuffleView.button
            self.shuffleView = shuffleView
            
            let arrangeBorderView = BorderedButtonView.with(title: .arrangeButtonTitle, image: #imageLiteral(resourceName: "AscendingLines"), tapAction: .init(action: #selector(showArranger), target: self))
            arrangeBorderView.borderView.centre(activityIndicator)
            arrangeButton = arrangeBorderView.button
            self.arrangeBorderView = arrangeBorderView
            
            let editView = BorderedButtonView.with(title: .inactiveEditButtonTitle, image: .inactiveEditImage, tapAction: .init(action: #selector(SongActionManager.toggleEditing(_:)), target: songManager), longPressAction: .init(action: #selector(SongActionManager.showActionsForAll(_:)), target: songManager))
            editButton = editView.button
            self.editView = editView
            
            [shuffleView, arrangeBorderView, editView].forEach({ actionsStackView.addArrangedSubview($0) })
        }
    }
    @objc var stackView: UIStackView! {
        
        didSet {
            
            let count = ScrollHeaderSubview.with(title: "–", image: #imageLiteral(resourceName: "Songs10"), useSmallerImage: true)
            songCountLabel = count.label
            
            let order = ScrollHeaderSubview.with(title: arrangementLabelText, image: #imageLiteral(resourceName: "Order10"))
            orderLabel = order.label
            
            let duration = ScrollHeaderSubview.with(title: "–", image: #imageLiteral(resourceName: "Time10"))
            totalDurationLabel = duration.label
            
            let year = ScrollHeaderSubview.with(title: "–", image: #imageLiteral(resourceName: "Year"), useSmallerImage: true)
            yearLabel = year.label
            
            let genre = ScrollHeaderSubview.with(title: "–", image: #imageLiteral(resourceName: "GenresSmaller"))
            genreLabel = genre.label
            
            let copyright = ScrollHeaderSubview.with(title: "–", image: nil)
            copyright.showImage = false
            copyrightLabel = copyright.label
            
            for view in [count, order, duration, year, genre, copyright] {
                
                stackView.addArrangedSubview(view)
            }
        }
    }
    @objc var totalDurationLabel: MELLabel!
    @objc var yearLabel: MELLabel!
    @objc var genreLabel: MELLabel!
    @objc var copyrightLabel: MELLabel!
    @objc var orderLabel: MELLabel!
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
    @objc var songCountLabel: MELLabel!
    @objc var artistImageView: UIImageView!
    @objc var artistChevronBorder: UIView!
    @objc var shuffleView: BorderedButtonView!
    @objc var arrangeBorderView: BorderedButtonView!
    @objc var editView: BorderedButtonView!
    
    var borderedButtons = [BorderedButtonView?]()
    var sectionIndexViewController: SectionIndexViewController?
    let requiresLargerTrailingConstraint = false
    var navigatable: Navigatable? { return entityVC }
    
    @objc lazy var sorter: Sorter = { Sorter.init(operation: self.operation) }()
    
    @objc var entityVC: EntityItemsViewController? { return parent as? EntityItemsViewController }
    @objc var album: MPMediaItemCollection? { return albumQuery?.collections?.first }
    @objc var albumQuery: MPMediaQuery? { return entityVC?.query }
    @objc var needsDismissal = false
    @objc var songs = [MPMediaItem]()
    @objc var filteredSongs: [MPMediaItem] { return filteredEntities as! [MPMediaItem] }
    @objc lazy var filtering = false
    var ignorePropertyChange = false
    var filterText: String?
    var entityCount: Int { return songs.count }
    @objc weak var peeker: UIViewController?
    lazy var applicableFilterProperties: Set<Property> = { self.applicationItemFilterProperties.subtracting( self.album?.representativeItem?.isCompilation == true ? [] : [.artist]) }()
    @objc var ignoreKeyboardForInset = true
    @objc lazy var wasFiltering = false
    @objc var lifetimeObservers = Set<NSObject>()
    @objc var transientObservers = Set<NSObject>()
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var composerQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    
    @objc lazy var tableDelegate: TableDelegate = { TableDelegate.init(container: self, location: .album) }()
    @objc var entities: [MPMediaEntity] { return songs }
    @objc var query: MPMediaQuery? { return albumQuery }
    @objc lazy var filteredEntities = [MPMediaEntity]()
    @objc var highlightedEntity: MPMediaEntity? { return entityVC?.highlightedEntities?.song }
    var filterContainer: (UIViewController & FilterContainer)?
    var filterEntities: FilterViewController.FilterEntities { return .songs(songs) }
    var collectionView: UICollectionView?
    
    @objc lazy var refresher: Refresher = { Refresher.init(refreshable: self) }()
    
    @objc var actionableSongs: [MPMediaItem] { return filtering ? filteredSongs : songs }
    var applicableActions: [SongAction] { return [SongAction.collect, .info(context: .album(at: 0, within: [])), .queue(name: album?.representativeItem?.albumTitle ??? .untitledAlbum, query: nil), .newPlaylist, .addTo] }
    @objc lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
    var sections = [SortSectionDetails]()
    var highlightedIndex: Int?
    @objc var ascending = true {
        
        didSet {
            
            if let tableView = tableView, let button = arrangeButton, let id = album?.representativeItem?.albumPersistentID {
                
                songs.reverse()
                
                if filtering {
                    
                    filteredEntities.reverse()
                }
                
                sections = prepareSections(from: songs)
                UniversalMethods.saveSortableItem(withPersistentID: id, order: ascending, sortCriteria: sortCriteria, kind: SortableKind.album)
                tableView.reloadData()
                animateCells(direction: .vertical)
                updateImage(for: button)
            }
        }
    }
    var location: SortLocation = .album
    var sortCriteria = SortCriteria.standard {
        
        didSet {
            
            if let _ = tableView, let id = album?.representativeItem?.albumPersistentID {
                
                sortItems()
                orderLabel.text = arrangementLabelText
                UniversalMethods.saveSortableItem(withPersistentID: id, order: ascending, sortCriteria: sortCriteria, kind: SortableKind.album)
            }
        }
    }
    var applicableSortCriteria: Set<SortCriteria> {
        
        let set: Set<SortCriteria> = [.duration, .artist, .album, .plays, .lastPlayed, .genre, .rating, .dateAdded, .title, .fileSize]
        
        if let album = album, album.representativeItem?.isCompilation == false {
            
            return set.subtracting([.artist, .album])
        }
        
        return set
    }
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
    @objc let sortOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Sort Operation Queue"
        
        
        return queue
    }()
    @objc var operation: BlockOperation?
    @objc var filterOperation: BlockOperation?
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        adjustInsets(context: .container)
        updateTopInset()
        
        prepareLifetimeObservers()
        
        tableView.delegate = tableDelegate
        tableView.dataSource = tableDelegate
        tableView.tableHeaderView = headerView
        
        let refreshControl = MELRefreshControl.init()
        refreshControl.addTarget(refresher, action: #selector(Refresher.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        updateImage(for: arrangeButton)
        updateHeaderView(with: (albumQuery?.items ?? []).count)
        
        prepareSupplementaryInfo()
        sortItems()
        
        prepareGestures()
        
        updateImage(for: arrangeButton)
        
        registerForPreviewing(with: self, sourceView: artistButton)
    }
    
    func updateTopInset() {
        
        let inset = entityVC?.peeker != nil ? 0 : entityVC?.inset ?? VisualEffectNavigationBar.Location.entity.inset
        tableView.contentInset.top = inset
        tableView.scrollIndicatorInsets.top = inset
    }
    
    @objc func prepareSupplementaryInfo() {
        
        updateSongsLabel(with: (albumQuery?.items ?? []).count)
        
        artistButton.setTitle(album?.representativeItem?.validAlbumArtist, for: .normal)
        
        totalDurationLabel.text = (albumQuery?.items ?? []).map({ $0.playbackDuration }).reduce(0, +).stringRepresentation(as: .short)
        
        if let year = Set((albumQuery?.items ?? []).map({ $0.year })).filter({ $0 != -1 && $0 != 0 }).max() {
            
            yearLabel.superview?.superview?.isHidden = false
            yearLabel.text = String.init(describing: year)
            
        } else {
            
            yearLabel.superview?.superview?.isHidden = true
        }
        
        if let genre = Set((albumQuery?.items ?? []).map({ $0.genre ??? "" })).sorted(by: <).filter({ $0 != "" }).first {
            
            genreLabel.text = genre
            genreLabel.superview?.superview?.isHidden = false
            
        } else {
            
            genreLabel.superview?.superview?.isHidden = true
        }
        
        if let copyright = Set((albumQuery?.items ?? []).map({ $0.copyright ??? "" })).filter({ $0 != "" }).first {
            
            copyrightLabel.text = copyright
            copyrightLabel.superview?.superview?.isHidden = false
        
        } else {
            
            copyrightLabel.superview?.superview?.isHidden = true
        }
    }
    
    func updateLikedButton(_ sender: UIButton) {
        
        guard let album = album else { return }
        
        sender.setImage(image(for: album.likedState), for: .normal)
    }
    
    func image(for likedState: LikedState) -> UIImage {
        
        switch likedState {
            
            case .liked: return #imageLiteral(resourceName: "Loved13")
            
            case .disliked: return #imageLiteral(resourceName: "Unloved13")
            
            case .none: return #imageLiteral(resourceName: "NoLove13")
        }
    }
    
    @objc func setLiked() {
        
        guard let album = album else { return }
        
        var value: Int {
            
            switch album.likedState {
                
                case .none: return LikedState.liked.rawValue
                
                case .liked: return LikedState.disliked.rawValue
                
                case .disliked: return LikedState.none.rawValue
            }
        }
        
        album.set(property: .albumLikedState, to: NSNumber.init(value: value))
        
        UIView.transition(with: headerView.likedStateButton, duration: 0.3, options: .transitionCrossDissolve, animations: { self.updateLikedButton(self.headerView.likedStateButton) }, completion: { [weak self] finished in
            
            guard finished, let weakSelf = self else { return }
            
            UniversalMethods.performOnMainThread({
            
                if weakSelf.headerView.likedStateButton.image(for: .normal) != weakSelf.image(for: album.likedState) {
                    
                    UIView.transition(with: weakSelf.headerView.likedStateButton, duration: 0.3, options: .transitionCrossDissolve, animations: { weakSelf.updateLikedButton(weakSelf.headerView.likedStateButton) }, completion: nil)
                }
            
            }, afterDelay: 0.3)
        })
    }
    
    @objc func prepareGestures() {
        
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
        
        let artistOptionsHold = UILongPressGestureRecognizer.init(target: self, action: #selector(showArtistOptions(_:)))
        artistOptionsHold.minimumPressDuration = longPressDuration
        artistButton.addGestureRecognizer(artistOptionsHold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: artistOptionsHold))
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
    
    @objc func showOptions(_ sender: Any) {
        
        tableDelegate.showOptions(sender)
    }
    
    @objc func showArranger() {
        
        performSegue(withIdentifier: "toArranger", sender: nil)
    }
    
    @objc func showArtistOptions(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            
            performSegue(withIdentifier: "toArtistOptions", sender: sender)
        }
    }
    
    @IBAction func goToArtist() {
        
        let sender: (MPMediaItemCollection?, MPMediaItem?) = (getArtist(from: album?.representativeItem), nil)
        
        performSegue(withIdentifier: "toArtist", sender: sender)
    }
    
    @objc func updateSongsLabel(with count: Int) {
        
        songCountLabel.text = filtering ? filteredSongs.count.formatted + " of " + count.formatted : count.formatted
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
        
        if needsDismissal {
            
            if let vc = presentedViewController {
                
                vc.dismiss(animated: false, completion: nil)
            }
            
            let banner = Banner.init(title: "This album has no offline songs", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
            banner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
            banner.show(duration: 1.5)
            
            _ = navigationController?.popViewController(animated: true)
        }
        
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
            
            guard let weakSelf = self, weakSelf.songs.count > 1 else { return }
     
            weakSelf.invokeSearch()
        })
        
        transientObservers.insert(secondaryObserver as! NSObject)
        
        let reloadObserver = notifier.addObserver(forName: .songWasEdited, object: self, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let indexPath = notification.userInfo?["indexPath"] as? IndexPath else { return }
            
            weakSelf.tableView.reloadRows(at: [indexPath], with: .none)
        })
        
        transientObservers.insert(reloadObserver as! NSObject)
    }
    
    @objc func prepareLifetimeObservers() {
        
        let insetsObserver = notifier.addObserver(forName: .resetInsets, object: nil, queue: nil, using: { [weak self] _ in self?.adjustInsets(context: .container) })
        
        lifetimeObservers.insert(insetsObserver as! NSObject)
        
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
        
        lifetimeObservers.insert(notifier.addObserver(forName: .showExplicitnessChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.tableView.reloadRows(at: weakSelf.tableView.indexPathsForVisibleRows ?? [], with: .none)
            
        }) as! NSObject)
        
        lifetimeObservers.insert((notifier.addObserver(forName: .libraryUpdated, object: appDelegate, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateWithQuery()
            
        })) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .lineHeightsCalculated, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateTopInset()
            
        }) as! NSObject)
    }
    
    @objc func updateWithQuery() {
        
        needsDismissal = false
        
        sortItems()
    }
    
    @objc func updateHeaderView(with count: Int) {
        
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

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        imageCache.removeAllObjects()
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
            
            let song: MPMediaItem? = {
                
                if album?.representativeItem?.isCompilation == true {
                    
                    guard let gr = sender as? UISwipeGestureRecognizer, let indexPath = tableView.indexPathForRow(at: gr.location(in: tableView)) else { return nil }
                    
                    return getSong(from: indexPath)
                    
                } else {
                    
                    return album?.representativeItem
                }
            }()
            
            if let artist = getArtist(from: song) {
                
                performSegue(withIdentifier: "toArtist", sender: (artist, song.value(given: song?.isCompilation == true)))
            }
        }
    }
    
    @objc func stopCollecting() {
        
        if tableView.isEditing {
            
            tableView.setEditing(false, animated: true)
        }
    }
    
    @objc @discardableResult func performTransition(to vc: UIViewController, sender: Any?, perform3DTouchActions: Bool = false) -> UIViewController? {
        
        if let presentedVC = vc as? PresentedContainerViewController {
            
            guard let rep = album?.representativeItem else { return nil }
            
            let query = MPMediaQuery.init(filterPredicates: [.for(.albumArtist, using: rep.albumArtistPersistentID)]).cloud.grouped(by: .albumArtist)
            
            guard let artist = query.collections?.first else { return nil }
        
            presentedVC.context = .info
            presentedVC.optionsContext = .collection(kind: .albumArtist, at: 0, within: [artist])
        }
        
        return nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
            
                case "toArtistOptions": performTransition(to: segue.destination, sender: sender)
                
                case "toArtist":
                    
                    let sender = sender as? (MPMediaItemCollection?, MPMediaItem?)
                    
                    Transitioner.shared.transition(to: /*album?.representativeItem?.isCompilation == true ? .artist : */.albumArtist, vc: segue.destination, from: entityVC, sender: sender?.0, highlightedItem: sender?.1, filter: self)
                
                case "toArranger": Transitioner.shared.transition(to: segue.destination, from: self)
            
            default: return
        }
    }
    
    @IBAction func shuffle() {
        
        musicPlayer.play(filtering ? filteredSongs : albumQuery?.items ?? [], startingFrom: nil, shuffleMode: .songs, from: self, withTitle: entityVC?.title, subtitle: headerView.artistButton.titleLabel?.text, alertTitle: .shuffle())
    }
    
    @objc func getSong(inSection section: Int, row: Int, filtering: Bool = false) -> MPMediaItem {
        
        if filtering {
            
            return filteredSongs[row]
            
        } else {
            
            switch sortCriteria {
                
                case .random: return songs[row]
                    
                default: return songs[sections[section].startingPoint + row]
            }
        }
    }
    
    @objc func getSong(from indexPath: IndexPath, filtering: Bool = false) -> MPMediaItem {
        
        return getSong(inSection: indexPath.section, row: indexPath.row, filtering: filtering)
    }
    
    @objc func getArtist(from song: MPMediaItem?) -> MPMediaItemCollection? {
        
        guard let song = song else { return nil }
        
        let query = MPMediaQuery.init(filterPredicates: [.for(/*song.isCompilation ? .artist : */.albumArtist, using: /*song.isCompilation ? song.artistPersistentID : */song.albumArtistPersistentID)]).cloud.grouped(by: /*song.isCompilation ? .artist : */.albumArtist)
        
        if let artist = query.collections?.first {
            
            return artist
        }
        
        return nil
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "AIVC going away...").show(for: 0.5)
        }
        
        unregisterAll(from: lifetimeObservers)
        notifier.removeObserver(self)
        operation?.cancel()
    }
}

extension AlbumItemsViewController: TableViewContainer {
    
    @objc func selectCell(in tableView: UITableView, at indexPath: IndexPath, filtering: Bool) {
        
        let song = getSong(from: indexPath, filtering: filtering)
        
        musicPlayer.play(filtering ? filteredSongs : songs, startingFrom: song, from: filterContainer ?? self, withTitle: song.validAlbum, subtitle: "Starting from \(song.validTitle)", alertTitle: "Play", completion: { [weak self] in
            
            guard let weakSelf = self, filtering, let container = weakSelf.filterContainer else { return }
            
            container.saveRecentSearch(withTitle: container.searchBar.text, resignFirstResponder: false)
        })
    }
    
    @objc func getEntity(at indexPath: IndexPath, filtering: Bool = false) -> MPMediaEntity {
        
        return getSong(from: indexPath, filtering: filtering)
    }
}

extension AlbumItemsViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        if artistButton.bounds.contains(location), let song = album?.representativeItem, !song.isCompilation, let artist = getArtist(from: song) {
            
            let vc = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
            
            previewingContext.sourceRect = artistButton.bounds
            
            return Transitioner.shared.transition(to: albumArtistsAvailable ? .albumArtist : .artist, vc: vc, from: entityVC, sender: artist, preview: true)
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        performCommitActions(on: viewControllerToCommit)
        
//        if let vc = viewControllerToCommit as? BackgroundHideable {
//
//            vc.modifyBackgroundView(forState: .removed)
//        }
//
//        if let vc = viewControllerToCommit as? Arrangeable {
//
//            vc.updateImage(for: vc.arrangeButton)
//        }
//
//        if let vc = viewControllerToCommit as? Peekable {
//
//            vc.peeker = nil
//            vc.oldArtwork = nil
//        }
//
//        if let vc = viewControllerToCommit as? Navigatable, let indexer = vc.activeChildViewController as? IndexContaining {
//
//            indexer.tableView.contentInset.top = vc.inset
//            indexer.tableView.scrollIndicatorInsets.top = vc.inset
//
//            if let sortable = indexer as? FullySortable, sortable.highlightedIndex == nil {
//
//                indexer.tableView.contentOffset.y = -vc.inset
//            }
//
//            entityVC?.container?.imageView.image = vc.artworkType.image
//            entityVC?.container?.visualEffectNavigationBar.backBorderView.alpha = 1
//            entityVC?.container?.visualEffectNavigationBar.backView.isHidden = false
//            entityVC?.container?.visualEffectNavigationBar.backLabel.text = vc.backLabelText
//            entityVC?.container?.visualEffectNavigationBar.titleLabel.text = vc.title
//        }
        
        show(viewControllerToCommit, sender: nil)
    }
}

extension AlbumItemsViewController: FullySortable {
    
    @objc func sortItems() {
        
        (arrangeButton.superview as? BorderedButtonView)?.stackView.alpha = 0
        activityIndicator.startAnimating()
        
        let mainBlock: ([MPMediaItem], [SortSectionDetails]) -> () = { [weak self] array, details in
            
            guard let weakSelf = self, weakSelf.operation?.isCancelled == false else {
                
                self?.activityIndicator.stopAnimating()
                (self?.arrangeButton.superview as? BorderedButtonView)?.stackView.alpha = 1
                
                return
            }
            
            weakSelf.songs = array
            weakSelf.sections = details
            weakSelf.activityIndicator.stopAnimating()
            (weakSelf.arrangeButton.superview as? BorderedButtonView)?.stackView.alpha = 1
            weakSelf.updateHeaderView(with: array.count)
            weakSelf.updateSongsLabel(with: array.count)
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
        
        operation = BlockOperation()
        operation?.addExecutionBlock({ [weak operation, weak albumQuery, weak self] in
            
            guard let weakOperation = operation, !weakOperation.isCancelled, let items = albumQuery?.items, !items.isEmpty, let weakSelf = self else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    (self?.arrangeButton.superview as? BorderedButtonView)?.stackView.alpha = 1
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
            
            if let song = self?.entityVC?.highlightedEntities?.song {
                
                self?.highlightedIndex = array.index(of: song)
            }
            
            guard !weakOperation.isCancelled else {
                
                UniversalMethods.performInMain {
                    
                    self?.activityIndicator.stopAnimating()
                    (self?.arrangeButton.superview as? BorderedButtonView)?.stackView.alpha = 1
                }
                
                return
            }
            
            let details = weakSelf.prepareSections(from: array)
            
            OperationQueue.main.addOperation({ mainBlock(array, details) })
        })
        
        sortOperationQueue.addOperation(operation!)
    }
}
