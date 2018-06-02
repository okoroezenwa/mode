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
    func filter(with searchText: String)
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
            
            let actions = Array(Int64.FileSize.byte.rawValue...Int64.FileSize.terabyte.rawValue).flatMap({ Int64.FileSize(rawValue: $0) }).map({ size in UIAlertAction.init(title: size.suffix, style: .default, handler: { _ in action(size) }) })
            
            let clear = UIAlertAction.init(title: "Clear", style: .destructive, handler: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                weakSelf.searchBar.text = nil
                weakSelf.searchBar?(weakSelf.searchBar, textDidChange: "")
            })
            
            let array = searchBar.text?.isEmpty == true ? [] : [clear]
            
            present(UIAlertController.withTitle(nil, message: nil, style: .actionSheet, actions: actions + array + [.cancel()]), animated: true, completion: nil)
            
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
            
            print(error.localizedDescription)
        }
    }
    
    func resetRecentSearches() {
        
        guard let sender = sender else { return }
        
        let recentSearchFetch: NSFetchRequest<RecentSearch> = RecentSearch.fetchRequest()
        recentSearchFetch.predicate = NSPredicate.init(format: "id = %@", NSNumber.init(value: sender.id))
        
        do {
            
            let results = try managedContext.fetch(recentSearchFetch)
            
            recentSearches = Array(results.reversed())
            updateDeleteButton()
            tableView.reloadData()
            
        } catch let error {
            
            print(error.localizedDescription)
        }
    }
    
    func updateDeleteButton() {
        
        if let searchVC = self as? SearchViewController {
            
            searchVC.emptyStackView.isHidden = filtering ? true : !recentSearches.isEmpty
            searchVC.topView.layoutIfNeeded()
            searchVC.clearButtonTrailingConstraint.constant = filtering || recentSearches.isEmpty ? -44 : 0
            
            UIView.animate(withDuration: 0.3, animations: { searchVC.topView.layoutIfNeeded() })
            
        } else if let filterVC = self as? FilterViewController, let parent = filterVC.parent as? PresentedContainerViewController {
            
            UIView.animate(withDuration: 0.3, animations: {
                
                ([parent.rightButton, parent.rightBorderView] as [UIView]).forEach({ $0.alpha = self.filtering || self.recentSearches.isEmpty ? 0 : 1 })
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
        
        if let properties = filterViewContainer.filterView.properties as? [Property], let property = Property(rawValue: property), let index = properties.index(of: property), let sender = sender {
            
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
        
        let delete = UIAlertAction.init(title: "Clear \(tableView.isEditing && (tableView.indexPathsForSelectedRows ?? []).isEmpty.inverted ? "Selected" : "All")", style: .destructive, handler: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.tableView.isEditing, let indexPaths = weakSelf.tableView.indexPathsForSelectedRows, indexPaths.isEmpty.inverted {
                
                weakSelf.clear(items: indexPaths.map({ weakSelf.recentSearches[$0.row] }))
                
            } else {
                
                weakSelf.clear(items:  weakSelf.recentSearches)
            }
        })
        
        present(UIAlertController.withTitle(nil, message: nil, style: .actionSheet, actions: delete, .cancel()), animated: true, completion: nil)
    }
    
    func showPropertyTests() {
        
        guard let sender = sender else { return }
        
        var actions = [UIAlertAction]()
        
        [PropertyTest.contains, .isExactly, .beginsWith, .endsWith, .isOver, .isUnder].filter({ sender.filterTests.contains($0) }).forEach({ test in
            
            actions.append(UIAlertAction.init(title: sender.title(for: test, property: sender.filterProperty), style: .default, handler: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                sender.propertyTest = test
                weakSelf.updateTestView()
                weakSelf.requiredInputView?.pickerView.reloadAllComponents()
            }))
        })
        
        present(UIAlertController.withTitle(nil, message: sender.filterProperty.title.capitalized, style: .actionSheet, actions: actions + [.cancel()]), animated: true, completion: nil)
    }
    
    func deleteRecentSearch(in cell: RecentSearchTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell), let filter = sender else { return }
        
        let search = recentSearches[indexPath.row]
        let property = Property(rawValue: Int(search.property)) ?? .title
        let test = PropertyTest(rawValue: search.propertyTest ?? "") ?? filter.initialPropertyTest(for: property)
        let alertTitle = property.title + " " + filter.title(for: test, property: property)
        
        let clear = UIAlertAction.init(title: "Clear", style: .destructive, handler: { _ in self.clear(items: self.recentSearches[indexPath.row]) })
        
        let alert = UniversalMethods.alertController(withTitle: alertTitle, message: search.title, preferredStyle: .actionSheet, actions: clear, UniversalMethods.cancelAlertAction())
        
        present(alert, animated: true, completion: nil)
    }
}
