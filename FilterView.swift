//
//  FilterView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 25/11/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class FilterViewContainer: UIView {
    
    var context = FilterViewContext.library {
        
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

    @IBOutlet var filterInputView: UIView!
    @IBOutlet var searchBar: MELSearchBar!
    @IBOutlet var filterTestButton: MELButton! {
        
        didSet {
            
            filterTestButton.imageEdgeInsets.bottom = 2
            filterTestButton.imageEdgeInsets.right = 1
        }
    }
    @IBOutlet var filterTestBorderView: MELBorderView!
    @IBOutlet var collectionView: MELCollectionView!
    @IBOutlet var filterInputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var filterInputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var collectedView: UIView!
    @IBOutlet var collectedLabel: MELLabel!
    @IBOutlet var searchButtonContainer: UIView!
    @IBOutlet var searchButtonContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var actionsButtonContainer: UIView!
    @IBOutlet var actionsButtonContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var gradientView: GradientView!
    @IBOutlet var editLabel: MELLabel!
    
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
    
    lazy var properties: [PropertyStripPresented] = {
        
        switch context {
            
            case .filter(let filter, _): return filterProperties.filter({ Set(hiddenFilterProperties).contains($0).inverted && filter?.applicableFilterProperties.contains($0) == true })
            
            case .library: return librarySections.filter({ Set(hiddenLibrarySections).contains($0).inverted })
        }
    }()
    lazy var otherProperties: [PropertyStripPresented] = {
        
        switch context {
            
            case .filter(let filter, _): return otherFilterProperties.filter({ filter?.applicableFilterProperties.contains($0) == true })
            
            case .library: return otherLibrarySections
        }
    }()
    @objc let cellSizes: NSCache<Index, Size> = {
        
        let cache = NSCache<Index, Size>()
        cache.name = "Cell Sizes"
        cache.countLimit = 50
        
        return cache
    }()
    
    var context = FilterViewContext.library {
        
        didSet {
            
            prepareProperties()
            
            collectionView.reloadData()
            filterInputViewHeightConstraint.constant = context == .library || withinSearchTerm ? 0 : 52
            
            UIView.transition(with: filterTestButton, duration: 0.3, options: .transitionCrossDissolve, animations: {
                
                self.updateTestButton()
                
            }, completion: nil)
            
            if case .filter(_, let container) = context, hasSetUpSettingsGesture.inverted {
                
                let gr = UILongPressGestureRecognizer.init(target: container, action: #selector(UIViewController.showSettings(with:)))
                gr.minimumPressDuration = longPressDuration
                actionsButtonContainer.addGestureRecognizer(gr)
                LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
                
                hasSetUpSettingsGesture = true
            }
        }
    }
    
    lazy var hasSetUpSettingsGesture = false
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        collectionView.register(UINib.init(nibName: "PropertyCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        
        updateSpacing(self)
        
        notifier.addObserver(self, selector: #selector(reloadCollectionView), name: .propertiesUpdated, object: nil)
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(showCollectedActions(_:)))
        hold.minimumPressDuration = longPressDuration
        collectedView.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        
        let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(showItemActions(_:)))
        gr.minimumPressDuration = longPressDuration
        collectionView.addGestureRecognizer(gr)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
    }
    
    @objc func reloadCollectionView(_ notification: Notification) {
        
        guard let context = notification.userInfo?[String.filterViewContext] as? FilterViewContext, context ~= self.context else { return }
        
        prepareProperties()
        collectionView.reloadData()
    }
    
    @objc func updateSpacing(_ sender: Any) {
        
        filterTestButton.titleEdgeInsets.bottom = {
            
            switch activeFont {
                
                case .avenirNext, .system: return 3
                
                case .myriadPro: return 0
            }
        }()
        
        if sender is Notification {
        
            collectionView.reloadData()
        }
    }
    
    func prepareProperties() {
        
        switch context {
            
            case .filter(let filter, _):
                
                properties = filterProperties.filter({ Set(hiddenFilterProperties).contains($0).inverted && filter?.applicableFilterProperties.contains($0) == true })
                otherProperties = otherFilterProperties.filter({ filter?.applicableFilterProperties.contains($0) == true })
    
            case .library:
            
                properties = librarySections.filter({ Set(hiddenLibrarySections).contains($0).inverted })
                otherProperties = otherLibrarySections
        }
        
        editLabel.isHidden = (properties.isEmpty && otherProperties.isEmpty).inverted
    }
    
    @objc func showItemActions(_ gr: UILongPressGestureRecognizer) {
        
        guard gr.state == .began else { return }
        
        var title: String {
            
            switch context {
                
                case .filter: return "Search Categories Settings..."
                
                case .library: return "Library Section Settings..."
            }
        }
        
        let settings = AlertAction.init(title: title, style: .default, requiresDismissalFirst: true, handler: { [weak self] in
            
            guard let weakSelf = self, let vc = topViewController else { return }
            
            Transitioner.shared.showPropertySettings(from: vc, with: weakSelf.context)
        })
        
        guard let indexPath = collectionView.indexPathForItem(at: gr.location(in: collectionView)) else {
            
            Transitioner.shared.showAlert(title: nil, from: topViewController, with: settings)
            
            return
        }
        
        let isOtherCell = indexPath.row > properties.count - 1
        let property = isOtherCell ? nil : properties[indexPath.row]
        
        let move = AlertAction.init(title: isOtherCell ? "Ungroup" : "Group into \"Other\"", style: .default, handler: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            if isOtherCell {
                
                switch weakSelf.context {
                    
                    case .filter:
                    
                        var properties = filterProperties
                        properties.append(contentsOf: otherFilterProperties)
                    
                        prefs.set(properties.map({ $0.rawValue }), forKey: .filterProperties)
                        prefs.set([Int](), forKey: .otherFilterProperties)
                    
                    case .library:
                    
                        var sections = librarySections
                        sections.append(contentsOf: otherLibrarySections)
                        
                        prefs.set(sections.map({ $0.rawValue }), forKey: .librarySections)
                        prefs.set([Int](), forKey: .otherLibrarySections)
                }
                
                notifier.post(name: .propertiesUpdated, object: nil, userInfo: [String.filterViewContext: weakSelf.context])
                
            } else {
                
                property?.perform(.group(index: nil), context: weakSelf.context)
            }
        })
        
        let hide = AlertAction.init(title: "Hide" + (isOtherCell ? " All" : ""), style: .destructive, handler: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            if isOtherCell {
                
                switch weakSelf.context {
                    
                    case .filter:
                        
                        prefs.set(filterProperties.appending(contentsOf: otherFilterProperties).map({ $0.rawValue }), forKey: .filterProperties)
                        prefs.set(hiddenFilterProperties.appending(contentsOf: otherFilterProperties).map({ $0.rawValue }), forKey: .hiddenFilterProperties)
                        prefs.set([Int](), forKey: .otherFilterProperties)
                    
                    case .library:
                    
                        prefs.set(librarySections.appending(contentsOf: otherLibrarySections).map({ $0.rawValue }), forKey: .librarySections)
                        prefs.set(hiddenLibrarySections.appending(contentsOf: otherLibrarySections).map({ $0.rawValue }), forKey: .hiddenLibrarySections)
                        prefs.set([Int](), forKey: .otherLibrarySections)
                }
                
                notifier.post(name: .propertiesUpdated, object: nil, userInfo: [String.filterViewContext: weakSelf.context])
                
            } else {
                
                property?.perform(.hide, context: weakSelf.context)
            }
        })
        
        Transitioner.shared.showAlert(title: property?.title ?? "Other", from: topViewController, with: hide, move, settings)
    }
    
    class func with(context: FilterViewContext) -> FilterView {
        
        let view = Bundle.main.loadNibNamed("FilterView", owner: nil, options: nil)?.first as! FilterView
        
        view.context = context
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }
    
    @IBAction func clearSearchBar(_ sender: Any) {
        
        guard case .filter(filter: _, container: let container) = context, let searchBar = container?.searchBar else { return }
        
        searchBar.text = nil
        container?.searchBar?(searchBar, textDidChange: "")
        
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
    
    func collectorAlertActions(from actions: [ContainerViewController.CollectorActions]) -> [AlertAction] {
        
        guard let container = appDelegate.window?.rootViewController as? ContainerViewController else { return [] }
        
        return actions.map({
            
            switch $0 {
                
                case .play:
                    
                    return AlertAction.init(title: "Play", style: .default, requiresDismissalFirst: true, handler: {
                        
                        musicPlayer.play(container.queue, startingFrom: container.queue.first, from: container, withTitle: container.queue.count.fullCountText(for: .song), alertTitle: "Play")
                        
                        notifier.post(name: .endQueueModification, object: nil)
                    })
                
                case .clear:
                    
                    return AlertAction.init(title: "Discard Collected", style: .destructive, requiresDismissalFirst: true, handler: { notifier.post(name: .endQueueModification, object: nil) })
                
                case .shuffleSongs:
                    
                    return AlertAction.init(title: .shuffle(.songs), style: .default, requiresDismissalFirst: true, handler: {
                        
                        musicPlayer.play(container.queue, startingFrom: nil, shuffleMode: .songs, from: container, withTitle: container.queue.count.fullCountText(for: .song), alertTitle: .shuffle(.songs))
                        
                        notifier.post(name: .endQueueModification, object: nil)
                    })
                
                case .shuffleAlbums:
                    
                    return AlertAction.init(title: .shuffle(.albums), style: .default, requiresDismissalFirst: true, handler: {
                        
                        musicPlayer.play(container.queue.albumsShuffled, startingFrom: nil, from: container, withTitle: container.queue.count.fullCountText(for: .song), alertTitle: .shuffle(.albums))
                        
                        notifier.post(name: .endQueueModification, object: nil)
                    })
                
                case .queue:
                    
                    return AlertAction.init(title: "Queue...", style: .default, requiresDismissalFirst: true, handler: { [weak self] in
                        
                        guard let weakSelf = self, let vc: UIViewController = {
                           
                            switch weakSelf.context {
                                
                                case .filter(filter: _, container: let filterContainer) where filterContainer is FilterViewController: return filterContainer
                                
                                default: return container
                            }
                            
                        }() else { return }
                        
                        Transitioner.shared.addToQueue(from: vc, kind: .items(container.queue), context: .collector(manager: container))
                    })
                
                case .existingPlaylist:
                    
                    return AlertAction.init(title: "Add to Playlists...", style: .default, requiresDismissalFirst: true, handler: { [weak self] in
                        
                        guard let weakSelf = self, let vc: UIViewController = {
                           
                            switch weakSelf.context {
                                
                                case .filter(filter: _, container: let filterContainer) where filterContainer is FilterViewController: return filterContainer
                                
                                default: return container
                            }
                            
                        }() else { return }
                        
                        vc.performSegue(withIdentifier: "toPlaylists", sender: nil)
                    })
                
                case .newPlaylist:
                    
                    return AlertAction.init(title: "Create Playlist...", style: .default, requiresDismissalFirst: true, handler: { [weak self] in
                        
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
        
        let collectorActions = collectorAlertActions(from: actions)// + [.cancel()]
        
        switch context {
            
            case .filter(filter: _, container: let filterContainer) where filterContainer is FilterViewController:
                
                Transitioner.shared.showAlert(title: container.queue.count.fullCountText(for: .song), from: filterContainer, with: collectorActions)
                
//                filterContainer?.present(UIAlertController.withTitle(container.queue.count.fullCountText(for: .song), message: nil, style: .actionSheet, actions: collectorActions), animated: true, completion: nil)
            
            default:
                
                Transitioner.shared.showAlert(title: container.queue.count.fullCountText(for: .song), from: container, with: collectorActions)
                
//                container.present(UIAlertController.withTitle(container.queue.count.fullCountText(for: .song), message: nil, style: .actionSheet, actions: collectorActions), animated: true, completion: nil)
        }
    }
    
    @IBAction func rightButtonTapped() {
        
        switch context {
            
        case .filter(filter: _, container: let container) where !withinSearchTerm: container?.showPropertyTests()
            
            default: notifier.post(name: .performSecondaryAction, object: (appDelegate.window?.rootViewController as? ContainerViewController)?.activeViewController)
        }
    }
    
    func updateTestButton() {
        
        switch self.context {
            
            case .filter(filter: let filter, container: _) where !self.withinSearchTerm:
                
                self.filterTestBorderView.layer.setRadiusTypeIfNeeded(to: true)
                self.filterTestBorderView.layer.cornerRadius = 14
                self.filterTestButton.setTitle(filter?.testTitle, for: .normal)
                self.filterTestButton.setImage(nil, for: .normal)
    
            default:
                
                self.filterTestBorderView.layer.setRadiusTypeIfNeeded(to: false)
                self.filterTestBorderView.layer.cornerRadius = 14
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
        
        return properties.count + (otherProperties.isEmpty ? 0 : 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PropertyCollectionViewCell
        
        prepare(cell, at: indexPath)
        
        return cell
    }
    
    func prepare(_ cell: PropertyCollectionViewCell, at indexPath: IndexPath) {
        
        if otherProperties.isEmpty.inverted && indexPath.row == properties.count {
            
            let isActive: Bool = {
                
                switch context {
                    
                    case . filter(let filter, _): return otherProperties.contains(where: { $0 as? Property == filter?.filterProperty })
                    
                    case .library: return otherProperties.contains(where: { $0 as? LibrarySection == LibrarySection(rawValue: lastUsedLibrarySection) })
                }
            }()
            
            let text = isActive ? "OTHER" : "Other"
            
            cell.label.text = text
            cell.label.fontWeight = (isActive ? FontWeight.bold : .regular).rawValue
            
        } else {
        
            let property = properties[indexPath.row]
            let isActive: Bool = {
                
                switch context {
                    
                    case . filter(let filter, _): return filter?.filterProperty == property as? Property
                    
                    case .library: return LibrarySection(rawValue: lastUsedLibrarySection) == property as? LibrarySection
                }
            }()
            
            let text = isActive ? property.title.uppercased() : property.title
            
            cell.label.text = text
            cell.label.fontWeight = (isActive ? FontWeight.bold : .regular).rawValue
        }
    }
    
    func selectCell(at indexPath: IndexPath, usingOtherArray useOtherArray: Bool, arrayIndex: Int) {
        
        var indexPaths = [IndexPath]()
        let relevantArray = useOtherArray ? otherProperties : properties
        
        switch context {
            
            case .filter(let filter, let container):
                
                guard let property = relevantArray[arrayIndex] as? Property, let oldProperty = filter?.filterProperty, property != oldProperty else {
                    
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
                
                if let index: Int = {
                    
                    if let index = (properties as? [Property])?.firstIndex(of: oldProperty) {
                        
                        return index
                        
                    } else if let _ = (otherProperties as? [Property])?.firstIndex(of: oldProperty) {
                        
                        return properties.count
                    }
                    
                    return nil
                    
                }() {
                    
                    let oldIndexPath = IndexPath.init(row: index, section: 0)
                    
                    if collectionView.indexPathsForVisibleItems.contains(oldIndexPath), oldIndexPath != indexPath {
                    
                        indexPaths.append(oldIndexPath)
                    }
                }
                
                filter?.clearIfNeeded(with: property)
                filter?.filterProperty = property
                filter?.verifyPropertyTest(with: container)
                container?.requiredInputView?.pickerView.reloadAllComponents()
                container?.updateRightView()
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
                
                guard let section = relevantArray[arrayIndex] as? LibrarySection, let oldSection = LibrarySection(rawValue: prefs.integer(forKey: .lastUsedLibrarySection)), section != oldSection else {
                    
                    if let container = appDelegate.window?.rootViewController as? ContainerViewController, container.libraryNavigationController?.topViewController != container.libraryNavigationController?.viewControllers.first {
                        
                        container.libraryNavigationController?.popToRootViewController(animated: true)
                    }
                    
                    collectionView.deselectItem(at: indexPath, animated: true)
                    
                    return
                }
                
                if let libraryVC = (appDelegate.window?.rootViewController as? ContainerViewController)?.libraryNavigationController?.viewControllers.first as? LibraryViewController {
                
                    indexPaths.append(indexPath)
                    
                    if let index: Int = {
                        
                        if let index = (properties as? [LibrarySection])?.firstIndex(of: oldSection) {
                            
                            return index
                            
                        } else if let _ = (otherProperties as? [LibrarySection])?.firstIndex(of: oldSection) {
                            
                            return properties.count
                        }
                        
                        return nil
                        
                    }() {
                        
                        let oldIndexPath = IndexPath.init(row: index, section: 0)
                        
                        if collectionView.indexPathsForVisibleItems.contains(oldIndexPath), oldIndexPath != indexPath {
                            
                            indexPaths.append(oldIndexPath)
                        }
                    }
                    
                    prefs.set(section.rawValue, forKey: .lastUsedLibrarySection)
                    libraryVC.activeChildViewController = libraryVC.viewControllerForCurrentSection()
                    
                    if libraryVC.navigationController?.topViewController != libraryVC.navigationController?.viewControllers.first {
                        
                        libraryVC.navigationController?.popToRootViewController(animated: true)
                    }
                }
                
                collectionView.deselectItem(at: indexPath, animated: true)
        }
        
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            
            guard let weakSelf = self else { return }

            indexPaths.forEach({

                if weakSelf.collectionView.indexPathsForVisibleItems.contains($0), let cell = weakSelf.collectionView.cellForItem(at: $0) as? PropertyCollectionViewCell {

                    cell.alpha = 0
                }
            })
            
        }, completion: { [weak self] _ in
            
            guard let weakSelf = self else { return }

            indexPaths.forEach({

                if weakSelf.collectionView.indexPathsForVisibleItems.contains($0), let cell = weakSelf.collectionView.cellForItem(at: $0) as? PropertyCollectionViewCell {
                    
                    cell.alpha = 0
                    
                    weakSelf.prepare(cell, at: $0)
                }
            })

            UIView.animate(withDuration: 0.2, animations: {
                
                guard let weakSelf = self else { return }

                indexPaths.forEach({

                    if weakSelf.collectionView.indexPathsForVisibleItems.contains($0), let cell = weakSelf.collectionView.cellForItem(at: $0) as? PropertyCollectionViewCell {

                        cell.alpha = 1
                        weakSelf.collectionView.deselectItem(at: $0, animated: false)
                    }
                })

                weakSelf.collectionView.performBatchUpdates({  }, completion: { _ in })
            })
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row == properties.count {
            
            let actions = otherProperties.enumerated().map({ (index, property) -> AlertAction in
                
                var isCurrentProperty: Bool {
                    
                    switch self.context {
                        
                        case .filter(filter: let filter, container: _): return filter?.filterProperty == property as? Property
                        
                        case .library: return LibrarySection(rawValue: lastUsedLibrarySection) == property as? LibrarySection
                    }
                }
                
                return AlertAction.init(title: property.title, style: .default, accessoryType: .check({ isCurrentProperty }), handler: { [weak self] in self?.selectCell(at: indexPath, usingOtherArray: true, arrayIndex: index) })
            })
            
            Transitioner.shared.showAlert(title: nil, from: topViewController, with: actions)
            
//            topViewController?.present(UIAlertController.withTitle(nil, message: nil, style: .actionSheet, actions: actions + [.cancel()]), animated: true, completion: nil)
            
            collectionView.deselectItem(at: indexPath, animated: true)
            
        } else {
            
            selectCell(at: indexPath, usingOtherArray: false, arrayIndex: indexPath.row)
        }
    }
}

extension FilterView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let isOtherCell = indexPath.row > properties.count - 1
        
        let property = isOtherCell ? nil : properties[indexPath.row]
        let isActive: Bool = {
            
            switch self.context {
                
                case . filter(let filter, _):
                    
                    if isOtherCell, let property = filter?.filterProperty {
                        
                        return Set(otherFilterProperties).contains(property)
                    }
                    
                    return filter?.filterProperty == property as? Property
                
                case .library:
                    
                    if isOtherCell, let section = LibrarySection(rawValue: lastUsedLibrarySection) {
                        
                        return Set(otherLibrarySections).contains(section)
                    }
                    
                    return LibrarySection(rawValue: lastUsedLibrarySection) == property as? LibrarySection
            }
        }()
        
        if let size = cellSizes.object(forKey: Index.init(indexPath: indexPath, uppercased: isActive)) {

            return .init(width: size.width, height: size.height)
        }
        
        let text = isActive ? property?.title.uppercased() ?? "OTHER" : property?.title ?? "Other"
        
        let size = Size.init(width: (text as NSString).boundingRect(with: .init(width: CGFloat.greatestFiniteMagnitude, height: 36), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [.font: UIFont.font(ofWeight: isActive ? .bold : .regular, size: 17)], context: nil).width + 32, height: 36)
        
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
