//
//  SearchViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 13/08/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class SearchViewController: UIViewController, Filterable, DynamicSections, AlbumTransitionable, Contained, InfoLoading, ArtistTransitionable, GenreTransitionable, ComposerTransitionable, AlbumArtistTransitionable, PlaylistTransitionable, EntityContainer, OptionsContaining, CellAnimatable, IndexContaining, FilterContainer, SingleItemActionable, EntityVerifiable, TopScrollable, Detailing {

    @IBOutlet weak var tableView: MELTableView!
    @IBOutlet weak var emptyStackView: UIStackView!
    @IBOutlet weak var titleLabel: MELLabel!
    @IBOutlet weak var clearButtonView: UIView!
    @IBOutlet weak var clearButtonTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var largeActivityIndicator: MELActivityIndicatorView!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityVisualEffectView: MELVisualEffectView!
    @IBOutlet var activityViewVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var emptySubLabel: MELLabel! {
        
        didSet {
            
            guard let text = emptySubLabel.text else { return }
            
            let style = NSMutableParagraphStyle.init()
            style.alignment = .center
            style.lineHeightMultiple = 1.2
            
            emptySubLabel.attributes = [Attributes.init(name: .paragraphStyle, value: .other(style), range: text.nsRange())]
        }
    }
    
//    @objc let managedContext = appDelegate.managedObjectContext
    @objc let presenter = NavigationAnimationController()
    @objc var recentSearches = [RecentSearch]()
    var currentEntity = Entity.artist
    @objc var filtering = false {
        
        didSet {
            
            guard oldValue != filtering else { return }
            
            tableView.allowsMultipleSelectionDuringEditing = filtering.inverted
        }
    }
    var filterText: String?
    var rightViewSetUp = false
    var category = SearchCategory.all
    var entityCount = 0
    @objc var unfilteredPoint = CGPoint.zero
    lazy var applicableFilterProperties: Set<Property> = { applicationItemFilterProperties.union(applicableCollectionFilterProperties) }()
    lazy var filterEntities = { FilterViewController.FilterEntities.songs([]) }()
    @objc var lifetimeObservers = Set<NSObject>()
    @objc var transientObservers = Set<NSObject>()
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var albumQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var composerQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    @objc var playlistQuery: MPMediaQuery?
    
    @objc var ignoreKeyboardForInset = true
    var sender: (UIViewController & Filterable)? {
        
        get { return self }
        
        set { }
    }
    var filterContainer: (UIViewController & FilterContainer)? {
        
        get { return self }
        
        set { }
    }
    @objc lazy var wasFiltering = false
    
    let applicableActions = [SongAction]()
    let actionableSongs = [MPMediaItem]()
    var songManager: SongActionManager { return manager }
    lazy var manager = { SongActionManager.init(actionable: self) }()
    var editButton: MELButton! = MELButton()
    
    @objc lazy var songs = [MPMediaItem]()
    @objc lazy var playlists = [MPMediaPlaylist]()
    @objc lazy var playlistCounts = [Int]()
    @objc lazy var artists = [MPMediaItemCollection]()
    @objc lazy var albums = [MPMediaItemCollection]()
    @objc lazy var genres = [MPMediaItemCollection]()
    @objc lazy var composers = [MPMediaItemCollection]()
    @objc var itemCount: Int { return songs.count + playlists.count + albums.count + artists.count + genres.count + composers.count }
    @objc var onlineOverride = false
    var options: LibraryOptions { return .init(fromVC: self, configuration: .search) }
    var sectionIndexViewController: SectionIndexViewController?
    let requiresLargerTrailingConstraint = false
    var ignorePropertyChange = false
    var filterViewContainer: FilterViewContainer! {
        
        get { return container?.filterViewContainer }
        
        set { }
    }
    weak var searchBar: MELSearchBar! {
        
        get { return filterViewContainer.filterView.searchBar }
        
        set { }
    }
    lazy var requiredInputView: InputView? = {
        
        let view = Bundle.main.loadNibNamed("InputView", owner: nil, options: nil)?.first as? InputView
        view?.pickerView.delegate = self
        view?.pickerView.dataSource = self
        
        return view
    }()
    
    lazy var rightViewButton: MELButton = {
        
        let button = MELButton.init(frame: .init(x: 0, y: 0, width: 30, height: 30))
        button.setTitle(nil, for: .normal)
        button.addTarget(self, action: #selector(rightViewButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = UIFont.myriadPro(ofWeight: .bold, size: 17)
        
        return button
    }()
    
    var sectionDetails: [SectionDetails] {
        
        return getSectionDetails(from: ("songs", songs.count, .songs),
                                ("artists", artists.count, .artists),
                                 ("albums", albums.count, .albums),
                                 ("playlists", playlists.count, .playlists),
                                 ("genres", genres.count, .genres),
                                 ("composers", composers.count, .composers)
        )
    }
    
    var filterProperty: Property = .title {
        
        didSet(oldValue) {
            
            guard filtering, ignorePropertyChange.inverted, let text = searchBar?.text, filterProperty != oldValue else { return }
            
            searchBar(searchBar, textDidChange: text)
        }
    }
    var propertyTest: PropertyTest = .contains {
        
        didSet(oldValue) {
            
            guard filtering, ignorePropertyChange.inverted, let text = searchBar?.text, propertyTest != oldValue else { return }
            
            searchBar(searchBar, textDidChange: text)
        }
    }
    
    @objc lazy var operations = ImageOperations()
    @objc lazy var infoOperations = InfoOperations()
    lazy var filterOperations = [String: Operation]()
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
    @objc let filterOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Filter Operation Queue"
        queue.maxConcurrentOperationCount = 3
        
        return queue
    }()
    @objc var operation: BlockOperation?
    @objc var filterOperation: BlockOperation?
    @objc lazy var songDelegate: SongDelegate = { SongDelegate.init(container: self) }()
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        title = "Search"
        
        navigationController?.delegate = presenter
        presenter.interactor.add(to: navigationController)
        
        prepareLifetimeObservers()
        
        adjustInsets(context: .container)
        searchBar?.delegate = self
        filterViewContainer.filterView.filterTestButton.setTitle(testTitle, for: .normal)
        
        tableView.register(UINib.init(nibName: "RecentSearchCell", bundle: nil), forCellReuseIdentifier: .recentCell)
        
        updateKeyboard(with: self)
        
        resetRecentSearches()
        
        let swipeRight = UISwipeGestureRecognizer.init(target: self, action: #selector(handleRightSwipe(_:)))
        swipeRight.direction = .right
        tableView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(handleLeftSwipe(_:)))
        swipeLeft.direction = .left
        tableView.addGestureRecognizer(swipeLeft)
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(showOptions(_:)))
        hold.minimumPressDuration = longPressDuration
        tableView.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.insert(Weak.init(value: hold))
        
        let edge = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(updateSections))
        edge.edges = .right
        view.addGestureRecognizer(edge)
        
        if traitCollection.forceTouchCapability == .available {
            
            registerForPreviewing(with: self, sourceView: tableView)
        }
    }
    
    @objc func showOptions(_ sender: Any) {
        
        guard filtering else { return }
        
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
        
        Transitioner.shared.showInfo(from: self, with: context(from: indexPath), completion: { [weak self] in self?.saveRecentSearch(withTitle: self?.searchBar?.text, resignFirstResponder: false) })
    }
    
    func context(from indexPath: IndexPath) -> InfoViewController.Context {
        
        switch sectionDetails[indexPath.section].category {
            
            case .artists: return .collection(kind: .artist, at: indexPath.row, within: artists)
            
            case .playlists: return .playlist(at: indexPath.row, within: playlists)
            
            case .albums: return .album(at: indexPath.row, within: albums)
            
            case .composers: return .collection(kind: .composer, at: indexPath.row, within: composers)
            
            case .genres: return .collection(kind: .genre, at: indexPath.row, within: genres)
            
            case .songs: return .song(location: .list, at: indexPath.row, within: songs)
            
            case .all: fatalError("Nothing should call this yet")
        }
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        imageCache.removeAllObjects()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        container?.shouldUseNowPlayingArt = true
        container?.updateBackgroundWithNowPlaying()
        container?.currentModifier = nil
        container?.currentOptionsContaining = self
        
        prepareTransientObservers()
        
        if wasFiltering {
            
            invokeSearch()
            wasFiltering = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        notifier.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notifier.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        unregisterAll(from: transientObservers)
    }
    
    @objc func handleRightSwipe(_ sender: Any) {
        
        tableView.setEditing(true, animated: true)
    }
    
    @objc func handleLeftSwipe(_ sender: Any) {
        
        if tableView.isEditing {
            
            tableView.setEditing(false, animated: true)
        
        } else if let gr = sender as? UISwipeGestureRecognizer, let indexPath = tableView.indexPathForRow(at: gr.location(in: tableView)), filtering {
            
            switch sectionDetails[indexPath.section].category {
                
                case .songs:
                
                    let song = songs[indexPath.row]
                    
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
                    
                    saveRecentSearch(withTitle: searchBar?.text, resignFirstResponder: false)
                
                case .albums:
                
                    let album = albums[indexPath.row]
                    
                    guard album.representativeItem?.isCompilation == false else {
                        
                        currentEntity = .album
                        
                        performSegue(withIdentifier: "toAlbum", sender: album)
                        
                        return
                    }
                    
                    guard let song = album.representativeItem else { return }
                    
                    let filterPredicates: Set<MPMediaPropertyPredicate> = showiCloudItems ? [.for(.artist, using: song.artistPersistentID)] : [.for(.artist, using: song.artistPersistentID), .offline]
                    
                    let query = MPMediaQuery.init(filterPredicates: filterPredicates)
                    query.groupingType = .artist
                    
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
                    
                    saveRecentSearch(withTitle: searchBar?.text, resignFirstResponder: false)
                
                default: break
            }
        }
    }
    
    @objc func prepareTransientObservers() {
        
        let secondaryObserver = notifier.addObserver(forName: .performSecondaryAction, object: navigationController, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            guard weakSelf.searchBar != nil else {
                
                notifier.post(name: .performSecondaryAction, object: weakSelf.navigationController)
                return
            }
            
            weakSelf.highlightSearchBar(withText: weakSelf.searchBar?.text, property: weakSelf.filterProperty.rawValue, propertyTest: weakSelf.propertyTest.rawValue, setFirstResponder: true)
        })
        
        transientObservers.insert(secondaryObserver as! NSObject)
        
        let queueObserver = notifier.addObserver(forName: .endQueueModification, object: nil, queue: nil, using: { _ in
        
            if self.tableView.isEditing && self.filtering {
                
                self.tableView.setEditing(false, animated: true)
            }
        })
        
        transientObservers.insert(queueObserver as! NSObject)
        
        let reloadObserver = notifier.addObserver(forName: .songWasEdited, object: self, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let indexPath = notification.userInfo?["indexPath"] as? IndexPath else { return }
            
            weakSelf.tableView.reloadRows(at: [indexPath], with: .none)
        })
        
        transientObservers.insert(reloadObserver as! NSObject)
        
        transientObservers.insert(notifier.addObserver(forName: .scrollCurrentViewToTop, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.scrollToTop()
            
        }) as! NSObject)
    }
    
    @objc func adjustKeyboard(with notification: Notification) {
        
        guard let keyboardHeightAtEnd = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height, searchBar?.isFirstResponder == true else { return }
        
        let keyboardWillShow = notification.name == NSNotification.Name.UIKeyboardWillShow
        
        filterViewContainer.filterView.filterInputViewBottomConstraint.constant = keyboardWillShow ? keyboardHeightAtEnd - 50 - (container?.collectedView.isHidden == true ? 0 : 44) : 0
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.adjustInsets(context: keyboardWillShow ? .filter(inset: keyboardHeightAtEnd) : .container)
            self.container?.view.layoutIfNeeded()
        })
    }
    
    @objc func prepareLifetimeObservers() {
        
        let insetsObserver = notifier.addObserver(forName: .resetInsets, object: nil, queue: nil, using: { [weak self] _ in self?.adjustInsets(context: .container) })
        
        lifetimeObservers.insert(insetsObserver as! NSObject)
        
        let iCloudObserver = notifier.addObserver(forName: .iCloudVisibilityChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.onlineOverride = false
//            weakSelf.updateTempView(hidden: true)
            
            if weakSelf.filtering, let text = weakSelf.searchBar?.text {
                
                weakSelf.filter(with: text)
            }
        })
        
        lifetimeObservers.insert(iCloudObserver as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self, let indexPath = weakSelf.tableView.indexPathsForVisibleRows?.first(where: { $0.section == SearchCategory.songs.rawValue }) else { return }
            
            weakSelf.tableView.reloadSections(.init(integer: indexPath.section), with: .none)
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .entityCountVisibilityChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self, let indexPaths = weakSelf.tableView.indexPathsForVisibleRows else { return }
            
            weakSelf.tableView.reloadRows(at: indexPaths, with: .none)
            
        }) as! NSObject)
    }
    
    @objc func rightViewButtonTapped() {
        
        updateRightViewButton()
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        if rightViewSetUp.inverted {
            
            searchBar.updateTextField(with: placeholder.isEmpty ? "Search Library" : placeholder)
            updateRightView()
        }
    }
    
    @objc func dismissSearch() {
        
        searchBar?.text = nil
        filterOperation = nil
        filtering = false
        tableView.reloadData()
        updateLoadingViews(hidden: true)
        
        if !filtering {
            
            tableView.contentOffset = unfilteredPoint
        }
        
        animateCells(direction: .vertical)
        if tableView.isEditing { tableView.setEditing(false, animated: false) }
        
        if searchBar?.isFirstResponder == true {
            
            searchBar?.resignFirstResponder()
        
        } else {
            
            if let searchBar = searchBar {
                
                searchBarTextDidEndEditing(searchBar)
            }
        }
        
        searchBar?.updateTextField(with: placeholder.isEmpty ? "Search Library" : placeholder)
        onlineOverride = false
        
        filterViewContainer.filterView.updateClearButton(to: .hidden)
//        updateTempView(hidden: true)
    }
    
    @objc func clearSearch() {
        
        searchBar?.text = nil
        filterOperation = nil
        filtering = false
        updateTitleLabel()
        tableView.reloadData()
        updateLoadingViews(hidden: true)
        
        if !filtering {
            
            tableView.contentOffset = unfilteredPoint
        }
        
        animateCells(direction: .vertical)
        if tableView.isEditing { tableView.setEditing(false, animated: false) }
        
        topView.layoutIfNeeded()
        searchBar?.updateTextField(with: placeholder.isEmpty ? "Search Library" : placeholder)
        
        clearButtonTrailingConstraint.constant = filtering || recentSearches.isEmpty ? -44 : 0
        
        UIView.animate(withDuration: 0.3, animations: { self.topView.layoutIfNeeded() })
        
        onlineOverride = false
        
        filterViewContainer.filterView.updateClearButton(to: .hidden)
//        updateTempView(hidden: true)
    }
    
    @IBAction func deleteRecentSearches() {
        
        clearRecentSearches()
    }
    
    func adjustInsets(context: InsetContext) {
        
        switch context {
            
        case .filter(let inset):
            
            tableView.scrollIndicatorInsets.bottom = inset
            tableView.contentInset.bottom = inset
            
        case .container:
            
            if let container = navigationController?.parent as? ContainerViewController, ignoreKeyboardForInset {
                
                tableView.scrollIndicatorInsets.bottom = container.inset
                tableView.contentInset.bottom = container.inset
            }
        }
    }
    
    @objc func updateSections(_ gr: UIScreenEdgePanGestureRecognizer) {
        
        guard filtering else { return }
        
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
    
    @objc func compare(_ text: String?, to searchText: String) -> Bool {
        
        if searchText == "" {
            
            return text == "" || text == nil
            
        } else {
            
            return (text ?? "").lowercased().contains(searchText.lowercased())
        }
    }
    
    @objc func filter(with searchText: String) {
        
        updateLoadingViews(hidden: false)
        
//        filterOperation?.cancel()
        filterOperationQueue.cancelAllOperations()
        filterOperation = BlockOperation()
        filterOperation?.addExecutionBlock({ [weak self, weak filterOperation] in
            
            let text = searchText
        
            guard let weakSelf = self, let operation = filterOperation else {
                
                UniversalMethods.performInMain { self?.updateLoadingViews(hidden: true) }
                
                return
            }
            
            guard operation.isCancelled.inverted else { return }
            
            UniversalMethods.performInMain { weakSelf.updateLoadingViews(hidden: false) }
            
            var songs = [MPMediaItem]()
            var artists = [MPMediaItemCollection]()
            var albums = [MPMediaItemCollection]()
            var genres = [MPMediaItemCollection]()
            var composers = [MPMediaItemCollection]()
            var playlists = [MPMediaPlaylist]()
            
            let songsQuery = MPMediaQuery.songs().cloud
            songsQuery.showAll()
            songs = weakSelf.getResults(for: songsQuery.items ?? [], against: searchText)
            
            if weakSelf.filterOperation == nil { UniversalMethods.performInMain{ weakSelf.updateLoadingViews(hidden: true) }; return }
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            artists = weakSelf.getResults(for: MPMediaQuery.artists().cloud.collections ?? [], of: .artist, against: searchText)
            
            if weakSelf.filterOperation == nil { UniversalMethods.performInMain{ weakSelf.updateLoadingViews(hidden: true) }; return }
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            albums = weakSelf.getResults(for: MPMediaQuery.albums().cloud.collections ?? [], of: .album, against: searchText)
            
            if weakSelf.filterOperation == nil { UniversalMethods.performInMain{ weakSelf.updateLoadingViews(hidden: true) }; return }
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            genres = weakSelf.getResults(for: MPMediaQuery.genres().cloud.collections ?? [], of: .genre, against: searchText)
            
            if weakSelf.filterOperation == nil { UniversalMethods.performInMain{ weakSelf.updateLoadingViews(hidden: true) }; return }
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            composers = weakSelf.getResults(for: MPMediaQuery.composers().cloud.collections ?? [], of: .composer, against: searchText)
            
            if weakSelf.filterOperation == nil { UniversalMethods.performInMain{ weakSelf.updateLoadingViews(hidden: true) }; return }
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            playlists = weakSelf.getResults(for: MPMediaQuery.playlists().cloud.playlistsExtracted(showCloudItems: showiCloudItems || weakSelf.onlineOverride), of: .playlist, against: searchText) as? [MPMediaPlaylist] ?? []
            
            OperationQueue.main.addOperation({
            
                if weakSelf.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.songs = songs
                
                if weakSelf.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.playlists = playlists
                
                if weakSelf.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.artists = artists
                
                if weakSelf.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.albums = albums
                
                if weakSelf.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.genres = genres
                
                if weakSelf.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.composers = composers
                
                if weakSelf.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.updateTitleLabel()
                
                if weakSelf.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.tableView.contentOffset = .zero
                
                if weakSelf.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.tableView.reloadData()
                
                if weakSelf.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.animateCells(direction: .vertical)
                weakSelf.updateLoadingViews(hidden: true)
            })
        })
        
        filterOperationQueue.addOperation(filterOperation!)
        filterOperations[searchText] = filterOperation!
    }
    
    @objc func performEmptySearch() {
        
        searchBar?.text = nil
        searchBar?.updateTextField(with: "Performing Empty Search...")
        filtering = true
        
        emptyStackView.isHidden = true
        
        topView.layoutIfNeeded()
        
        clearButtonTrailingConstraint.constant = -44
        
        UIView.animate(withDuration: 0.3, animations: { self.topView.layoutIfNeeded() })
        
        filter(with: "")
    }
    
    @objc func updateTitleLabel() {
        
        if filtering, let searchText = searchBar?.text {
            
            let text = /*searchText == "" ? "empty search" : */"\"\(searchText)\""
            let countString = itemCount.formatted
            let restOfString = "\(itemCount == 1 ? "result" : "results") for \(text)".uppercased()
            let string = countString + " " + restOfString

            titleLabel.text = string
            titleLabel.updateTheme = false
            titleLabel.greyOverride = true
            titleLabel.attributes = [

                .init(name: .font, value: .other(UIFont.myriadPro(ofWeight: .regular, size: 15)), range: string.nsRange(of: restOfString)),
                .init(kind: .title, range: string.nsRange(of: countString))
            ]
            titleLabel.updateTheme = true
            
        } else {
            
            titleLabel.text = "Previous Searches"
            titleLabel.updateTheme = false
            titleLabel.greyOverride = false
            titleLabel.attributes = nil
            titleLabel.updateTheme = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
            
            case "toSettings": performTransition(to: segue.destination, sender: sender)
            
            case "toAlbum", "toArtist", "toPlaylist": Transitioner.shared.transition(to: currentEntity, segue: segue, sender: sender)
            
            default: return
        }
    }
    
    @objc @discardableResult func performTransition(to vc: UIViewController, sender: Any?, perform3DTouchActions: Bool = false) -> UIViewController? {
        
        if let presentedVC = vc as? PresentedContainerViewController {
            
            presentedVC.context = .settings
        }
        
        return nil
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == "toSettings" || identifier == "toLibraryOptions" {
            
            return true
        }
        
        guard !tableView.isEditing, let sender = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: sender) else { return false }
        
        switch identifier {
            
            case "toPlaylist": return sectionDetails[indexPath.section].category == .playlists
            
            case "toAlbum": return sectionDetails[indexPath.section].category == .albums
            
            case "toArtist": return sectionDetails[indexPath.section].category == .artists
            
            default: return true
        }
    }
    
    func collectionArray(from category: SearchCategory) -> [MPMediaItemCollection] {
        
        switch category {
            
            case .all: return []
            
            case .artists: return artists
            
            case .genres: return genres
            
            case .composers: return composers
            
            case .songs: return []
            
            case .albums: return albums
            
            case .playlists: return playlists
        }
    }
    
    func goToDetails(basedOn entity: Entity) -> (entities: [Entity], albumArtOverride: Bool) {
        
        switch entity {
            
            case .song: return ([.artist, .genre, .album, .composer, .albumArtist], true)
            
            case .album: return ([albumArtistsAvailable ? .albumArtist : .artist, .genre, .album], false)
            
            case .artist: return ([.artist], false)
            
            case .albumArtist: return ([.albumArtist], false)
            
            case .playlist: return ([.playlist], false)
            
            case .genre: return ([.genre], false)
            
            case .composer: return ([.composer], false)
        }
    }
    
    deinit {
        
        unregisterAll(from: lifetimeObservers)
    }
}

// MARK: - TableView
extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return filtering && category == .all ? sectionDetails.count : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if filtering {
            
            switch category {
                
                case .all: return sectionDetails[section].count
                    
                case .songs: return songs.count
                
                case .artists: return artists.count
                
                case .albums: return albums.count
                
                case .playlists: return playlists.count
                
                case .genres: return genres.count
                
                case .composers: return composers.count
            }
        
        } else {
            
            return recentSearches.count
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        operations[indexPath]?.cancel()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard filtering else {
            
            let cell = tableView.recentSearchCell(for: indexPath)
            let search = recentSearches[indexPath.row]
            
            cell.termLabel?.text = search.title
            cell.backgroundColor = .clear
            cell.searchCategoryImageView.image = category.image
            
            let property = Property(rawValue: Int(search.property)) ?? .title
            let test = PropertyTest(rawValue: search.propertyTest ?? "") ?? initialPropertyTest(for: property)
            
            cell.criteriaLabel.text = property.title + " " + title(for: test, property: property)
            cell.delegate = self
            
            return cell
        }
        
        let cell = tableView.songCell(for: indexPath)
        
        switch sectionDetails[indexPath.section].category {
            
            case .all: break
            
            case .songs:
            
                let song = songs[indexPath.row]
                
                cell.prepare(with: song, songNumber: songCountVisible.inverted ? nil : indexPath.row + 1)
                
                updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: tableView)
                
                for category in [SecondaryCategory.loved, .plays, .rating, .lastPlayed, .dateAdded, .genre, .year, .fileSize] {
                    
                    update(category: category, using: song, in: cell, at: indexPath, reusableView: tableView)
                }
            
            case .playlists:
            
                let playlist = playlists[indexPath.row]
                cell.prepare(with: playlist, count: playlist.count, number: songCountVisible.inverted ? nil : indexPath.row + 1)
                updateImageView(using: playlist, in: cell, indexPath: indexPath, reusableView: tableView, overridable: self)
            
            case .albums:
            
                let album = albums[indexPath.row]
                
                cell.prepare(with: album, withinArtist: false, number: songCountVisible.inverted ? nil : indexPath.row + 1)
                updateImageView(using: album, in: cell, indexPath: indexPath, reusableView: tableView, overridable: self)
            
            case .artists, .genres, .composers:
                
                let collection = collectionArray(from: sectionDetails[indexPath.section].category)[indexPath.row]
            
                cell.prepare(for: sectionDetails[indexPath.section].category.albumBasedCollectionKind, with: collection, number: songCountVisible.inverted ? nil : indexPath.row + 1)
                updateImageView(using: collection, in: cell, indexPath: indexPath, reusableView: tableView, overridable: self)
        }
        
        cell.delegate = self
        cell.swipeDelegate = self
        
        cell.playButton.isUserInteractionEnabled = allowPlayOnly
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        switch editingStyle {
            
            case .insert:
                
                let songs: [MPMediaItem] = {
                    
                    switch sectionDetails[indexPath.section].category {
                        
                        case .songs: return [self.songs[indexPath.row]]
                            
                        case .albums: return albums[indexPath.row].items
                            
                        case .artists: return artists[indexPath.row].items
                            
                        case .playlists: return showiCloudItems || onlineOverride ? playlists[indexPath.row].items : playlists[indexPath.row].items.filter({ !$0.isCloudItem })
                            
                        case .genres: return genres[indexPath.row].items
                        
                        case .composers: return composers[indexPath.row].items
                        
                        case .all: return []
                    }
                }()
                
                notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: songs])
            
            case .none, .delete: break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return filtering ? 72 : 57
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        return filtering ? .insert : .none
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing {
            
            if filtering {
                
                self.tableView(tableView, commit: .insert, forRowAt: indexPath)
                saveRecentSearch(withTitle: searchBar?.text, resignFirstResponder: false)
                tableView.deselectRow(at: indexPath, animated: true)
            }
        
        } else {
            
            if filtering {
                
                switch sectionDetails[indexPath.section].category {
                    
                    case .songs:
                    
                        let song = songs[indexPath.row]
                        
                        musicPlayer.play(songs, startingFrom: song, from: self, withTitle: "Search Results (Songs)", subtitle: "Starting from \(song.validTitle)", alertTitle: "Play")
                    
                    case .artists, .genres, .composers:
                    
                        currentEntity = sectionDetails[indexPath.section].category.entity
                        performSegue(withIdentifier: "toArtist", sender: collectionArray(from: sectionDetails[indexPath.section].category))
                    
                    case .albums:
                    
                        currentEntity = .album
                        performSegue(withIdentifier: "toAlbum", sender: albums[indexPath.row])
                    
                    case .playlists:
                    
                        currentEntity = .playlist
                        performSegue(withIdentifier: "toPlaylist", sender: playlists[indexPath.row])
                    
                    case .all: break
                }
                
                saveRecentSearch(withTitle: searchBar?.text, resignFirstResponder: false)
                
            } else {
                
                let search = recentSearches[indexPath.row]
                
                highlightSearchBar(withText: (tableView.cellForRow(at: indexPath) as? RecentSearchTableViewCell)?.termLabel?.text, property: Int(search.property), propertyTest: search.propertyTest, setFirstResponder: false)
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if filtering {
            
            let view = tableView.sectionHeader
            
            view?.attributor = self
            view?.section = section
            updateAttributedText(for: view, inSection: section)
            
            return view
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if filtering {
            
            let height = ("eh" as NSString).boundingRect(with: CGSize(width: 100, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.myriadPro(ofWeight: .light, size: .tableHeader)], context: nil).height
            
            return height + 24
            
        } else {
            
            return 0.001
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        return filtering || self.numberOfSections(in: tableView) > 1 ? sectionDetails.map({ String($0.0.prefix(2)).capitalized }) : nil
    }
}

// MARK: - SearchBar
extension SearchViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        ignoreKeyboardForInset = false
        
        if !filtering {
            
            unfilteredPoint = .init(x: 0, y: tableView.contentOffset.y)
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        ignoreKeyboardForInset = true
        
        if !filtering {
            
            UIView.transition(with: titleLabel, duration: 0.2, options: .transitionCrossDissolve, animations: { self.updateTitleLabel() } , completion: nil)
        }
        
        searchBar.resignFirstResponder()
        
        emptyStackView.isHidden = filtering || recentSearches.count > 0
        
//        if !filtering {
//
//            tableView.contentOffset = unfilteredPoint
//        }
        
        updateDeleteButton()
        
//        topView.layoutIfNeeded()
//
//        clearButtonTrailingConstraint.constant = filtering || recentSearches.isEmpty ? -44 : 0
//
//        UIView.animate(withDuration: 0.3, animations: { self.topView.layoutIfNeeded() })
        
        adjustInsets(context: .container)
        
        if let _ = presentedViewController as? PropertyTestViewController {
            
            presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filtering = searchText != ""
        
        filterViewContainer.filterView.updateClearButton(to: filtering ? .visible : .hidden)
        
        if filtering {
            
            updateDeleteButton()
            
//            emptyStackView.isHidden = true
//
//            topView.layoutIfNeeded()
//
//            clearButtonTrailingConstraint.constant = -44
//
//            UIView.animate(withDuration: 0.3, animations: { self.topView.layoutIfNeeded() })
            
            filter(with: searchText)
        
        } else {
            
            filterOperation = nil
            updateTitleLabel()
            emptyStackView.isHidden = recentSearches.count > 0
            tableView.reloadData()
            tableView.contentOffset = unfilteredPoint
            
            animateCells(direction: .vertical)
            
            updateDeleteButton()
            
//            topView.layoutIfNeeded()
//
//            clearButtonTrailingConstraint.constant = recentSearches.isEmpty ? -44 : 0
//
//            UIView.animate(withDuration: 0.3, animations: { self.topView.layoutIfNeeded() })
            
            if tableView.isEditing {
                
                tableView.isEditing = false
            }
            
            onlineOverride = false
//            updateTempView(hidden: true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        saveRecentSearch(withTitle: searchBar.text, resignFirstResponder: true)
    }
}

// MARK: - 3D Touch
extension SearchViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location), filtering && !tableView.isEditing, sectionDetails[indexPath.section].category != .songs, let cell = tableView.cellForRow(at: indexPath) else { return nil }
        
        let vc = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
        
        previewingContext.sourceRect = cell.frame
        
        return Transitioner.shared.transition(to: sectionDetails[indexPath.section].category.entity, vc: vc, from: self, sender: collectionArray(from: sectionDetails[indexPath.section].category)[indexPath.row], preview: true)
        
//        if SearchCategory.playlists.rawValue == sectionDetails[indexPath.section].rawValue, let cell = tableView.cellForRow(at: indexPath) {
//
//            let vc = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
//
//            previewingContext.sourceRect = cell.frame
//
//            return Transitioner.shared.transition(to: .playlist, vc: vc, from: self, sender: playlists[indexPath.row], preview: true)
//
//        } else if SearchCategory.albums.rawValue == sectionDetails[indexPath.section].rawValue, let cell = tableView.cellForRow(at: indexPath) {
//
//            let vc = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
//
//            previewingContext.sourceRect = cell.frame
//
//            return Transitioner.shared.transition(to: .album, vc: vc, from: self, sender: albums[indexPath.row], preview: true)
//
//        } else if Set([SearchCategory.artists, .genres, .composers].map({ $0.rawValue })).contains(sectionDetails[indexPath.section].rawValue), let cell = tableView.cellForRow(at: indexPath) {
//
//            let details: (collection: MPMediaItemCollection, entity: Entity) = {
//
//                if sectionDetails[indexPath.section].rawValue == SearchCategory.artists.rawValue {
//
//                    return (artists[indexPath.row], .artist)
//
//                } else if sectionDetails[indexPath.section].rawValue == SearchCategory.genres.rawValue {
//
//                    return (genres[indexPath.row], .genre)
//
//                } else {
//
//                    return (composers[indexPath.row], .composer)
//                }
//            }()
//
//            let vc = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
//
//            previewingContext.sourceRect = cell.frame
//
//            return Transitioner.shared.transition(to: details.entity, vc: vc, from: self, sender: details.collection, preview: true)
//        }
//
//        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        if let vc = viewControllerToCommit as? BackgroundHideable {
            
            vc.modifyBackgroundView(forState: .removed)
        }
        
        if searchBar?.isFirstResponder == true {
            
            wasFiltering = true
            searchBar.resignFirstResponder()
        }
        
        if let vc = viewControllerToCommit as? Peekable {
            
            vc.peeker = nil
        }
        
        if let vc = viewControllerToCommit as? Arrangeable {
            
            vc.updateImage(for: vc.arrangeButton)
        }
        
        show(viewControllerToCommit, sender: nil)
        
        if let container = container {
            
            container.filterViewContainer.filterView.withinSearchTerm = true
            notifier.post(name: .resetInsets, object: nil)
        }
    }
}

extension SearchViewController: Attributor {
    
    @objc func updateAttributedText(for view: TableHeaderView?, inSection section: Int) {
        
        view?.label.updateTheme = false
        view?.label.greyOverride = true
        
        let count = tableView.numberOfRows(inSection: section).formatted
        let title = sectionDetails[section].0
        let string = "\(title) (\(count))"
        
        view?.label.text = string
        view?.label.attributes = [.init(kind: .title, range: string.nsRange(of: count))]
        view?.label.updateTheme = true
    }
}

extension SearchViewController: OnlineOverridable {
    
    @IBAction func performOnlineOverride() {
        
        onlineOverride = !onlineOverride
//        updateTempView(hidden: !onlineOverride)
        
        if filtering, let text = searchBar?.text, text.isEmpty.inverted {
            
            filter(with: text)
        }
    }
    
    @objc func updateOfflineFilterPredicates(onCondition condition: Bool) {
        
        
    }
}

extension SearchViewController: EntityCellDelegate {
    
    func artworkTapped(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        if tableView.isEditing {
            
            cell.setHighlighted(true, animated: true)
            
            self.tableView(tableView, commit: self.tableView(self.tableView, editingStyleForRowAt: indexPath), forRowAt: indexPath)
            saveRecentSearch(withTitle: searchBar?.text, resignFirstResponder: false)
            
            cell.setHighlighted(false, animated: true)
            
        } else if allowPlayOnly.inverted {
            
            cell.setHighlighted(true, animated: true)
            
            self.tableView(tableView, didSelectRowAt: indexPath)
            saveRecentSearch(withTitle: searchBar?.text, resignFirstResponder: false)
            
            cell.setHighlighted(false, animated: true)
            
        } else if let songs = getItems(at: indexPath) {
            
            if songs.count > 1 {
                
                var array = [UIAlertAction]()
                let canShuffleAlbums = songs.canShuffleAlbums
                
                let play = UIAlertAction.init(title: "Play", style: .default, handler: { _ in
                    
                    musicPlayer.play(songs, startingFrom: songs.first, from: self, withTitle: cell.nameLabel.text, alertTitle: "Play", completion: { self.saveRecentSearch(withTitle: self.searchBar?.text, resignFirstResponder: false) })
                })
                
                array.append(play)
                
                let shuffle = UIAlertAction.init(title: .shuffle(canShuffleAlbums ? .songs : .none), style: .default, handler: { _ in
                    
                    musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: cell.nameLabel.text, alertTitle: .shuffle(canShuffleAlbums ? .songs : .none), completion: { self.saveRecentSearch(withTitle: self.searchBar?.text, resignFirstResponder: false) })
                })
                
                array.append(shuffle)
                
                if canShuffleAlbums {
                    
                    let shuffleAlbums = UIAlertAction.init(title: .shuffle(.albums), style: .default, handler: { _ in
                        
                        musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: self, withTitle: cell.nameLabel.text, alertTitle: .shuffle(.albums), completion: { self.saveRecentSearch(withTitle: self.searchBar?.text, resignFirstResponder: false) })
                    })
                    
                    array.append(shuffleAlbums)
                }
                
                present(UIAlertController.withTitle(cell.nameLabel.text, message: nil, style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
                
            } else {
                
                musicPlayer.play(songs, startingFrom: nil, from: self, withTitle: cell.nameLabel.text, alertTitle: "Play", completion: { self.saveRecentSearch(withTitle: self.searchBar?.text, resignFirstResponder: false) })
            }
        }
    }
    
    func editButtonTapped(in cell: SongTableViewCell) {
        
        
    }
    
    func accessoryButtonTapped(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell), let entity = getEntity(at: indexPath), let count: Int = {
            
            if let _ = entity as? MPMediaItem {
                
                return 1
                
            } else if let collection = entity as? MPMediaItemCollection {
                
                return collection.count
            }
            
            return nil
            
        }(), count > 0 else { return }
        
        var actions = [SongAction.collect, .info(context: context(from: indexPath)), .queue(name: cell.nameLabel.text, query: nil), .newPlaylist, .addTo].map({ singleItemAlertAction(for: $0, entity: .song, using: entity, from: self) })
        
        if let item = entity as? MPMediaItem, item.existsInLibrary.inverted {
            
            actions.insert(singleItemAlertAction(for: .library, entity: .song, using: item, from: self), at: 3)
        }
        
        present(UIAlertController.withTitle(nil, message: cell.nameLabel.text, style: .actionSheet, actions: actions + [.cancel()] ), animated: true, completion: nil)
    }
    
    func scrollViewTapped(in cell: SongTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        cell.setHighlighted(true, animated: true)
        
        self.tableView(self.tableView, didSelectRowAt: indexPath)
        
        cell.setHighlighted(false, animated: true)
    }
}

extension SearchViewController: SwipeTableViewCellDelegate {
    
    func getEntity(at indexPath: IndexPath) -> MPMediaEntity? {
        
        switch sectionDetails[indexPath.section].category {
            
            case .songs: return songs[indexPath.row]
            
            case .all: return nil
            
            default: return collectionArray(from: sectionDetails[indexPath.section].category)[indexPath.row]
        }
    }
    
    func getItems(at indexPath: IndexPath) -> [MPMediaItem]? {
        
        if let song = getEntity(at: indexPath) as? MPMediaItem {
            
            return [song]
            
        } else if let collection = getEntity(at: indexPath) as? MPMediaItemCollection {
            
            return collection.items
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        return TableDelegate.editActions(for: self, orientation: orientation, using: getEntity(at: indexPath), at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        
        var options = SwipeTableOptions()
        options.transitionStyle = .drag
        options.expansionStyle = .selection
        
        return options
    }
}

extension SearchViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    var array: [String?] { return pickerViewText }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return array.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let label = view as? MELLabel ?? MELLabel.init(fontWeight: .regular, fontSize: 25, alignment: .center)
        
        label.text = array[row] ?? "----"
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        
        return 36
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        searchBar.text = array[row]
        searchBar(searchBar, textDidChange: array[row] ?? "")
    }
}
