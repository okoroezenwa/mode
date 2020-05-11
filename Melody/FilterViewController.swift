//
//  FilterViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 09/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit
import CoreData

class FilterViewController: UIViewController, InfoLoading, SingleItemActionable, CellAnimatable, FilterContainer, AlbumTransitionable, ArtistTransitionable, AlbumArtistTransitionable, GenreTransitionable, ComposerTransitionable, PlaylistTransitionable, EntityVerifiable, Arrangeable, Refreshable, PillButtonContaining, Navigatable, Contained, ArtworkModifying, TopScrollable, CentreViewDisplaying {
    
    @IBOutlet var tableView: MELTableView!
    @IBOutlet var filterViewContainer: FilterViewContainer! {
        
        didSet {
            
            filterViewContainer.filterInfo = (filter: sender, container: self)
        }
    }
    @IBOutlet var bottomViewBottomConstraint: NSLayoutConstraint!
    
    lazy var headerView: HeaderView = {
        
        let view = HeaderView.instance
        self.actionsStackView = view.actionsStackView
//        self.stackView = view.scrollStackView
        view.scrollStackViewHeightConstraint.constant = 0
        
        return view
    }()
    var actionsStackView: UIStackView! {
        
        didSet {
            
//            let shuffleView = PillButtonView.with(title: .shuffleButtonTitle, image: #imageLiteral(resourceName: "Shuffle13"), action: #selector(shuffle), target: self)
//            shuffleButton = shuffleView.button
//            self.shuffleView = shuffleView
//
//            let arrangeBorderView = PillButtonView.with(title: .arrangeButtonTitle, image: #imageLiteral(resourceName: "AscendingLines"), action: #selector(showArranger), target: self)
//            arrangeBorderView.borderView.centre(activityIndicator)
//            arrangeButton = arrangeBorderView.button
//            self.arrangeBorderView = arrangeBorderView
            
            let editView = PillButtonView.with(title: .inactiveEditButtonTitle, image: .inactiveEditImage, tapAction: .init(action: #selector(SongActionManager.toggleEditing(_:)), target: songManager), longPressAction: .init(action: #selector(SongActionManager.showActionsForAll(_:)), target: songManager))
            editButton = editView.button
            self.editView = editView
            
            [/*shuffleView, arrangeBorderView, */editView].forEach({ actionsStackView.addArrangedSubview($0) })
        }
    }
    
//    var stackView: UIStackView!
    
    enum FilterEntities {
        
        case songs([MPMediaItem]), collections([MPMediaItemCollection], kind: CollectionsKind)
        
        var category: SearchCategory {
            
            switch self {
                
                case .songs: return .songs
                
                case .collections(_, let kind): return kind.category
            }
        }
        
        var entityType: EntityType {
            
            switch self {
                
                case .songs: return .song
                
                case .collections(_, let kind): return kind.entityType
            }
        }
    }
    
    var backLabelText: String?
    var preferredTitle: String? {
        
        get { ("Filter" ?+ (backLabelText?.isEmpty == true ? nil : ": ")) ?+ backLabelText }
        
        set { }
    }
    var inset: CGFloat { return VisualEffectNavigationBar.Location.entity.inset }
    var activeChildViewController: UIViewController?
    var artworkDetails: NavigationBarArtworkDetails?
    var buttonDetails: NavigationBarButtonDetails = (.clear, true) {
        
        didSet {
            
            guard animateClearButton else {
                
                animateClearButton = true
                
                return
            }
            
            let shouldAnimate: Bool = {
                
                if let _ = container, let controller = navigationController?.delegate as? NavigationAnimationController, controller.disregardViewLayoutDuringKeyboardPresentation {
                    
                    return false
                }
                
                return true
            }()
            
            container?.visualEffectNavigationBar.prepareRightButton(for: self, animated: shouldAnimate)
        }
    }
    var artwork: UIImage? {
        
        get { (sender?.parent as? ArtworkModifying)?.artwork }
        
        set { }
    }
    
    var centreViewGiantImage: UIImage?
    var centreViewTitleLabelText: String?
    var centreViewSubtitleLabelText: String?
    var centreViewLabelsImage: UIImage?
    lazy var internalCentreView = CentreView.instance
    var currentCentreView = CentreView.CurrentView.none
    var centreView: CentreView? {
        
        get { parent is PresentedContainerViewController ? internalCentreView : container?.centreView }
        
        set { }
    }
    let components: Set<CentreView.CurrentView.LabelStackViewComponent> = [.image, .title, .subtitle]
    
    var searchBar: MELSearchBar! { filterViewContainer.filterView.searchBar }
    
    weak var sender: (UIViewController & Filterable)?
    var tableContainer: TableViewContainer? { return sender as? TableViewContainer }
    var infoLoader: InfoLoading? { return sender as? InfoLoading }
    var actionable: SongActionable? { return sender as? SongActionable }
    var sorter: Arrangeable? { return sender as? Arrangeable }
    var entities = FilterEntities.songs([])
    @objc var unfilteredPoint = CGPoint.zero
    @objc var recentSearches = [RecentSearch]()
    lazy var category = { entities.category }()
    var filterTitle: String? { (parent as? PresentedContainerViewController)?.prompt ?? backLabelText ?? sender?.filterEntities.entityType.title().capitalized }
    
    var sectionIndexViewController: SectionIndexViewController?
    var requiresLargerTrailingConstraint = false
    
    var navigatable: Navigatable? { return self }
    
    @objc lazy var refresher: Refresher = { Refresher.init(refreshable: self) }()
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var albumQuery: MPMediaQuery?
    @objc var composerQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    @objc var playlistQuery: MPMediaQuery?
    
    var emptyCondition: Bool { return (tableContainer as? CollectionsViewController)?.presented == true || (filtering ? tableContainer?.filteredEntities.isEmpty != false : recentSearches.isEmpty) }
    
//    lazy var filteredSongs = [MPMediaItem]()
//    lazy var filteredCollections = [MPMediaItemCollection]()
    
    lazy var requiredInputView: InputView? = {
        
        let view = Bundle.main.loadNibNamed("InputView", owner: nil, options: nil)?.first as? InputView
        view?.pickerView.delegate = self
        view?.pickerView.dataSource = self
        
        return view
    }()
    
    lazy var rightViewButton: MELButton = filterViewContainer.filterView.rightButton
    var animateClearButton = false
    
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
    var shuffleView: PillButtonView!
    var arrangeBorderView: PillButtonView!
    var editView: PillButtonView!
    
    var query: MPMediaQuery?
    var sortCriteria: SortCriteria {
        
        get { return staticSortCriteria }
        
        set {
            
            staticSortCriteria = newValue
//            sortItems()
            headerView.sortButton.setTitle(arrangementLabelText, for: .normal)
                UIView.animate(withDuration: 0.3, animations: { self.headerView.layoutIfNeeded() })
        }
    }
    lazy var staticSortCriteria: SortCriteria = { sorter?.sortCriteria ?? .standard }()
    var applySort = true
    var ascending: Bool {
        
        get { return actualAscending }
        
        set {
            
            actualAscending = newValue
            
            tableContainer?.filteredEntities.reverse()
            
            updateHeaderView()
            tableView.reloadData()
            animateCells(direction: .vertical)
        }
    }
    
    lazy var actualAscending: Bool = { sorter?.ascending ?? true }()
    lazy var applicableSortCriteria: Set<SortCriteria> = { sorter?.applicableSortCriteria ?? [] }()
    lazy var sortLocation: SortLocation = { sorter?.sortLocation ?? .songs }()
    
    @objc var ignoreKeyboardForInset = true
    
    var borderedButtons = [PillButtonView?]()
    var applicableActions: [SongAction] { return actionable?.applicableActions ?? [] }
    var actionableSongs: [MPMediaItem] { return actionable?.actionableSongs ?? [] }
    lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    var wasFirstResponder = false
    var filtering = false {
        
        didSet {
            
            guard oldValue != filtering else { return }
            
            tableView.allowsMultipleSelectionDuringEditing = filtering.inverted
        }
    }
    
    @objc var lifetimeObservers = Set<NSObject>()
    @objc var transientObservers = Set<NSObject>()
    
    @objc var operations = ImageOperations()
    @objc var infoOperations = InfoOperations()
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
    @objc let filterOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Filter Operation Queue"
        queue.qualityOfService = .userInitiated
        
        return queue
    }()
    @objc let sortOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Sort Operation Queue"
        
        return queue
    }()
    @objc let imageCache: ImageCache = {
        
        let cache = ImageCache()
        cache.name = "Image Cache"
        cache.countLimit = 500
        
        return cache
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        sender?.filtering = true
        tableContainer?.filterContainer = self
        
        if let container = container {
            
            filterViewContainer.removeFromSuperview()
            filterViewContainer = container.filterViewContainer
        
        } else {
            
            internalCentreView.add(to: view, below: self, above: filterViewContainer)
            
            filterViewContainer.filterView.alpha = 1
            tableView.scrollIndicatorInsets.bottom = 53
            tableView.contentInset.bottom = 53
        }
        
        centreViewLabelsImage = #imageLiteral(resourceName: "Filter100")
        centreViewTitleLabelText = "Nothing Here..."
        centreViewSubtitleLabelText = "Filters acted upon are added here"
        
        adjustInsets(context: .container)
        updateTopInset()
        
        let swipeRight = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeRight.direction = .right
        tableView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer.init(target: songManager, action: #selector(SongActionManager.toggleEditing(_:)))
        swipeLeft.direction = .left
        tableView.addGestureRecognizer(swipeLeft)
        
        let hold = UILongPressGestureRecognizer.init(target: tableContainer?.tableDelegate, action: #selector(TableDelegate.performHold(_:)))
        hold.minimumPressDuration = longPressDuration
        hold.delegate = self
        tableView.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        
//        let refreshControl = MELRefreshControl.init()
//        refreshControl.addTarget(refresher, action: #selector(Refresher.refresh(_:)), for: .valueChanged)
//        tableView.addSubview(refreshControl)
        
        if let collectionsVC = tableContainer as? CollectionsViewController, collectionsVC.presented {
            
            tableView.allowsMultipleSelection = true
        }
        
        view.layoutIfNeeded()
        
        tableView.register(UINib.init(nibName: "RecentSearchCell", bundle: nil), forCellReuseIdentifier: .recentCell)
        
        resetRecentSearches()
        
        searchBar.delegate = self
        searchBar.text = sender?.filterText
        filterViewContainer.filterView.propertyButton.setTitle(sender?.filterProperty.title, for: .normal)
        filterViewContainer.filterView.filterTestButton.setTitle(sender?.testTitle, for: .normal)
        sender?.updateKeyboard(with: self)
        searchBar(searchBar, textDidChange: "")
        
        if let _ = container {
            
            tableView.contentOffset = .init(x: 0, y: -inset)
        
        } else {
            
            notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        }
        
//        updateCollectedView(self)
        
//        updateHeaderView(with: tableContainer?.filteredEntities.count ?? 0)
        
        prepareLifetimeObservers()
        
        searchBar?.textField?.leftView = filterViewContainer.filterView.leftView
        searchBar.updateTextField(with: placeholder)
        
        updateRightView(animated: false)
        
        if case .collections(_, .playlist) = entities { } else {
            
            [Notification.Name.playerChanged, .MPMusicPlayerControllerNowPlayingItemDidChange].forEach({ notifier.addObserver(self, selector: #selector(updateNowPlaying), name: $0, object: /*musicPlayer*/nil) })
        }
        
        (parent as? PresentedContainerViewController)?.transitionStart = { [weak self] in
            
            guard let weakSelf = self, weakSelf.searchBar.isFirstResponder else { return }
            
            weakSelf.bottomViewBottomConstraint.constant = 0
            weakSelf.wasFirstResponder = true
        }
        
        (parent as? PresentedContainerViewController)?.transitionAnimation = { [weak self] in
            
            guard let weakSelf = self, weakSelf.wasFirstResponder else { return }
            
            weakSelf.searchBar.resignFirstResponder()
            weakSelf.view.layoutIfNeeded()
        }
        
        (parent as? PresentedContainerViewController)?.transitionCancellation = { [weak self] in
            
            guard let weakSelf = self, weakSelf.wasFirstResponder else { return }
            
            weakSelf.searchBar.becomeFirstResponder()
            weakSelf.wasFirstResponder = false
        }
        
        if searchBar.text?.isEmpty == true, container == nil {
        
            searchBar.becomeFirstResponder()
        }
    }
    
    @objc func prepareLifetimeObservers() {
        
        notifier.addObserver(self, selector: #selector(updateCollectedView(_:)), name: .managerItemsChanged, object: nil)
        
        [Notification.Name.entityCountVisibilityChanged, .showExplicitnessChanged].forEach({ notifier.addObserver(self, selector: #selector(updateEntityCountVisibility), name: $0, object: nil) })
        
        let insetsObserver = notifier.addObserver(forName: .resetInsets, object: nil, queue: nil, using: { [weak self] _ in self?.adjustInsets(context: .container) })
        
        lifetimeObservers.insert(insetsObserver as! NSObject)
    }
    
    @objc func prepareTransientObservers() {
        
        transientObservers.insert(notifier.addObserver(forName: .scrollCurrentViewToTop, object: navigationController, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.scrollToTop()
            
        }) as! NSObject)
    }
    
    func updateTopInset() {
        
        guard let _ = container else { return }
        
        tableView.contentInset.top = inset
        tableView.scrollIndicatorInsets.top = inset
    }
    
    func adjustInsets(context: InsetContext) {
        
        guard let _ = container else { return }
        
        switch context {
            
            case .filter(let inset):
                
                tableView.scrollIndicatorInsets.bottom = inset
                tableView.contentInset.bottom = inset
                
            case .container:
                
                if let container = container, ignoreKeyboardForInset {
                    
                    tableView.scrollIndicatorInsets.bottom = container.inset
                    tableView.contentInset.bottom = container.inset
                }
        }
    }
    
    func prepareSupplementaryInfo(animated: Bool) {
        
        
    }
    
    @objc func updateEntityCountVisibility() {
        
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        
        tableView.reloadRows(at: indexPaths, with: .none)
    }
    
    @objc func updateNowPlaying() {
        
        for cell in tableView.visibleCells {

            guard let entityCell = cell as? EntityTableViewCell, let indexPath = tableView.indexPath(for: entityCell), let nowPlaying = musicPlayer.nowPlayingItem else {

                (cell as? EntityTableViewCell)?.playingView.isHidden = true
                (cell as? EntityTableViewCell)?.indicator.state = .stopped

                continue
            }
            
            if entityCell.playingView.isHidden.inverted && {

                switch entities {

                    case .songs: return nowPlaying != (tableContainer?.filteredEntities as? [MPMediaItem])?[indexPath.row]

                    case .collections(_, kind: let kind):

                        guard kind != .playlist, let collections = tableContainer?.filteredEntities as? [MPMediaItemCollection] else { return true }

                        return Set(collections[indexPath.row].items).contains(nowPlaying).inverted
                }

            }() {

                entityCell.playingView.isHidden = true
                entityCell.indicator.state = .stopped

            } else if entityCell.playingView.isHidden && {

                switch entities {

                    case .songs: return nowPlaying == (tableContainer?.filteredEntities as? [MPMediaItem])?[indexPath.row]

                    case .collections(_, kind: let kind):

                        guard kind != .playlist, let collections = tableContainer?.filteredEntities as? [MPMediaItemCollection] else { return false }

                        return Set(collections[indexPath.row].items).contains(nowPlaying)
                }

            }() {
                
                entityCell.playingView.isHidden = false
                UniversalMethods.performOnMainThread({ entityCell.indicator.state = musicPlayer.isPlaying ? .playing : .paused }, afterDelay: 0.1)
            }
        }
    }
    
    @objc func updateCollectedView(_ sender: Any) {
        
//        guard let container = appDelegate.window?.rootViewController as? ContainerViewController else { return }
//        
//        let animated = sender is Notification
        
//        modifyCollectedView(forState: container.queue.isEmpty ? .dismissed : .invoked, animated: animated)
//        updateCollectedText(animated: animated)
    }
    
    @objc func updateHeaderView(withCount count: Int = 0) {
        
//        shuffleButton.superview?.isHidden = count < 2
        tableView.tableHeaderView = emptyCondition ? nil : headerView
        tableView.tableHeaderView?.frame.size.height = emptyCondition ? 0 : 48//92
        
        let array = /*emptyCondition ? [] : */[/*shuffleView, arrangeBorderView, */editView]
        
//        if count < 2 {
//
//            array.remove(at: 0)
//        }
        
        borderedButtons = array
        
        updateButtons()
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)
        
        if let _ = container {
        
            notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillHideNotification, object: nil)
            
            prepareTransientObservers()
        }
        
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
        
//        filterViewContainer.filterInfo = (filter: sender, container: self)
        container?.visualEffectNavigationBar.entityTypeLabel.superview?.isHidden = true
        
        if let row = array.firstIndex(where: { $0 == searchBar.text }) {
            
            requiredInputView?.pickerView.selectRow(row, inComponent: 0, animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        for cell in tableView.visibleCells {
            
            if let cell = cell as? EntityTableViewCell, !cell.playingView.isHidden {
                
                cell.indicator.state = musicPlayer.isPlaying ? .playing : .paused
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        sender?.filtering = false
        
        if ascending.inverted && tableContainer?.ascending != false {
            
            tableContainer?.filteredEntities.reverse()
        }
        
        filterViewContainer.filterInfo = (filter: nil, container: nil)
        tableContainer?.filterContainer = nil
        
        notifier.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notifier.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
        unregisterAll(from: transientObservers)
    }
    
    @objc func adjustKeyboard(with notification: Notification) {
        
        guard let keyboardHeightAtEnd    = ((notification as NSNotification).userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height, /*searchBar.isFirstResponder, */let duration = (notification as NSNotification).userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        if let _ = container, let controller = navigationController?.delegate as? NavigationAnimationController, controller.animationInProgress { return }
        
        let keyboardWillShow = notification.name == UIResponder.keyboardWillShowNotification
        
        let constraint = container == nil ? bottomViewBottomConstraint : filterViewContainer.filterView.filterInputViewBottomConstraint
        let view = container == nil ? self.view : container?.view
        let negativeConstant: CGFloat = container == nil ? 6 : {
            
            if let container = container {

                return 51 + container.collectedViewHeight + container.sliderHeight + container.titlesHeight
            }
            
            return 0
        }()
        
        constraint?.constant = keyboardWillShow ? keyboardHeightAtEnd - negativeConstant : 0
        
        if let _ = container, let controller = navigationController?.delegate as? NavigationAnimationController, controller.disregardViewLayoutDuringKeyboardPresentation {
            
            return
        }
        
        UIView.animate(withDuration: duration, animations: {
            
            self.adjustInsets(context: keyboardWillShow ? .filter(inset: keyboardHeightAtEnd) : .container)
            view?.layoutIfNeeded()
        })
    }
    
    @objc func showArranger() {
        
        performSegue(withIdentifier: "toArranger", sender: nil)
    }
    
    func updateHeader(count: Int) {
        
        guard let parent = parent as? PresentedContainerViewController else { return }
        
        parent.prepare(animated: true, updateConstraintsAndButtons: false)
    }
    
    func filter(with searchText: String) {
        
        updateCurrentView(to: .indicator)
        
        filterOperationQueue.cancelAllOperations()
        sender?.filterOperation = BlockOperation()
        sender?.filterOperation?.addExecutionBlock({ [weak self, weak tableContainer, weak sender] in
            
            let text = searchText
            
            guard let weakSelf = self, let sender = sender, let operation = sender.filterOperation, operation.isCancelled.inverted else { return }
            
            let array: [MPMediaEntity] = {
                
                switch weakSelf.entities {
                    
                    case .songs(let songs): return sender.getResults(for: songs, against: searchText)
                    
                    case .collections(let collections, let kind): return sender.getResults(for: collections, of: kind, against: searchText)
                }
            }()
            
            guard let tableContainer = tableContainer, sender.filterOperation != nil, let currentOperation = weakSelf.filterOperations[text], currentOperation.isCancelled.inverted else { return }
            
            OperationQueue.main.addOperation({
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                tableContainer.filteredEntities = array
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.updateHeaderView()
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.tableView.reloadData()
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.tableView.setContentOffset(weakSelf.container == nil ? .zero : .init(x: 0, y: -weakSelf.inset), animated: false)
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.animateCells(direction: .vertical)
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.updateCurrentView(to: .none)
                
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                UIView.setAnimationsEnabled(false)
                weakSelf.updateTitleLabel()
                UIView.setAnimationsEnabled(true)
                
                if let parent = weakSelf.parent as? PresentedContainerViewController {
                
                    parent.rightButton.setImage(VisualEffectNavigationBar.RightButtonType.actions.image, for: .normal)
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        
                        parent.rightBorderView.alpha = array.isEmpty ? 0 : 1
                        parent.rightButton.alpha = array.isEmpty ? 0 : 1
                    })
                
                } else if let _ = weakSelf.container {
                    
                    weakSelf.updateDeleteButton()
                }
            })
        })
        
        filterOperationQueue.addOperation((sender?.filterOperation)!)
        filterOperations[searchText] = (sender?.filterOperation)!
    }
    
    func updateTitleLabel() {
        
        guard let tableContainer = tableContainer else { return }
        
        let text = filtering.inverted ? "Previous Filters" : tableContainer.filteredEntities.count.formatted + " of " + tableContainer.entities.count.fullCountText(for: {
            
            switch self.entities {
                
                case .songs: return .song
                
                case .collections(_, kind: let kind): return kind.entityType
            }
        }())
        
        if let parent = parent as? PresentedContainerViewController {
            
            parent.titleLabel.text = text
        
        } else if let container = container {
            
            title = text
            
            guard container.activeViewController?.topViewController == self else { return }
            
            container.visualEffectNavigationBar.titleLabel.text = title
        }
    }
    
    @IBAction func shuffle() {
        
        let songs: [MPMediaItem] = {
        
            switch entities {
                
                case .songs(let songs): return songs
                
                case .collections(let collections, kind: _): return collections.reduce([], { $0 + $1.items })
            }
        }()
        
        let canShuffleAlbums = songs.canShuffleAlbums
        
        if canShuffleAlbums {
            
            var array = [AlertAction]()
            
            let shuffle = AlertAction.init(title: .shuffle(.songs), style: .default, requiresDismissalFirst: true, handler: {
                
                musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: (self.tableContainer?.filteredEntities.count ?? 0).countText(for: self.entities.entityType), alertTitle: .shuffle(.songs))
            })
            
            array.append(shuffle)
            
            let shuffleAlbums = AlertAction.init(title: .shuffle(.albums), style: .default, requiresDismissalFirst: true, handler: {
                
                musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: self, withTitle: (self.tableContainer?.filteredEntities.count ?? 0).countText(for: self.entities.entityType), alertTitle: .shuffle(.albums))
            })
            
            array.append(shuffleAlbums)
            
            showAlert(title: "Filtered Items", with: array)
            
        } else {
            
            musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: (self.tableContainer?.filteredEntities.count ?? 0).countText(for: self.entities.entityType), alertTitle: .shuffle())
        }
    }
    
    @IBAction func unwind(_ sender: UIStoryboardSegue) { }
    
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        
        if action == #selector(unwind(_:)) {
            
            return presentedViewController != nil && parent?.presentedViewController != nil
        }
        
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
            case "toArranger": Transitioner.shared.transition(to: segue.destination, from: self)
            
            default: break
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            let banner = UniversalMethods.banner(withTitle: "FVC going away...")
            banner.titleLabel.font = .font(ofWeight: .light, size: 22)
            banner.show(for: 0.3)
        }
        
        unregisterAll(from: lifetimeObservers)
        notifier.removeObserver(self)
    }
}

extension FilterViewController {
    
//    func sortItems() {
//        
//        
//    }
}

extension FilterViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        
        guard filtering else { return 1 }
        
        return tableContainer!.tableDelegate.numberOfSections(in: tableView, filtering: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard filtering else { return recentSearches.count }
        
        return tableContainer!.tableDelegate.tableView(tableView, numberOfRowsInSection: section, filtering: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard filtering else {
            
            guard let filter = sender else { return UITableViewCell() }
            
            let cell = tableView.recentSearchCell(for: indexPath)
            let search = recentSearches[indexPath.row]
            
            cell.termLabel?.text = search.title
            cell.backgroundColor = .clear
            cell.searchCategoryImageView.image = #imageLiteral(resourceName: "SearchTab")
            
            let property = Property.fromOldRawValue(Int(search.property)) ?? .title
            let test = PropertyTest(rawValue: search.propertyTest ?? "") ?? filter.initialPropertyTest(for: property)
            
            cell.criteriaLabel.text = property.title + " " + filter.title(for: test, property: property)
            cell.delegate = self
            
            return cell
        }
        
        return tableContainer!.tableDelegate.tableView(tableView, cellForRowAt: indexPath, filtering: true)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        tableContainer?.tableDelegate.tableView(tableView, didEndDisplaying: cell, forRowAt: indexPath, filtering: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing {
            
            if filtering {
                
                tableContainer?.tableDelegate.tableView(tableView, didSelectRowAt: indexPath, filtering: true)
            }
            
        } else {
            
            if filtering {
                
                tableContainer?.tableDelegate.tableView(tableView, didSelectRowAt: indexPath, filtering: true)
                
                if let collectionsVC = tableContainer as? CollectionsViewController, collectionsVC.presented {
                    
                    return
                }
                
            } else {
                
                let search = recentSearches[indexPath.row]
                
                highlightSearchBar(withText: (tableView.cellForRow(at: indexPath) as? RecentSearchTableViewCell)?.termLabel?.text, property: Int(search.property), propertyTest: search.propertyTest, setFirstResponder: false)
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if let collectionsVC = tableContainer as? CollectionsViewController, collectionsVC.presented {
            
            tableContainer?.tableDelegate.tableView(tableView, didDeselectRowAt: indexPath, filtering: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return filtering ? FontManager.shared.entityCellHeight : 57
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return emptyCondition ? 0.00001 : 11
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        return tableContainer?.tableDelegate.tableView(tableView, viewForHeaderInSection: section, filtering: true)
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        return tableContainer?.tableDelegate.sectionIndexTitles(for: tableView, filtering: true)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        return /*filtering ? .insert : */.none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        return filtering.inverted
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        guard filtering else { return }
        
        tableContainer?.tableDelegate.tableView(tableView, commit: editingStyle, forRowAt: indexPath, filtering: true)
    }
}

extension FilterViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let _ = parent as? PresentedContainerViewController, let _ = gestureRecognizer as? UILongPressGestureRecognizer {
            
            return gestureRecognizer.location(in: parent?.view).x > 22
        }
        
        return true
    }
}

//extension FilterViewController {
//
//    @objc func rightViewButtonTapped() {
//
//        showRightButtonOptions()
//    }
//
//    func modifyCollectedView(forState state: QueueViewState, animated: Bool = true) {
//
//        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
//
//            if state == .dismissed && self.filterViewContainer.filterView.collectedView.isHidden { } else {
//
//                self.filterViewContainer.filterView.collectedView.isHidden = state == .dismissed
//            }
//
//            self.filterViewContainer.filterView.collectedView.alpha = state == .dismissed ? 0 : 1
//
//        }, completion: nil)
//    }
//
//    @objc func updateCollectedText(animated: Bool = true) {
//
//        guard let container = appDelegate.window?.rootViewController as? ContainerViewController else { return }
//        
//        UIView.transition(with: filterViewContainer.filterView.collectedLabel, duration: animated ? 0.3 : 0, options: .transitionCrossDissolve, animations: { self.filterViewContainer.filterView.collectedLabel.text = container.queue.count.formatted }, completion: nil)
//        
//        if animated {
//            
//            UIView.animate(withDuration: 0.3, animations: { self.view.layoutIfNeeded() })
//        }
//    }
//}

extension FilterViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        ignoreKeyboardForInset = false
        
        if filtering.inverted {
            
            unfilteredPoint = .init(x: 0, y: tableView.contentOffset.y)
        }
        
        updateDeleteButton()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            
        ignoreKeyboardForInset = true
        
        if !filtering {
            
            updateTitleLabel()
        }
        
        searchBar.resignFirstResponder()
            
//        updateCurrentView(to: recentSearches.isEmpty ? .labels(components: components) : .none)
        
        updateDeleteButton()
        
        adjustInsets(context: .container)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filtering = searchText != ""
        
        sender?.filterText = searchText
        
        if filtering {
            
            updateDeleteButton()
            
            filter(with: searchText)
            
            if searchText.isEmpty {
                
                requiredInputView?.pickerView.selectRow(0, inComponent: 0, animated: true)
            }
            
        } else {
            
            sender?.filterOperation?.cancel()
            sender?.filterOperation = nil
            updateTitleLabel()
            updateCurrentView(to: recentSearches.isEmpty ? .labels(components: components) : .none)
            tableView.reloadData()
            updateHeaderView()
            tableView.contentOffset = unfilteredPoint
            
            animateCells(direction: .vertical)
            
            updateDeleteButton()
            
            if tableView.isEditing {
                
                tableView.isEditing = false
                editView.imageView?.image = .inactiveEditImage
                editView.label?.text = .inactiveEditButtonTitle
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if filtering {
        
            saveRecentSearch(withTitle: searchBar.text, resignFirstResponder: true)
            
        } else if filtering.inverted, let text = searchBar.text, text.isEmpty.inverted {
            
            self.searchBar(searchBar, textDidChange: text)
            searchBar.resignFirstResponder()
        }
    }
}

extension FilterViewController: EntityContainer {
    
    func handleLeftSwipe(_ sender: Any) {
        
        tableView.setEditing(false, animated: true)
    }
    
    func handleRightSwipe(_ sender: Any) {
        
        tableView.setEditing(true, animated: true)
    }
}

extension FilterViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    var array: [String?] { return sender?.pickerViewText ?? [] }
    
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

//extension FilterViewController: RecentSearchCellDelegate {
//
//    func deleteRecentSearch(in cell: RecentSearchTableViewCell) {
//
//        performRecentSearchDeletion(in: cell)
//    }
//}

