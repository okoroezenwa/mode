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

class PlaylistItemsViewController: UIViewController, FilterContextDiscoverable, AlbumTransitionable, AlbumArtistTransitionable, GenreTransitionable, ComposerTransitionable, ArtistTransitionable, InfoLoading, QueryUpdateable, CellAnimatable, SingleItemActionable, PillButtonContaining, Refreshable, EntityVerifiable, TopScrollable, EntityContainer {

    @IBOutlet var tableView: MELTableView!
    @IBOutlet var emptyStackView: UIStackView!
    @IBOutlet var emptyLabel: UILabel!
    @IBOutlet var emptySubLabel: UILabel!
    @objc lazy var headerView: HeaderView = {
        
        let view = HeaderView.fresh
        self.actionsStackView = view.actionsStackView
        self.stackView = view.scrollStackView
        view.showTextView = true
        view.showLoved = true
        view.showInfo = true
        view.showGrouping = true
        view.showInsert = playlist?.playlistAttributes == [] && playlist?.isAppleMusic == false
        view.sortButton.setTitle(arrangementLabelText, for: .normal)
        view.sortButton.addTarget(self, action: #selector(showArranger), for: .touchUpInside)
        self.descriptionTextView = view.descriptionTextView
        view.infoButton.addTarget(entityVC, action: #selector(EntityItemsViewController.showOptions), for: .touchUpInside)
        view.likedStateButton.addTarget(self, action: #selector(setLiked), for: .touchUpInside)
        view.addButton.addTarget(self, action: #selector(addSongs), for: .touchUpInside)
        
        updateLikedButton(view.likedStateButton)
        
        return view
    }()
    @objc var actionsStackView: UIStackView! {
        
        didSet {
            
            let shuffleView = PillButtonView.with(title: .shuffleButtonTitle, image: #imageLiteral(resourceName: "Shuffle13"), tapAction: .init(action: #selector(shuffle), target: self))
            shuffleButton = shuffleView.button
            self.shuffleView = shuffleView
            
            let filterView = PillButtonView.with(title: "Filter", image: #imageLiteral(resourceName: "Filter13"), tapClosure: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                weakSelf.invokeSearch()
            })
            self.filterView = filterView
            
            let editView = PillButtonView.with(title: .inactiveEditButtonTitle, image: .inactiveEditImage, tapAction: .init(action: #selector(SongActionManager.toggleEditing(_:)), target: songManager), longPressAction: .init(action: #selector(SongActionManager.showActionsForAll(_:)), target: songManager))
            editButton = editView.button
            self.editView = editView
            
            [shuffleView, filterView, editView].forEach({ actionsStackView.addArrangedSubview($0) })
        }
    }
    @objc var stackView: UIStackView! {
        
        didSet {
            
            let duration = ScrollHeaderSubview.with(title: "Duration", image: #imageLiteral(resourceName: "Time10"))
            totalDurationLabel = duration.label
            
            let created = ScrollHeaderSubview.with(title: "Created", image: #imageLiteral(resourceName: "DateAdded"), useSmallerImage: true)
            dateCreatedLabel = created.label
            
            let size = ScrollHeaderSubview.with(title: "Size", image: #imageLiteral(resourceName: "FileSize10"))
            sizeLabel = size.label
            
            let plays = ScrollHeaderSubview.with(title: "Plays", image: #imageLiteral(resourceName: "Plays"))
            playsLabel = plays.label
            
            for view in [duration, size, created, plays] {
                
                stackView.addArrangedSubview(view)
            }
        }
    }
    
    @objc var totalDurationLabel: MELLabel!
    @objc var dateCreatedLabel: MELLabel!
    @objc var sizeLabel: MELLabel!
    @objc var playsLabel: MELLabel!
    @objc var descriptionTextView: MELTextView!
    @objc var activityIndicator: MELActivityIndicatorView!
    @objc var arrangeButton: MELButton!
    @objc var editButton: MELButton! {
        
        didSet {
            
            let allHold = UILongPressGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.showActionsForAll(_:)))
            allHold.minimumPressDuration = longPressDuration
            (editButton.superview as? PillButtonView)?.addGestureRecognizer(allHold)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: allHold))
        }
    }
    @objc var shuffleButton: MELButton!
//    @objc var likedStateButton: MELButton!
    @objc var shuffleView: PillButtonView!
    @objc var filterView: PillButtonView!
    @objc var editView: PillButtonView!
    
    var borderedButtons = [PillButtonView?]()
    var sectionIndexViewController: SectionIndexViewController?
    var navigatable: Navigatable? { return entityVC }
    let requiresLargerTrailingConstraint = false
    
    @objc lazy var sorter: Sorter = { Sorter.init(operation: self.operation) }()
    
    @objc var actionableSongs: [MPMediaItem] { return filtering ? filteredSongs : songs }
    var applicableActions: [SongAction] { return [SongAction.collect, .info(context: .album(at: 0, within: [])), .queue(name: playlist?.name ??? .untitledPlaylist, query: nil), .newPlaylist, .addTo] }
    @objc lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
    @objc var playlistQuery: MPMediaQuery? { return entityVC?.query }
    @objc var playlist: MPMediaPlaylist? { return playlistQuery?.collections?.first as? MPMediaPlaylist }
    @objc weak var entityVC: EntityItemsViewController? { return parent as? EntityItemsViewController }
    
    @objc lazy var tableDelegate: TableDelegate = { TableDelegate.init(container: self, location: .playlist) }()
    @objc var entities: [MPMediaEntity] {
        
        get { return songs }
        
        set { songs = newValue as? [MPMediaItem] ?? [] }
    }
    @objc var query: MPMediaQuery? { return playlistQuery } // used to be albumQuery
    @objc lazy var filteredEntities = [MPMediaEntity]()
    @objc var highlightedEntity: MPMediaEntity? { return entityVC?.highlightedEntities?.song }
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
    
    @objc var hasDescriptionText: Bool { return playlist?.descriptionText != nil && playlist?.descriptionText != "" }
    var applySort = true
    @objc var ascending = true {
        
        didSet {
            
            if let _ = tableView {
                
                if applySort {
                    
                    sortAllItems()
                }
                
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
    var staticSortCriteria: SortCriteria = .standard
    var sortCriteria: SortCriteria {
        
        get { return staticSortCriteria }
        
        set {
            
            if let _ = tableView, let id = playlist?.persistentID {
                
                staticSortCriteria = newValue
                sortAllItems()
                
                headerView.sortButton.setTitle(arrangementLabelText, for: .normal)
                UIView.animate(withDuration: 0.3, animations: { self.headerView.layoutIfNeeded() })
                UniversalMethods.saveSortableItem(withPersistentID: id, order: ascending, sortCriteria: staticSortCriteria, kind: .playlist)
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
//                if let playlist = playlist {
//
//                    UniversalMethods.saveSortableItem(withPersistentID: playlist.persistentID, order: ascending, sortCriteria: sortCriteria, kind: SortableKind.playlist)
//                }
//            }
//        }
    }
    var sortLocation: SortLocation = .playlist
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
    @objc var artworkOperation: BlockOperation?
    @objc var filterOperation: BlockOperation?
    @objc var supplementaryOperation: BlockOperation?
    // MARK: - Methods

    override func viewDidLoad() {
        
        super.viewDidLoad()
        prepareLifetimeObservers()
        
        adjustInsets(context: .container)
        updateTopInset()
        
        tableView.delegate = tableDelegate
        tableView.dataSource = tableDelegate
        tableView.tableHeaderView = headerView
        
        let refreshControl = MELRefreshControl.init()
        refreshControl.addTarget(refresher, action: #selector(Refresher.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
//        prepareTopArtwork()
        prepareSupplementaryInfo(animated: false)
        
        UIView.performWithoutAnimation { self.descriptionTextView.layoutIfNeeded() }
        updateHeaderView(withCount: (playlistQuery?.items ?? []).count)
        
        updateEmptyLabel(withCount: (playlistQuery?.items ?? []).count)
        sortAllItems()
        
        prepareGestures()
    }
    
    func updateTopInset() {
        
        let inset = entityVC?.peeker != nil ? 0 : entityVC?.inset ?? VisualEffectNavigationBar.Location.entity.inset
        tableView.contentInset.top = inset
        tableView.scrollIndicatorInsets.top = inset
    }
    
    @objc func prepareSupplementaryInfo(animated: Bool = true) {
        
        headerView.groupingButton.setTitle((playlistQuery?.items ?? []).count.fullCountText(for: .song, capitalised: true), for: .normal)
        
        if animated {
            
            UIView.animate(withDuration: 0.3, animations: { self.headerView.layoutIfNeeded() })
        }
        
        guard let items = playlistQuery?.items, let dateCreated = playlist?.dateCreated else { return }
        
        supplementaryOperation?.cancel()
        supplementaryOperation = BlockOperation()
        supplementaryOperation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self else { return }
            
            let dateCreated = dateCreated.timeIntervalSinceNow.shortStringRepresentation
            let totalDuration = items.totalDuration.stringRepresentation(as: .short)
            let totalSize = FileSize.init(actualSize: items.totalSize).actualSize.fileSizeRepresentation
            let plays = items.totalPlays
            
            guard weakSelf.supplementaryOperation?.isCancelled == false else { return }
            
            OperationQueue.main.addOperation({
            
                weakSelf.dateCreatedLabel.text = dateCreated
                weakSelf.totalDurationLabel.text = totalDuration
                weakSelf.sizeLabel.text = totalSize
                weakSelf.playsLabel.text = plays.formatted
            })
        })
        
        sortOperationQueue.addOperation(supplementaryOperation!)
    }
    
    func updateLikedButton(_ sender: UIButton) {
        
        guard let playlist = playlist else { return }
        
        sender.setImage(image(for: playlist.likedState), for: .normal)
    }
    
    func image(for likedState: LikedState) -> UIImage {
        
        switch likedState {
            
            case .liked: return #imageLiteral(resourceName: "Loved13")

            case .disliked: return #imageLiteral(resourceName: "Unloved13")

            case .none: return #imageLiteral(resourceName: "NoLove13")
        }
    }
    
    @objc func setLiked() {
        
        guard let playlist = playlist else { return }
        
        var value: Int {
            
            switch playlist.likedState {
                
                case .none: return LikedState.liked.rawValue
                
                case .liked: return LikedState.disliked.rawValue
                
                case .disliked: return LikedState.none.rawValue
            }
        }
        
        playlist.set(property: .likedState, to: NSNumber.init(value: value))
        
        UIView.transition(with: headerView.likedStateButton, duration: 0.3, options: .transitionCrossDissolve, animations: { self.updateLikedButton(self.headerView.likedStateButton) }, completion: { [weak self] finished in
            
            guard finished, let weakSelf = self else { return }
            
            UniversalMethods.performOnMainThread({
            
                if weakSelf.headerView.likedStateButton.image(for: .normal) != weakSelf.image(for: playlist.likedState) {
                    
                    UIView.transition(with: weakSelf.headerView.likedStateButton, duration: 0.3, options: .transitionCrossDissolve, animations: { weakSelf.updateLikedButton(weakSelf.headerView.likedStateButton) }, completion: nil)
                }
            
            }, afterDelay: 0.3)
        })
    }
    
    @objc func addSongs() {
        
        let picker = MPMediaPickerController.init(mediaTypes: .music)
        picker.allowsPickingMultipleItems = true
        picker.delegate = self
        picker.modalPresentationStyle = .overFullScreen
        
        present(picker, animated: true, completion: nil)
    }
    
    @objc func updateHeaderView(withCount count: Int) {
        
        let descriptionHeight: CGFloat = {
            
            if hasDescriptionText {
                
                if prepareDescriptionText() {
                    
                    descriptionTextView.textContainerInset.top = 10
                    descriptionTextView.textContainerInset.bottom = -4
                }
                
                return ceil(descriptionTextView.intrinsicContentSize.height) + FontManager.shared.descriptionConstant
                
            } else {
                
                return 0
            }
        }()
        
        shuffleButton.superview?.isHidden = count < 2
        tableView.tableHeaderView?.frame.size.height = 92 + descriptionHeight
        tableView.tableHeaderView = headerView
        
        var array = [shuffleView, filterView, editView]
        
        if count < 2 {
            
            array.remove(at: 0)
        }
        
        borderedButtons = array
        
        updateButtons()
    }
    
    @objc @discardableResult func prepareDescriptionText() -> Bool {
        
        guard let text = playlist?.descriptionText else { return false }
        
        let style = NSMutableParagraphStyle.init()
        style.lineHeightMultiple = FontManager.shared.textLineHeight
        
        let attributed = NSAttributedString.init(string: text, attributes: [
            
            .paragraphStyle: style,
            .font: UIFont.font(ofWeight: .regular, size: TextStyle.accessory.textSize()),
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
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: optionsHold))
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
        
        entityVC?.highlightedEntities?.song = song
        highlightedIndex = songs.firstIndex(of: song)
        scrollToHighlightedRow()
    }
    
    @objc func clearSavedPlaylists(_ gr: UILongPressGestureRecognizer) {
        
        if gr.state == .began {
            
            let reset = UIAlertAction.init(title: "Reset", style: .destructive, handler: { _ in UniversalMethods.deleteSortableItems() })
            
            present(UniversalMethods.alertController(withTitle: "Remove Sortable Entities?", message: "This will remove all sorted entities, reverting them to their default orders", preferredStyle: .alert, actions: reset, UniversalMethods.cancelAlertAction()), animated: true, completion: nil)
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
        
        lifetimeObservers.insert(notifier.addObserver(forName: .songsAddedToPlaylists, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let id = weakSelf.playlist?.persistentID, let ids = notification.userInfo?[String.addedPlaylists] as? [MPMediaEntityPersistentID], Set(ids).contains(id) else { return }
            
            if let query = weakSelf.getCurrentQuery() {
                
                weakSelf.entityVC?.query = query
            }
            
            weakSelf.sortAllItems()
            
        }) as! NSObject)
        
        lifetimeObservers.insert((notifier.addObserver(forName: .libraryUpdated, object: appDelegate, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateWithQuery()
            
        })) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .lineHeightsCalculated, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateTopInset()
            
            if weakSelf.hasDescriptionText {
            
                weakSelf.updateHeaderView(withCount: weakSelf.songs.count)
            }
            
        }) as! NSObject)
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
        sortAllItems()
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
        
        if needsUpdating {
            
            if let vc = presentedViewController {
                
                vc.dismiss(animated: false, completion: nil)
            }
            
            let banner = Banner.init(title: "This playlist has no offline songs", subtitle: nil, image: nil, backgroundColor: .orange, didTapBlock: nil)
            banner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
            banner.show(view, duration: 1.5)
            
            sortAllItems()
        }
        
        if wasFiltering {
            
            invokeSearch()
            wasFiltering = false
        }
        
        entityVC?.setCurrentOptions()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        notifier.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notifier.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
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
            
            let shuffle = AlertAction.init(title: .shuffle(.songs), style: .default, requiresDismissalFirst: true, handler: { musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: self.playlist?.name ??? "Untitled Playlist", alertTitle: .shuffle(.songs)) })
            
            let shuffleAlbums = AlertAction.init(title: .shuffle(.albums), style: .default, requiresDismissalFirst: true, handler: { musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: self, withTitle: self.playlist?.name ??? "Untitled Playlist", alertTitle: .shuffle(.albums)) })
            
            showAlert(title: entityVC?.title, with: shuffle, shuffleAlbums)
            
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

extension PlaylistItemsViewController: FullySortable {
    
    /*@objc func sortItems() {
        
        headerView.updateSortActivityIndicator(to: .visible)
        
        let mainBlock: ([MPMediaItem], [SortSectionDetails]) -> () = { [weak self] array, details in

            guard let weakSelf = self, weakSelf.operation?.isCancelled == false else {

                self?.headerView.updateSortActivityIndicator(to: .hidden)

                return
            }

            weakSelf.songs = array
            weakSelf.sections = details
            weakSelf.headerView.updateSortActivityIndicator(to: .hidden)
            weakSelf.updateEmptyLabel(withCount: weakSelf.songs.count)
            weakSelf.updateHeaderView(withCount: weakSelf.songs.count)
            weakSelf.tableView.reloadData()

            if weakSelf.filtering, let filterContainer = weakSelf.filterContainer, let text = filterContainer.searchBar?.text {
                
                filterContainer.searchBar?(filterContainer.searchBar, textDidChange: text)

            } else {

                if weakSelf.entityVC?.peeker == nil {

                    weakSelf.animateCells(direction: .vertical, alphaOnly: weakSelf.highlightedIndex != nil)
                }

                weakSelf.scrollToHighlightedRow()
            }
        }
        
        operation?.cancel()
        operation = BlockOperation()
        operation?.addExecutionBlock({ [weak operation, weak self] in
            
            guard let weakSelf = self, let weakOperation = operation, !weakOperation.isCancelled, let items = weakSelf.playlistQuery?.items, !items.isEmpty else {
                
                OperationQueue.main.addOperation { [weak self] in
                    
                    self?.headerView.updateSortActivityIndicator(to: .hidden)
                    
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
                
                weakSelf.highlightedIndex = array.firstIndex(of: song)
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
    }*/
}

extension PlaylistItemsViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if touch.view?.isDescendant(of: headerView) == true {
            
            return false
        }
        
        return true
    }
}

extension PlaylistItemsViewController: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        guard let playlist = playlist else { return }
        
        playlist.add(mediaItemCollection.items, completionHandler: { [weak self] error in
            
            guard let weakSelf = self else { return }
            
            guard error == nil else {
                
                UniversalMethods.performInMain {
                    
                    let banner = Banner.init(title: "Unable to add \(mediaItemCollection.items.count.fullCountText(for: .song))", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
                    banner.titleLabel.font = .myriadPro(ofWeight: .regular, size: 20)
                    banner.show(duration: 0.5)
                    
                    (weakSelf.parent as? PresentedContainerViewController)?.activityIndicator.stopAnimating()
                }
                
                return
            }
            
            UniversalMethods.performInMain {
                
                let banner = Banner.init(title: playlist.validName, subtitle: "Added \(mediaItemCollection.items.count.fullCountText(for: .song))", image: nil, backgroundColor: .deepGreen, didTapBlock: nil)
                banner.titleLabel.font = .myriadPro(ofWeight: .semibold, size: 22)
                banner.detailLabel.font = .myriadPro(ofWeight: .regular, size: 17)
                banner.detailLabel.textColor = Themer.textColour(for: .subtitle)
                banner.show(for: .bannerInterval)
                
                notifier.post(name: .songsAddedToPlaylists, object: nil, userInfo: [String.addedPlaylists: [playlist.persistentID], String.addedSongs: mediaItemCollection.items])
            }
        })
        
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        
        mediaPicker.dismiss(animated: true, completion: nil)
    }
}
