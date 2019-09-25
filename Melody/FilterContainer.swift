//
//  FilterContainer.swift
//  Mode
//
//  Created by Ezenwa Okoro on 19/03/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit
import CoreData

protocol FilterContainer: LargeActivityIndicatorContaining, UISearchBarDelegate, InfoLoading {
    
    var requiredInputView: InputView? { get set }
    var filterViewContainer: FilterViewContainer! { get set }
    var rightViewButton: MELButton { get set }
    var searchBar: MELSearchBar! { get }
    var filterOperationQueue: OperationQueue { get }
    var rightViewSetUp: Bool { get set }
    var sender: (UIViewController & Filterable)? { get set }
    var unfilteredPoint: CGPoint { get set }
    var recentSearches: [RecentSearch] { get set }
    var category: SearchCategory { get set }
    var filtering: Bool { get set }
    var emptyCondition: Bool { get }
    func filter(with searchText: String)
    func updateHeaderView(withCount count: Int)
}

extension FilterContainer where Self: UIViewController {
    
    var managedContext: NSManagedObjectContext { return appDelegate.managedObjectContext }
    
    func updateTestView() {
        
        guard case .filter(filter: let filter, container: _) = filterViewContainer.context else { return }
        
        filterViewContainer.filterView.filterTestButton.setTitle(filter?.testTitle, for: .normal)
        
        UIView.animate(withDuration: 0.3, animations: { self.filterViewContainer.layoutIfNeeded() })
    }
    
    func updateRightView() {
        
        guard case .filter(filter: let sender, container: _) = filterViewContainer.context, let filter = sender else { return }
        
        let details = filter.rightViewDetails
        
        searchBar.textField?.rightView = details.rightView
        updateRightViewButtonText()
        searchBar.textField?.rightViewMode = details.mode
        
        if let _ = details.rightView?.superview {
            
            rightViewSetUp = true
        }
    }
    
    func updateRightViewButtonText() {
        
        guard let size = Int64.FileSize(rawValue: primarySizeSuffix) else { return }
        
        rightViewButton.setTitle(size.suffix, for: .normal)
    }
    
    func updateRightViewButton() {
        
        guard case .filter(filter: let sender, container: _) = filterViewContainer.context, let filter = sender else { return }
        
        let action: ((Int64.FileSize) -> Void) = { [weak self] size in
            
            guard let weakSelf = self else { return }
            
            prefs.set(size.rawValue, forKey: .primarySizeSuffix)
            weakSelf.rightViewButton.setTitle(size.suffix, for: .normal)
            weakSelf.filter(with: weakSelf.searchBar.text ?? "")
        }
        
        switch filter.filterProperty {
            
            case .size:
                
                let actions = Array(Int64.FileSize.byte.rawValue...Int64.FileSize.terabyte.rawValue).compactMap({ Int64.FileSize(rawValue: $0) }).map({ size in AlertAction.init(title: size.suffix, style: .default, handler: { action(size) }) })
                
                showAlert(title: nil, with: actions)
            
            default: return
        }
    }
    
    func saveRecentSearch(withTitle title: String?, resignFirstResponder resign: Bool) {
        
        guard let recentSearchEntity = NSEntityDescription.entity(forEntityName: "RecentSearch", in: managedContext) else { print("Couldn't get recent searches"); return }
        
        guard let title = title, title.isEmpty.inverted, let sender = sender else { return }
        
        if let recentSearch = recentSearches.first(where: { $0.uniqueID == sender.uniqueID(with: category, searchBar: searchBar) }) {
            
            managedContext.delete(recentSearch)
        }
        
        let recentSearch = RecentSearch(entity: recentSearchEntity, insertInto: managedContext)
        recentSearch.title = title
        recentSearch.category = Int16(category.rawValue)
        recentSearch.property = Int16(sender.filterProperty.rawValue)
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
            searchVC.emptyStackView.isHidden = filtering ? true : !recentSearches.isEmpty
            
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
        
        if let properties = filterViewContainer.filterView.properties as? [Property], let property = Property(rawValue: property), let index = properties.firstIndex(of: property), let sender = sender {
            
            sender.propertyTest = {
                
                if let string = propertyTest, let test = PropertyTest(rawValue: string) {
                    
                    return test
                }
                
                return sender.initialPropertyTest(for: property)
            }()
            
            filterViewContainer.filterView.collectionView(filterViewContainer.filterView.collectionView, didSelectItemAt: .init(row: index, section: 0))
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
        
        let delete = AlertAction.init(title: "Clear \(tableView.isEditing && (tableView.indexPathsForSelectedRows ?? []).isEmpty.inverted ? "Selected" : "All")", style: .destructive, handler: { [weak self] in
            
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
        
        let actions = [PropertyTest.contains, .isExactly, .beginsWith, .endsWith, .isOver, .isUnder].filter({ sender.filterTests.contains($0) }).map({ test in
            
            AlertAction.init(title: sender.title(for: test, property: sender.filterProperty), style: .default, accessoryType: .check({ test == sender.propertyTest }), handler: { [weak self] in
                
                guard let weakSelf = self else { return }
                
                sender.propertyTest = test
                weakSelf.updateTestView()
                weakSelf.requiredInputView?.pickerView.reloadAllComponents()
            })
        })
        
        showAlert(title: sender.filterProperty.title.capitalized, with: actions)
    }
    
    func deleteRecentSearch(in cell: RecentSearchTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell), let filter = sender else { return }
        
        let search = recentSearches[indexPath.row]
        let property = Property(rawValue: Int(search.property)) ?? .title
        let test = PropertyTest(rawValue: search.propertyTest ?? "") ?? filter.initialPropertyTest(for: property)
        let alertTitle = property.title + " " + filter.title(for: test, property: property)
        
        let clear = AlertAction.init(title: "Clear", style: .destructive, handler: { self.clear(items: self.recentSearches[indexPath.row]) })
        
        showAlert(title: alertTitle, subtitle: search.title, with: clear)
    }
}
