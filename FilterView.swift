//
//  FilterView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 25/11/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class FilterViewContainer: UIView {
    
    var context = FilterView.Context.library {
        
        didSet {
            
            guard oldValue != context else { return }
            
            filterView.context = context
        }
    }
    
    lazy var filterView: FilterView = { FilterView.with(context: context) }()
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        fill(with: filterView)
    }
}

class FilterView: UIView {

    @IBOutlet weak var filterInputView: UIView!
    @IBOutlet weak var searchBar: MELSearchBar!
    @IBOutlet weak var filterTestButton: MELButton! {
        
        didSet {
            
            filterTestButton.imageEdgeInsets.bottom = 2
            filterTestButton.imageEdgeInsets.right = 1
        }
    }
    @IBOutlet weak var collectionView: MELCollectionView!
    @IBOutlet weak var filterInputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterInputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectedView: UIView!
    @IBOutlet weak var collectedLabel: MELLabel!
    @IBOutlet var searchButtonContainer: UIView!
    @IBOutlet var searchButtonContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var actionsButtonContainer: UIView!
    @IBOutlet var actionsButtonContainerWidthConstraint: NSLayoutConstraint!
    
    enum Context: Equatable {
        
        case filter(filter: Filterable?, container: FilterContainer & UIViewController), library
        
        static func ==(lhs: Context, rhs: Context) -> Bool {
            
            switch lhs {
                
                case .filter(let filter, _):
                
                    switch rhs {
                        
                        case .filter(filter: let otherFilter, container: _): return filter == nil && otherFilter == nil
                          
                        default: return false
                    }
                
                case .library:
                
                    switch rhs {
                        
                        case .library: return true
                        
                        default: return false
                    }
            }
        }
    }
    
    enum ClearButtonState { case hidden, visible }
    
    var withinSearchTerm = false {
        
        didSet {
            
            filterInputViewHeightConstraint.constant = context == .library || withinSearchTerm ? 0 : 52
            self.updateTestButton()
        }
    }
    
    var showActionsButton = false {
        
        didSet {
            
            actionsButtonContainer.alpha = showActionsButton ? 1 : 0
            actionsButtonContainerWidthConstraint.constant = showActionsButton ? 36 : 0
        }
    }
    
    lazy var properties: [TitleContaining] = {
        
        switch context {
            
            case .filter(let filter, _): return filterProperties.filter({ filter?.applicableFilterProperties.contains($0) == true })
            
            case .library: return librarySections
        }
    }()
    @objc let cellSizes: NSCache<Index, Size> = {
        
        let cache = NSCache<Index, Size>()
        cache.name = "Cell Sizes"
        cache.countLimit = 50
        
        return cache
    }()
    
    var context = Context.library {
        
        didSet {
            
            properties = {
                
                switch context {
                    
                    case .filter(let filter, _): return filterProperties.filter({ filter?.applicableFilterProperties.contains($0) == true })
                    
                    case .library: return librarySections
                }
            }()
            
            collectionView.reloadData()
            filterInputViewHeightConstraint.constant = context == .library || withinSearchTerm ? 0 : 52
            
            UIView.transition(with: filterTestButton, duration: 0.3, options: .transitionCrossDissolve, animations: {
                
                self.updateTestButton()
                
            }, completion: nil)
            
            if case .filter(_, let container) = context, hasSetUpSettingsGesture.inverted {
                
                let gr = UILongPressGestureRecognizer.init(target: container, action: #selector(UIViewController.showSettings(with:)))
                gr.minimumPressDuration = longPressDuration
                actionsButtonContainer.addGestureRecognizer(gr)
                LongPressManager.shared.gestureRecognisers.insert(Weak.init(value: gr))
                
                hasSetUpSettingsGesture = true
            }
        }
    }
    
    lazy var hasSetUpSettingsGesture = false
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        collectionView.register(UINib.init(nibName: "PropertyCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(showCollectedActions(_:)))
        hold.minimumPressDuration = longPressDuration
        collectedView.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.insert(Weak.init(value: hold))
    }
    
    class func with(context: Context) -> FilterView {
        
        let view = Bundle.main.loadNibNamed("FilterView", owner: nil, options: nil)?.first as! FilterView
        
        view.context = context
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }
    
    @IBAction func clearSearchBar(_ sender: Any) {
        
        guard case .filter(filter: _, container: let container) = context, let searchBar = container.searchBar else { return }
        
        searchBar.text = nil
        container.searchBar?(searchBar, textDidChange: "")
        
        updateClearButton(to: .hidden)
    }
    
    func updateClearButton(to state: ClearButtonState) {
        
        if (state == .hidden && searchButtonContainerWidthConstraint.constant == 0) || (state == .visible && searchButtonContainerWidthConstraint.constant != 0) { return }
        
        searchButtonContainerWidthConstraint.constant = state == .hidden ? 0 : 36
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.searchButtonContainer.alpha = state == .hidden ? 0 : 1
            self.searchButtonContainer.superview?.layoutIfNeeded()
        })
    }
    
    func collectorAlertActions(from actions: [ContainerViewController.CollectorActions]) -> [UIAlertAction] {
        
        guard let container = appDelegate.window?.rootViewController as? ContainerViewController else { return [] }
        
//        let canShuffleAlbums = actions.contains(.shuffleAlbums)
        
        return actions.map({
            
            switch $0 {
                
                case .play:
                    
                    return UIAlertAction.init(title: "Play", style: .default, handler: { _ in
                        
                        musicPlayer.play(container.queue, startingFrom: container.queue.first, from: container, withTitle: container.queue.count.fullCountText(for: .song), alertTitle: "Play")
                        
                        notifier.post(name: .endQueueModification, object: nil)
                    })
                
                case .clear:
                    
                    return UIAlertAction.init(title: "Discard Collected", style: .destructive, handler: { _ in
                        
                        notifier.post(name: .endQueueModification, object: nil)
                    })
                
                case .shuffleSongs:
                    
                    return UIAlertAction.init(title: .shuffle(.songs), style: .default, handler: { _ in
                        
                        musicPlayer.play(container.queue, startingFrom: nil, shuffleMode: .songs, from: container, withTitle: container.queue.count.fullCountText(for: .song), alertTitle: .shuffle(.songs))
                        
                        notifier.post(name: .endQueueModification, object: nil)
                    })
                
                case .shuffleAlbums:
                    
                    return UIAlertAction.init(title: .shuffle(.albums), style: .default, handler: { _ in
                        
                        musicPlayer.play(container.queue.albumsShuffled, startingFrom: nil, from: container, withTitle: container.queue.count.fullCountText(for: .song), alertTitle: .shuffle(.albums))
                        
                        notifier.post(name: .endQueueModification, object: nil)
                    })
                
                case .queue:
                    
                    return UIAlertAction.init(title: "Queue...", style: .default, handler: { [weak self] _ in
                        
                        guard let weakSelf = self, let vc: UIViewController = {
                           
                            switch weakSelf.context {
                                
                                case .filter(filter: _, container: let filterContainer) where filterContainer is FilterViewController: return filterContainer
                                
                                default: return container
                            }
                            
                        }() else { return }
                        
                        Transitioner.shared.addToQueue(from: vc, kind: .items(container.queue), context: .collector(manager: container))
                    })
                
                case .existingPlaylist:
                    
                    return UIAlertAction.init(title: "Add to Playlist", style: .default, handler: { [weak self] _ in
                        
                        guard let weakSelf = self, let vc: UIViewController = {
                           
                            switch weakSelf.context {
                                
                                case .filter(filter: _, container: let filterContainer) where filterContainer is FilterViewController: return filterContainer
                                
                                default: return container
                            }
                            
                        }() else { return }
                        
                        vc.performSegue(withIdentifier: "toPlaylists", sender: nil)
                    })
                
                case .newPlaylist:
                    
                    return UIAlertAction.init(title: "Create Playlist", style: .default, handler: { [weak self] _ in
                        
                        guard let weakSelf = self, let vc: UIViewController = {
                           
                            switch weakSelf.context {
                                
                                case .filter(filter: _, container: let filterContainer) where filterContainer is FilterViewController: return filterContainer
                                
                                default: return container
                            }
                            
                        }() else { return }
                        
                        vc.performSegue(withIdentifier: "toNewPlaylist", sender: nil)
                    })
            }
        })
    }
    
    @objc func showCollectedActions(_ gr: UILongPressGestureRecognizer) {
        
        guard let container = appDelegate.window?.rootViewController as? ContainerViewController, gr.state == .began else { return }
        
        var actions = [ContainerViewController.CollectorActions.play]
        
        if musicPlayer.nowPlayingItem != nil {
            
            actions.append(.queue)
        }
        
        if container.queue.count > 1 {
            
            actions.append(.shuffleSongs)
            
            if container.queue.canShuffleAlbums {
                
                actions.append(.shuffleAlbums)
            }
        }
        
        actions.append(contentsOf: [.newPlaylist, .existingPlaylist, .clear])
        
        let collectorActions = collectorAlertActions(from: actions) + [.cancel()]
        
        switch context {
            
            case .filter(filter: _, container: let filterContainer) where filterContainer is FilterViewController: filterContainer.present(UIAlertController.withTitle(container.queue.count.fullCountText(for: .song), message: nil, style: .actionSheet, actions: collectorActions), animated: true, completion: nil)
            
            default: container.present(UIAlertController.withTitle(container.queue.count.fullCountText(for: .song), message: nil, style: .actionSheet, actions: collectorActions), animated: true, completion: nil)
        }
    }
    
    @IBAction func rightButtonTapped() {
        
        switch context {
            
            case .filter(filter: _, container: let container) where !withinSearchTerm: container.showPropertyTests()
            
            default: notifier.post(name: .performSecondaryAction, object: (appDelegate.window?.rootViewController as? ContainerViewController)?.activeViewController)
        }
    }
    
    func updateTestButton() {
        
        switch self.context {
            
            case .filter(filter: let filter, container: _) where !self.withinSearchTerm:
                
                self.filterTestButton.setTitle(filter?.testTitle, for: .normal)
                self.filterTestButton.setImage(nil, for: .normal)
    
            default:
                
                self.filterTestButton.setTitle(nil, for: .normal)
                self.filterTestButton.setImage(#imageLiteral(resourceName: "Filter"), for: .normal)
        }
    }
    
    @IBAction func showCollector() {
        
        switch context {
            
            case .filter(filter: _, container: let container) where container is FilterViewController:
            
                guard let filterVC = container as? FilterViewController, let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
            
                presentedVC.manager = appDelegate.window?.rootViewController as? ContainerViewController
                presentedVC.container = appDelegate.window?.rootViewController as? ContainerViewController
            
                filterVC.present(presentedVC, animated: true, completion: nil)
            
            default: (appDelegate.window?.rootViewController as? ContainerViewController)?.performSegue(withIdentifier: "manageQueue", sender: nil)
        }
    }
}

extension FilterView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return properties.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PropertyCollectionViewCell
        
        let property = properties[indexPath.row]
        let isActive: Bool = {
            
            switch context {
                
                case . filter(let filter, _): return filter?.filterProperty == property as? Property
                
                case .library: return LibrarySection(rawValue: lastUsedLibrarySection) == property as? LibrarySection
            }
        }()
        
        let text = isActive ? property.title.uppercased() : property.title
        
        cell.label.text = text
        cell.label.font = UIFont.myriadPro(ofWeight: isActive ? .bold : .regular, size: 17)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var indexPaths = [IndexPath]()
        
        switch context {
            
            case .filter(let filter, let container):
                
                guard let property = properties[indexPath.row] as? Property, let oldProperty = filter?.filterProperty, property != oldProperty, let index = (properties as? [Property])?.index(of: oldProperty) else {
                    
                    if let searchVC = container as? SearchViewController, searchVC != searchVC.navigationController?.topViewController {
                        
                        searchVC.wasFiltering = true
                        searchVC.navigationController?.popToRootViewController(animated: true)
                    
                    } else {
                        
                        if filter?.ignorePropertyChange == true {
                            
                            filter?.verifyPropertyTest(with: container)
                            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                            
                        } else if searchBar.isFirstResponder.inverted, searchBar.textField?.text?.isEmpty == true {
                            
                            searchBar.becomeFirstResponder()
                        }
                    }
                    
                    collectionView.deselectItem(at: indexPath, animated: true)
                    
                    return
                }
                
                indexPaths.append(indexPath)
                
                let oldIndexPath = IndexPath.init(row: index, section: 0)
                
                if collectionView.indexPathsForVisibleItems.contains(oldIndexPath) {
                    
                    indexPaths.append(oldIndexPath)
                }
                
                filter?.clearIfNeeded(with: property)
                filter?.filterProperty = property
                filter?.verifyPropertyTest(with: container)
                container.requiredInputView?.pickerView.reloadAllComponents()
                container.updateRightView()
                UIView.performWithoutAnimation { self.searchBar.updateTextField(with: filter?.placeholder ?? "") }
            
                if let searchVC = container as? SearchViewController, searchVC != searchVC.navigationController?.topViewController {
                    
                    searchVC.wasFiltering = true
                    searchVC.navigationController?.popToRootViewController(animated: true)
                    
                } else {
                    
                    if filter?.ignorePropertyChange == true {
                        
                        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    
                    } else if searchBar.isFirstResponder.inverted, searchBar.textField?.text?.isEmpty == true {
                        
                        searchBar.becomeFirstResponder()
                    }
                }
            
            case .library:
                
                guard let section = properties[indexPath.row] as? LibrarySection, let oldSection = LibrarySection(rawValue: prefs.integer(forKey: .lastUsedLibrarySection)), section != oldSection, let index = (properties as? [LibrarySection])?.index(of: oldSection) else {
                    
                    if let container = appDelegate.window?.rootViewController as? ContainerViewController, container.libraryNavigationController?.topViewController != container.libraryNavigationController?.viewControllers.first {
                        
                        container.libraryNavigationController?.popToRootViewController(animated: true)
                    }
                    
                    collectionView.deselectItem(at: indexPath, animated: true)
                    
                    return
                }
                
                if let libraryVC = (appDelegate.window?.rootViewController as? ContainerViewController)?.libraryNavigationController?.viewControllers.first as? LibraryViewController {
                
                    indexPaths.append(indexPath)
                    
                    let oldIndexPath = IndexPath.init(row: index, section: 0)
                    
                    if collectionView.indexPathsForVisibleItems.contains(oldIndexPath) {
                        
                        indexPaths.append(oldIndexPath)
                    }
                    
                    prefs.set(section.rawValue, forKey: .lastUsedLibrarySection)
                    libraryVC.activeChildViewController = libraryVC.viewControllerForCurrentSection()
                    
                    if libraryVC.navigationController?.topViewController != libraryVC.navigationController?.viewControllers.first {
                        
                        libraryVC.navigationController?.popToRootViewController(animated: true)
                    }
                }
                
                collectionView.deselectItem(at: indexPath, animated: true)
        }
        
        UIView.animate(withDuration: 0.2, animations: {

            indexPaths.forEach({

                if collectionView.indexPathsForVisibleItems.contains($0), let cell = collectionView.cellForItem(at: $0) as? PropertyCollectionViewCell {

                    cell.alpha = 0
                }
            })
            
        }, completion: { _ in

            indexPaths.forEach({

                if collectionView.indexPathsForVisibleItems.contains($0), let cell = collectionView.cellForItem(at: $0) as? PropertyCollectionViewCell {
                    
                    cell.alpha = 0

                    let property = self.properties[$0.row]
                    let isActive: Bool = {
                        
                        switch self.context {
                            
                            case . filter(let filter, _): return filter?.filterProperty == property as? Property
                            
                            case .library: return LibrarySection(rawValue: lastUsedLibrarySection) == property as? LibrarySection
                        }
                    }()
                    
                    let text = isActive ? property.title.uppercased() : property.title

                    cell.label.text = text
                    cell.label.font = UIFont.myriadPro(ofWeight: isActive ? .bold : .regular, size: 17)
                }
            })

            UIView.animate(withDuration: 0.2, animations: {

                indexPaths.forEach({

                    if collectionView.indexPathsForVisibleItems.contains($0), let cell = collectionView.cellForItem(at: $0) as? PropertyCollectionViewCell {

                        cell.alpha = 1
                        collectionView.deselectItem(at: $0, animated: false)
                    }
                })

                self.collectionView.performBatchUpdates({  }, completion: { _ in })
            })
        })
    }
}

extension FilterView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
//        guard case .filter(let filter, _) = context else { return .zero }
        
        let property = properties[indexPath.row]
        let isActive: Bool = {
            
            switch self.context {
                
                case . filter(let filter, _): return filter?.filterProperty == property as? Property
                
                case .library: return LibrarySection(rawValue: lastUsedLibrarySection) == property as? LibrarySection
            }
        }()
        
        if let size = cellSizes.object(forKey: Index.init(indexPath: indexPath, uppercased: isActive)) {

            return .init(width: size.width, height: size.height)
        }
        
        let text = isActive ? property.title.uppercased() : property.title
        
        let size = Size.init(width: (text as NSString).boundingRect(with: .init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [.font: UIFont.myriadPro(ofWeight: isActive ? .bold : .regular, size: 17)], context: nil).width + 32, height: 36)
        
        cellSizes.setObject(size, forKey: Index.init(indexPath: indexPath, uppercased: isActive))
        
        return size.cgSize
    }
}

class Size: NSObject {
    
    let width: CGFloat
    let height: CGFloat
    
    init(width: CGFloat, height: CGFloat) {
        
        self.width = width
        self.height = height
        
        super.init()
    }
    
    var cgSize: CGSize { return CGSize.init(width: width, height: height) }
    
    override var hash: Int { return width.hashValue ^ height.hashValue }
}

class Index: NSObject {
    
    let indexPath: IndexPath
    let uppercased: Bool
    
    init(indexPath: IndexPath, uppercased: Bool) {
        
        self.indexPath = indexPath
        self.uppercased = uppercased
        
        super.init()
    }
    
    override var hash: Int { return indexPath.hashValue ^ uppercased.hashValue }
}
