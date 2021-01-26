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

class SearchViewController: UIViewController, Filterable, DynamicSections, AlbumTransitionable, Contained, InfoLoading, ArtistTransitionable, GenreTransitionable, ComposerTransitionable, AlbumArtistTransitionable, PlaylistTransitionable, EntityContainer, OptionsContaining, CellAnimatable, IndexContaining, FilterContainer, SingleItemActionable, EntityVerifiable, TopScrollable, Detailing, Navigatable, ArtworkModifying, PillButtonContaining, CentreViewDisplaying {

    @IBOutlet var tableView: MELTableView!
//    @IBOutlet var emptySubLabel: MELLabel! {
//
//        didSet {
//
//            guard let text = emptySubLabel.text else { return }
//
//            let style = NSMutableParagraphStyle.init()
//            style.alignment = .center
//            style.lineHeightMultiple = 1.2
//
//            emptySubLabel.attributes = [Attributes.init(name: .paragraphStyle, value: .other(style), range: text.nsRange())]
//        }
//    }
    
    lazy var headerView: HeaderView = {
        
        let view = HeaderView.instance
        self.actionsStackView = view.actionsStackView
        view.scrollStackViewHeightConstraint.constant = 0
        
        return view
    }()
    var actionsStackView: UIStackView! {
        
        didSet {
            
            let editView = PillButtonView.with(title: .inactiveEditButtonTitle, image: .inactiveEditImage, tapAction: .init(action: #selector(SongActionManager.toggleEditing(_:)), target: songManager))
            editButton = editView.button
            self.editView = editView
            
            [editView].forEach({ actionsStackView.addArrangedSubview($0) })
        }
    }
    
    @objc let presenter = NavigationAnimationController()
    @objc var recentSearches = [RecentSearch]()
    var currentEntity = EntityType.artist
    @objc var filtering = false {
        
        didSet {
            
            guard oldValue != filtering else { return }
            
            tableView.allowsMultipleSelectionDuringEditing = filtering.inverted
        }
    }
    var filterText: String?
    let filterTitle: String? = "Library"
    var category = SearchCategory.all
    var entityCount = 0
    @objc var unfilteredPoint = CGPoint.zero
    lazy var applicableFilterProperties: Set = applicationItemFilterProperties.union(applicableCollectionFilterProperties)
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
    
    var preferredEditingStyle = EditingStyle.insert
    
    lazy var borderedButtons = [PillButtonView?]()
    
    @objc var ignoreKeyboardForInset = true
    var sender: (UIViewController & Filterable)? {
        
        get { return self }
        
        set { }
    }
    var filterContainer: (UIViewController & FilterContainer)? {
        
        get { return self }
        
        set { filterViewContainer.filterInfo = (filter: sender, container: self) }
    }
    @objc lazy var wasFiltering = false
    var emptyCondition: Bool { return filtering ? itemCount < 1 : recentSearches.isEmpty }
    
    let applicableActions = [SongAction]()
    let actionableSongs = [MPMediaItem]()
    lazy var songManager: SongActionManager = { SongActionManager.init(actionable: self) }()
    
    var editView: PillButtonView!
    var editButton: MELButton! {
        
        didSet {
            
            let allHold = UILongPressGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.showActionsForAll(_:)))
            allHold.minimumPressDuration = longPressDuration
            editButton.addGestureRecognizer(allHold)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: allHold))
        }
    }
    
    var backLabelText: String?
    var animateClearButton = false
    
    var artwork: UIImage? {
        
        get { return musicPlayer.nowPlayingItem?.actualArtwork?.image(at: .artworkSize) }
        
        set { }
    }
    var artworkDetails: NavigationBarArtworkDetails?
    var buttonDetails: NavigationBarButtonDetails = (.clear, true) {
        
        didSet {
            
            guard animateClearButton else {
                
                animateClearButton = true
                
                return
            }
        
            container?.visualEffectNavigationBar.prepareRightButton(for: self, animated: true)
//            firstButtonUpdateUsed = true
        }
    }
    
    var inset: CGFloat { return VisualEffectNavigationBar.Location.main.total }
    lazy var preferredTitle: String? = "Search"
    var activeChildViewController: UIViewController?
    
    var centreViewGiantImage: UIImage?
    var centreViewTitleLabelText: String?
    var centreViewSubtitleLabelText: String?
    var centreViewLabelsImage: UIImage?
    var currentCentreView = CentreView.CurrentView.none
    var centreView: CentreView? {
        
        get { container?.centreView }
        
        set { }
    }
    let components: Set<CentreView.CurrentView.LabelStackViewComponent> = [.image, .title, .subtitle]
    
    @objc lazy var songs = [MPMediaItem]()
    @objc lazy var playlists = [MPMediaPlaylist]()
    @objc lazy var playlistCounts = [Int]()
    @objc lazy var artists = [MPMediaItemCollection]()
    @objc lazy var albums = [MPMediaItemCollection]()
    @objc lazy var genres = [MPMediaItemCollection]()
    @objc lazy var composers = [MPMediaItemCollection]()
    @objc lazy var albumArtists = [MPMediaItemCollection]()
    
    @objc var itemCount: Int { return songs.count + playlists.count + albums.count + artists.count + genres.count + composers.count + albumArtists.count }
    @objc var onlineOverride = false
    var options: LibraryOptions { return .init(fromVC: self, configuration: .search) }
    var sectionIndexViewController: SectionIndexViewController?
    let requiresLargerTrailingConstraint = false
    var navigatable: Navigatable? { return self }
    var ignorePropertyChange = false
    var filterViewContainer: FilterViewContainer! {
        
        get { return container?.filterViewContainer }
        
        set { newValue.filterInfo = (self, self) }
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
    
    lazy var rightViewButton: MELButton = filterViewContainer.filterView.rightButton
    
    var sectionDetails: [SectionDetails] {
        
        return getSectionDetails(from: ("songs", songs.count, .songs),
                                ("artists", artists.count, .artists),
                                ("album artists", albumArtists.count, .albumArtists),
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
        queue.qualityOfService = .userInitiated
        
        return queue
    }()
    @objc var operation: BlockOperation?
    @objc var filterOperation: BlockOperation?
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        container?.visualEffectNavigationBar.titleLabel.text = title
        
        navigationController?.delegate = presenter
        presenter.interactor.add(to: navigationController)
        
        centreViewLabelsImage = #imageLiteral(resourceName: "Search100")
        centreViewTitleLabelText = "Nothing Here..."
        centreViewSubtitleLabelText = "Searches acted upon are added here"
        
        prepareLifetimeObservers()
        
        adjustInsets(context: .container)
        searchBar?.delegate = self
        filterViewContainer.filterView.alpha = 1
        filterViewContainer.filterView.filterTestButton.setTitle(testTitle, for: .normal)
        
        tableView.register(UINib.init(nibName: "RecentSearchCell", bundle: nil), forCellReuseIdentifier: .recentCell)
        updateTopInset()
        
        updateKeyboard(with: self)
        
        resetRecentSearches()
        
        let swipeRight = UISwipeGestureRecognizer.init(target: self, action: #selector(handleRightSwipe(_:)))
        swipeRight.direction = .right
        tableView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(handleLeftSwipe(_:)))
        swipeLeft.direction = .left
        tableView.addGestureRecognizer(swipeLeft)
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(performHold(_:)))
        hold.minimumPressDuration = longPressDuration
        tableView.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        
        let edge = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(updateSections))
        edge.edges = .right
        view.addGestureRecognizer(edge)
        
        searchBar?.textField?.leftView = filterViewContainer.filterView.leftView
        searchBar?.updateTextField(with: placeholder)
        
        updateRightView(animated: false)
        
        if traitCollection.forceTouchCapability == .available {
            
            registerForPreviewing(with: self, sourceView: tableView)
        }
    }
    
    func updateTopInset() {
        
        tableView.contentInset.top = inset
        tableView.scrollIndicatorInsets.top = inset
    }
    
    @objc func updateHeaderView(withCount count: Int = 0) {
        
        tableView.tableHeaderView = emptyCondition ? nil : headerView
        tableView.tableHeaderView?.frame.size.height = emptyCondition ? 0 : 48
        
        let array = [editView]
        
        borderedButtons = array
        
        updateButtons()
    }
    
    @objc func performHold(_ sender: UILongPressGestureRecognizer) {
        
        guard filtering else { return }
        
        switch sender.state {
            
            case .began:
            
                guard let indexPath = tableView.indexPathForRow(at: sender.location(in: tableView)), let cell = tableView.cellForRow(at: indexPath) as? EntityTableViewCell, let entity = getEntity(at: indexPath) else { return }
                
                let location = sender.location(in: cell)
                
                if cell.editingView.frame.contains(location) {
                    
                    Transitioner.shared.performDeepSelection(from: self, title: cell.nameLabel.text)
                    
                } else if cell.mainView.convert(cell.infoButton.frame, to: cell).contains(location) {
                    
                    singleItemActionDetails(for: .show(title: cell.nameLabel.text, context: context(from: indexPath), canDisplayInLibrary: true), entityType: sectionDetails[indexPath.section].category.entityType, using: entity, from: self, useAlternateTitle: true).handler()
                
                } else if musicPlayer.nowPlayingItem != nil, cell.mainView.convert(cell.playButton.frame, to: cell).contains(location) == true {
                    
                    singleItemActionDetails(for: .queue(name: cell.nameLabel.text, query: nil), entityType: sectionDetails[indexPath.section].category.entityType, using: entity, from: self).handler()
                    
                } else {
                    
                    var actions = [
                        SongAction.collect,
                        .info(context: context(from: indexPath)),
                        .queue(name: cell.nameLabel.text, query: nil),
                        .newPlaylist,
                        .addTo,
                        .show(title: cell.nameLabel.text, context: context(from: indexPath), canDisplayInLibrary: true)/*,
                        .search(unwinder: nil)*/].map({ singleItemAlertAction(for: $0, entityType: sectionDetails[indexPath.section].category.entityType, using: entity, from: self) })
                    
                    if let item = entity as? MPMediaItem, item.existsInLibrary.inverted {
                        
                        actions.append(singleItemAlertAction(for: .library, entityType: .song, using: item, from: self))
                    }
                    
                    showAlert(title: cell.nameLabel.text, with: actions)
                }
            
            case .changed, .ended:
            
                guard let top = topViewController as? VerticalPresentationContainerViewController else { return }
            
                top.gestureActivated(sender)
            
            default: break
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
            
            case .albumArtists: return .collection(kind: .albumArtist, at: indexPath.row, within: albumArtists)
            
            case .all: fatalError("Nothing should call this yet")
        }
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        imageCache.removeAllObjects()
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
        
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if searchBar?.delegate == nil, let container = container {
            
            self.filterViewContainer = container.filterViewContainer
            self.searchBar.delegate = self
            self.searchBar.text = self.sender?.filterText
            self.filterViewContainer.filterView.propertyButton.setTitle(self.sender?.filterProperty.title, for: .normal)
            self.filterViewContainer.filterView.filterTestButton.setTitle(self.sender?.testTitle, for: .normal)
            self.sender?.updateKeyboard(with: self)
            self.searchBar?.textField?.leftView = self.filterViewContainer.filterView.leftView
            self.searchBar.updateTextField(with: self.placeholder)
            self.updateRightView(animated: true)
        }
        
        container?.visualEffectNavigationBar.entityTypeLabel.superview?.isHidden = true
        
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
        
        notifier.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notifier.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
        unregisterAll(from: transientObservers)
    }
    
    @objc func handleRightSwipe(_ sender: Any) {
        
        tableView.setEditing(true, animated: true)
        
        editView?.animateChange(title: "Done", image: .doneImage)
    }
    
    @objc func handleLeftSwipe(_ sender: Any) {
        
        if tableView.isEditing {
            
            tableView.setEditing(false, animated: true)
            
            editView.animateChange(title: .inactiveEditButtonTitle, image: .inactiveEditImage)
        
        } else if let gr = sender as? UIGestureRecognizer, let indexPath = tableView.indexPathForRow(at: gr.location(in: tableView)), filtering, let cell = tableView.cellForRow(at: indexPath) as? EntityTableViewCell, let entity = getEntity(at: indexPath) {
            
            singleItemActionDetails(for: .show(title: cell.nameLabel.text, context: context(from: indexPath), canDisplayInLibrary: true), entityType: sectionDetails[indexPath.section].category.entityType, using: entity, from: self, useAlternateTitle: true).handler()
            
            /*switch sectionDetails[indexPath.section].category {
                
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
                        newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
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
                        newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                        newBanner.show(duration: 0.7)
                    }
                    
                    saveRecentSearch(withTitle: searchBar?.text, resignFirstResponder: false)
                
                default: break
            }*/
        }
    }
    
    @objc func prepareTransientObservers() {
        
        let secondaryObserver = notifier.addObserver(forName: .performSecondaryAction, object: navigationController, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            guard weakSelf.searchBar != nil else {
                
                notifier.post(name: .performSecondaryAction, object: weakSelf.navigationController)
                return
            }
            
            weakSelf.highlightSearchBar(withText: weakSelf.searchBar?.text, property: weakSelf.filterProperty.oldRawValue, propertyTest: weakSelf.propertyTest.rawValue, setFirstResponder: true)
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
        
        guard let keyboardHeightAtEnd = ((notification as NSNotification).userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height/*, searchBar?.isFirstResponder == true*/, let container = container else { return }
        
        let keyboardWillShow = notification.name == UIResponder.keyboardWillShowNotification
        
        filterViewContainer.filterView.filterInputViewBottomConstraint.constant = keyboardWillShow ? keyboardHeightAtEnd - 51 - container.collectedViewHeight - container.sliderHeight - container.titlesHeight : 0
        
//        if let controller = navigationController?.delegate as? NavigationAnimationController, controller.disregardViewLayoutDuringKeyboardPresentation.inverted {
//
//            return
//        }
        
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
        
        lifetimeObservers.insert(notifier.addObserver(forName: .showExplicitnessChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.tableView.reloadRows(at: weakSelf.tableView.indexPathsForVisibleRows ?? [], with: .none)
            
        }) as! NSObject)
        
        lifetimeObservers.insert(iCloudObserver as! NSObject)
        
        [Notification.Name.playerChanged, .MPMusicPlayerControllerNowPlayingItemDidChange].forEach({
        
            lifetimeObservers.insert(notifier.addObserver(forName: $0, object: /*musicPlayer*/nil, queue: nil, using: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                for cell in weakSelf.tableView.visibleCells where weakSelf.tableView.indexPath(for: cell)?.section != SearchCategory.playlists.rawValue {
                    
                    guard let entityCell = cell as? EntityTableViewCell, let indexPath = weakSelf.tableView.indexPath(for: entityCell), let nowPlaying = musicPlayer.nowPlayingItem else {
                        
                        (cell as? EntityTableViewCell)?.playingView.isHidden = true
                        (cell as? EntityTableViewCell)?.indicator.state = .stopped
                        
                        continue
                    }
                    
                    if let song = weakSelf.getEntity(at: indexPath) as? MPMediaItem {
                        
                        if entityCell.playingView.isHidden.inverted && musicPlayer.nowPlayingItem != song {
                            
                            entityCell.playingView.isHidden = true
                            entityCell.indicator.state = .stopped
                            
                        } else if entityCell.playingView.isHidden && musicPlayer.nowPlayingItem == song {
                            
                            entityCell.playingView.isHidden = false
                            UniversalMethods.performOnMainThread({ entityCell.indicator.state = musicPlayer.isPlaying ? .playing : .paused }, afterDelay: 0.1)
                        }
                    
                    } else if let collection = weakSelf.getEntity(at: indexPath) as? MPMediaItemCollection {
                        
                        if entityCell.playingView.isHidden.inverted && Set(collection.items).contains(nowPlaying).inverted {
                            
                            entityCell.playingView.isHidden = true
                            entityCell.indicator.state = .stopped
                            
                        } else if entityCell.playingView.isHidden && Set(collection.items).contains(nowPlaying) {
                            
                            entityCell.playingView.isHidden = false
                            UniversalMethods.performOnMainThread({ entityCell.indicator.state = musicPlayer.isPlaying ? .playing : .paused }, afterDelay: 0.1)
                        }
                    }
                }
                
            }) as! NSObject)
        })
        
        lifetimeObservers.insert(notifier.addObserver(forName: .entityCountVisibilityChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self, let indexPaths = weakSelf.tableView.indexPathsForVisibleRows else { return }
            
            weakSelf.tableView.reloadRows(at: indexPaths, with: .none)
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .lineHeightsCalculated, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.tableView.reloadData()
            weakSelf.updateTopInset()
            
        }) as! NSObject)
    }
    
//    @objc func rightViewButtonTapped() {
//        
//        showRightButtonOptions()
//    }
    
    @objc func dismissSearch() {
        
        searchBar?.text = nil
        filterOperation = nil
        filtering = false
        updateHeaderView()
        tableView.reloadData()
        updateCurrentView(to: .none)
        
        if !filtering {
            
            tableView.contentOffset = unfilteredPoint
        }
        
        animateCells(direction: .vertical)
        
        if tableView.isEditing {
        
            tableView.isEditing = false
            editView.imageView?.image = .inactiveEditImage
            editView.label?.text = .inactiveEditButtonTitle
        }
        
        if searchBar?.isFirstResponder == true {
            
            searchBar?.resignFirstResponder()
        
        } else {
            
            if let searchBar = searchBar {
                
                searchBarTextDidEndEditing(searchBar)
            }
        }
        
        searchBar?.updateTextField(with: placeholder)
        onlineOverride = false
        
//        filterViewContainer.filterView.updateClearButton(to: .hidden)
//        updateTempView(hidden: true)
    }
    
    @objc func clearSearch() {
        
        searchBar?.text = nil
        filterOperation = nil
        filtering = false
        updateTitleLabel()
        updateHeaderView()
        tableView.reloadData()
        updateCurrentView(to: recentSearches.isEmpty ? .labels(components: components) : .none)
        
        if !filtering {
            
            tableView.contentOffset = unfilteredPoint
        }
        
        animateCells(direction: .vertical)
        if tableView.isEditing { tableView.setEditing(false, animated: false) }
        
//        topView.layoutIfNeeded()
//        searchBar?.updateTextField(with: placeholder)
//
//        clearButtonTrailingConstraint.constant = filtering || recentSearches.isEmpty ? -44 : 0
//
//        UIView.animate(withDuration: 0.3, animations: { self.topView.layoutIfNeeded() })
        
        onlineOverride = false
        
//        filterViewContainer.filterView.updateClearButton(to: .hidden)
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
    
    @objc func viewSections() {
        
        guard let sectionVC = popoverStoryboard.instantiateViewController(withIdentifier: String.init(describing: SectionIndexViewController.self)) as? SectionIndexViewController, let sections = self.sectionIndexTitles(for: tableView), !sections.isEmpty else { return }
        
        sectionVC.array = sections.map({ SectionIndexViewController.IndexKind.text($0) })
        sectionVC.container = self
        sectionIndexViewController = sectionVC
        
        present(sectionVC, animated: true, completion: nil)
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
        
        updateCurrentView(to: .indicator)
        
        filterOperationQueue.cancelAllOperations()
        filterOperation = BlockOperation()
        filterOperation?.qualityOfService = .userInitiated
        filterOperation?.addExecutionBlock({ [weak self, weak filterOperation] in
            
            let text = searchText
        
            guard let weakSelf = self, let operation = filterOperation, operation.isCancelled.inverted else { return }
            
            var songs = [MPMediaItem]()
            var artists = [MPMediaItemCollection]()
            var albums = [MPMediaItemCollection]()
            var genres = [MPMediaItemCollection]()
            var composers = [MPMediaItemCollection]()
            var playlists = [MPMediaPlaylist]()
            var albumArtists = [MPMediaItemCollection]()
            
            songs = weakSelf.getResults(for: MPMediaQuery.songs().itemsAccessed(at: showiCloudItems ? .all : .unadded).cloud.items ?? [], against: searchText)
            
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            artists = weakSelf.getResults(for: MPMediaQuery.artists().cloud.collections ?? [], of: .artist, against: searchText)
            
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            albumArtists = weakSelf.getResults(for: MPMediaQuery.albumArtists.cloud.collections ?? [], of: .albumArtist, against: searchText)
            
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            albums = weakSelf.getResults(for: MPMediaQuery.albums().cloud.collections ?? [], of: .album, against: searchText)
            
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            genres = weakSelf.getResults(for: MPMediaQuery.genres().cloud.collections ?? [], of: .genre, against: searchText)
            
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            composers = weakSelf.getResults(for: MPMediaQuery.composers().cloud.collections ?? [], of: .composer, against: searchText)
            
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            playlists = weakSelf.getResults(for: MPMediaQuery.playlists().cloud.playlistsExtracted(showCloudItems: showiCloudItems || weakSelf.onlineOverride), of: .playlist, against: searchText) as? [MPMediaPlaylist] ?? []
            
            OperationQueue.main.addOperation({
            
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.songs = songs
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.playlists = playlists
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.artists = artists
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.albumArtists = albumArtists
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.albums = albums
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.genres = genres
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.composers = composers
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                UIView.setAnimationsEnabled(false)
                weakSelf.updateTitleLabel()
                UIView.setAnimationsEnabled(true)
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.tableView.contentOffset = .init(x: 0, y: -weakSelf.inset)
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.updateHeaderView()
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.tableView.reloadData()
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.updateCurrentView(to: .none)
                weakSelf.animateCells(direction: .vertical)
            })
        })
        
        filterOperationQueue.addOperation(filterOperation!)
        filterOperations[searchText] = filterOperation!
    }
    
    @objc func performEmptySearch() {
        
        searchBar?.text = nil
        searchBar?.updateTextField(with: "Performing Empty Search...")
        filtering = true
        
        updateCurrentView(to: recentSearches.isEmpty ? .labels(components: components) : .none)
        
        filter(with: "")
    }
    
    @objc func updateTitleLabel() {
        
        title = filtering ? itemCount.formatted + " \(itemCount == 1 ? "Result" : "Results")" : "Previous Searches"
        
        guard container?.activeViewController?.topViewController == self else { return }
        
        container?.visualEffectNavigationBar.titleLabel.text = title
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
            
            case .albumArtists: return albumArtists
            
            case .genres: return genres
            
            case .composers: return composers
            
            case .songs: return []
            
            case .albums: return albums
            
            case .playlists: return playlists
        }
    }
    
    func goToDetails(basedOn entity: EntityType) -> (entities: [EntityType], albumArtOverride: Bool) {
        
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
                
                case .albumArtists: return albumArtists.count
                
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
            
            let property = Property.fromOldRawValue(Int(search.property)) ?? .title
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
                updateInfo(for: song, ofType: .song, in: cell, at: indexPath, within: tableView)
                
//                for category in [SecondaryCategory.loved, .plays, .rating, .lastPlayed, .dateAdded, .genre, .year, .fileSize] {
//                    
//                    update(category: category, using: song, in: cell, at: indexPath, reusableView: tableView)
//                }
            
            case .playlists:
            
                let playlist = playlists[indexPath.row]
                cell.prepare(with: playlist, count: MPMediaQuery.for(.playlist, using: playlist).itemsAccessed(at: showiCloudItems ? .all : .standard).cloud.collections?.count ?? 0, number: songCountVisible.inverted ? nil : indexPath.row + 1)
                updateImageView(using: playlist, entityType: .playlist, in: cell, indexPath: indexPath, reusableView: tableView, overridable: self)
            
            case .albums:
            
                let album = albums[indexPath.row]
                
                cell.prepare(with: album, withinArtist: false, number: songCountVisible.inverted ? nil : indexPath.row + 1)
                updateImageView(using: album, entityType: .album, in: cell, indexPath: indexPath, reusableView: tableView, overridable: self)
            
            case .artists, .genres, .composers, .albumArtists:
                
                let collection = collectionArray(from: sectionDetails[indexPath.section].category)[indexPath.row]
            
                cell.prepare(for: sectionDetails[indexPath.section].category.albumBasedCollectionKind, with: collection, number: songCountVisible.inverted ? nil : indexPath.row + 1)
                updateImageView(using: collection, entityType: sectionDetails[indexPath.section].category.entityType, in: cell, indexPath: indexPath, reusableView: tableView, overridable: self)
        }
        
        cell.delegate = self
//        cell.swipeDelegate = self
        cell.preferredEditingStyle = preferredEditingStyle
        
        cell.playButton.isUserInteractionEnabled = allowPlayOnly
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        guard filtering else { return }
        
//        switch editingStyle {
//
//            case .insert:
//
                let songs: [MPMediaItem] = {
                    
                    switch sectionDetails[indexPath.section].category {
                        
                        case .songs: return [self.songs[indexPath.row]]
                            
                        case .albums: return albums[indexPath.row].items
                            
                        case .artists: return artists[indexPath.row].items
                        
                        case .albumArtists: return albumArtists[indexPath.row].items
                            
                        case .playlists: return showiCloudItems || onlineOverride ? playlists[indexPath.row].items : playlists[indexPath.row].items.filter({ !$0.isCloudItem })
                            
                        case .genres: return genres[indexPath.row].items
                        
                        case .composers: return composers[indexPath.row].items
                        
                        case .all: return []
                    }
                }()
                
                notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: songs])
//
//            case .none, .delete: break
//
//            @unknown default: break
//        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return filtering ? FontManager.shared.entityCellHeight : 57
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        return /*filtering ? .insert : */.none
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing {
            
            if filtering {
                
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
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
                    
                    case .artists, .genres, .composers, .albumArtists:
                    
                        currentEntity = sectionDetails[indexPath.section].category.entityType
                        performSegue(withIdentifier: "toArtist", sender: collectionArray(from: sectionDetails[indexPath.section].category)[indexPath.row])
                    
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
            
            let header = tableView.sectionHeader
            
            header?.attributor = self
            header?.section = section
            updateAttributedText(for: header, inSection: section)
            header?.altButton.addTarget(self, action: #selector(viewSections), for: .touchUpInside)
            
            return header
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            
        return filtering ? .textHeaderHeight : emptyCondition ? 0.00001 : .emptyHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        return filtering || self.numberOfSections(in: tableView) > 1 ? sectionDetails.map({ String($0.2.indexTitle.prefix(2)).capitalized }) : nil
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        return filtering.inverted
    }
    
//    @available(iOS 13, *)
//    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
//
//        return true
//    }
//
//    @available(iOS 13, *)
//    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
//
//        songManager.toggleEditing(self)
//    }
//
//    @available(iOS 13, *)
//    func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
//
//        songManager.toggleEditing(self)
//    }
}

// MARK: - SearchBar
extension SearchViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        ignoreKeyboardForInset = false
        
        if !filtering {
            
            unfilteredPoint = CGPoint.init(x: 0, y: tableView.contentOffset.y)
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        ignoreKeyboardForInset = true
        
        if !filtering {

            updateTitleLabel()
        }
        
        searchBar.resignFirstResponder()
        
        updateDeleteButton()
        
        adjustInsets(context: .container)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filtering = searchText != ""
        
        filterText = searchText
        
        if filtering {
            
            updateDeleteButton()
            
            filter(with: searchText)
            
            if searchText.isEmpty {
                
                requiredInputView?.pickerView.selectRow(0, inComponent: 0, animated: true)
            }
        
        } else {
            
            filterOperation?.cancel()
            filterOperation = nil
            updateTitleLabel()
            updateCurrentView(to: recentSearches.isEmpty ? .labels(components: components) : .none)
            updateHeaderView()
            tableView.reloadData()
            tableView.contentOffset = unfilteredPoint
            
            animateCells(direction: .vertical)
            
            updateDeleteButton()
            
            if tableView.isEditing {
                
                tableView.isEditing = false
                editView.imageView?.image = .inactiveEditImage
                editView.label?.text = .inactiveEditButtonTitle
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
        
        return Transitioner.shared.transition(to: sectionDetails[indexPath.section].category.entityType, vc: vc, from: self, sender: collectionArray(from: sectionDetails[indexPath.section].category)[indexPath.row], preview: true)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        performCommitActions(on: viewControllerToCommit)
        
        if searchBar?.isFirstResponder == true {
            
            wasFiltering = true
            searchBar.resignFirstResponder()
        }
        
        show(viewControllerToCommit, sender: nil)
        
        if let container = container {
            
            container.filterViewContainer.filterView.requiresSearchBar = true
            notifier.post(name: .resetInsets, object: nil)
        }
    }
}

extension SearchViewController: Attributor {
    
    @objc func updateAttributedText(for view: TableHeaderView?, inSection section: Int) {
            
        view?.label.updateTheme = false
        view?.label.greyOverride = true
        
        let count = tableView.numberOfRows(inSection: section).formatted
        let title = sectionDetails.value(at: section)?.0
        let string: String = {
            
            if let title = title {
                
                return "\(title) (\(count))"
            }
            
            return ""
        }()
        
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
    
    func handleScrollSwipe(from gr: UIGestureRecognizer, direction: UISwipeGestureRecognizer.Direction) {
        
        switch direction {
            
            case .left: handleLeftSwipe(gr)
            
            case .right: handleRightSwipe(gr)
            
            default: break
        }
    }
    
    func editButtonHeld(in cell: EntityTableViewCell) {
        
        Transitioner.shared.performDeepSelection(from: self, title: cell.nameLabel.text)
    }
    
    func artworkTapped(in cell: EntityTableViewCell) {
        
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
                
                var array = [AlertAction]()
                let canShuffleAlbums = songs.canShuffleAlbums
                
                let play = AlertAction.init(title: "Play", style: .default, requiresDismissalFirst: true, handler: {
                    
                    musicPlayer.play(songs, startingFrom: songs.first, from: self, withTitle: cell.nameLabel.text, alertTitle: "Play", completion: { self.saveRecentSearch(withTitle: self.searchBar?.text, resignFirstResponder: false) })
                })
                
                array.append(play)
                
                let shuffle = AlertAction.init(title: .shuffle(canShuffleAlbums ? .songs : .none), style: .default, requiresDismissalFirst: true, handler: {
                    
                    musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: cell.nameLabel.text, alertTitle: .shuffle(canShuffleAlbums ? .songs : .none), completion: { self.saveRecentSearch(withTitle: self.searchBar?.text, resignFirstResponder: false) })
                })
                
                array.append(shuffle)
                
                if canShuffleAlbums {
                    
                    let shuffleAlbums = AlertAction.init(title: .shuffle(.albums), style: .default, requiresDismissalFirst: true, handler: {
                        
                        musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: self, withTitle: cell.nameLabel.text, alertTitle: .shuffle(.albums), completion: { self.saveRecentSearch(withTitle: self.searchBar?.text, resignFirstResponder: false) })
                    })
                    
                    array.append(shuffleAlbums)
                }
                
                showAlert(title: cell.nameLabel.text, with: array)
                
            } else {
                
                musicPlayer.play(songs, startingFrom: nil, from: self, withTitle: cell.nameLabel.text, alertTitle: "Play", completion: { self.saveRecentSearch(withTitle: self.searchBar?.text, resignFirstResponder: false) })
            }
        }
    }
    
    func artworkHeld(in cell: EntityTableViewCell) {
        
        guard musicPlayer.nowPlayingItem != nil, let indexPath = tableView.indexPath(for: cell) else { return }
        
        getActionDetails(from: .queue(name: cell.nameLabel.text, query: nil), indexPath: indexPath, actionable: self, vc: self, entityType: .song, entity: getEntity(at: indexPath)!)?.handler()
    }
    
    func editButtonTapped(in cell: EntityTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        cell.setHighlighted(true, animated: true)
        self.tableView(tableView, didSelectRowAt: indexPath)
        cell.setHighlighted(false, animated: true)
    }
    
    func accessoryButtonTapped(in cell: EntityTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell), let entity = getEntity(at: indexPath), let count: Int = {
            
            if let _ = entity as? MPMediaItem {
                
                return 1
                
            } else if let collection = entity as? MPMediaItemCollection {
                
                return collection.count
            }
            
            return nil
            
        }(), count > 0 else { return }
        
        var actions = [
            SongAction.collect,
            .info(context: context(from: indexPath)),
            .queue(name: cell.nameLabel.text, query: nil),
            .newPlaylist,
            .addTo,
            .show(title: cell.nameLabel.text, context: context(from: indexPath), canDisplayInLibrary: true)/*,
            .search(unwinder: nil)*/].map({ singleItemAlertAction(for: $0, entityType: sectionDetails[indexPath.section].category.entityType, using: entity, from: self) })
        
        if let item = entity as? MPMediaItem, item.existsInLibrary.inverted {
            
            actions.append(singleItemAlertAction(for: .library, entityType: .song, using: item, from: self))
        }
        
        showAlert(title: cell.nameLabel.text, with: actions)
    }
    
    func accessoryButtonHeld(in cell: EntityTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell), let action = self.tableView(tableView, editActionsForRowAt: indexPath, for: .right)?.first else { return }
        
        action.handler?(action, indexPath)
    }
    
    func scrollViewTapped(in cell: EntityTableViewCell) {
        
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
        
        let label = view as? MELLabel ?? MELLabel.init(fontWeight: .regular, textStyle: .subheading, alignment: .center)
        
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
