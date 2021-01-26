//
//  FilterContainer.swift
//  Mode
//
//  Created by Ezenwa Okoro on 19/03/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit
import CoreData

protocol FilterContainer: UISearchBarDelegate, InfoLoading, CentreViewDisplaying, TableViewContaining {
    
    var requiredInputView: InputView? { get set }
    var filterViewContainer: FilterViewContainer! { get set }
    var rightViewButton: MELButton { get set }
    var searchBar: MELSearchBar! { get }
    var filterOperationQueue: OperationQueue { get }
    var sender: (UIViewController & Filterable)? { get set }
    var unfilteredPoint: CGPoint { get set }
    var recentSearches: [RecentSearch] { get set }
    var category: SearchCategory { get set }
    var filtering: Bool { get set }
    var filterTitle: String? { get }
    var emptyCondition: Bool { get }
    func filter(with searchText: String)
    func updateHeaderView(withCount count: Int)
}

extension FilterContainer where Self: UIViewController {
    
    var managedContext: NSManagedObjectContext { return appDelegate.managedObjectContext }
    
    var placeholder: String {
        
        if let placeholder = sender?.placeholder { return placeholder }
        
        let initial = self is SearchViewController ? "Search" : "Filter"
        
        guard let end = filterTitle else { return initial }
        
        return initial + " " + end
    }
    
    func updateTestView() {
        
        guard let filter = filterViewContainer.filterInfo?.filter else { return }
        
        filterViewContainer.filterView.leftView.translatesAutoresizingMaskIntoConstraints = false
        filterViewContainer.filterView.filterTestButton.setTitle(filter.testTitle, for: .normal)
        
        UIView.animate(withDuration: 0.3, animations: { self.filterViewContainer.layoutIfNeeded() }, completion: { _ in self.filterViewContainer.filterView.leftView.translatesAutoresizingMaskIntoConstraints = true })
    }
    
    func updateRightView(animated: Bool = true) {
        
        guard let sender = sender else { return }
        
        let constraint = filterViewContainer.filterView.rightButtonContainerWidthConstraint
        let container = filterViewContainer.filterView.rightButtonContainer
        let canUseRightView = sender.filterProperty.canUseRightView
        
        if animated {
        
            filterViewContainer.filterView.leftView.translatesAutoresizingMaskIntoConstraints = false
        }

        constraint?.priority = .init(rawValue: canUseRightView.inverted ? 999 : 250)
        filterViewContainer.filterView.rightButtonContainerEqualityWidthConstraint.isActive = canUseRightView
        updateRightViewButtonText()
        
        if animated {

            UIView.animate(withDuration: 0.3, animations: {

                container?.alpha = canUseRightView.inverted ? 0 : 1
                container?.superview?.layoutIfNeeded()
            
            }, completion: { _ in self.filterViewContainer?.filterView.leftView.translatesAutoresizingMaskIntoConstraints = true })
            
        } else {
            
            container?.alpha = canUseRightView.inverted ? 0 : 1
            container?.superview?.layoutIfNeeded()
        }
    }
    
    func updateRightViewButtonText() {
        
        guard let sender = sender else { return }
        
        switch sender.filterProperty {
            
            case .album, .albumCount, .artist, .albumArtist, .artwork, .composer, .genre, .isCloud, .isCompilation, .isExplicit, .plays, .rating, .songCount, .title, .year, .affinity, .default, .random, .albumName, .albumYear, .duration, .dateAdded, .lastPlayed: break
            
//            case .duration: rightViewButton.setTitle("s", for: .normal)
//
//            case .dateAdded, .lastPlayed: rightViewButton.setTitle("d ago", for: .normal)
                 
            case .size:
            
                guard let size = Int64.FileSize(rawValue: primarySizeSuffix) else { return }
                
                rightViewButton.setTitle(size.suffix, for: .normal)
        }
    }
    
    func showRightButtonOptions() {
        
        guard let filter = filterViewContainer.filterInfo?.filter, filter.filterProperty.canUseRightView else { return }
        
        let action: ((Int) -> Void) = { [weak self] rawValue in
            
            guard let weakSelf = self else { return }
            
            if filter.filterProperty == .size {
            
                prefs.set(rawValue, forKey: .primarySizeSuffix)
            }
            
            weakSelf.updateRightViewButtonText()
            weakSelf.filter(with: weakSelf.searchBar.text ?? "")
        }
        
        let actions: [AlertAction] = {
            
            switch filter.filterProperty {
                
                case .size: return Array(Int64.FileSize.byte.rawValue...Int64.FileSize.terabyte.rawValue).compactMap({ Int64.FileSize(rawValue: $0) }).map({ size in AlertAction.init(title: size.suffix, style: .default, requiresDismissalFirst: false, handler: { action(size.rawValue) }) })
                
                case .duration: return [AlertAction.init(title: "s", style: .default, requiresDismissalFirst: false, handler: nil)]
                
                case .dateAdded, .lastPlayed: return [AlertAction.init(title: "d ago", style: .default, requiresDismissalFirst: false, handler: nil)]
                
                default: return []
            }
        }()
        
        showAlert(title: nil, with: actions, shouldSortActions: false)
    }
    
    func saveRecentSearch(withTitle title: String?, resignFirstResponder resign: Bool) {
        
        guard let recentSearchEntity = NSEntityDescription.entity(forEntityName: "RecentSearch", in: managedContext) else { print("Couldn't get recent \(self is FilterViewController ? "filters" : "searches")"); return }
        
        guard let title = title, title.isEmpty.inverted, let sender = sender else { return }
        
        if let recentSearch = recentSearches.first(where: { $0.uniqueID == sender.uniqueID(with: category, searchBar: searchBar) }) {
            
            managedContext.delete(recentSearch)
        }
        
        let recentSearch = RecentSearch(entity: recentSearchEntity, insertInto: managedContext)
        recentSearch.title = title
        recentSearch.category = Int16(category.rawValue)
        recentSearch.property = Int16(sender.filterProperty.oldRawValue)
        recentSearch.propertyTest = sender.propertyTest.rawValue
        recentSearch.id = NSNumber.init(value: sender.id)
        recentSearch.uniqueID = sender.uniqueID(with: category, searchBar: searchBar)
        
        do {
            
            try managedContext.save()
            resetRecentSearches()
            
            if resign {
                
                searchBar?.resignFirstResponder()
            }
            
        } catch let error {
            
            print(error)
        }
    }
    
    func resetRecentSearches() {
        
        guard let sender = sender else { return }
        
        let recentSearchFetch: NSFetchRequest<RecentSearch> = RecentSearch.fetchRequest()
        recentSearchFetch.predicate = NSPredicate.init(format: "id = %@", NSNumber.init(value: sender.id))
        
        do {
            
            let results = try managedContext.fetch(recentSearchFetch)
            
            recentSearches = Array(results.reversed())
            
            if filtering.inverted {
            
                self.updateDeleteButton()
            }
            
            updateCurrentView(to: recentSearches.isEmpty ? .labels(components: [.image, .title, .subtitle]) : .none)
            
            if filtering.inverted {
                
                tableView.reloadData()
                updateHeaderView(withCount: 0)
            }
            
        } catch let error {
            
            print(error.localizedDescription)
        }
    }
    
    func updateDeleteButton() {
        
        if let searchVC = self as? SearchViewController {
            
            searchVC.buttonDetails = (.clear, filtering ? true : recentSearches.isEmpty)
//            searchVC.emptyStackView.isHidden = filtering ? true : !recentSearches.isEmpty
            
        } else if let filterVC = self as? FilterViewController, let _ = filterVC.container {
            
            filterVC.buttonDetails = (filtering ? .actions : .clear, filtering ? filterVC.tableContainer?.filteredEntities.isEmpty == true : recentSearches.isEmpty)
            
        } else if let filterVC = self as? FilterViewController, let parent = filterVC.parent as? PresentedContainerViewController {
            #warning("Need to properly manage the state of the button image depending on filter operation status")
            parent.rightButton.setImage(VisualEffectNavigationBar.RightButtonType.clear.image, for: .normal)
            
            UIView.animate(withDuration: 0.3, animations: {
                
                ([parent.rightButton, parent.rightBorderView] as [UIView]).forEach({ $0.alpha = self.filtering || self.recentSearches.isEmpty || filterVC.tableContainer?.filteredEntities.isEmpty != false ? 0 : 1 })
            })
        }
    }
    
    func highlightSearchBar(withText text: String?, property: Int, propertyTest: String?, setFirstResponder: Bool) {
        
        if !filtering {
            
            unfilteredPoint = .init(x: 0, y: tableView.contentOffset.y)
        }
        
        if setFirstResponder {
            
            sender?.invokeSearch()
        }
        
        sender?.ignorePropertyChange = true
        
        if let property = Property.fromOldRawValue(property), let sender = sender {
            
            sender.propertyTest = {
                
                if let string = propertyTest, let test = PropertyTest(rawValue: string) {
                    
                    return test
                }
                
                return sender.initialPropertyTest(for: property)
            }()
            
            if sender.filterProperty != property {
                
                sender.clearIfNeeded(with: property)
                sender.filterProperty = property
                filterViewContainer.filterView.propertyButton.setTitle(property.title, for: .normal)
                requiredInputView?.pickerView.reloadAllComponents()
                updateRightView()
                UIView.performWithoutAnimation { searchBar.updateTextField(with: placeholder) }
            }
            
            if sender.ignorePropertyChange {
                
                sender.verifyPropertyTest(with: self)
                
            } else if searchBar.isFirstResponder.inverted, searchBar.textField?.text?.isEmpty == true {
                
                searchBar.becomeFirstResponder()
            }
        }
        
        sender?.ignorePropertyChange = false
        
        if let text = text, let searchBar = searchBar {
            
            searchBar.text = text
            self.searchBar?(searchBar, textDidChange: text)
        }
    }
    
    func clear(items: [RecentSearch]) {
        
        for search in items {
            
            managedContext.delete(search)
        }
        
        do {
            
            try managedContext.save()
            resetRecentSearches()
            
        } catch let error {
            
            print(error.localizedDescription)
        }
    }
    
    func clear(items: RecentSearch...) {
        
        clear(items: items)
    }
    
    func clearRecentSearches() {
        
        let delete = AlertAction.init(title: "Clear \(tableView.isEditing && (tableView.indexPathsForSelectedRows ?? []).isEmpty.inverted ? "Selected" : "All")", style: .destructive, requiresDismissalFirst: false, handler: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.tableView.isEditing, let indexPaths = weakSelf.tableView.indexPathsForSelectedRows, indexPaths.isEmpty.inverted {
                
                weakSelf.clear(items: indexPaths.map({ weakSelf.recentSearches[$0.row] }))
                
            } else {
                
                weakSelf.clear(items:  weakSelf.recentSearches)
            }
        })
        
        showAlert(title: nil, with: delete)
    }
    
    func showPropertyTests() {
        
        guard let sender = sender else { return }
        
        let actions = PropertyTest.allCases.filter({ sender.filterTests.contains($0) }).map({ test in
            
            AlertAction.init(title: sender.title(for: test, property: sender.filterProperty), style: .default, accessoryType: .check({ test == sender.propertyTest }), requiresDismissalFirst: false, handler: { [weak self] in
                
                guard let weakSelf = self else { return }
                
                sender.propertyTest = test
                weakSelf.updateTestView()
                weakSelf.requiredInputView?.pickerView.reloadAllComponents()
                UIView.performWithoutAnimation { weakSelf.searchBar.updateTextField(with: weakSelf.placeholder) }
            })
        })
        
        showAlert(title: sender.filterProperty.title.capitalized, with: actions)
    }
    
    func showFilterProperties() {
        
        guard let sender = sender else { return }
        
        let propertyHandler: ([Property]) -> [AlertAction] = { properties in
            
            properties.map({ property in
                
                AlertAction.init(title: property.title, subtitle: nil, style: .default, accessoryType: .check({ sender.filterProperty == property }), image: #imageLiteral(resourceName: "Search22"), requiresDismissalFirst: false, handler: { [weak self] in
                    
                    guard let weakSelf = self else { return }
                    
                    if sender.filterProperty != property {
                        
                        sender.clearIfNeeded(with: property)
                        sender.filterProperty = property
                        weakSelf.filterViewContainer.filterView.propertyButton.setTitle(property.title, for: .normal)
                        sender.verifyPropertyTest(with: weakSelf)
                        weakSelf.requiredInputView?.pickerView.reloadAllComponents()
                        weakSelf.updateRightView()
                        UIView.performWithoutAnimation { weakSelf.searchBar.updateTextField(with: weakSelf.placeholder) }
                    }
                    
                    if sender.ignorePropertyChange {
                        
                        sender.verifyPropertyTest(with: weakSelf)
                        
                    } else if weakSelf.searchBar.isFirstResponder.inverted, isInDebugMode.inverted, weakSelf.searchBar.textField?.text?.isEmpty == true {
                        
                        weakSelf.searchBar.becomeFirstResponder()
                    }
                })
            })
        }
        
        let initial = "\(self is FilterViewController ? "Filter" : "Search") Categories"
        let title = initial + " Settings..."
        let handler = { [weak self] in
            
            guard let weakSelf = self else { return }
            
            Transitioner.shared.showPropertySettings(from: weakSelf, with: .filter)
        }
        
        var properties = propertyHandler(filterProperties.removing(contentsOf: hiddenFilterProperties))
        
        properties.append(.init(title: "Secondary Categories...", accessoryType: .check({ Set(otherFilterProperties).contains(sender.filterProperty) }), image: #imageLiteral(resourceName: "More22"), requiresDismissalFirst: true, handler: { [weak self] in
            
            self?.showAlert(title: "Secondary Categories", subtitle: nil, with: propertyHandler(otherFilterProperties), shouldSortActions: false, rightAction: { _, vc in vc.dismiss(animated: true, completion: handler) }, images: (nil, #imageLiteral(resourceName: "Settings13")))
            
        }), if: otherFilterProperties.isEmpty.inverted)
        
        properties.append(.init(title: title, requiresDismissalFirst: false, handler: handler), if: useSystemAlerts)
        
        showAlert(title: initial, subtitle: nil, with: properties, shouldSortActions: false, rightAction: { _, vc in vc.dismiss(animated: true, completion: handler) }, images: (nil, #imageLiteral(resourceName: "Settings13")))
    }
    
    func deleteRecentSearch(in cell: RecentSearchTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell), let filter = sender else { return }
        
        let search = recentSearches[indexPath.row]
        let property = Property.fromOldRawValue(Int(search.property)) ?? .title
        let test = PropertyTest(rawValue: search.propertyTest ?? "") ?? filter.initialPropertyTest(for: property)
        let alertTitle = property.title + " " + filter.title(for: test, property: property)
        
        let clear = AlertAction.init(title: "Clear", style: .destructive, requiresDismissalFirst: false, handler: { self.clear(items: self.recentSearches[indexPath.row]) })
        
        showAlert(title: alertTitle, subtitle: search.title, with: clear)
    }
}
