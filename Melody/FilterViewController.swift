//
//  FilterViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 09/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit
import CoreData

class FilterViewController: UIViewController, InfoLoading, SingleItemActionable, CellAnimatable, FilterContainer, AlbumTransitionable, ArtistTransitionable, AlbumArtistTransitionable, GenreTransitionable, ComposerTransitionable, PlaylistTransitionable, EntityVerifiable, Arrangeable, Refreshable, BorderButtonContaining {
    
    @IBOutlet var tableView: MELTableView!
    @IBOutlet var filterViewContainer: FilterViewContainer! {
        
        didSet {
            
            filterViewContainer.context = .filter(filter: sender, container: self)
        }
    }
    @IBOutlet var bottomViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var largeActivityIndicator: MELActivityIndicatorView!
    @IBOutlet var activityView: UIView!
    @IBOutlet var activityVisualEffectView: MELVisualEffectView!
    @IBOutlet var activityViewVerticalCenterConstraint: NSLayoutConstraint!
    
    lazy var headerView: HeaderView = {
        
        let view = HeaderView.fresh
        self.actionsStackView = view.actionsStackView
//        self.stackView = view.scrollStackView
        view.scrollStackViewHeightConstraint.constant = 0
        
        return view
    }()
    var actionsStackView: UIStackView! {
        
        didSet {
            
//            let shuffleView = BorderedButtonView.with(title: .shuffleButtonTitle, image: #imageLiteral(resourceName: "Shuffle13"), action: #selector(shuffle), target: self)
//            shuffleButton = shuffleView.button
//            self.shuffleView = shuffleView
//
//            let arrangeBorderView = BorderedButtonView.with(title: .arrangeButtonTitle, image: #imageLiteral(resourceName: "AscendingLines"), action: #selector(showArranger), target: self)
//            arrangeBorderView.borderView.centre(activityIndicator)
//            arrangeButton = arrangeBorderView.button
//            self.arrangeBorderView = arrangeBorderView
            
            let editView = BorderedButtonView.with(title: .inactiveEditButtonTitle, image: .inactiveEditImage, tapAction: .init(action: #selector(SongActionManager.toggleEditing(_:)), target: songManager), longPressAction: .init(action: #selector(SongActionManager.showActionsForAll(_:)), target: songManager))
            editButton = editView.button
            self.editView = editView
            
            [/*shuffleView, arrangeBorderView, */editView].forEach({ actionsStackView.addArrangedSubview($0) })
        }
    }
    
//    var stackView: UIStackView! {
//
//        didSet {
//
//            let view = ScrollHeaderSubview.with(title: arrangementLabelText, image: #imageLiteral(resourceName: "Order10"))
//
//            orderLabel = view.label
//
//            for view in [view] {
//
//                stackView.addArrangedSubview(view)
//            }
//        }
//    }
    
    enum FilterEntities {
        
        case songs([MPMediaItem]), collections([MPMediaItemCollection], kind: CollectionsKind)
        
        var category: SearchCategory {
            
            switch self {
                
                case .songs: return .songs
                
                case .collections(_, let kind): return kind.category
            }
        }
        
        var entityType: Entity {
            
            switch self {
                
                case .songs: return .song
                
                case .collections(_, let kind): return kind.entity
            }
        }
    }
    
    var searchBar: MELSearchBar! { return filterViewContainer.filterView.searchBar }
    
    weak var sender: (UIViewController & Filterable)?
    var tableContainer: TableViewContainer? { return sender as? TableViewContainer }
    var infoLoader: InfoLoading? { return sender as? InfoLoading }
    var actionable: SongActionable? { return sender as? SongActionable }
    var sorter: Arrangeable? { return sender as? Arrangeable }
    var entities = FilterEntities.songs([])
    @objc var unfilteredPoint = CGPoint.zero
    @objc var recentSearches = [RecentSearch]()
    lazy var category = { entities.category }()
    
    @objc lazy var refresher: Refresher = { Refresher.init(refreshable: self) }()
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var albumQuery: MPMediaQuery?
    @objc var composerQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    @objc var playlistQuery: MPMediaQuery?
    
    var emptyCondition: Bool { return filtering ? tableContainer?.filteredEntities.isEmpty != false : recentSearches.isEmpty }
    
//    lazy var filteredSongs = [MPMediaItem]()
//    lazy var filteredCollections = [MPMediaItemCollection]()
    
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
        button.fontWeight = FontWeight.semibold.rawValue
        
        return button
    }()
    
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
    
    var query: MPMediaQuery?
    var sortCriteria: SortCriteria {
        
        get { return actualSortCriteria }
        
        set {
            
            sortItems()
            orderLabel.text = arrangementLabelText
        }
    }
    lazy var actualSortCriteria: SortCriteria = { sorter?.sortCriteria ?? .standard }()
    var applySort = true
    var ascending: Bool {
        
        get { return actualAscending }
        
        set {
            
            actualAscending = newValue
            
            tableContainer?.filteredEntities.reverse()
            
            updateHeaderView()
            tableView.reloadData()
            animateCells(direction: .vertical)
            updateImage(for: arrangeButton)
        }
    }
    
    lazy var actualAscending: Bool = { sorter?.ascending ?? true }()
    lazy var applicableSortCriteria: Set<SortCriteria> = { sorter?.applicableSortCriteria ?? [] }()
    lazy var location: SortLocation = { sorter?.location ?? .songs }()
    
    var borderedButtons = [BorderedButtonView?]()
    var applicableActions: [SongAction] { return actionable?.applicableActions ?? [] }
    var actionableSongs: [MPMediaItem] { return actionable?.actionableSongs ?? [] }
    lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    var rightViewSetUp = false
    var wasFirstResponder = false
    var filtering = false {
        
        didSet {
            
            guard oldValue != filtering else { return }
            
            tableView.allowsMultipleSelectionDuringEditing = filtering.inverted
        }
    }
    
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
        filterViewContainer.filterView.filterTestButton.setTitle(sender?.testTitle, for: .normal)
        filterViewContainer.filterView.showActionsButton = true
        sender?.updateKeyboard(with: self)
        searchBar(searchBar, textDidChange: searchBar.text ?? "")
        
        updateCollectedView(self)
        
//        updateHeaderView(with: tableContainer?.filteredEntities.count ?? 0)
//        updateImage(for: arrangeButton)
       
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        notifier.addObserver(self, selector: #selector(updateCollectedView(_:)), name: .managerItemsChanged, object: nil)
        [Notification.Name.entityCountVisibilityChanged, .showExplicitnessChanged].forEach({ notifier.addObserver(self, selector: #selector(updateEntityCountVisibility), name: $0, object: nil) })
        
        if case .collections(_, .playlist) = entities { } else {
            
            notifier.addObserver(self, selector: #selector(updateNowPlaying), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer)
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
        
        if searchBar.text?.isEmpty == true {
        
            searchBar.becomeFirstResponder()
        }
    }
    
    @objc func updateEntityCountVisibility() {
        
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        
        tableView.reloadRows(at: indexPaths, with: .none)
    }
    
    @objc func updateNowPlaying() {
        
        switch entities {
            
            case .songs(let songs):
            
                for cell in tableView.visibleCells {
                    
                    guard let cell = cell as? SongTableViewCell, let indexPath = tableView.indexPath(for: cell) else { continue }
                    
                    if cell.playingView.isHidden.inverted && musicPlayer.nowPlayingItem != songs[indexPath.row] {
                        
                        cell.playingView.isHidden = true
                        cell.indicator.state = .stopped
                        
                    } else if cell.playingView.isHidden && musicPlayer.nowPlayingItem == songs[indexPath.row] {
                        
                        cell.playingView.isHidden = false
                        UniversalMethods.performOnMainThread({ cell.indicator.state = musicPlayer.isPlaying ? .playing : .paused }, afterDelay: 0.1)
                    }
                }
            
            case .collections(let collections, kind: _):
            
                for cell in tableView.visibleCells {
                    
                    guard let entityCell = cell as? SongTableViewCell, let indexPath = tableView.indexPath(for: entityCell), let nowPlaying = musicPlayer.nowPlayingItem else {
                        
                        (cell as? SongTableViewCell)?.playingView.isHidden = true
                        (cell as? SongTableViewCell)?.indicator.state = .stopped
                        
                        continue
                    }
                    
                    if entityCell.playingView.isHidden.inverted && Set(collections[indexPath.row].items).contains(nowPlaying).inverted {
                        
                        entityCell.playingView.isHidden = true
                        entityCell.indicator.state = .stopped
                        
                    } else if entityCell.playingView.isHidden && Set(collections[indexPath.row].items).contains(nowPlaying) {
                        
                        entityCell.playingView.isHidden = false
                        UniversalMethods.performOnMainThread({ entityCell.indicator.state = musicPlayer.isPlaying ? .playing : .paused }, afterDelay: 0.1)
                    }
                }
        }
    }
    
    @objc func updateCollectedView(_ sender: Any) {
        
        guard let container = appDelegate.window?.rootViewController as? ContainerViewController else { return }
        
        let animated = sender is Notification
        
        modifyCollectedView(forState: container.queue.isEmpty ? .dismissed : .invoked, animated: animated)
        updateCollectedText(animated: animated)
    }
    
    @objc func updateHeaderView() {
        
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
        
        if let row = array.index(where: { $0 == searchBar.text }) {
            
            requiredInputView?.pickerView.selectRow(row, inComponent: 0, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        sender?.filtering = false
        
        if ascending.inverted && tableContainer?.ascending != false {
            
            tableContainer?.filteredEntities.reverse()
        }
        
        filterViewContainer.context = .filter(filter: nil, container: nil)
        tableContainer?.filterContainer = nil
        
        notifier.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notifier.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        if rightViewSetUp.inverted {
            
            searchBar.updateTextField(with: sender?.placeholder ?? "")
            updateRightView()
        }
    }
    
    @objc func adjustKeyboard(with notification: Notification) {
        
        guard let keyboardHeightAtEnd = ((notification as NSNotification).userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height, searchBar.isFirstResponder, let duration = (notification as NSNotification).userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        let keyboardWillShow = notification.name == UIResponder.keyboardWillShowNotification
        
        bottomViewBottomConstraint.constant = keyboardWillShow ? keyboardHeightAtEnd - 6 : 0
        updateActivityViewConstraint(keyboardShowing: keyboardWillShow)
        
        UIView.animate(withDuration: duration, animations: { self.view.layoutIfNeeded() })
    }
    
    @objc func showArranger() {
        
        performSegue(withIdentifier: "toArranger", sender: nil)
    }
    
    func updateActivityViewConstraint(keyboardShowing: Bool) {
        
        activityViewVerticalCenterConstraint.constant = keyboardShowing ? -(view.frame.height - 22) / 4 : 0
    }
    
    func updateHeader(count: Int) {
        
        guard let parent = parent as? PresentedContainerViewController else { return }
        
        parent.prepare(animated: true, updateConstraintsAndButtons: false)
    }
    
    func filter(with searchText: String) {
        
        updateLoadingViews(hidden: false)
        
        filterOperationQueue.cancelAllOperations()
        sender?.filterOperation = BlockOperation()
        sender?.filterOperation?.addExecutionBlock({ [weak self, weak tableContainer, weak sender] in
            
            let text = searchText
            
            guard let weakSelf = self, let sender = sender, let operation = sender.filterOperation else {
                
                UniversalMethods.performInMain { self?.updateLoadingViews(hidden: true) }
                
                return
            }
            
            guard operation.isCancelled.inverted else { return }
            
            UniversalMethods.performInMain { weakSelf.updateLoadingViews(hidden: false) }
            
            let array: [MPMediaEntity] = {
                
                switch weakSelf.entities {
                    
                    case .songs(let songs): return sender.getResults(for: songs, against: searchText)
                    
                    case .collections(let collections, let kind): return sender.getResults(for: collections, of: kind, against: searchText)
                }
            }()
            
            guard let tableContainer = tableContainer else {
                
                weakSelf.updateLoadingViews(hidden: true)
                
                return
            }
            
            if sender.filterOperation == nil {
                
                UniversalMethods.performInMain { weakSelf.updateLoadingViews(hidden: true) }
                
                return
            }
            
            if let operation = weakSelf.filterOperations[text], operation.isCancelled {
                
                UniversalMethods.performInMain { weakSelf.updateLoadingViews(hidden: true) }
                    
                return
            }
            
            OperationQueue.main.addOperation({
                
                if sender.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                tableContainer.filteredEntities = array
                
                if sender.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.updateHeaderView()
                
                if sender.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.tableView.reloadData()
                
                if sender.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.tableView.setContentOffset(.zero, animated: false)
                
                if sender.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.animateCells(direction: .vertical)
                
                if sender.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.updateHeader(count: array.count)
                
                if sender.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.updateLoadingViews(hidden: true)
                
                if sender.filterOperation == nil { weakSelf.updateLoadingViews(hidden: true); return }
                if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                
                weakSelf.updateTitleLabel()
            })
        })
        
        filterOperationQueue.addOperation((sender?.filterOperation)!)
        filterOperations[searchText] = (sender?.filterOperation)!
    }
    
    func updateTitleLabel() {
        
        guard let parent = parent as? PresentedContainerViewController, let tableContainer = tableContainer else { return }
        
        parent.titleLabel.text = filtering.inverted ? "Previous Searches" : tableContainer.filteredEntities.count.formatted + " of " + tableContainer.entities.count.fullCountText(for: {
            
            switch self.entities {
                
                case .songs: return .song
                
                case .collections(_, kind: let kind): return kind.entity
            }
        }())
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
            
            var array = [UIAlertAction]()
            
            let shuffle = UIAlertAction.init(title: .shuffle(.songs), style: .default, handler: { _ in
                
                musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: (self.tableContainer?.filteredEntities.count ?? 0).countText(for: self.entities.entityType), alertTitle: .shuffle(.songs))
            })
            
            array.append(shuffle)
            
            let shuffleAlbums = UIAlertAction.init(title: .shuffle(.albums), style: .default, handler: { _ in
                
                musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: self, withTitle: (self.tableContainer?.filteredEntities.count ?? 0).countText(for: self.entities.entityType), alertTitle: .shuffle(.albums))
            })
            
            array.append(shuffleAlbums)
            
            present(UIAlertController.withTitle(nil, message: "Filtered Items", style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
            
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
            banner.titleLabel.font = .myriadPro(ofWeight: .light, size: 22)
            banner.show(for: 0.3)
        }
    }
}

extension FilterViewController {
    
    func sortItems() {
        
        
    }
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
            
            let property = Property(rawValue: Int(search.property)) ?? .title
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
        
        return filtering ? .insert : .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        guard filtering else { return }
        
        tableContainer?.tableDelegate.tableView(tableView, commit: editingStyle, forRowAt: indexPath, filtering: true)
    }
}

extension FilterViewController {
    
    @objc func rightViewButtonTapped() {
        
        updateRightViewButton()
    }
    
    func modifyCollectedView(forState state: QueueViewState, animated: Bool = true) {
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            
            if state == .dismissed && self.filterViewContainer.filterView.collectedView.isHidden { } else {
                
                self.filterViewContainer.filterView.collectedView.isHidden = state == .dismissed
            }
            
            self.filterViewContainer.filterView.collectedView.alpha = state == .dismissed ? 0 : 1
            
        }, completion: nil)
    }
    
    @objc func updateCollectedText(animated: Bool = true) {
        
        guard let container = appDelegate.window?.rootViewController as? ContainerViewController else { return }
        
        UIView.transition(with: filterViewContainer.filterView.collectedLabel, duration: animated ? 0.3 : 0, options: .transitionCrossDissolve, animations: { self.filterViewContainer.filterView.collectedLabel.text = container.queue.count.formatted }, completion: nil)
        
        if animated {
            
            UIView.animate(withDuration: 0.3, animations: { self.view.layoutIfNeeded() })
        }
    }
}

extension FilterViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        if filtering.inverted {
            
            unfilteredPoint = .init(x: 0, y: tableView.contentOffset.y)
        }
        
        updateDeleteButton()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filtering = searchText != ""
        
        filterViewContainer.filterView.updateClearButton(to: filtering ? .visible : .hidden)
        
        sender?.filterText = searchText
        
        if filtering {
            
            updateDeleteButton()
            
            filter(with: searchText)
            
            if searchText.isEmpty {
                
                requiredInputView?.pickerView.selectRow(0, inComponent: 0, animated: true)
            }
            
        } else {
            
            sender?.filterOperation?.cancel()
            updateTitleLabel()
            tableView.reloadData()
            updateHeaderView()
            tableView.contentOffset = unfilteredPoint
            
            animateCells(direction: .vertical)
            
            updateDeleteButton()
            
            if tableView.isEditing {
                
                tableView.isEditing = false
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        saveRecentSearch(withTitle: searchBar.text, resignFirstResponder: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        self.searchBar(searchBar, textDidChange: "")
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

