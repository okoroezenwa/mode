//
//  FilterViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 09/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit
import CoreData

class FilterViewController: UIViewController, InfoLoading, SingleItemActionable, CellAnimatable, FilterContainer, AlbumTransitionable, ArtistTransitionable, AlbumArtistTransitionable, GenreTransitionable, ComposerTransitionable, PlaylistTransitionable, EntityVerifiable {
    
    @IBOutlet weak var tableView: MELTableView!
    @IBOutlet weak var filterViewContainer: FilterViewContainer! {
        
        didSet {
            
            filterViewContainer.context = .filter(filter: sender, container: self)
        }
    }
    @IBOutlet weak var bottomViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var largeActivityIndicator: MELActivityIndicatorView!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityVisualEffectView: MELVisualEffectView!
    @IBOutlet var activityViewVerticalCenterConstraint: NSLayoutConstraint!
    
    enum FilterEntities {
        
        case songs([MPMediaItem]), collections([MPMediaItemCollection], kind: CollectionsKind)
        
        var category: SearchCategory {
            
            switch self {
                
                case .songs: return .songs
                
                case .collections(_, let kind): return kind.category
            }
        }
    }
    
    var searchBar: MELSearchBar! { return filterViewContainer.filterView.searchBar }
    
//    let managedContext = appDelegate.managedObjectContext
    weak var sender: (UIViewController & Filterable)?
    var tableContainer: TableViewContainer? { return sender as? TableViewContainer }
    var infoLoader: InfoLoading? { return sender as? InfoLoading }
    var actionable: SongActionable? { return sender as? SongActionable }
    var sorter: Arrangeable? { return sender as? Arrangeable }
    var entities = FilterEntities.songs([])
    @objc var unfilteredPoint = CGPoint.zero
    @objc var recentSearches = [RecentSearch]()
    lazy var category = { entities.category }()
    
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var albumQuery: MPMediaQuery?
    @objc var composerQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    @objc var playlistQuery: MPMediaQuery?
    
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
        button.titleLabel?.font = UIFont.myriadPro(ofWeight: .bold, size: 17)
        
        return button
    }()
    
    var editButton: MELButton! = MELButton()
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
        queue.maxConcurrentOperationCount = 3
        
        return queue
    }()
    @objc let filterOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Filter Operation Queue"
        queue.maxConcurrentOperationCount = 3
        
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
        
        view.layoutIfNeeded()
        
        searchBar.delegate = self
        searchBar.text = sender?.filterText
        filterViewContainer.filterView.filterTestButton.setTitle(sender?.testTitle, for: .normal)
        filterViewContainer.filterView.showActionsButton = true
        sender?.updateKeyboard(with: self)
        searchBar(searchBar, textDidChange: searchBar.text ?? "")
        
        updateCollectedView(self)
        
        tableView.register(UINib.init(nibName: "RecentSearchCell", bundle: nil), forCellReuseIdentifier: .recentCell)
        
        resetRecentSearches()
       
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        notifier.addObserver(self, selector: #selector(updateCollectedView(_:)), name: .managerItemsChanged, object: nil)
        
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
    
    @objc func updateCollectedView(_ sender: Any) {
        
        guard let container = appDelegate.window?.rootViewController as? ContainerViewController else { return }
        
        let animated = sender is Notification
        
        modifyCollectedView(forState: container.queue.isEmpty ? .dismissed : .invoked, animated: animated)
        updateCollectedText(animated: animated)
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
        tableContainer?.filterContainer = nil
        
        notifier.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notifier.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        if rightViewSetUp.inverted {
            
            searchBar.updateTextField(with: sender?.placeholder ?? "")
            updateRightView()
        }
    }
    
    @objc func adjustKeyboard(with notification: Notification) {
        
        guard let keyboardHeightAtEnd = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height, searchBar.isFirstResponder, let duration = (notification as NSNotification).userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        let keyboardWillShow = notification.name == NSNotification.Name.UIKeyboardWillShow
        
        bottomViewBottomConstraint.constant = keyboardWillShow ? keyboardHeightAtEnd - 8 : 0
        updateActivityViewConstraint(keyboardShowing: keyboardWillShow)
        
        UIView.animate(withDuration: duration, animations: { self.view.layoutIfNeeded() })
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
        sender?.filterOperation?.addExecutionBlock({ [weak self] in
            
            let text = searchText
            
            guard let weakSelf = self, let sender = weakSelf.sender, let operation = sender.filterOperation else {
                
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
            
            guard let tableContainer = weakSelf.tableContainer else {
                
                weakSelf.updateLoadingViews(hidden: true)
                
                return
            }
            
            if sender.filterOperation == nil { UniversalMethods.performInMain{ weakSelf.updateLoadingViews(hidden: true) }; return }
            if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
            
            [{ tableContainer.filteredEntities = array },
             { weakSelf.tableView.reloadData() },
             { weakSelf.tableView.setContentOffset(.zero, animated: false)},
             { weakSelf.animateCells(direction: .vertical) },
             { weakSelf.updateHeader(count: array.count) },
             { weakSelf.updateLoadingViews(hidden: true) },
             { weakSelf.updateTitleLabel() }].forEach({ closure in
                
                OperationQueue.main.addOperation({
                    
                    if sender.filterOperation == nil { UniversalMethods.performInMain{ weakSelf.updateLoadingViews(hidden: true) }; return }
                    if let operation = weakSelf.filterOperations[text], operation.isCancelled { return }
                    
                    closure()
                })
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
    
    @IBAction func showSorter() {
        
        guard let sorter = sorter, let arrangeVC = popoverStoryboard.instantiateViewController(withIdentifier: "simpleArrangeVC") as? ArrangeViewController else { return }
        
        arrangeVC.modalPresentationStyle = .popover
        
        arrangeVC.sorter = sorter
        arrangeVC.preferredContentSize = CGSize.init(width: 350, height: 169)
        arrangeVC.view.backgroundColor = UIDevice.current.isBlurAvailable ? .clear : darkTheme ? UIColor.darkGray.withAlphaComponent(0.6) : .white
        
        if let popover = arrangeVC.popoverPresentationController {
            
            popover.delegate = PopoverDelegate.shared
//            popover.sourceRect = sortButton.bounds.modifiedBy(width: 0, height: 5)
//            popover.sourceView = sortButton
            popover.backgroundColor = darkTheme ? UIColor.darkGray.withAlphaComponent(UIDevice.current.isBlurAvailable ? 0.5 : 1) : UIColor.white.withAlphaComponent(UIDevice.current.isBlurAvailable ? 0.6 : 1)
            popover.permittedArrowDirections = [.up, .down]
        }
        
        present(arrangeVC, animated: true, completion: nil)
    }
    
    @IBAction func unwind(_ sender: UIStoryboardSegue) { }
    
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        
        if action == #selector(unwind(_:)) {
            
            return presentedViewController != nil && parent?.presentedViewController != nil
        }
        
        return false
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            let banner = UniversalMethods.banner(withTitle: "FVC going away...")
            banner.titleLabel.font = .myriadPro(ofWeight: .light, size: 22)
            banner.show(for: 0.3)
        }
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
        
        guard filtering else {
            
            let search = recentSearches[indexPath.row]
            
            highlightSearchBar(withText: (tableView.cellForRow(at: indexPath) as? RecentSearchTableViewCell)?.termLabel?.text, property: Int(search.property), propertyTest: search.propertyTest, setFirstResponder: false)
            
            tableView.deselectRow(at: indexPath, animated: true)
            
            return
        }
        
        tableContainer?.tableDelegate.tableView(tableView, didSelectRowAt: indexPath, filtering: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return filtering ? 72 : 57
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return tableContainer!.tableDelegate.tableView(tableView, heightForHeaderInSection: section, filtering: true)
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
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        return filtering ? .insert : .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard filtering else { return }
        
        tableContainer?.tableDelegate.tableView(tableView, commit: editingStyle, forRowAt: indexPath, filtering: true)
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        return false
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
            tableView.contentOffset = unfilteredPoint
            
            animateCells(direction: .vertical)
            
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

//extension FilterViewController: RecentSearchCellDelegate {
//
//    func deleteRecentSearch(in cell: RecentSearchTableViewCell) {
//
//        performRecentSearchDeletion(in: cell)
//    }
//}

